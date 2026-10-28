/*
 * MacWin32Api.mm
 * --------------
 * Purpose: macOS implementations of the Win32 / MFC entry points that mptrack calls and that the
 *          window and GDI shims (MacWin32Afx.mm, MacGDI.mm) do not cover: kernel objects, files,
 *          INI profiles, window queries, menus, timers, keyboard state, shell helpers and main().
 */

#import "MacWin32Afx.h"
#import "MacResources.h"
#import "MacGDI.h"
#import <Carbon/Carbon.h>
#include "afxole.h"

#include <atomic>
#include <condition_variable>
#include <cstdarg>
#include <cwchar>
#include <dirent.h>
#include <fcntl.h>
#include <fnmatch.h>
#include <functional>
#include <map>
#include <mutex>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <pthread.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <unistd.h>

// Win32 constants the shim headers do not define.
#ifndef SORT_DIGITSASNUMBERS
#define SORT_DIGITSASNUMBERS 0x00000008
#endif
#ifndef MB_TYPEMASK
#define MB_TYPEMASK 0x0000000FL
#endif
#ifndef MB_ICONMASK
#define MB_ICONMASK 0x000000F0L
#endif
#ifndef CSIDL_DESKTOP
#define CSIDL_DESKTOP 0x0000
#endif
#ifndef CSIDL_DESKTOPDIRECTORY
#define CSIDL_DESKTOPDIRECTORY 0x0010
#endif

// ---------------------------------------------------------------------------------------------
// String helpers
// ---------------------------------------------------------------------------------------------

static std::string W2U(LPCWSTR s, int len = -1)
{
	if(!s) return {};
	if(len < 0) len = (int)wcslen(s);
	NSString *ns = [[NSString alloc] initWithBytes:s length:(NSUInteger)len * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
	return ns ? std::string([ns UTF8String]) : std::string();
}

static std::wstring U2W(const char *s, int len = -1)
{
	if(!s) return {};
	if(len < 0) len = (int)strlen(s);
	NSString *ns = [[NSString alloc] initWithBytes:s length:(NSUInteger)len encoding:NSUTF8StringEncoding];
	if(!ns) return {};
	NSData *data = [ns dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
	return std::wstring((const wchar_t *)data.bytes, data.length / sizeof(wchar_t));
}

static NSString *W2NS(LPCWSTR s)
{
	return s ? [[NSString alloc] initWithBytes:s length:wcslen(s) * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding] : @"";
}

static std::wstring NS2W(NSString *s)
{
	if(!s) return {};
	NSData *data = [s dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
	return std::wstring((const wchar_t *)data.bytes, data.length / sizeof(wchar_t));
}

// Copies with truncation and NUL termination; returns characters copied (excluding NUL).
template <typename CharT>
static DWORD CopyOut(const std::basic_string<CharT> &src, CharT *dst, DWORD dstSize)
{
	if(!dst || dstSize == 0) return 0;
	const DWORD n = std::min<DWORD>((DWORD)src.size(), dstSize - 1);
	std::copy_n(src.data(), n, dst);
	dst[n] = 0;
	return n;
}

// Win32 paths may use backslashes; the native side always uses '/'.
static std::string PosixPathW(LPCWSTR p)
{
	std::string s = W2U(p);
	std::replace(s.begin(), s.end(), '\\', '/');
	return s;
}

static std::string PosixPathA(LPCSTR p)
{
	std::string s = p ? p : "";
	std::replace(s.begin(), s.end(), '\\', '/');
	return s;
}

// ---------------------------------------------------------------------------------------------
// Last error
// ---------------------------------------------------------------------------------------------

static thread_local DWORD t_lastError = 0;

static DWORD ErrnoToWin32(int e)
{
	switch(e)
	{
	case 0: return ERROR_SUCCESS;
	case ENOENT: return ERROR_FILE_NOT_FOUND;
	case EACCES: case EPERM: return 5;  // ERROR_ACCESS_DENIED
	case EEXIST: return 183;  // ERROR_ALREADY_EXISTS
	case ENOTDIR: return 3;  // ERROR_PATH_NOT_FOUND
	default: return 31;  // ERROR_GEN_FAILURE
	}
}

static BOOL FailErrno() { t_lastError = ErrnoToWin32(errno); return FALSE; }

DWORD WINAPI GetLastError() { return t_lastError; }

// ---------------------------------------------------------------------------------------------
// Kernel handles: files, find handles, events, change notifications
// ---------------------------------------------------------------------------------------------

struct MacKernelObject
{
	virtual ~MacKernelObject() = default;
};

struct MacFileHandle : MacKernelObject
{
	int fd = -1;
	~MacFileHandle() override { if(fd >= 0) ::close(fd); }
};

struct MacFindHandle : MacKernelObject
{
	DIR *dir = nullptr;
	std::string directory;
	std::string pattern;
	~MacFindHandle() override { if(dir) closedir(dir); }
};

struct MacEvent : MacKernelObject
{
	std::mutex mutex;
	std::condition_variable cv;
	bool manualReset = false;
	bool signaled = false;
};

struct MacChangeNotification : MacKernelObject
{
	std::string path;
	time_t lastMTime = 0;
};

static time_t DirMTime(const std::string &path)
{
	struct stat st{};
	return ::stat(path.c_str(), &st) == 0 ? st.st_mtimespec.tv_sec : 0;
}

static bool IsKernelHandle(HANDLE h)
{
	return h && h != INVALID_HANDLE_VALUE;
}

BOOL WINAPI CloseHandle(HANDLE hObject)
{
	if(!IsKernelHandle(hObject)) return FALSE;
	delete static_cast<MacKernelObject *>(hObject);
	return TRUE;
}

static HANDLE OpenFilePosix(const std::string &path, DWORD access, DWORD creation)
{
	int flags = 0;
	const bool wantRead = (access & (GENERIC_READ | FILE_READ_ATTRIBUTES)) != 0;
	const bool wantWrite = (access & GENERIC_WRITE) != 0;
	flags |= (wantRead && wantWrite) ? O_RDWR : (wantWrite ? O_WRONLY : O_RDONLY);
	switch(creation)
	{
	case CREATE_NEW: flags |= O_CREAT | O_EXCL; break;
	case CREATE_ALWAYS: flags |= O_CREAT | O_TRUNC; break;
	case OPEN_ALWAYS: flags |= O_CREAT; break;
	case TRUNCATE_EXISTING: flags |= O_TRUNC; break;
	default: break;
	}
	const int fd = ::open(path.c_str(), flags | O_CLOEXEC, 0644);
	if(fd < 0)
	{
		FailErrno();
		return INVALID_HANDLE_VALUE;
	}
	auto *h = new MacFileHandle();
	h->fd = fd;
	return h;
}

HANDLE WINAPI CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD, LPSECURITY_ATTRIBUTES, DWORD dwCreationDisposition, DWORD, HANDLE)
{
	return OpenFilePosix(PosixPathA(lpFileName), dwDesiredAccess, dwCreationDisposition);
}

HANDLE WINAPI CreateFileW(LPCWSTR lpFileName, DWORD dwDesiredAccess, DWORD, LPSECURITY_ATTRIBUTES, DWORD dwCreationDisposition, DWORD, HANDLE)
{
	return OpenFilePosix(PosixPathW(lpFileName), dwDesiredAccess, dwCreationDisposition);
}

static MacFileHandle *AsFile(HANDLE h)
{
	return IsKernelHandle(h) ? dynamic_cast<MacFileHandle *>(static_cast<MacKernelObject *>(h)) : nullptr;
}

BOOL WINAPI ReadFile(HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED)
{
	MacFileHandle *f = AsFile(hFile);
	if(lpNumberOfBytesRead) *lpNumberOfBytesRead = 0;
	if(!f) return FALSE;
	const ssize_t r = ::read(f->fd, lpBuffer, nNumberOfBytesToRead);
	if(r < 0) return FailErrno();
	if(lpNumberOfBytesRead) *lpNumberOfBytesRead = (DWORD)r;
	return TRUE;
}

BOOL WINAPI WriteFile(HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED)
{
	MacFileHandle *f = AsFile(hFile);
	if(lpNumberOfBytesWritten) *lpNumberOfBytesWritten = 0;
	if(!f) return FALSE;
	const ssize_t r = ::write(f->fd, lpBuffer, nNumberOfBytesToWrite);
	if(r < 0) return FailErrno();
	if(lpNumberOfBytesWritten) *lpNumberOfBytesWritten = (DWORD)r;
	return TRUE;
}

BOOL WINAPI SetFilePointerEx(HANDLE hFile, LARGE_INTEGER liDistanceToMove, PLARGE_INTEGER lpNewFilePointer, DWORD dwMoveMethod)
{
	MacFileHandle *f = AsFile(hFile);
	if(!f) return FALSE;
	const int whence = dwMoveMethod == FILE_END ? SEEK_END : (dwMoveMethod == FILE_CURRENT ? SEEK_CUR : SEEK_SET);
	const off_t pos = ::lseek(f->fd, (off_t)liDistanceToMove.QuadPart, whence);
	if(pos < 0) return FailErrno();
	if(lpNewFilePointer) lpNewFilePointer->QuadPart = pos;
	return TRUE;
}

BOOL WINAPI GetFileSizeEx(HANDLE hFile, PLARGE_INTEGER lpFileSize)
{
	MacFileHandle *f = AsFile(hFile);
	struct stat st{};
	if(!f || !lpFileSize) return FALSE;
	if(::fstat(f->fd, &st) != 0) return FailErrno();
	lpFileSize->QuadPart = st.st_size;
	return TRUE;
}

BOOL WINAPI SetEndOfFile(HANDLE hFile)
{
	MacFileHandle *f = AsFile(hFile);
	if(!f) return FALSE;
	const off_t pos = ::lseek(f->fd, 0, SEEK_CUR);
	return (pos >= 0 && ::ftruncate(f->fd, pos) == 0) ? TRUE : FailErrno();
}

BOOL WINAPI FlushFileBuffers(HANDLE hFile)
{
	MacFileHandle *f = AsFile(hFile);
	return (f && ::fsync(f->fd) == 0) ? TRUE : FALSE;
}

static void FillFindData(const std::string &dir, const char *name, WIN32_FIND_DATAW *data)
{
	*data = {};
	struct stat st{};
	const std::string full = dir + "/" + name;
	if(::stat(full.c_str(), &st) == 0)
	{
		data->dwFileAttributes = S_ISDIR(st.st_mode) ? FILE_ATTRIBUTE_DIRECTORY : FILE_ATTRIBUTE_NORMAL;
		data->nFileSizeHigh = (DWORD)((uint64_t)st.st_size >> 32);
		data->nFileSizeLow = (DWORD)((uint64_t)st.st_size & 0xFFFFFFFF);
		const ULONGLONG ft = ((ULONGLONG)st.st_mtimespec.tv_sec + 11644473600ULL) * 10000000ULL + (ULONGLONG)st.st_mtimespec.tv_nsec / 100;
		data->ftLastWriteTime.dwLowDateTime = (DWORD)ft;
		data->ftLastWriteTime.dwHighDateTime = (DWORD)(ft >> 32);
	}
	if(name[0] == '.' && strcmp(name, ".") && strcmp(name, ".."))
		data->dwFileAttributes |= FILE_ATTRIBUTE_HIDDEN;
	CopyOut(U2W(name), data->cFileName, MAX_PATH);
}

static BOOL FindNext(MacFindHandle *h, WIN32_FIND_DATAW *data)
{
	while(dirent *e = readdir(h->dir))
	{
		if(fnmatch(h->pattern.c_str(), e->d_name, FNM_CASEFOLD) == 0)
		{
			FillFindData(h->directory, e->d_name, data);
			return TRUE;
		}
	}
	t_lastError = 18;  // ERROR_NO_MORE_FILES
	return FALSE;
}

HANDLE WINAPI FindFirstFileW(LPCWSTR lpFileName, WIN32_FIND_DATAW *lpFindFileData)
{
	const std::string spec = PosixPathW(lpFileName);
	const auto slash = spec.find_last_of('/');
	auto *h = new MacFindHandle();
	h->directory = slash == std::string::npos ? "." : spec.substr(0, slash);
	h->pattern = slash == std::string::npos ? spec : spec.substr(slash + 1);
	if(h->pattern == "*.*") h->pattern = "*";
	h->dir = opendir(h->directory.c_str());
	if(!h->dir || !FindNext(h, lpFindFileData))
	{
		if(!h->dir) FailErrno();
		delete h;
		return INVALID_HANDLE_VALUE;
	}
	return h;
}

BOOL WINAPI FindNextFileW(HANDLE hFindFile, WIN32_FIND_DATAW *lpFindFileData)
{
	auto *h = IsKernelHandle(hFindFile) ? dynamic_cast<MacFindHandle *>(static_cast<MacKernelObject *>(hFindFile)) : nullptr;
	return h ? FindNext(h, lpFindFileData) : FALSE;
}

BOOL WINAPI FindClose(HANDLE hFindFile) { return CloseHandle(hFindFile); }

// Polled: mptrack's watch-dir thread waits on the handle, then rescans the folder.
HANDLE WINAPI FindFirstChangeNotificationA(LPCSTR lpPathName, BOOL, DWORD)
{
	auto *h = new MacChangeNotification();
	h->path = PosixPathA(lpPathName);
	h->lastMTime = DirMTime(h->path);
	return h;
}

BOOL WINAPI FindNextChangeNotification(HANDLE hChangeHandle)
{
	auto *h = IsKernelHandle(hChangeHandle) ? dynamic_cast<MacChangeNotification *>(static_cast<MacKernelObject *>(hChangeHandle)) : nullptr;
	if(h) h->lastMTime = DirMTime(h->path);
	return h != nullptr;
}

BOOL WINAPI FindCloseChangeNotification(HANDLE hChangeHandle) { return CloseHandle(hChangeHandle); }

DWORD WINAPI GetFileAttributesA(LPCSTR lpFileName)
{
	struct stat st{};
	if(::stat(PosixPathA(lpFileName).c_str(), &st) != 0)
	{
		FailErrno();
		return INVALID_FILE_ATTRIBUTES;
	}
	DWORD attr = S_ISDIR(st.st_mode) ? FILE_ATTRIBUTE_DIRECTORY : FILE_ATTRIBUTE_NORMAL;
	if(!(st.st_mode & S_IWUSR)) attr |= FILE_ATTRIBUTE_READONLY;
	return attr;
}

BOOL WINAPI CopyFileA(LPCSTR lpExistingFileName, LPCSTR lpNewFileName, BOOL bFailIfExists)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *dst = [NSString stringWithUTF8String:PosixPathA(lpNewFileName).c_str()];
	if([fm fileExistsAtPath:dst])
	{
		if(bFailIfExists) { t_lastError = 80; return FALSE; }  // ERROR_FILE_EXISTS
		[fm removeItemAtPath:dst error:nil];
	}
	return [fm copyItemAtPath:[NSString stringWithUTF8String:PosixPathA(lpExistingFileName).c_str()] toPath:dst error:nil] ? TRUE : FALSE;
}

BOOL WINAPI MoveFileA(LPCSTR lpExistingFileName, LPCSTR lpNewFileName)
{
	return ::rename(PosixPathA(lpExistingFileName).c_str(), PosixPathA(lpNewFileName).c_str()) == 0 ? TRUE : FailErrno();
}

BOOL WINAPI DeleteFileA(LPCSTR lpFileName)
{
	return ::unlink(PosixPathA(lpFileName).c_str()) == 0 ? TRUE : FailErrno();
}

BOOL WINAPI CreateDirectoryA(LPCSTR lpPathName, LPSECURITY_ATTRIBUTES)
{
	return ::mkdir(PosixPathA(lpPathName).c_str(), 0755) == 0 ? TRUE : FailErrno();
}

BOOL WINAPI RemoveDirectoryA(LPCSTR lpPathName)
{
	return ::rmdir(PosixPathA(lpPathName).c_str()) == 0 ? TRUE : FailErrno();
}

int WINAPI SHCreateDirectoryExA(HWND, LPCSTR pszPath, const SECURITY_ATTRIBUTES *)
{
	NSString *path = [NSString stringWithUTF8String:PosixPathA(pszPath).c_str()];
	return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil] ? ERROR_SUCCESS : 3;
}

BOOL WINAPI SetCurrentDirectoryA(LPCSTR lpPathName)
{
	return ::chdir(PosixPathA(lpPathName).c_str()) == 0 ? TRUE : FailErrno();
}

DWORD WINAPI GetCurrentDirectoryW(DWORD nBufferLength, LPWSTR lpBuffer)
{
	char buf[PATH_MAX] = {};
	if(!::getcwd(buf, sizeof(buf))) return 0;
	const std::wstring w = U2W(buf);
	if(!lpBuffer || nBufferLength <= w.size()) return (DWORD)w.size() + 1;
	return CopyOut(w, lpBuffer, nBufferLength);
}

static std::string AbsolutePath(std::string path)
{
	if(path.empty() || path[0] != '/')
	{
		char cwd[PATH_MAX] = {};
		if(::getcwd(cwd, sizeof(cwd))) path = std::string(cwd) + "/" + path;
	}
	return [[[NSString stringWithUTF8String:path.c_str()] stringByStandardizingPath] UTF8String];
}

DWORD WINAPI GetFullPathNameA(LPCSTR lpFileName, DWORD nBufferLength, LPSTR lpBuffer, LPSTR *lpFilePart)
{
	const std::string full = AbsolutePath(PosixPathA(lpFileName));
	if(!lpBuffer || nBufferLength <= full.size()) return (DWORD)full.size() + 1;
	const DWORD n = CopyOut(full, lpBuffer, nBufferLength);
	if(lpFilePart)
	{
		char *slash = strrchr(lpBuffer, '/');
		*lpFilePart = slash ? slash + 1 : lpBuffer;
	}
	return n;
}

DWORD WINAPI GetFullPathNameW(LPCWSTR lpFileName, DWORD nBufferLength, LPWSTR lpBuffer, LPWSTR *lpFilePart)
{
	const std::wstring full = U2W(AbsolutePath(PosixPathW(lpFileName)).c_str());
	if(!lpBuffer || nBufferLength <= full.size()) return (DWORD)full.size() + 1;
	const DWORD n = CopyOut(full, lpBuffer, nBufferLength);
	if(lpFilePart)
	{
		wchar_t *slash = wcsrchr(lpBuffer, L'/');
		*lpFilePart = slash ? slash + 1 : lpBuffer;
	}
	return n;
}

DWORD WINAPI GetTempPathW(DWORD nBufferLength, LPWSTR lpBuffer)
{
	std::wstring tmp = NS2W(NSTemporaryDirectory());
	if(tmp.empty() || tmp.back() != L'/') tmp += L'/';
	if(!lpBuffer || nBufferLength <= tmp.size()) return (DWORD)tmp.size() + 1;
	return CopyOut(tmp, lpBuffer, nBufferLength);
}

DWORD WINAPI GetModuleFileNameW(HMODULE, LPWSTR lpFilename, DWORD nSize)
{
	// The bundle's MacOS folder plays the role of the install directory.
	return CopyOut(NS2W([[NSBundle mainBundle] executablePath]), lpFilename, nSize);
}

HMODULE WINAPI GetModuleHandleW(LPCWSTR lpModuleName)
{
	return lpModuleName ? nullptr : (HMODULE)AfxGetInstanceHandle();
}

UINT WINAPI GetDriveTypeW(LPCWSTR)
{
	return DRIVE_NO_ROOT_DIR;  // No drive letters on macOS; the tree shows "/" via the normal directory listing.
}

// ---------------------------------------------------------------------------------------------
// INI profile files (TrackerSettings, plugin cache, keymaps)
// ---------------------------------------------------------------------------------------------

namespace {

// Order-preserving INI model; section and key lookups are case-insensitive like Win32.
struct IniFile
{
	struct Section
	{
		std::wstring name;
		std::vector<std::pair<std::wstring, std::wstring>> entries;
	};
	std::vector<Section> sections;
};

bool IEquals(const std::wstring &a, const std::wstring &b)
{
	return a.size() == b.size() && std::equal(a.begin(), a.end(), b.begin(), [](wchar_t x, wchar_t y) { return towlower(x) == towlower(y); });
}

std::wstring Trim(const std::wstring &s)
{
	const auto first = s.find_first_not_of(L" \t\r\n");
	if(first == std::wstring::npos) return {};
	return s.substr(first, s.find_last_not_of(L" \t\r\n") - first + 1);
}

std::mutex g_iniMutex;

IniFile LoadIni(LPCWSTR fileName)
{
	IniFile ini;
	NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:PosixPathW(fileName).c_str()]];
	if(!data) return ini;
	NSString *text = nil;
	const uint8_t *bytes = (const uint8_t *)data.bytes;
	if(data.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE)
		text = [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
	if(!text) text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if(!text) text = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
	const std::wstring all = NS2W(text);
	IniFile::Section *current = nullptr;
	size_t pos = 0;
	while(pos <= all.size())
	{
		size_t end = all.find(L'\n', pos);
		if(end == std::wstring::npos) end = all.size();
		std::wstring line = Trim(all.substr(pos, end - pos));
		pos = end + 1;
		if(!line.empty() && line[0] == 0xFEFF) line.erase(0, 1);
		if(line.empty() || line[0] == L';') continue;
		if(line.front() == L'[' && line.back() == L']')
		{
			ini.sections.push_back({line.substr(1, line.size() - 2), {}});
			current = &ini.sections.back();
		} else if(current)
		{
			const auto eq = line.find(L'=');
			if(eq != std::wstring::npos)
				current->entries.emplace_back(Trim(line.substr(0, eq)), Trim(line.substr(eq + 1)));
		}
	}
	return ini;
}

bool SaveIni(LPCWSTR fileName, const IniFile &ini)
{
	std::wstring out;
	for(const auto &section : ini.sections)
	{
		out += L"[" + section.name + L"]\n";
		for(const auto &[key, value] : section.entries)
			out += key + L"=" + value + L"\n";
		out += L"\n";
	}
	NSString *path = [NSString stringWithUTF8String:PosixPathW(fileName).c_str()];
	NSString *text = [[NSString alloc] initWithBytes:out.data() length:out.size() * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
	return [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

IniFile::Section *FindSection(IniFile &ini, LPCWSTR name)
{
	for(auto &s : ini.sections)
		if(IEquals(s.name, name)) return &s;
	return nullptr;
}

// Writes a list of NUL-separated strings terminated by a double NUL, truncating like Win32.
DWORD WriteMultiString(const std::vector<std::wstring> &items, LPWSTR buffer, DWORD size)
{
	if(!buffer || size < 2) return 0;
	DWORD pos = 0;
	for(const auto &item : items)
	{
		if(pos + item.size() + 2 > size) return size - 2;
		std::copy(item.begin(), item.end(), buffer + pos);
		pos += (DWORD)item.size();
		buffer[pos++] = 0;
	}
	buffer[pos] = 0;
	return pos;
}

std::wstring ToHex(const BYTE *data, UINT size)
{
	static const wchar_t digits[] = L"0123456789ABCDEF";
	std::wstring s;
	BYTE checksum = 0;
	for(UINT i = 0; i < size; i++)
	{
		s += digits[data[i] >> 4];
		s += digits[data[i] & 0x0F];
		checksum += data[i];
	}
	s += digits[checksum >> 4];
	s += digits[checksum & 0x0F];
	return s;
}

}  // namespace

DWORD WINAPI GetPrivateProfileStringW(LPCWSTR lpAppName, LPCWSTR lpKeyName, LPCWSTR lpDefault, LPWSTR lpReturnedString, DWORD nSize, LPCWSTR lpFileName)
{
	std::lock_guard lock(g_iniMutex);
	IniFile ini = LoadIni(lpFileName);
	if(!lpAppName)
	{
		std::vector<std::wstring> names;
		for(const auto &s : ini.sections) names.push_back(s.name);
		return WriteMultiString(names, lpReturnedString, nSize);
	}
	IniFile::Section *section = FindSection(ini, lpAppName);
	if(section && !lpKeyName)
	{
		std::vector<std::wstring> keys;
		for(const auto &e : section->entries) keys.push_back(e.first);
		return WriteMultiString(keys, lpReturnedString, nSize);
	}
	if(section)
	{
		for(const auto &[key, value] : section->entries)
			if(IEquals(key, lpKeyName)) return CopyOut(value, lpReturnedString, nSize);
	}
	return CopyOut(std::wstring(lpDefault ? lpDefault : L""), lpReturnedString, nSize);
}

UINT WINAPI GetPrivateProfileIntW(LPCWSTR lpAppName, LPCWSTR lpKeyName, INT nDefault, LPCWSTR lpFileName)
{
	wchar_t buf[64] = {};
	if(!GetPrivateProfileStringW(lpAppName, lpKeyName, L"", buf, 64, lpFileName)) return (UINT)nDefault;
	return (UINT)wcstol(buf, nullptr, 0);
}

DWORD WINAPI GetPrivateProfileSectionNamesW(LPWSTR lpszReturnBuffer, DWORD nSize, LPCWSTR lpFileName)
{
	return GetPrivateProfileStringW(nullptr, nullptr, nullptr, lpszReturnBuffer, nSize, lpFileName);
}

DWORD WINAPI GetPrivateProfileSectionW(LPCWSTR lpAppName, LPWSTR lpReturnedString, DWORD nSize, LPCWSTR lpFileName)
{
	std::lock_guard lock(g_iniMutex);
	IniFile ini = LoadIni(lpFileName);
	std::vector<std::wstring> lines;
	if(IniFile::Section *section = FindSection(ini, lpAppName))
		for(const auto &[key, value] : section->entries) lines.push_back(key + L"=" + value);
	return WriteMultiString(lines, lpReturnedString, nSize);
}

BOOL WINAPI WritePrivateProfileStringW(LPCWSTR lpAppName, LPCWSTR lpKeyName, LPCWSTR lpString, LPCWSTR lpFileName)
{
	if(!lpAppName || !lpFileName) return FALSE;
	std::lock_guard lock(g_iniMutex);
	IniFile ini = LoadIni(lpFileName);
	IniFile::Section *section = FindSection(ini, lpAppName);
	if(!lpKeyName)
	{
		// NULL key deletes the whole section.
		if(section) ini.sections.erase(ini.sections.begin() + (section - ini.sections.data()));
		return SaveIni(lpFileName, ini);
	}
	if(!section)
	{
		if(!lpString) return TRUE;
		ini.sections.push_back({lpAppName, {}});
		section = &ini.sections.back();
	}
	auto &entries = section->entries;
	auto it = std::find_if(entries.begin(), entries.end(), [&](const auto &e) { return IEquals(e.first, lpKeyName); });
	if(!lpString)
	{
		if(it != entries.end()) entries.erase(it);
	} else if(it != entries.end())
	{
		it->second = lpString;
	} else
	{
		entries.emplace_back(lpKeyName, lpString);
	}
	return SaveIni(lpFileName, ini);
}

BOOL WINAPI WritePrivateProfileSectionW(LPCWSTR lpAppName, LPCWSTR lpString, LPCWSTR lpFileName)
{
	if(!lpAppName || !lpFileName) return FALSE;
	std::lock_guard lock(g_iniMutex);
	IniFile ini = LoadIni(lpFileName);
	IniFile::Section *section = FindSection(ini, lpAppName);
	if(!section)
	{
		ini.sections.push_back({lpAppName, {}});
		section = &ini.sections.back();
	}
	section->entries.clear();
	for(const wchar_t *p = lpString; p && *p; p += wcslen(p) + 1)
	{
		const std::wstring line = p;
		const auto eq = line.find(L'=');
		if(eq != std::wstring::npos) section->entries.emplace_back(line.substr(0, eq), line.substr(eq + 1));
	}
	return SaveIni(lpFileName, ini);
}

// Win32 stores structs as hex followed by a one-byte additive checksum.
BOOL WINAPI WritePrivateProfileStructW(LPCWSTR lpszSection, LPCWSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCWSTR szFile)
{
	if(!lpStruct) return WritePrivateProfileStringW(lpszSection, lpszKey, nullptr, szFile);
	return WritePrivateProfileStringW(lpszSection, lpszKey, ToHex((const BYTE *)lpStruct, uSizeStruct).c_str(), szFile);
}

BOOL WINAPI GetPrivateProfileStructW(LPCWSTR lpszSection, LPCWSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCWSTR szFile)
{
	std::vector<wchar_t> buf(uSizeStruct * 2 + 8);
	const DWORD len = GetPrivateProfileStringW(lpszSection, lpszKey, L"", buf.data(), (DWORD)buf.size(), szFile);
	if(len != uSizeStruct * 2 + 2) return FALSE;
	auto nibble = [](wchar_t c) -> int { return (c >= L'0' && c <= L'9') ? c - L'0' : (towupper(c) >= L'A' && towupper(c) <= L'F') ? towupper(c) - L'A' + 10 : -1; };
	BYTE checksum = 0;
	std::vector<BYTE> bytes(uSizeStruct + 1);
	for(UINT i = 0; i <= uSizeStruct; i++)
	{
		const int hi = nibble(buf[i * 2]), lo = nibble(buf[i * 2 + 1]);
		if(hi < 0 || lo < 0) return FALSE;
		bytes[i] = (BYTE)((hi << 4) | lo);
		if(i < uSizeStruct) checksum += bytes[i];
	}
	if(checksum != bytes[uSizeStruct]) return FALSE;
	memcpy(lpStruct, bytes.data(), uSizeStruct);
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Strings and character sets
// ---------------------------------------------------------------------------------------------

int WINAPI MultiByteToWideChar(UINT CodePage, DWORD, LPCSTR lpMultiByteStr, int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar)
{
	if(!lpMultiByteStr) return 0;
	const bool withNul = cbMultiByte < 0;
	const int len = withNul ? (int)strlen(lpMultiByteStr) : cbMultiByte;
	std::wstring w;
	if(CodePage == CP_UTF8 || CodePage == 65001)
	{
		w = U2W(lpMultiByteStr, len);
	} else
	{
		NSString *ns = [[NSString alloc] initWithBytes:lpMultiByteStr length:(NSUInteger)len encoding:NSWindowsCP1252StringEncoding];
		w = NS2W(ns);
	}
	if(withNul) w.push_back(0);
	if(cchWideChar == 0 || !lpWideCharStr) return (int)w.size();
	const int n = std::min<int>((int)w.size(), cchWideChar);
	std::copy_n(w.data(), n, lpWideCharStr);
	return n;
}

int WINAPI WideCharToMultiByte(UINT CodePage, DWORD, LPCWSTR lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCSTR, LPBOOL lpUsedDefaultChar)
{
	if(lpUsedDefaultChar) *lpUsedDefaultChar = FALSE;
	if(!lpWideCharStr) return 0;
	const bool withNul = cchWideChar < 0;
	const int len = withNul ? (int)wcslen(lpWideCharStr) : cchWideChar;
	std::string s;
	if(CodePage == CP_UTF8 || CodePage == 65001)
	{
		s = W2U(lpWideCharStr, len);
	} else
	{
		NSString *ns = [[NSString alloc] initWithBytes:lpWideCharStr length:(NSUInteger)len * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
		NSData *data = [ns dataUsingEncoding:NSWindowsCP1252StringEncoding allowLossyConversion:YES];
		s.assign((const char *)data.bytes, data.length);
	}
	if(withNul) s.push_back(0);
	if(cbMultiByte == 0 || !lpMultiByteStr) return (int)s.size();
	const int n = std::min<int>((int)s.size(), cbMultiByte);
	std::copy_n(s.data(), n, lpMultiByteStr);
	return n;
}

int WINAPI CompareStringW(DWORD, DWORD dwCmpFlags, LPCWSTR lpString1, int cchCount1, LPCWSTR lpString2, int cchCount2)
{
	NSString *a = [[NSString alloc] initWithBytes:lpString1 length:(cchCount1 < 0 ? wcslen(lpString1) : (size_t)cchCount1) * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
	NSString *b = [[NSString alloc] initWithBytes:lpString2 length:(cchCount2 < 0 ? wcslen(lpString2) : (size_t)cchCount2) * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
	NSStringCompareOptions opts = 0;
	if(dwCmpFlags & NORM_IGNORECASE) opts |= NSCaseInsensitiveSearch;
	if(dwCmpFlags & SORT_DIGITSASNUMBERS) opts |= NSNumericSearch;
	return (int)[a compare:b options:opts] + 2;  // CSTR_LESS_THAN = 1, CSTR_EQUAL = 2, CSTR_GREATER_THAN = 3
}

int WINAPI CompareStringA(DWORD Locale, DWORD dwCmpFlags, LPCSTR lpString1, int cchCount1, LPCSTR lpString2, int cchCount2)
{
	const std::wstring a = U2W(lpString1, cchCount1), b = U2W(lpString2, cchCount2);
	return CompareStringW(Locale, dwCmpFlags, a.c_str(), -1, b.c_str(), -1);
}

int WINAPI lstrcmpiW(LPCWSTR lpString1, LPCWSTR lpString2) { return CompareStringW(0, NORM_IGNORECASE, lpString1, -1, lpString2, -1) - 2; }
int WINAPI lstrcmpiA(LPCSTR lpString1, LPCSTR lpString2) { return strcasecmp(lpString1, lpString2); }

int wsprintfW(LPWSTR lpOut, LPCWSTR lpFmt, ...)
{
	va_list args;
	va_start(args, lpFmt);
	const int n = vswprintf(lpOut, 1024, lpFmt, args);  // wsprintf's documented maximum buffer size
	va_end(args);
	return n;
}

DWORD WINAPI FormatMessageW(DWORD dwFlags, LPCVOID, DWORD dwMessageId, DWORD, LPWSTR lpBuffer, DWORD nSize, va_list *)
{
	const std::wstring msg = U2W(strerror((int)dwMessageId));
	if(dwFlags & FORMAT_MESSAGE_ALLOCATE_BUFFER)
	{
		auto *buf = static_cast<wchar_t *>(GlobalAlloc(0, (msg.size() + 1) * sizeof(wchar_t)));
		CopyOut(msg, buf, (DWORD)msg.size() + 1);
		*reinterpret_cast<LPWSTR *>(lpBuffer) = buf;
		return (DWORD)msg.size();
	}
	return CopyOut(msg, lpBuffer, nSize);
}

// ---------------------------------------------------------------------------------------------
// Memory
// ---------------------------------------------------------------------------------------------

// Global/Local memory is a size-prefixed malloc block; handles and pointers are the same thing.
HGLOBAL WINAPI GlobalAlloc(UINT uFlags, SIZE_T dwBytes)
{
	auto *block = static_cast<size_t *>((uFlags & GMEM_ZEROINIT) ? calloc(1, dwBytes + sizeof(size_t)) : malloc(dwBytes + sizeof(size_t)));
	if(!block) return nullptr;
	*block = dwBytes;
	return block + 1;
}

HGLOBAL WINAPI GlobalFree(HGLOBAL hMem)
{
	if(hMem) free(static_cast<size_t *>(hMem) - 1);
	return nullptr;
}

LPVOID WINAPI GlobalLock(HGLOBAL hMem) { return hMem; }
BOOL WINAPI GlobalUnlock(HGLOBAL) { return TRUE; }
SIZE_T WINAPI GlobalSize(HGLOBAL hMem) { return hMem ? *(static_cast<size_t *>(hMem) - 1) : 0; }
HLOCAL WINAPI LocalFree(HLOCAL hMem) { return GlobalFree(hMem); }

BOOL WINAPI GlobalMemoryStatusEx(LPMEMORYSTATUSEX lpBuffer)
{
	if(!lpBuffer) return FALSE;
	uint64_t total = 0;
	size_t size = sizeof(total);
	sysctlbyname("hw.memsize", &total, &size, nullptr, 0);
	vm_statistics64_data_t vm{};
	mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
	host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vm, &count);
	const uint64_t avail = (uint64_t)(vm.free_count + vm.inactive_count) * (uint64_t)vm_page_size;
	lpBuffer->ullTotalPhys = total;
	lpBuffer->ullAvailPhys = avail;
	lpBuffer->ullTotalPageFile = total;
	lpBuffer->ullAvailPageFile = avail;
	lpBuffer->ullTotalVirtual = 1ULL << 47;
	lpBuffer->ullAvailVirtual = 1ULL << 47;
	lpBuffer->dwMemoryLoad = total ? (DWORD)(100 - avail * 100 / total) : 0;
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Processes, threads, time, synchronisation
// ---------------------------------------------------------------------------------------------

HANDLE WINAPI GetCurrentProcess() { return (HANDLE)(LONG_PTR)-1; }
HANDLE WINAPI GetCurrentThread() { return (HANDLE)(LONG_PTR)-2; }

DWORD WINAPI GetCurrentThreadId()
{
	uint64_t tid = 0;
	pthread_threadid_np(nullptr, &tid);
	return (DWORD)tid;
}

BOOL WINAPI SetThreadPriority(HANDLE, int) { return TRUE; }  // Audio thread priority is handled by the sound device.
void WINAPI Sleep(DWORD dwMilliseconds) { usleep((useconds_t)dwMilliseconds * 1000); }
void WINAPI ExitProcess(UINT uExitCode) { exit((int)uExitCode); }
BOOL WINAPI IsDebuggerPresent() { return FALSE; }
DWORD GetExceptionCode() { return 0; }

static uint64_t NowNanoseconds()
{
	return clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
}

BOOL WINAPI QueryPerformanceCounter(LARGE_INTEGER *lpPerformanceCount)
{
	lpPerformanceCount->QuadPart = (LONGLONG)NowNanoseconds();
	return TRUE;
}

BOOL WINAPI QueryPerformanceFrequency(LARGE_INTEGER *lpFrequency)
{
	lpFrequency->QuadPart = 1000000000LL;
	return TRUE;
}

DWORD WINAPI GetTickCount() { return (DWORD)(NowNanoseconds() / 1000000); }

extern "C" {
DWORD WINAPI timeGetTime(void) { return GetTickCount(); }
MMRESULT WINAPI timeBeginPeriod(UINT) { return MMSYSERR_NOERROR; }
MMRESULT WINAPI timeEndPeriod(UINT) { return MMSYSERR_NOERROR; }
}

void WINAPI GetSystemTimeAsFileTime(LPFILETIME lpSystemTimeAsFileTime)
{
	struct timespec ts{};
	clock_gettime(CLOCK_REALTIME, &ts);
	const ULONGLONG ft = ((ULONGLONG)ts.tv_sec + 11644473600ULL) * 10000000ULL + (ULONGLONG)ts.tv_nsec / 100;
	lpSystemTimeAsFileTime->dwLowDateTime = (DWORD)ft;
	lpSystemTimeAsFileTime->dwHighDateTime = (DWORD)(ft >> 32);
}

void WINAPI GetSystemInfo(LPSYSTEM_INFO lpSystemInfo)
{
	*lpSystemInfo = {};
#if defined(__aarch64__)
	lpSystemInfo->wProcessorArchitecture = PROCESSOR_ARCHITECTURE_ARM64;
#else
	lpSystemInfo->wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64;
#endif
	lpSystemInfo->dwPageSize = (DWORD)getpagesize();
	lpSystemInfo->dwAllocationGranularity = 65536;
	lpSystemInfo->dwNumberOfProcessors = (DWORD)[[NSProcessInfo processInfo] activeProcessorCount];
	lpSystemInfo->dwActiveProcessorMask = (lpSystemInfo->dwNumberOfProcessors >= 64) ? ~DWORD_PTR(0) : ((DWORD_PTR(1) << lpSystemInfo->dwNumberOfProcessors) - 1);
}

void WINAPI GetNativeSystemInfo(LPSYSTEM_INFO lpSystemInfo) { GetSystemInfo(lpSystemInfo); }

HANDLE WINAPI CreateEventW(LPSECURITY_ATTRIBUTES, BOOL bManualReset, BOOL bInitialState, LPCWSTR)
{
	auto *e = new MacEvent();
	e->manualReset = bManualReset != FALSE;
	e->signaled = bInitialState != FALSE;
	return e;
}

BOOL WINAPI SetEvent(HANDLE hEvent)
{
	auto *e = IsKernelHandle(hEvent) ? dynamic_cast<MacEvent *>(static_cast<MacKernelObject *>(hEvent)) : nullptr;
	if(!e) return FALSE;
	{
		std::lock_guard lock(e->mutex);
		e->signaled = true;
	}
	e->cv.notify_all();
	return TRUE;
}

// Supports what mptrack waits on: events and (polled) change notifications, any-of semantics.
DWORD WINAPI WaitForMultipleObjects(DWORD nCount, const HANDLE *lpHandles, BOOL bWaitAll, DWORD dwMilliseconds)
{
	(void)bWaitAll;
	const uint64_t deadline = dwMilliseconds == INFINITE ? UINT64_MAX : NowNanoseconds() + (uint64_t)dwMilliseconds * 1000000;
	for(;;)
	{
		for(DWORD i = 0; i < nCount; i++)
		{
			auto *obj = IsKernelHandle(lpHandles[i]) ? static_cast<MacKernelObject *>(lpHandles[i]) : nullptr;
			if(auto *e = dynamic_cast<MacEvent *>(obj))
			{
				std::lock_guard lock(e->mutex);
				if(e->signaled)
				{
					if(!e->manualReset) e->signaled = false;
					return WAIT_OBJECT_0 + i;
				}
			} else if(auto *n = dynamic_cast<MacChangeNotification *>(obj))
			{
				if(DirMTime(n->path) != n->lastMTime) return WAIT_OBJECT_0 + i;
			}
		}
		if(NowNanoseconds() >= deadline) return WAIT_TIMEOUT;
		usleep(20000);
	}
}

// ---------------------------------------------------------------------------------------------
// COM / OLE: nothing on macOS registers COM classes, so creation fails cleanly.
// ---------------------------------------------------------------------------------------------

HRESULT WINAPI CoInitializeEx(LPVOID, DWORD) { return S_OK; }
void WINAPI CoUninitialize() {}
void WINAPI CoTaskMemFree(LPVOID pv) { free(pv); }
HRESULT WINAPI CoCreateInstance(REFCLSID, IUnknown *, DWORD, REFIID, LPVOID *ppv)
{
	if(ppv) *ppv = nullptr;
	return REGDB_E_CLASSNOTREG;
}
// Read/write memory stream, enough for GDI+ image decoding and OLE clipboard data.
class MacMemoryStream final : public IStream
{
public:
	explicit MacMemoryStream(std::vector<BYTE> data) : m_data(std::move(data)) {}
	HRESULT QueryInterface(REFIID, void **ppv) override { *ppv = this; AddRef(); return S_OK; }
	ULONG AddRef() override { return ++m_refs; }
	ULONG Release() override
	{
		const ULONG refs = --m_refs;
		if(!refs) delete this;
		return refs;
	}
	HRESULT Read(void *pv, ULONG cb, ULONG *pcbRead) override
	{
		const ULONG n = (ULONG)std::min<size_t>(cb, m_data.size() - m_pos);
		memcpy(pv, m_data.data() + m_pos, n);
		m_pos += n;
		if(pcbRead) *pcbRead = n;
		return n == cb ? S_OK : S_FALSE;
	}
	HRESULT Write(const void *pv, ULONG cb, ULONG *pcbWritten) override
	{
		if(m_pos + cb > m_data.size()) m_data.resize(m_pos + cb);
		memcpy(m_data.data() + m_pos, pv, cb);
		m_pos += cb;
		if(pcbWritten) *pcbWritten = cb;
		return S_OK;
	}
	HRESULT Stat(STATSTG *pstatstg, DWORD) override
	{
		*pstatstg = {};
		pstatstg->cbSize.QuadPart = m_data.size();
		return S_OK;
	}

private:
	std::vector<BYTE> m_data;
	size_t m_pos = 0;
	std::atomic<ULONG> m_refs{1};
};

HRESULT WINAPI CreateStreamOnHGlobal(HGLOBAL hGlobal, BOOL fDeleteOnRelease, IStream **ppstm)
{
	if(!ppstm) return E_POINTER;
	const BYTE *bytes = static_cast<const BYTE *>(hGlobal);
	*ppstm = new MacMemoryStream(std::vector<BYTE>(bytes, bytes + GlobalSize(hGlobal)));
	if(fDeleteOnRelease) GlobalFree(hGlobal);  // the stream owns a copy
	return S_OK;
}

IStream *WINAPI SHCreateMemStream(const BYTE *pInit, UINT cbInit)
{
	return new MacMemoryStream(pInit ? std::vector<BYTE>(pInit, pInit + cbInit) : std::vector<BYTE>());
}
BOOL AFXAPI AfxOleInit() { return TRUE; }
void WINAPI InitCommonControls() {}

// ---------------------------------------------------------------------------------------------
// Window queries and attributes
// ---------------------------------------------------------------------------------------------

BOOL WINAPI IsWindow(HWND hWnd) { return GetWindowRecord(hWnd) != nullptr; }

HWND WINAPI GetParent(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? rec->parent : nullptr;
}

HWND WINAPI SetParent(HWND hWndChild, HWND hWndNewParent)
{
	WindowRecord *rec = GetWindowRecord(hWndChild);
	if(!rec) return nullptr;
	HWND old = rec->parent;
	if(WindowRecord *oldParent = GetWindowRecord(old))
		std::erase(oldParent->children, hWndChild);
	rec->parent = hWndNewParent;
	WindowRecord *newParent = GetWindowRecord(hWndNewParent);
	if(newParent)
	{
		newParent->children.push_back(hWndChild);
		if(rec->nsView && newParent->nsView)
		{
			[rec->nsView removeFromSuperview];
			[(NSView *)newParent->nsView addSubview:(NSView *)rec->nsView];
		}
	}
	return old;
}

BOOL WINAPI IsChild(HWND hWndParent, HWND hWnd)
{
	for(HWND p = GetParent(hWnd); p; p = GetParent(p))
		if(p == hWndParent) return TRUE;
	return FALSE;
}

BOOL WINAPI IsWindowVisible(HWND hWnd)
{
	for(WindowRecord *rec = GetWindowRecord(hWnd); rec; rec = GetWindowRecord(rec->parent))
		if(!rec->isVisible) return FALSE;
	return GetWindowRecord(hWnd) != nullptr;
}

BOOL WINAPI IsWindowEnabled(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec && rec->isEnabled;
}

BOOL WINAPI EnableWindow(HWND hWnd, BOOL bEnable)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return FALSE;
	const BOOL wasDisabled = !rec->isEnabled;
	if(rec->isEnabled != (bEnable != FALSE))
	{
		rec->isEnabled = bEnable != FALSE;
		bEnable ? rec->style &= ~WS_DISABLED : rec->style |= WS_DISABLED;
		DispatchNativeMessage(hWnd, WM_ENABLE, (WPARAM)bEnable, 0);
		InvalidateRect(hWnd, nullptr, TRUE);
	}
	return wasDisabled;
}

BOOL WINAPI IsIconic(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec && rec->nsWindow && [(NSWindow *)rec->nsWindow isMiniaturized];
}

BOOL WINAPI IsZoomed(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec && rec->nsWindow && [(NSWindow *)rec->nsWindow isZoomed];
}

HWND WINAPI GetWindow(HWND hWnd, UINT uCmd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return nullptr;
	if(uCmd == GW_CHILD) return rec->children.empty() ? nullptr : rec->children.front();
	if(uCmd == GW_OWNER) return rec->parent;
	WindowRecord *parent = GetWindowRecord(rec->parent);
	if(!parent) return nullptr;
	const auto &siblings = parent->children;
	auto it = std::find(siblings.begin(), siblings.end(), hWnd);
	if(it == siblings.end()) return nullptr;
	switch(uCmd)
	{
	case GW_HWNDFIRST: return siblings.front();
	case GW_HWNDLAST: return siblings.back();
	case GW_HWNDNEXT: return (it + 1 != siblings.end()) ? *(it + 1) : nullptr;
	case GW_HWNDPREV: return (it != siblings.begin()) ? *(it - 1) : nullptr;
	default: return nullptr;
	}
}

HWND WINAPI GetDlgItem(HWND hDlg, int nIDDlgItem)
{
	WindowRecord *rec = GetWindowRecord(hDlg);
	if(!rec) return nullptr;
	for(HWND child : rec->children)
	{
		WindowRecord *c = GetWindowRecord(child);
		if(c && (int)c->id == nIDDlgItem) return child;
	}
	return nullptr;
}

int WINAPI GetDlgCtrlID(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? (int)rec->id : 0;
}

HWND WINAPI GetNextDlgTabItem(HWND hDlg, HWND hCtl, BOOL bPrevious)
{
	WindowRecord *rec = GetWindowRecord(hDlg);
	if(!rec) return nullptr;
	std::vector<HWND> tabStops;
	for(HWND child : rec->children)
	{
		WindowRecord *c = GetWindowRecord(child);
		if(c && (c->style & WS_TABSTOP) && c->isVisible && c->isEnabled) tabStops.push_back(child);
	}
	if(tabStops.empty()) return nullptr;
	auto it = std::find(tabStops.begin(), tabStops.end(), hCtl);
	if(it == tabStops.end()) return bPrevious ? tabStops.back() : tabStops.front();
	if(bPrevious) return (it == tabStops.begin()) ? tabStops.back() : *(it - 1);
	return (it + 1 == tabStops.end()) ? tabStops.front() : *(it + 1);
}

int WINAPI GetClassNameW(HWND hWnd, LPWSTR lpClassName, int nMaxCount)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? (int)CopyOut(U2W(rec->className.c_str()), lpClassName, (DWORD)nMaxCount) : 0;
}

struct RegisteredClass
{
	std::wstring name;
	WNDCLASSW wc;
};
static std::vector<std::unique_ptr<RegisteredClass>> g_windowClasses;  // index + 0xC000 is the ATOM

ATOM WINAPI RegisterClassW(const WNDCLASSW *lpWndClass)
{
	if(!lpWndClass || !lpWndClass->lpszClassName) return 0;
	if(MacFindWindowClass(lpWndClass->lpszClassName)) return 0;  // ERROR_CLASS_ALREADY_EXISTS
	auto cls = std::make_unique<RegisteredClass>();
	cls->name = IS_INTRESOURCE(lpWndClass->lpszClassName) ? std::wstring() : std::wstring(lpWndClass->lpszClassName);
	cls->wc = *lpWndClass;
	cls->wc.lpszClassName = cls->name.c_str();
	g_windowClasses.push_back(std::move(cls));
	return (ATOM)(0xC000 + g_windowClasses.size() - 1);
}

const WNDCLASSW *MacFindWindowClass(LPCWSTR lpClassName)
{
	if(!lpClassName) return nullptr;
	if(IS_INTRESOURCE(lpClassName))
	{
		const size_t index = (size_t)(uintptr_t)lpClassName - 0xC000;
		return index < g_windowClasses.size() ? &g_windowClasses[index]->wc : nullptr;
	}
	for(const auto &cls : g_windowClasses)
		if(lstrcmpiW(cls->name.c_str(), lpClassName) == 0) return &cls->wc;
	return nullptr;
}

LRESULT WINAPI DefWindowProcW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	switch(Msg)
	{
	case WM_SETTEXT:
		if(rec) rec->windowText = W2U(reinterpret_cast<LPCWSTR>(lParam));
		if(rec && rec->nsWindow) [(NSWindow *)rec->nsWindow setTitle:W2NS(reinterpret_cast<LPCWSTR>(lParam))];
		InvalidateRect(hWnd, nullptr, TRUE);
		return TRUE;
	case WM_GETTEXT:
		return rec ? (LRESULT)CopyOut(U2W(rec->windowText.c_str()), reinterpret_cast<LPWSTR>(lParam), (DWORD)wParam) : 0;
	case WM_GETTEXTLENGTH:
		return rec ? (LRESULT)U2W(rec->windowText.c_str()).size() : 0;
	case WM_CLOSE:
		DestroyWindow(hWnd);
		return 0;
	case WM_PAINT:
	{
		// Validates the window; BeginPaint erases the background.
		PAINTSTRUCT ps;
		BeginPaint(hWnd, &ps);
		EndPaint(hWnd, &ps);
		return 0;
	}
	case WM_GETFONT:
		return rec ? (LRESULT)rec->font : 0;
	case WM_ERASEBKGND:
	{
		// Erase with the class background brush; COLOR_xxx + 1 values name system colours.
		if(!rec) return 0;
		COLORREF color;
		if(rec->className == "MDICLIENT") color = GetSysColor(COLOR_APPWORKSPACE);
		else if(const WNDCLASSW *wc = MacFindWindowClass(U2W(rec->className.c_str()).c_str()); wc && wc->hbrBackground)
		{
			const uintptr_t brush = (uintptr_t)wc->hbrBackground;
			if(brush <= 64) color = GetSysColor((int)brush - 1);
			else color = static_cast<MacBrush *>(static_cast<MacGdiObject *>((void *)wc->hbrBackground))->color;
		} else return 0;
		RECT client;
		GetClientRect(hWnd, &client);
		HBRUSH b = CreateSolidBrush(color);
		FillRect((HDC)wParam, &client, b);
		DeleteObject(b);
		return 1;
	}
	case WM_SETFONT:
		if(rec) rec->font = (HFONT)wParam;
		return 0;
	default:
		return 0;
	}
}

BOOL WINAPI SetWindowTextW(HWND hWnd, LPCWSTR lpString)
{
	if(!GetWindowRecord(hWnd)) return FALSE;
	SendMessageW(hWnd, WM_SETTEXT, 0, (LPARAM)(lpString ? lpString : L""));
	return TRUE;
}

BOOL WINAPI SetWindowTextA(HWND hWnd, LPCSTR lpString)
{
	return SetWindowTextW(hWnd, U2W(lpString).c_str());
}

int WINAPI GetWindowTextLengthW(HWND hWnd)
{
	return (int)SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
}

int WINAPI GetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount)
{
	if(lpString && nMaxCount > 0) lpString[0] = 0;
	return (int)SendMessageW(hWnd, WM_GETTEXT, (WPARAM)nMaxCount, (LPARAM)lpString);
}

int WINAPI GetWindowTextLengthA(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? (int)rec->windowText.size() : 0;
}

int WINAPI GetWindowTextA(HWND hWnd, LPSTR lpString, int nMaxCount)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? (int)CopyOut(rec->windowText, lpString, (DWORD)nMaxCount) : 0;
}

BOOL WINAPI SetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPCWSTR lpString)
{
	return SetWindowTextW(GetDlgItem(hDlg, nIDDlgItem), lpString);
}

UINT WINAPI GetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPWSTR lpString, int cchMax)
{
	return (UINT)GetWindowTextW(GetDlgItem(hDlg, nIDDlgItem), lpString, cchMax);
}

BOOL WINAPI SetDlgItemInt(HWND hDlg, int nIDDlgItem, UINT uValue, BOOL bSigned)
{
	const std::wstring text = bSigned ? std::to_wstring((int)uValue) : std::to_wstring(uValue);
	return SetDlgItemTextW(hDlg, nIDDlgItem, text.c_str());
}

UINT WINAPI GetDlgItemInt(HWND hDlg, int nIDDlgItem, BOOL *lpTranslated, BOOL bSigned)
{
	wchar_t buf[64] = {};
	GetDlgItemTextW(hDlg, nIDDlgItem, buf, 64);
	wchar_t *end = nullptr;
	const long v = bSigned ? wcstol(buf, &end, 10) : (long)wcstoul(buf, &end, 10);
	if(lpTranslated) *lpTranslated = (end != buf);
	return (UINT)v;
}

BOOL WINAPI CheckDlgButton(HWND hDlg, int nIDButton, UINT uCheck)
{
	HWND hButton = GetDlgItem(hDlg, nIDButton);
	if(!hButton) return FALSE;
	SendMessageW(hButton, BM_SETCHECK, uCheck, 0);
	if(WindowRecord *rec = GetWindowRecord(hButton)) rec->checkState = (int)uCheck;
	InvalidateRect(hButton, nullptr, TRUE);
	return TRUE;
}

UINT WINAPI IsDlgButtonChecked(HWND hDlg, int nIDButton)
{
	WindowRecord *rec = GetWindowRecord(GetDlgItem(hDlg, nIDButton));
	return rec ? (UINT)rec->checkState : 0;
}

BOOL WINAPI CheckRadioButton(HWND hDlg, int nIDFirstButton, int nIDLastButton, int nIDCheckButton)
{
	for(int id = nIDFirstButton; id <= nIDLastButton; id++)
		CheckDlgButton(hDlg, id, id == nIDCheckButton ? BST_CHECKED : BST_UNCHECKED);
	return TRUE;
}

int CWnd::GetCheckedRadioButton(int nIDFirstButton, int nIDLastButton) const
{
	for(int id = nIDFirstButton; id <= nIDLastButton; id++)
		if(::IsDlgButtonChecked(m_hWnd, id)) return id;
	return 0;
}

CFrameWnd *CWnd::GetParentFrame() const
{
	for(HWND h = ::GetParent(m_hWnd); h; h = ::GetParent(h))
	{
		CWnd *wnd = CWnd::FromHandlePermanent(h);
		if(auto *frame = dynamic_cast<CFrameWnd *>(wnd)) return frame;
	}
	return nullptr;
}

void CCheckListBox::SetCheck(int nIndex, int nCheck)
{
	if(nIndex < 0) return;
	m_checks.resize(std::max(m_checks.size(), (size_t)nIndex + 1));
	m_checks[nIndex] = nCheck;
	::InvalidateRect(m_hWnd, nullptr, TRUE);
}

int CCheckListBox::GetCheck(int nIndex) const
{
	return (nIndex >= 0 && (size_t)nIndex < m_checks.size()) ? m_checks[nIndex] : 0;
}

static constexpr int kCheckListBoxSize = 13;

// A check box at the left of each row, then the item text, as MFC's CCheckListBox draws it.
void CCheckListBox::DrawItem(LPDRAWITEMSTRUCT dis)
{
	if(dis->itemID == (UINT)-1) return;
	HDC dc = dis->hDC;
	const RECT &row = dis->rcItem;
	const bool selected = dis->itemState & ODS_SELECTED, enabled = !(dis->itemState & ODS_DISABLED);
	auto fill = [dc](const RECT &rect, int color, bool frame) {
		HBRUSH brush = CreateSolidBrush(GetSysColor(color));
		frame ? FrameRect(dc, &rect, brush) : FillRect(dc, &rect, brush);
		DeleteObject(brush);
	};
	fill(row, selected ? COLOR_HIGHLIGHT : COLOR_WINDOW, false);

	const int size = std::min<int>(kCheckListBoxSize, row.bottom - row.top - 2);
	const int top = row.top + (row.bottom - row.top - size) / 2;
	RECT box{row.left + 2, top, row.left + 2 + size, top + size};
	fill(box, COLOR_WINDOW, false);
	fill(box, enabled ? COLOR_WINDOWTEXT : COLOR_GRAYTEXT, true);
	if(GetCheck((int)dis->itemID))
	{
		HPEN pen = CreatePen(PS_SOLID, 2, GetSysColor(enabled ? COLOR_WINDOWTEXT : COLOR_GRAYTEXT));
		// Swap the field directly: SelectObject ignores a null pen, which would leave the deleted pen selected.
		HPEN oldPen = dc->currentPen;
		dc->currentPen = pen;
		MoveToEx(dc, box.left + 3, box.top + size / 2, nullptr);
		LineTo(dc, box.left + size / 2 - 1, box.bottom - 4);
		LineTo(dc, box.right - 3, box.top + 3);
		dc->currentPen = oldPen;
		DeleteObject(pen);
	}

	std::wstring text((size_t)std::max<LRESULT>(0, ::SendMessageW(m_hWnd, LB_GETTEXTLEN, dis->itemID, 0)), L'\0');
	if(!text.empty()) ::SendMessageW(m_hWnd, LB_GETTEXT, dis->itemID, (LPARAM)text.data());
	SetBkMode(dc, TRANSPARENT);
	SetTextColor(dc, GetSysColor(!enabled ? COLOR_GRAYTEXT : selected ? COLOR_HIGHLIGHTTEXT : COLOR_WINDOWTEXT));
	RECT textRect{box.right + 4, row.top, row.right - 2, row.bottom};
	DrawTextW(dc, text.c_str(), (int)text.size(), &textRect, DT_LEFT | DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX);
}

// A click on the check box or Space toggles the item and sends CLBN_CHKCHANGE to the parent, as in MFC.
LRESULT CCheckListBox::WindowProc(UINT message, WPARAM wParam, LPARAM lParam)
{
	int toggle = -1;
	if((message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK) && GET_X_LPARAM(lParam) < kCheckListBoxSize + 4)
	{
		const DWORD hit = (DWORD)::SendMessageW(m_hWnd, LB_ITEMFROMPOINT, 0, lParam);
		if(!HIWORD(hit)) toggle = LOWORD(hit);
	} else if(message == WM_CHAR && wParam == ' ')
	{
		toggle = GetCurSel();
		if(toggle < 0) return 0;
	}
	const LRESULT result = (message == WM_CHAR && toggle >= 0) ? 0 : CListBox::WindowProc(message, wParam, lParam);
	if(toggle >= 0 && m_hWnd)
	{
		SetCheck(toggle, GetCheck(toggle) ? 0 : 1);
		if(HWND parent = ::GetParent(m_hWnd)) ::SendMessageW(parent, WM_COMMAND, MAKEWPARAM(GetDlgCtrlID(), CLBN_CHKCHANGE), (LPARAM)m_hWnd);
	}
	return result;
}

static std::map<std::pair<HWND, int>, LONG_PTR> g_extraWindowLongs;

LONG_PTR WINAPI GetWindowLongPtrW(HWND hWnd, int nIndex)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return 0;
	switch(nIndex)
	{
	case GWL_STYLE: return (LONG_PTR)rec->style;
	case GWL_EXSTYLE: return (LONG_PTR)rec->exStyle;
	case GWLP_ID: return (LONG_PTR)rec->id;
	case GWLP_WNDPROC: return (LONG_PTR)rec->wndProc;
	case GWLP_USERDATA: return rec->userData;
	case GWLP_HWNDPARENT: return (LONG_PTR)rec->parent;
	case GWLP_HINSTANCE: return (LONG_PTR)AfxGetInstanceHandle();
	default:
		auto it = g_extraWindowLongs.find({hWnd, nIndex});
		return it != g_extraWindowLongs.end() ? it->second : 0;
	}
}

LONG_PTR WINAPI SetWindowLongPtrW(HWND hWnd, int nIndex, LONG_PTR dwNewLong)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return 0;
	const LONG_PTR old = GetWindowLongPtrW(hWnd, nIndex);
	switch(nIndex)
	{
	case GWL_STYLE:
		rec->style = (DWORD)dwNewLong;
		rec->isVisible = (rec->style & WS_VISIBLE) != 0;
		rec->isEnabled = (rec->style & WS_DISABLED) == 0;
		break;
	case GWL_EXSTYLE: rec->exStyle = (DWORD)dwNewLong; break;
	case GWLP_ID: rec->id = (UINT_PTR)dwNewLong; break;
	case GWLP_WNDPROC: rec->wndProc = (WNDPROC)dwNewLong; break;
	case GWLP_USERDATA: rec->userData = dwNewLong; break;
	default: g_extraWindowLongs[{hWnd, nIndex}] = dwNewLong; break;
	}
	return old;
}

LONG WINAPI GetWindowLongW(HWND hWnd, int nIndex) { return (LONG)GetWindowLongPtrW(hWnd, nIndex); }
LONG WINAPI SetWindowLongW(HWND hWnd, int nIndex, LONG dwNewLong) { return (LONG)SetWindowLongPtrW(hWnd, nIndex, dwNewLong); }

BOOL WINAPI EnumChildWindows(HWND hWndParent, WNDENUMPROC lpEnumFunc, LPARAM lParam)
{
	WindowRecord *rec = GetWindowRecord(hWndParent);
	if(!rec) return FALSE;
	const std::vector<HWND> children = rec->children;  // callbacks may create or destroy windows
	for(HWND child : children)
	{
		if(!IsWindow(child)) continue;
		if(!lpEnumFunc(child, lParam)) return FALSE;
		if(!EnumChildWindows(child, lpEnumFunc, lParam)) return FALSE;
	}
	return TRUE;
}

BOOL WINAPI EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam)
{
	for(HWND hWnd : GetAllWindowHandles())
	{
		WindowRecord *rec = GetWindowRecord(hWnd);
		if(rec && !rec->parent && !lpEnumFunc(hWnd, lParam)) return FALSE;
	}
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Coordinates, placement and activation
// ---------------------------------------------------------------------------------------------

static CGFloat PrimaryScreenHeight()
{
	NSArray<NSScreen *> *screens = [NSScreen screens];
	return screens.count ? screens[0].frame.size.height : 0;
}

BOOL WINAPI ClientToScreen(HWND hWnd, LPPOINT lpPoint)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec || !rec->nsView || !lpPoint) return FALSE;
	NSView *view = (NSView *)rec->nsView;
	if(!view.window) return FALSE;
	const NSPoint inWindow = [view convertPoint:NSMakePoint(lpPoint->x, lpPoint->y) toView:nil];
	const NSPoint onScreen = [view.window convertPointToScreen:inWindow];
	lpPoint->x = (LONG)onScreen.x;
	lpPoint->y = (LONG)(PrimaryScreenHeight() - onScreen.y);
	return TRUE;
}

BOOL WINAPI ScreenToClient(HWND hWnd, LPPOINT lpPoint)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec || !rec->nsView || !lpPoint) return FALSE;
	NSView *view = (NSView *)rec->nsView;
	if(!view.window) return FALSE;
	const NSPoint onScreen = NSMakePoint(lpPoint->x, PrimaryScreenHeight() - lpPoint->y);
	const NSPoint inWindow = [view.window convertPointFromScreen:onScreen];
	const NSPoint inView = [view convertPoint:inWindow fromView:nil];
	lpPoint->x = (LONG)inView.x;
	lpPoint->y = (LONG)inView.y;
	return TRUE;
}

int WINAPI MapWindowPoints(HWND hWndFrom, HWND hWndTo, LPPOINT lpPoints, UINT cPoints)
{
	POINT origin{0, 0};
	if(hWndFrom) ClientToScreen(hWndFrom, &origin);
	POINT target{0, 0};
	if(hWndTo) ClientToScreen(hWndTo, &target);
	const LONG dx = origin.x - target.x, dy = origin.y - target.y;
	for(UINT i = 0; i < cPoints; i++)
	{
		lpPoints[i].x += dx;
		lpPoints[i].y += dy;
	}
	return MAKELONG((WORD)(SHORT)dx, (WORD)(SHORT)dy);
}

BOOL WINAPI GetCursorPos(LPPOINT lpPoint)
{
	const NSPoint p = [NSEvent mouseLocation];
	lpPoint->x = (LONG)p.x;
	lpPoint->y = (LONG)(PrimaryScreenHeight() - p.y);
	return TRUE;
}

HWND WINAPI WindowFromPoint(POINT Point)
{
	const NSPoint screenPt = NSMakePoint(Point.x, PrimaryScreenHeight() - Point.y);
	const NSInteger windowNumber = [NSWindow windowNumberAtPoint:screenPt belowWindowWithWindowNumber:0];
	NSWindow *window = [NSApp windowWithWindowNumber:windowNumber];
	if(!window) return nullptr;
	NSView *hit = [window.contentView hitTest:[window.contentView convertPoint:[window convertPointFromScreen:screenPt] fromView:nil]];
	for(HWND hWnd : GetAllWindowHandles())
	{
		WindowRecord *rec = GetWindowRecord(hWnd);
		if(rec && (NSView *)rec->nsView == hit) return hWnd;
	}
	return nullptr;
}

HWND WINAPI GetDesktopWindow() { return nullptr; }

HWND WINAPI GetActiveWindow()
{
	return MacGetActiveWindow();
}

HWND WINAPI SetActiveWindow(HWND hWnd)
{
	HWND old = GetActiveWindow();
	if(WindowRecord *rec = GetWindowRecord(hWnd); rec && rec->nsWindow)
	{
		[(NSWindow *)rec->nsWindow makeKeyAndOrderFront:nil];
		MacSetActiveWindow(hWnd);
	}
	return old;
}

BOOL WINAPI SetForegroundWindow(HWND hWnd)
{
	[NSApp activateIgnoringOtherApps:YES];
	SetActiveWindow(hWnd);
	return TRUE;
}

BOOL WINAPI AdjustWindowRectEx(LPRECT lpRect, DWORD dwStyle, BOOL bMenu, DWORD)
{
	// Top-level frames are NSWindows whose content rect is the client area; child windows have no frame.
	(void)dwStyle; (void)bMenu;
	return lpRect != nullptr;
}

BOOL WINAPI GetWindowPlacement(HWND hWnd, WINDOWPLACEMENT *lpwndpl)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec || !lpwndpl) return FALSE;
	lpwndpl->flags = 0;
	lpwndpl->showCmd = IsZoomed(hWnd) ? SW_SHOWMAXIMIZED : (IsIconic(hWnd) ? SW_SHOWMINIMIZED : SW_SHOWNORMAL);
	if(rec->nsWindow)
	{
		const NSRect f = [(NSWindow *)rec->nsWindow frame];
		const LONG top = (LONG)(PrimaryScreenHeight() - f.origin.y - f.size.height);
		lpwndpl->rcNormalPosition = RECT{(LONG)f.origin.x, top, (LONG)(f.origin.x + f.size.width), (LONG)(top + f.size.height)};
	} else
	{
		lpwndpl->rcNormalPosition = rec->rect;
	}
	return TRUE;
}

BOOL WINAPI SetWindowPlacement(HWND hWnd, const WINDOWPLACEMENT *lpwndpl)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec || !lpwndpl) return FALSE;
	const RECT &r = lpwndpl->rcNormalPosition;
	if(rec->nsWindow)
	{
		NSWindow *window = (NSWindow *)rec->nsWindow;
		if(r.right > r.left && r.bottom > r.top)
			[window setFrame:NSMakeRect(r.left, PrimaryScreenHeight() - r.bottom, r.right - r.left, r.bottom - r.top) display:YES];
		if(lpwndpl->showCmd == SW_SHOWMAXIMIZED && !window.isZoomed) [window zoom:nil];
	} else
	{
		MoveWindow(hWnd, r.left, r.top, r.right - r.left, r.bottom - r.top, TRUE);
	}
	return TRUE;
}

struct HDWP__
{
	struct Entry { HWND hWnd; HWND after; int x, y, cx, cy; UINT flags; };
	std::vector<Entry> entries;
};

HDWP WINAPI BeginDeferWindowPos(int nNumWindows)
{
	auto *d = new HDWP__();
	d->entries.reserve((size_t)std::max(nNumWindows, 0));
	return d;
}

HDWP WINAPI DeferWindowPos(HDWP hWinPosInfo, HWND hWnd, HWND hWndInsertAfter, int x, int y, int cx, int cy, UINT uFlags)
{
	if(hWinPosInfo) hWinPosInfo->entries.push_back({hWnd, hWndInsertAfter, x, y, cx, cy, uFlags});
	return hWinPosInfo;
}

BOOL WINAPI EndDeferWindowPos(HDWP hWinPosInfo)
{
	if(!hWinPosInfo) return FALSE;
	for(const auto &e : hWinPosInfo->entries) SetWindowPos(e.hWnd, e.after, e.x, e.y, e.cx, e.cy, e.flags);
	delete hWinPosInfo;
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Painting
// ---------------------------------------------------------------------------------------------

HDC WINAPI BeginPaint(HWND hWnd, LPPAINTSTRUCT lpPaint)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return nullptr;
	HDC hdc = rec->paintDC ? rec->paintDC : GetDC(hWnd);
	if(lpPaint)
	{
		*lpPaint = {};
		lpPaint->hdc = hdc;
		lpPaint->fErase = TRUE;
		if(rec->paintDC) lpPaint->rcPaint = rec->paintRect;
		else GetClientRect(hWnd, &lpPaint->rcPaint);
	}
	DispatchNativeMessage(hWnd, WM_ERASEBKGND, (WPARAM)hdc, 0);
	return hdc;
}

BOOL WINAPI EndPaint(HWND hWnd, const PAINTSTRUCT *lpPaint)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(rec && lpPaint && lpPaint->hdc != rec->paintDC) ReleaseDC(hWnd, lpPaint->hdc);
	return TRUE;
}

// Outside of drawRect AppKit offers no drawable surface, so immediate-mode DCs draw nothing and
// request a repaint instead; the view's WM_PAINT handler then renders the up-to-date state.
// shortcut: no backing store per window, upgrade when views that paint only via GetDC show stale content.
HDC WINAPI GetDC(HWND hWnd)
{
	MacHDC *dc = new MacHDC();
	dc->hWnd = hWnd;
	dc->isWindowDC = true;
	dc->ownsContext = false;
	return dc;
}

HDC WINAPI GetWindowDC(HWND hWnd) { return GetDC(hWnd); }

int WINAPI ReleaseDC(HWND hWnd, HDC hDC)
{
	if(!hDC) return 0;
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(rec && rec->paintDC == hDC) return 1;
	delete hDC;
	if(rec) InvalidateRect(hWnd, nullptr, FALSE);
	return 1;
}

BOOL WINAPI GetUpdateRect(HWND hWnd, LPRECT lpRect, BOOL)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return FALSE;
	if(lpRect) GetClientRect(hWnd, lpRect);
	return rec->nsView && [(NSView *)rec->nsView needsDisplay];
}

BOOL WINAPI ScrollWindow(HWND hWnd, int, int, const RECT *, const RECT *)
{
	return InvalidateRect(hWnd, nullptr, TRUE);
}

int WINAPI ScrollWindowEx(HWND hWnd, int, int, const RECT *, const RECT *, HRGN, LPRECT prcUpdate, UINT)
{
	if(prcUpdate) GetClientRect(hWnd, prcUpdate);
	InvalidateRect(hWnd, nullptr, TRUE);
	return COMPLEXREGION;
}

BOOL WINAPI GdiFlush() { return TRUE; }

// ---------------------------------------------------------------------------------------------
// Scroll bars (state only; the owning view draws its own)
// ---------------------------------------------------------------------------------------------

static std::map<std::pair<HWND, int>, SCROLLINFO> g_scrollInfo;

static SCROLLINFO &ScrollState(HWND hWnd, int nBar)
{
	auto [it, inserted] = g_scrollInfo.try_emplace({hWnd, nBar});
	if(inserted)
	{
		it->second = {};
		it->second.cbSize = sizeof(SCROLLINFO);
		it->second.nMax = 100;
	}
	return it->second;
}

static void ClampScroll(SCROLLINFO &si)
{
	const int maxPos = std::max(si.nMin, si.nMax - std::max<int>((int)si.nPage - 1, 0));
	si.nPos = std::clamp(si.nPos, si.nMin, maxPos);
}

int WINAPI SetScrollInfo(HWND hwnd, int nBar, LPCSCROLLINFO lpsi, BOOL redraw)
{
	if(!lpsi) return 0;
	SCROLLINFO &si = ScrollState(hwnd, nBar);
	if(lpsi->fMask & SIF_RANGE) { si.nMin = lpsi->nMin; si.nMax = lpsi->nMax; }
	if(lpsi->fMask & SIF_PAGE) si.nPage = lpsi->nPage;
	if(lpsi->fMask & SIF_POS) si.nPos = lpsi->nPos;
	ClampScroll(si);
	if(redraw) InvalidateRect(hwnd, nullptr, FALSE);
	return si.nPos;
}

BOOL WINAPI GetScrollInfo(HWND hwnd, int nBar, LPSCROLLINFO lpsi)
{
	if(!lpsi) return FALSE;
	const SCROLLINFO &si = ScrollState(hwnd, nBar);
	if(lpsi->fMask & SIF_RANGE) { lpsi->nMin = si.nMin; lpsi->nMax = si.nMax; }
	if(lpsi->fMask & SIF_PAGE) lpsi->nPage = si.nPage;
	if(lpsi->fMask & SIF_POS) lpsi->nPos = si.nPos;
	if(lpsi->fMask & SIF_TRACKPOS) lpsi->nTrackPos = si.nPos;
	return TRUE;
}

int WINAPI SetScrollPos(HWND hWnd, int nBar, int nPos, BOOL bRedraw)
{
	SCROLLINFO &si = ScrollState(hWnd, nBar);
	const int old = si.nPos;
	si.nPos = nPos;
	ClampScroll(si);
	if(bRedraw) InvalidateRect(hWnd, nullptr, FALSE);
	return old;
}

int WINAPI GetScrollPos(HWND hWnd, int nBar) { return ScrollState(hWnd, nBar).nPos; }

BOOL WINAPI SetScrollRange(HWND hWnd, int nBar, int nMinPos, int nMaxPos, BOOL bRedraw)
{
	SCROLLINFO &si = ScrollState(hWnd, nBar);
	si.nMin = nMinPos;
	si.nMax = nMaxPos;
	ClampScroll(si);
	if(bRedraw) InvalidateRect(hWnd, nullptr, FALSE);
	return TRUE;
}

BOOL WINAPI GetScrollRange(HWND hWnd, int nBar, LPINT lpMinPos, LPINT lpMaxPos)
{
	const SCROLLINFO &si = ScrollState(hWnd, nBar);
	if(lpMinPos) *lpMinPos = si.nMin;
	if(lpMaxPos) *lpMaxPos = si.nMax;
	return TRUE;
}

BOOL WINAPI EnableScrollBar(HWND, UINT, UINT) { return TRUE; }

BOOL WINAPI GetComboBoxInfo(HWND hwndCombo, PCOMBOBOXINFO pcbi)
{
	if(!pcbi || !IsWindow(hwndCombo)) return FALSE;
	pcbi->hwndCombo = hwndCombo;
	pcbi->hwndItem = hwndCombo;
	pcbi->hwndList = nullptr;
	GetClientRect(hwndCombo, &pcbi->rcItem);
	pcbi->rcButton = pcbi->rcItem;
	pcbi->rcButton.left = std::max(pcbi->rcItem.left, pcbi->rcItem.right - 17);
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Timers
// ---------------------------------------------------------------------------------------------

@interface MPTTimerTarget : NSObject
@property(nonatomic) HWND hWnd;
@property(nonatomic) UINT_PTR timerID;
@property(nonatomic) TIMERPROC proc;
- (void)fire:(NSTimer *)timer;
@end

@implementation MPTTimerTarget
- (void)fire:(NSTimer *)timer
{
	if(_proc)
		_proc(_hWnd, WM_TIMER, _timerID, GetTickCount());
	else if(IsWindow(_hWnd))
		DispatchNativeMessage(_hWnd, WM_TIMER, _timerID, 0);
	else
		[timer invalidate];
}
@end

static std::map<std::pair<HWND, UINT_PTR>, NSTimer *> g_timers;

UINT_PTR WINAPI SetTimer(HWND hWnd, UINT_PTR nIDEvent, UINT uElapse, TIMERPROC lpTimerFunc)
{
	static UINT_PTR nextAnonymousID = 0x8000;
	if(!hWnd && !nIDEvent) nIDEvent = nextAnonymousID++;
	KillTimer(hWnd, nIDEvent);
	MPTTimerTarget *target = [MPTTimerTarget new];
	target.hWnd = hWnd;
	target.timerID = nIDEvent;
	target.proc = lpTimerFunc;
	NSTimer *timer = [NSTimer timerWithTimeInterval:std::max<UINT>(uElapse, 10) / 1000.0 target:target selector:@selector(fire:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	g_timers[{hWnd, nIDEvent}] = timer;
	return nIDEvent;
}

BOOL WINAPI KillTimer(HWND hWnd, UINT_PTR uIDEvent)
{
	auto it = g_timers.find({hWnd, uIDEvent});
	if(it == g_timers.end()) return FALSE;
	[it->second invalidate];
	g_timers.erase(it);
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Keyboard and mouse state
// ---------------------------------------------------------------------------------------------

static bool IsVirtualKeyDown(int vKey)
{
	const NSEventModifierFlags mods = [NSEvent modifierFlags];
	switch(vKey)
	{
	case VK_SHIFT: case VK_LSHIFT: case VK_RSHIFT: return mods & NSEventModifierFlagShift;
	// Command plays the role of Ctrl so standard shortcuts (Cmd+C, Cmd+V, ...) map onto OpenMPT's Ctrl bindings.
	case VK_CONTROL: case VK_LCONTROL: case VK_RCONTROL: return mods & (NSEventModifierFlagCommand | NSEventModifierFlagControl);
	case VK_MENU: case VK_LMENU: case VK_RMENU: return mods & NSEventModifierFlagOption;
	case VK_CAPITAL: return mods & NSEventModifierFlagCapsLock;
	case VK_LBUTTON: return [NSEvent pressedMouseButtons] & 1;
	case VK_RBUTTON: return [NSEvent pressedMouseButtons] & 2;
	case VK_MBUTTON: return [NSEvent pressedMouseButtons] & 4;
	default: return false;
	}
}

SHORT WINAPI GetKeyState(int nVirtKey)
{
	SHORT state = IsVirtualKeyDown(nVirtKey) ? (SHORT)0x8000 : 0;
	if(nVirtKey == VK_CAPITAL && ([NSEvent modifierFlags] & NSEventModifierFlagCapsLock)) state |= 1;
	return state;
}

SHORT WINAPI GetAsyncKeyState(int vKey) { return GetKeyState(vKey); }

BOOL WINAPI GetKeyboardState(BYTE *lpKeyState)
{
	if(!lpKeyState) return FALSE;
	for(int vk = 0; vk < 256; vk++) lpKeyState[vk] = (BYTE)(GetKeyState(vk) >> 8);
	return TRUE;
}

// Mac key code -> Win32 virtual key, PC (set 1) scan code and extended-key flag, laid out like a US PC keyboard.
// OpenMPT binds note keys by scan code, so the scan codes must be the real PC ones.
struct MacKeyMapping { unsigned short mac; UINT vk; UINT scan; bool extended; };
static const MacKeyMapping g_keyMap[] = {
	{kVK_Escape, VK_ESCAPE, 0x01, false},
	{kVK_ANSI_1, '1', 0x02, false}, {kVK_ANSI_2, '2', 0x03, false}, {kVK_ANSI_3, '3', 0x04, false}, {kVK_ANSI_4, '4', 0x05, false},
	{kVK_ANSI_5, '5', 0x06, false}, {kVK_ANSI_6, '6', 0x07, false}, {kVK_ANSI_7, '7', 0x08, false}, {kVK_ANSI_8, '8', 0x09, false},
	{kVK_ANSI_9, '9', 0x0A, false}, {kVK_ANSI_0, '0', 0x0B, false}, {kVK_ANSI_Minus, VK_OEM_MINUS, 0x0C, false},
	{kVK_ANSI_Equal, VK_OEM_PLUS, 0x0D, false}, {kVK_Delete, VK_BACK, 0x0E, false}, {kVK_Tab, VK_TAB, 0x0F, false},
	{kVK_ANSI_Q, 'Q', 0x10, false}, {kVK_ANSI_W, 'W', 0x11, false}, {kVK_ANSI_E, 'E', 0x12, false}, {kVK_ANSI_R, 'R', 0x13, false},
	{kVK_ANSI_T, 'T', 0x14, false}, {kVK_ANSI_Y, 'Y', 0x15, false}, {kVK_ANSI_U, 'U', 0x16, false}, {kVK_ANSI_I, 'I', 0x17, false},
	{kVK_ANSI_O, 'O', 0x18, false}, {kVK_ANSI_P, 'P', 0x19, false}, {kVK_ANSI_LeftBracket, VK_OEM_4, 0x1A, false},
	{kVK_ANSI_RightBracket, VK_OEM_6, 0x1B, false}, {kVK_Return, VK_RETURN, 0x1C, false}, {kVK_Control, VK_CONTROL, 0x1D, false},
	{kVK_Command, VK_CONTROL, 0x1D, false},  // Command acts as Ctrl
	{kVK_ANSI_A, 'A', 0x1E, false}, {kVK_ANSI_S, 'S', 0x1F, false}, {kVK_ANSI_D, 'D', 0x20, false}, {kVK_ANSI_F, 'F', 0x21, false},
	{kVK_ANSI_G, 'G', 0x22, false}, {kVK_ANSI_H, 'H', 0x23, false}, {kVK_ANSI_J, 'J', 0x24, false}, {kVK_ANSI_K, 'K', 0x25, false},
	{kVK_ANSI_L, 'L', 0x26, false}, {kVK_ANSI_Semicolon, VK_OEM_1, 0x27, false}, {kVK_ANSI_Quote, VK_OEM_7, 0x28, false},
	{kVK_ANSI_Grave, VK_OEM_3, 0x29, false}, {kVK_Shift, VK_SHIFT, 0x2A, false}, {kVK_ANSI_Backslash, VK_OEM_5, 0x2B, false},
	{kVK_ANSI_Z, 'Z', 0x2C, false}, {kVK_ANSI_X, 'X', 0x2D, false}, {kVK_ANSI_C, 'C', 0x2E, false}, {kVK_ANSI_V, 'V', 0x2F, false},
	{kVK_ANSI_B, 'B', 0x30, false}, {kVK_ANSI_N, 'N', 0x31, false}, {kVK_ANSI_M, 'M', 0x32, false},
	{kVK_ANSI_Comma, VK_OEM_COMMA, 0x33, false}, {kVK_ANSI_Period, VK_OEM_PERIOD, 0x34, false}, {kVK_ANSI_Slash, VK_OEM_2, 0x35, false},
	{kVK_RightShift, VK_SHIFT, 0x36, false}, {kVK_ANSI_KeypadMultiply, VK_MULTIPLY, 0x37, false}, {kVK_Option, VK_MENU, 0x38, false},
	{kVK_Space, VK_SPACE, 0x39, false}, {kVK_CapsLock, VK_CAPITAL, 0x3A, false},
	{kVK_F1, VK_F1, 0x3B, false}, {kVK_F2, VK_F2, 0x3C, false}, {kVK_F3, VK_F3, 0x3D, false}, {kVK_F4, VK_F4, 0x3E, false},
	{kVK_F5, VK_F5, 0x3F, false}, {kVK_F6, VK_F6, 0x40, false}, {kVK_F7, VK_F7, 0x41, false}, {kVK_F8, VK_F8, 0x42, false},
	{kVK_F9, VK_F9, 0x43, false}, {kVK_F10, VK_F10, 0x44, false}, {kVK_ANSI_KeypadClear, VK_NUMLOCK, 0x45, false},
	{kVK_ANSI_Keypad7, VK_NUMPAD7, 0x47, false}, {kVK_ANSI_Keypad8, VK_NUMPAD8, 0x48, false}, {kVK_ANSI_Keypad9, VK_NUMPAD9, 0x49, false},
	{kVK_ANSI_KeypadMinus, VK_SUBTRACT, 0x4A, false}, {kVK_ANSI_Keypad4, VK_NUMPAD4, 0x4B, false}, {kVK_ANSI_Keypad5, VK_NUMPAD5, 0x4C, false},
	{kVK_ANSI_Keypad6, VK_NUMPAD6, 0x4D, false}, {kVK_ANSI_KeypadPlus, VK_ADD, 0x4E, false}, {kVK_ANSI_Keypad1, VK_NUMPAD1, 0x4F, false},
	{kVK_ANSI_Keypad2, VK_NUMPAD2, 0x50, false}, {kVK_ANSI_Keypad3, VK_NUMPAD3, 0x51, false}, {kVK_ANSI_Keypad0, VK_NUMPAD0, 0x52, false},
	{kVK_ANSI_KeypadDecimal, VK_DECIMAL, 0x53, false}, {kVK_ISO_Section, VK_OEM_102, 0x56, false},
	{kVK_F11, VK_F11, 0x57, false}, {kVK_F12, VK_F12, 0x58, false}, {kVK_ANSI_KeypadEquals, VK_OEM_PLUS, 0x59, false},
	{kVK_F13, VK_F13, 0x64, false}, {kVK_F14, VK_F14, 0x65, false}, {kVK_F15, VK_F15, 0x66, false}, {kVK_F16, VK_F16, 0x67, false},
	{kVK_ANSI_KeypadEnter, VK_RETURN, 0x1C, true}, {kVK_RightControl, VK_CONTROL, 0x1D, true}, {kVK_RightCommand, VK_CONTROL, 0x1D, true},
	{kVK_ANSI_KeypadDivide, VK_DIVIDE, 0x35, true}, {kVK_RightOption, VK_MENU, 0x38, true},
	{kVK_Home, VK_HOME, 0x47, true}, {kVK_UpArrow, VK_UP, 0x48, true}, {kVK_PageUp, VK_PRIOR, 0x49, true},
	{kVK_LeftArrow, VK_LEFT, 0x4B, true}, {kVK_RightArrow, VK_RIGHT, 0x4D, true}, {kVK_End, VK_END, 0x4F, true},
	{kVK_DownArrow, VK_DOWN, 0x50, true}, {kVK_PageDown, VK_NEXT, 0x51, true}, {kVK_Help, VK_INSERT, 0x52, true},
	{kVK_ForwardDelete, VK_DELETE, 0x53, true},
};

bool MacKeyInfo(unsigned short macKeyCode, UINT *vk, UINT *scan, bool *extended)
{
	for(const auto &m : g_keyMap)
	{
		if(m.mac != macKeyCode) continue;
		*vk = m.vk; *scan = m.scan; *extended = m.extended;
		return true;
	}
	return false;
}

UINT WINAPI MapVirtualKeyW(UINT uCode, UINT uMapType)
{
	switch(uMapType)
	{
	case MAPVK_VK_TO_CHAR:
		return (uCode >= 'A' && uCode <= 'Z') || (uCode >= '0' && uCode <= '9') ? uCode : 0;
	case MAPVK_VSC_TO_VK:
	case MAPVK_VSC_TO_VK_EX:
		for(const auto &m : g_keyMap)
			if(m.scan == uCode && !m.extended) return m.vk;
		return 0;
	case MAPVK_VK_TO_VSC:
		for(const auto &m : g_keyMap)
			if(m.vk == uCode) return m.scan;
		return 0;
	}
	return 0;
}

UINT WINAPI MapVirtualKeyExW(UINT uCode, UINT uMapType, HKL) { return MapVirtualKeyW(uCode, uMapType); }

int WINAPI GetKeyNameTextW(LONG lParam, LPWSTR lpString, int cchSize)
{
	const UINT vk = (UINT)((lParam >> 16) & 0xFF);
	static const std::map<UINT, const wchar_t *> names = {
		{VK_BACK, L"Backspace"}, {VK_TAB, L"Tab"}, {VK_RETURN, L"Enter"}, {VK_SHIFT, L"Shift"},
		{VK_CONTROL, L"Ctrl"}, {VK_MENU, L"Alt"}, {VK_PAUSE, L"Pause"}, {VK_CAPITAL, L"Caps Lock"},
		{VK_ESCAPE, L"Esc"}, {VK_SPACE, L"Space"}, {VK_PRIOR, L"Page Up"}, {VK_NEXT, L"Page Down"},
		{VK_END, L"End"}, {VK_HOME, L"Home"}, {VK_LEFT, L"Left"}, {VK_UP, L"Up"}, {VK_RIGHT, L"Right"},
		{VK_DOWN, L"Down"}, {VK_INSERT, L"Insert"}, {VK_DELETE, L"Delete"}, {VK_MULTIPLY, L"Num *"},
		{VK_ADD, L"Num +"}, {VK_SUBTRACT, L"Num -"}, {VK_DECIMAL, L"Num Del"}, {VK_DIVIDE, L"Num /"},
		{VK_OEM_1, L";"}, {VK_OEM_PLUS, L"="}, {VK_OEM_COMMA, L","}, {VK_OEM_MINUS, L"-"},
		{VK_OEM_PERIOD, L"."}, {VK_OEM_2, L"/"}, {VK_OEM_3, L"`"}, {VK_OEM_4, L"["}, {VK_OEM_5, L"\\"},
		{VK_OEM_6, L"]"}, {VK_OEM_7, L"'"},
	};
	std::wstring name;
	if(auto it = names.find(vk); it != names.end()) name = it->second;
	else if((vk >= '0' && vk <= '9') || (vk >= 'A' && vk <= 'Z')) name = std::wstring(1, (wchar_t)vk);
	else if(vk >= VK_NUMPAD0 && vk <= VK_NUMPAD9) name = L"Num " + std::to_wstring(vk - VK_NUMPAD0);
	else if(vk >= VK_F1 && vk <= VK_F24) name = L"F" + std::to_wstring(vk - VK_F1 + 1);
	return (int)CopyOut(name, lpString, (DWORD)cchSize);
}

UINT WINAPI SendInput(UINT, LPINPUT, int) { return 0; }
LPARAM WINAPI GetMessageExtraInfo() { return 0; }

BOOL WINAPI TrackMouseEvent(LPTRACKMOUSEEVENT lpEventTrack)
{
	// MPTNSView's tracking area already delivers WM_MOUSELEAVE.
	return lpEventTrack != nullptr;
}

static int g_cursorShowCount = 0;

int WINAPI ShowCursor(BOOL bShow)
{
	g_cursorShowCount += bShow ? 1 : -1;
	if(bShow && g_cursorShowCount == 0) [NSCursor unhide];
	if(!bShow && g_cursorShowCount == -1) [NSCursor hide];
	return g_cursorShowCount;
}

HCURSOR WINAPI LoadCursorW(HINSTANCE, LPCWSTR lpCursorName)
{
	static std::map<uintptr_t, HICON__ *> cursors;
	const uintptr_t id = (uintptr_t)lpCursorName;
	auto &cursor = cursors[id];
	if(!cursor)
	{
		cursor = new HICON__();
		if(id == (uintptr_t)IDC_IBEAM) cursor->cursor = [NSCursor IBeamCursor];
		else if(id == (uintptr_t)IDC_SIZEWE) cursor->cursor = [NSCursor resizeLeftRightCursor];
		else if(id == (uintptr_t)IDC_SIZENS) cursor->cursor = [NSCursor resizeUpDownCursor];
		else if(id == (uintptr_t)IDC_HAND) cursor->cursor = [NSCursor pointingHandCursor];
		else if(id == (uintptr_t)IDC_CROSS) cursor->cursor = [NSCursor crosshairCursor];
		else if(id == (uintptr_t)IDC_NO) cursor->cursor = [NSCursor operationNotAllowedCursor];
		else cursor->cursor = [NSCursor arrowCursor];
	}
	return cursor;
}

HCURSOR WINAPI SetCursor(HCURSOR hCursor)
{
	static HCURSOR current = nullptr;
	HCURSOR old = current;
	current = hCursor;
	if(hCursor && hCursor->cursor) [hCursor->cursor set];
	return old;
}

HICON WINAPI LoadIconW(HINSTANCE, LPCWSTR lpIconName)
{
	auto *icon = new HICON__();
	if(IS_INTRESOURCE(lpIconName))
	{
		if(const auto *data = MacResourceManager::Instance().GetImageData((int)(uintptr_t)lpIconName))
			icon->image = [[NSImage alloc] initWithData:[NSData dataWithBytes:data->data() length:data->size()]];
	}
	if(!icon->image) icon->image = [NSApp applicationIconImage];
	return icon;
}

HANDLE WINAPI LoadImageW(HINSTANCE hInst, LPCWSTR name, UINT type, int, int, UINT)
{
	if(type == IMAGE_CURSOR) return LoadCursorW(hInst, name);
	if(type == IMAGE_ICON) return LoadIconW(hInst, name);
	CBitmap bitmap;
	return bitmap.LoadBitmap(name) ? bitmap.Detach() : nullptr;
}

BOOL WINAPI DestroyIcon(HICON hIcon)
{
	delete hIcon;
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// Hooks: mptrack installs a keyboard hook to see keys before dialogs do; MPTNSView feeds it.
// ---------------------------------------------------------------------------------------------

struct HHOOK__
{
	int idHook;
	HOOKPROC proc;
};

static std::vector<HHOOK> g_hooks;

HHOOK WINAPI SetWindowsHookExW(int idHook, HOOKPROC lpfn, HINSTANCE, DWORD)
{
	auto *hook = new HHOOK__{idHook, lpfn};
	g_hooks.push_back(hook);
	return hook;
}

BOOL WINAPI UnhookWindowsHookEx(HHOOK hhk)
{
	std::erase(g_hooks, hhk);
	delete hhk;
	return TRUE;
}

LRESULT WINAPI CallNextHookEx(HHOOK hhk, int nCode, WPARAM wParam, LPARAM lParam)
{
	auto it = std::find(g_hooks.begin(), g_hooks.end(), hhk);
	if(it == g_hooks.end()) return 0;
	for(++it; it != g_hooks.end(); ++it)
		if((*it)->idHook == hhk->idHook) return (*it)->proc(nCode, wParam, lParam);
	return 0;
}

// Returns true if a WH_KEYBOARD hook consumed the key.
bool MacCallKeyboardHooks(WPARAM vk, LPARAM lParam)
{
	for(HHOOK hook : g_hooks)
		if(hook->idHook == WH_KEYBOARD) return hook->proc(HC_ACTION, vk, lParam) != 0;
	return false;
}

// ---------------------------------------------------------------------------------------------
// Menus: HMENU is a plain item tree; SetMenu mirrors it into the macOS menu bar.
// ---------------------------------------------------------------------------------------------

struct MacMenuItem
{
	UINT flags = 0;
	UINT_PTR id = 0;
	std::wstring text;
	HMENU subMenu = nullptr;
};

struct HMENU__
{
	std::vector<MacMenuItem> items;
	UINT defaultItem = (UINT)-1;
	bool popup = false;
};

static std::vector<HMENU> g_liveMenus;

HMENU WINAPI CreateMenu()
{
	auto *menu = new HMENU__();
	g_liveMenus.push_back(menu);
	return menu;
}

HMENU WINAPI CreatePopupMenu()
{
	HMENU menu = CreateMenu();
	menu->popup = true;
	return menu;
}

static bool IsLiveMenu(HMENU hMenu)
{
	return hMenu && std::find(g_liveMenus.begin(), g_liveMenus.end(), hMenu) != g_liveMenus.end();
}

BOOL WINAPI DestroyMenu(HMENU hMenu)
{
	if(!IsLiveMenu(hMenu)) return FALSE;
	for(auto &item : hMenu->items)
		if(item.subMenu) DestroyMenu(item.subMenu);
	std::erase(g_liveMenus, hMenu);
	delete hMenu;
	return TRUE;
}

static MacMenuItem MakeItem(UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem)
{
	MacMenuItem item;
	item.flags = uFlags & ~MF_BYPOSITION;
	if(uFlags & MF_POPUP) item.subMenu = (HMENU)uIDNewItem;
	else item.id = uIDNewItem;
	if(!(uFlags & (MF_SEPARATOR | MF_BITMAP | MF_OWNERDRAW)) && lpNewItem) item.text = lpNewItem;
	return item;
}

// Locates an item by command ID (searching submenus) or by position.
static std::pair<HMENU, int> FindMenuItem(HMENU hMenu, UINT uItem, UINT uFlags)
{
	if(!IsLiveMenu(hMenu)) return {nullptr, -1};
	if(uFlags & MF_BYPOSITION)
		return uItem < hMenu->items.size() ? std::pair{hMenu, (int)uItem} : std::pair{(HMENU)nullptr, -1};
	for(size_t i = 0; i < hMenu->items.size(); i++)
	{
		const MacMenuItem &item = hMenu->items[i];
		if(!item.subMenu && item.id == uItem) return {hMenu, (int)i};
		if(item.subMenu)
		{
			auto found = FindMenuItem(item.subMenu, uItem, uFlags);
			if(found.first) return found;
		}
	}
	return {nullptr, -1};
}

static void MenuChanged(HMENU hMenu);

BOOL WINAPI AppendMenuW(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem)
{
	if(!IsLiveMenu(hMenu)) return FALSE;
	hMenu->items.push_back(MakeItem(uFlags, uIDNewItem, lpNewItem));
	MenuChanged(hMenu);
	return TRUE;
}

BOOL WINAPI InsertMenuW(HMENU hMenu, UINT uPosition, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem)
{
	if(!IsLiveMenu(hMenu)) return FALSE;
	auto [menu, index] = FindMenuItem(hMenu, uPosition, uFlags);
	if(!menu)
	{
		menu = hMenu;
		index = (int)hMenu->items.size();
	}
	menu->items.insert(menu->items.begin() + index, MakeItem(uFlags, uIDNewItem, lpNewItem));
	MenuChanged(hMenu);
	return TRUE;
}

BOOL WINAPI ModifyMenuW(HMENU hMenu, UINT uPosition, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem)
{
	auto [menu, index] = FindMenuItem(hMenu, uPosition, uFlags);
	if(!menu) return FALSE;
	menu->items[index] = MakeItem(uFlags, uIDNewItem, lpNewItem);
	MenuChanged(hMenu);
	return TRUE;
}

BOOL WINAPI RemoveMenu(HMENU hMenu, UINT uPosition, UINT uFlags)
{
	auto [menu, index] = FindMenuItem(hMenu, uPosition, uFlags);
	if(!menu) return FALSE;
	menu->items.erase(menu->items.begin() + index);
	MenuChanged(hMenu);
	return TRUE;
}

BOOL WINAPI DeleteMenu(HMENU hMenu, UINT uPosition, UINT uFlags)
{
	auto [menu, index] = FindMenuItem(hMenu, uPosition, uFlags);
	if(!menu) return FALSE;
	if(HMENU sub = menu->items[index].subMenu) DestroyMenu(sub);
	menu->items.erase(menu->items.begin() + index);
	MenuChanged(hMenu);
	return TRUE;
}

int WINAPI GetMenuItemCount(HMENU hMenu) { return IsLiveMenu(hMenu) ? (int)hMenu->items.size() : -1; }

UINT WINAPI GetMenuItemID(HMENU hMenu, int nPos)
{
	if(!IsLiveMenu(hMenu) || nPos < 0 || (size_t)nPos >= hMenu->items.size()) return (UINT)-1;
	const MacMenuItem &item = hMenu->items[nPos];
	return item.subMenu ? (UINT)-1 : (UINT)item.id;
}

HMENU WINAPI GetSubMenu(HMENU hMenu, int nPos)
{
	if(!IsLiveMenu(hMenu) || nPos < 0 || (size_t)nPos >= hMenu->items.size()) return nullptr;
	return hMenu->items[nPos].subMenu;
}

BOOL WINAPI EnableMenuItem(HMENU hMenu, UINT uIDEnableItem, UINT uEnable)
{
	auto [menu, index] = FindMenuItem(hMenu, uIDEnableItem, uEnable);
	if(!menu) return -1;
	UINT &flags = menu->items[index].flags;
	const UINT old = flags & (MF_GRAYED | MF_DISABLED);
	flags = (flags & ~(MF_GRAYED | MF_DISABLED)) | (uEnable & (MF_GRAYED | MF_DISABLED));
	MenuChanged(hMenu);
	return (BOOL)old;
}

DWORD WINAPI CheckMenuItem(HMENU hMenu, UINT uIDCheckItem, UINT uCheck)
{
	auto [menu, index] = FindMenuItem(hMenu, uIDCheckItem, uCheck);
	if(!menu) return (DWORD)-1;
	UINT &flags = menu->items[index].flags;
	const DWORD old = flags & MF_CHECKED;
	flags = (flags & ~MF_CHECKED) | (uCheck & MF_CHECKED);
	MenuChanged(hMenu);
	return old;
}

BOOL WINAPI SetMenuDefaultItem(HMENU hMenu, UINT uItem, UINT fByPos)
{
	if(!IsLiveMenu(hMenu)) return FALSE;
	hMenu->defaultItem = fByPos ? uItem : (UINT)FindMenuItem(hMenu, uItem, 0).second;
	return TRUE;
}

// Win32 menu text uses '&' mnemonics and '\t' before the accelerator label.
static NSString *MenuTitle(const std::wstring &text)
{
	std::wstring label = text.substr(0, text.find(L'\t'));
	std::wstring clean;
	for(size_t i = 0; i < label.size(); i++)
	{
		if(label[i] == L'&' && i + 1 < label.size())
		{
			i++;
		}
		clean += label[i];
	}
	return W2NS(clean.c_str());
}

// ON_UPDATE_COMMAND_UI for a menu item: the handlers write straight to the NSMenuItem.
class MacMenuCmdUI : public CCmdUI
{
public:
	NSMenuItem *item = nil;
	void Enable(BOOL bOn) override { m_bEnableChanged = TRUE; item.enabled = bOn; }
	void SetCheck(int nCheck) override { item.state = nCheck == 0 ? NSControlStateValueOff : nCheck == 1 ? NSControlStateValueOn : NSControlStateValueMixed; }
	void SetRadio(BOOL bOn) override { SetCheck(bOn ? 1 : 0); }
	void SetText(LPCTSTR lpszText) override
	{
		NSString *title = MenuTitle(lpszText ? lpszText : L"");
		const NSRange tab = [item.title rangeOfString:@"\t"];
		item.title = tab.location == NSNotFound ? title : [title stringByAppendingString:[item.title substringFromIndex:tab.location]];
	}
};

@interface MPTMenuTarget : NSObject <NSMenuDelegate>
@property(nonatomic) HWND hWnd;
@property(nonatomic) UINT selected;
- (void)menuItemChosen:(NSMenuItem *)sender;
@end

@implementation MPTMenuTarget
- (void)menuItemChosen:(NSMenuItem *)sender
{
	_selected = (UINT)sender.tag;
	if(_hWnd) PostMessageW(_hWnd, WM_COMMAND, MAKEWPARAM(sender.tag, 0), 0);
}

// As MFC does on WM_INITMENUPOPUP for frame menus: update each item, and disable commands nobody handles.
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	auto *frame = dynamic_cast<CFrameWnd *>(CWnd::FromHandlePermanent(_hWnd));
	if(!frame) return;
	for(NSMenuItem *item in menu.itemArray)
	{
		if(item.submenu || item.isSeparatorItem || item.tag == 0) continue;
		MacMenuCmdUI ui;
		ui.m_nID = (UINT)item.tag;
		ui.item = item;
		ui.DoUpdate(frame, TRUE);
	}
}
@end

static NSMenu *BuildNSMenu(HMENU hMenu, NSString *title, MPTMenuTarget *target)
{
	NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
	menu.autoenablesItems = NO;
	menu.delegate = target;
	for(const MacMenuItem &item : hMenu->items)
	{
		if(item.flags & MF_SEPARATOR)
		{
			[menu addItem:[NSMenuItem separatorItem]];
			continue;
		}
		NSMenuItem *nsItem = [[NSMenuItem alloc] initWithTitle:MenuTitle(item.text) action:nil keyEquivalent:@""];
		nsItem.enabled = !(item.flags & (MF_GRAYED | MF_DISABLED));
		nsItem.state = (item.flags & MF_CHECKED) ? NSControlStateValueOn : NSControlStateValueOff;
		if(item.subMenu)
		{
			nsItem.submenu = BuildNSMenu(item.subMenu, nsItem.title, target);
		} else
		{
			nsItem.tag = (NSInteger)item.id;
			nsItem.target = target;
			nsItem.action = @selector(menuItemChosen:);
			// Show the Win32 accelerator text the way Windows does, right-aligned after a tab.
			const auto tab = item.text.find(L'\t');
			if(tab != std::wstring::npos)
			{
				nsItem.title = [NSString stringWithFormat:@"%@\t%@", nsItem.title, W2NS(item.text.substr(tab + 1).c_str())];
			}
		}
		[menu addItem:nsItem];
	}
	return menu;
}

static HWND g_menuBarOwner = nullptr;
static HMENU g_menuBar = nullptr;
static MPTMenuTarget *g_menuBarTarget = nil;

static void RebuildMenuBar()
{
	if(!g_menuBar) return;
	NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main"];
	// Application menu required by macOS (About / Quit live here).
	NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"OpenMPT" action:nil keyEquivalent:@""];
	NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"OpenMPT"];
	[appMenu addItemWithTitle:@"Quit OpenMPT" action:@selector(terminate:) keyEquivalent:@"q"];
	appItem.submenu = appMenu;
	[mainMenu addItem:appItem];
	NSMenu *built = BuildNSMenu(g_menuBar, @"Main", g_menuBarTarget);
	for(NSMenuItem *item in [built.itemArray copy])
	{
		[built removeItem:item];
		[mainMenu addItem:item];
	}
	[NSApp setMainMenu:mainMenu];
}

static void MenuChanged(HMENU)
{
	// Cheap enough for OpenMPT's menu sizes; keeps the bar in sync with Enable/CheckMenuItem.
	if(g_menuBar) RebuildMenuBar();
}

static void AppendResourceItems(HMENU menu, const std::vector<RCMenuItemDef> &items)
{
	for(const RCMenuItemDef &def : items)
	{
		const std::wstring text = U2W(def.text.c_str());
		if(def.flags & MF_POPUP)
		{
			HMENU sub = CreatePopupMenu();
			AppendResourceItems(sub, def.subItems);
			AppendMenuW(menu, def.flags | MF_STRING, (UINT_PTR)sub, text.c_str());
		} else
		{
			AppendMenuW(menu, def.flags | ((def.flags & MF_SEPARATOR) ? 0 : MF_STRING), (UINT_PTR)def.id, text.c_str());
		}
	}
}

HMENU WINAPI LoadMenuW(HINSTANCE, LPCWSTR lpMenuName)
{
	const RCMenuDef *def = IS_INTRESOURCE(lpMenuName)
		? MacResourceManager::Instance().GetMenu((int)(uintptr_t)lpMenuName)
		: MacResourceManager::Instance().GetMenu(W2U(lpMenuName).c_str());
	if(!def) return nullptr;
	HMENU menu = CreateMenu();
	AppendResourceItems(menu, def->items);
	return menu;
}

BOOL WINAPI SetMenu(HWND hWnd, HMENU hMenu)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec) return FALSE;
	rec->menu = hMenu;
	g_menuBarOwner = hWnd;
	g_menuBar = hMenu;
	if(!g_menuBarTarget) g_menuBarTarget = [MPTMenuTarget new];
	g_menuBarTarget.hWnd = hWnd;
	RebuildMenuBar();
	return TRUE;
}

HMENU WINAPI GetMenu(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? rec->menu : nullptr;
}

BOOL WINAPI DrawMenuBar(HWND hWnd)
{
	if(hWnd == g_menuBarOwner) RebuildMenuBar();
	return TRUE;
}

BOOL WINAPI TrackPopupMenuEx(HMENU hMenu, UINT uFlags, int x, int y, HWND hwnd, LPTPMPARAMS)
{
	if(!IsLiveMenu(hMenu)) return FALSE;
	MPTMenuTarget *target = [MPTMenuTarget new];
	target.hWnd = (uFlags & TPM_RETURNCMD) ? nullptr : hwnd;
	NSMenu *menu = BuildNSMenu(hMenu, @"", target);
	NSPoint location = NSMakePoint(x, PrimaryScreenHeight() - y);
	[menu popUpMenuPositioningItem:nil atLocation:location inView:nil];
	return (uFlags & TPM_RETURNCMD) ? (BOOL)target.selected : TRUE;
}

BOOL WINAPI TrackPopupMenu(HMENU hMenu, UINT uFlags, int x, int y, int, HWND hWnd, const RECT *)
{
	return TrackPopupMenuEx(hMenu, uFlags, x, y, hWnd, nullptr);
}

// ---------------------------------------------------------------------------------------------
// Message boxes, system metrics and colours
// ---------------------------------------------------------------------------------------------

int WINAPI MessageBoxW(HWND, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType)
{
	NSAlert *alert = [NSAlert new];
	alert.messageText = lpCaption ? W2NS(lpCaption) : @"OpenMPT";
	alert.informativeText = W2NS(lpText);
	switch(uType & MB_ICONMASK)
	{
	case MB_ICONERROR: alert.alertStyle = NSAlertStyleCritical; break;
	case MB_ICONWARNING: alert.alertStyle = NSAlertStyleWarning; break;
	default: alert.alertStyle = NSAlertStyleInformational; break;
	}
	std::vector<int> results;
	auto add = [&](NSString *title, int result) { [alert addButtonWithTitle:title]; results.push_back(result); };
	switch(uType & MB_TYPEMASK)
	{
	case MB_OKCANCEL: add(@"OK", IDOK); add(@"Cancel", IDCANCEL); break;
	case MB_YESNO: add(@"Yes", IDYES); add(@"No", IDNO); break;
	case MB_YESNOCANCEL: add(@"Yes", IDYES); add(@"No", IDNO); add(@"Cancel", IDCANCEL); break;
	case MB_RETRYCANCEL: add(@"Retry", IDRETRY); add(@"Cancel", IDCANCEL); break;
	case MB_ABORTRETRYIGNORE: add(@"Abort", IDABORT); add(@"Retry", IDRETRY); add(@"Ignore", IDIGNORE); break;
	default: add(@"OK", IDOK); break;
	}
	const NSModalResponse response = [alert runModal];
	const size_t index = (size_t)(response - NSAlertFirstButtonReturn);
	return index < results.size() ? results[index] : IDCANCEL;
}

BOOL WINAPI MessageBeep(UINT) { NSBeep(); return TRUE; }

// Classic Windows 10 system colours, so owner-drawn views match the Windows build.
DWORD WINAPI GetSysColor(int nIndex)
{
	switch(nIndex)
	{
	case COLOR_WINDOW: return RGB(255, 255, 255);
	case COLOR_WINDOWTEXT: return RGB(0, 0, 0);
	case COLOR_BTNFACE: return RGB(240, 240, 240);
	case COLOR_BTNTEXT: return RGB(0, 0, 0);
	case COLOR_BTNSHADOW: return RGB(160, 160, 160);
	case COLOR_BTNHIGHLIGHT: return RGB(255, 255, 255);
	case COLOR_3DDKSHADOW: return RGB(105, 105, 105);
	case COLOR_3DLIGHT: return RGB(227, 227, 227);
	case COLOR_HIGHLIGHT: return RGB(0, 120, 215);
	case COLOR_HIGHLIGHTTEXT: return RGB(255, 255, 255);
	case COLOR_GRAYTEXT: return RGB(109, 109, 109);
	case COLOR_INFOBK: return RGB(255, 255, 225);
	case COLOR_INFOTEXT: return RGB(0, 0, 0);
	case COLOR_APPWORKSPACE: return RGB(171, 171, 171);
	case COLOR_WINDOWFRAME: return RGB(100, 100, 100);
	case COLOR_ACTIVECAPTION: return RGB(153, 180, 209);
	case COLOR_CAPTIONTEXT: return RGB(0, 0, 0);
	case COLOR_MENU: return RGB(240, 240, 240);
	case COLOR_MENUTEXT: return RGB(0, 0, 0);
	case COLOR_SCROLLBAR: return RGB(200, 200, 200);
	case COLOR_HOTLIGHT: return RGB(0, 102, 204);
	default: return RGB(240, 240, 240);
	}
}

int WINAPI GetSystemMetrics(int nIndex)
{
	const NSRect screen = [NSScreen mainScreen].frame;
	switch(nIndex)
	{
	case SM_CXSCREEN: case SM_CXVIRTUALSCREEN: case SM_CXFULLSCREEN: return (int)screen.size.width;
	case SM_CYSCREEN: case SM_CYVIRTUALSCREEN: case SM_CYFULLSCREEN: return (int)screen.size.height;
	case SM_CXVSCROLL: case SM_CYHSCROLL: return 17;
	case SM_CYVSCROLL: case SM_CXHSCROLL: return 17;
	case SM_CXEDGE: case SM_CYEDGE: return 2;
	case SM_CXBORDER: case SM_CYBORDER: return 1;
	case SM_CXFRAME: case SM_CYFRAME: return 4;
	case SM_CYCAPTION: return 23;
	case SM_CYMENU: return 20;
	case SM_CXICON: case SM_CYICON: return 32;
	case SM_CXSMICON: case SM_CYSMICON: return 16;
	case SM_CXDOUBLECLK: case SM_CYDOUBLECLK: return 4;
	case SM_CXDRAG: case SM_CYDRAG: return 4;
	case SM_SWAPBUTTON: return 0;
	case SM_CMONITORS: return (int)[NSScreen screens].count;
	default: return 0;
	}
}

BOOL WINAPI SystemParametersInfoW(UINT uiAction, UINT, PVOID pvParam, UINT)
{
	switch(uiAction)
	{
	case SPI_GETWORKAREA:
	{
		const NSRect r = [NSScreen mainScreen].visibleFrame;
		const LONG top = (LONG)(PrimaryScreenHeight() - r.origin.y - r.size.height);
		*static_cast<RECT *>(pvParam) = RECT{(LONG)r.origin.x, top, (LONG)(r.origin.x + r.size.width), (LONG)(top + r.size.height)};
		return TRUE;
	}
	case SPI_GETWHEELSCROLLLINES:
		*static_cast<UINT *>(pvParam) = 3;
		return TRUE;
	case SPI_GETNONCLIENTMETRICS:
	{
		auto *ncm = static_cast<NONCLIENTMETRICSW *>(pvParam);
		const UINT cb = ncm->cbSize;
		*ncm = {};
		ncm->cbSize = cb;
		for(LOGFONTW *lf : {&ncm->lfMessageFont, &ncm->lfMenuFont, &ncm->lfStatusFont, &ncm->lfCaptionFont, &ncm->lfSmCaptionFont})
		{
			lf->lfHeight = -12;
			lf->lfWeight = FW_NORMAL;
			wcscpy(lf->lfFaceName, L"Segoe UI");
		}
		ncm->iScrollWidth = ncm->iScrollHeight = 17;
		ncm->iMenuHeight = 20;
		ncm->iCaptionHeight = 23;
		return TRUE;
	}
	default:
		return FALSE;
	}
}

UINT WINAPI RegisterClipboardFormatW(LPCWSTR lpszFormat)
{
	static std::map<std::wstring, UINT> formats;
	auto [it, inserted] = formats.try_emplace(lpszFormat ? lpszFormat : L"", 0xC000 + (UINT)formats.size());
	return it->second;
}

// ---------------------------------------------------------------------------------------------
// Drag and drop from Finder
// ---------------------------------------------------------------------------------------------

struct HDROP__
{
	std::vector<std::wstring> files;
	POINT point;
};

void WINAPI DragAcceptFiles(HWND hWnd, BOOL fAccept)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(!rec || !rec->nsView) return;
	if(fAccept) [(NSView *)rec->nsView registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
	else [(NSView *)rec->nsView unregisterDraggedTypes];
}

// Called by MPTNSView's performDragOperation: builds the HDROP that WM_DROPFILES expects.
HDROP MacCreateDrop(const std::vector<std::wstring> &files, POINT pt)
{
	return new HDROP__{files, pt};
}

UINT WINAPI DragQueryFileW(HDROP hDrop, UINT iFile, LPWSTR lpszFile, UINT cch)
{
	if(!hDrop) return 0;
	if(iFile == 0xFFFFFFFF) return (UINT)hDrop->files.size();
	if(iFile >= hDrop->files.size()) return 0;
	const std::wstring &file = hDrop->files[iFile];
	if(!lpszFile) return (UINT)file.size();
	return CopyOut(file, lpszFile, cch);
}

void WINAPI DragFinish(HDROP hDrop) { delete hDrop; }

// ---------------------------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------------------------

HINSTANCE WINAPI ShellExecuteW(HWND, LPCWSTR, LPCWSTR lpFile, LPCWSTR, LPCWSTR, INT)
{
	NSString *target = W2NS(lpFile);
	NSURL *url = [target containsString:@"://"] ? [NSURL URLWithString:target] : [NSURL fileURLWithPath:[target stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]];
	return (HINSTANCE)(uintptr_t)([[NSWorkspace sharedWorkspace] openURL:url] ? 33 : 2);  // > 32 means success
}

static std::wstring KnownFolder(int csidl)
{
	NSSearchPathDirectory dir;
	switch(csidl & 0xFF)
	{
	case CSIDL_APPDATA: case CSIDL_LOCAL_APPDATA: dir = NSApplicationSupportDirectory; break;
	case CSIDL_MYMUSIC: dir = NSMusicDirectory; break;
	case CSIDL_DESKTOP: case CSIDL_DESKTOPDIRECTORY: dir = NSDesktopDirectory; break;
	default: dir = NSDocumentDirectory; break;
	}
	NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
	return paths.count ? NS2W(paths[0]) : NS2W(NSHomeDirectory());
}

HRESULT WINAPI SHGetFolderPathW(HWND, int csidl, HANDLE, DWORD, LPWSTR pszPath)
{
	const std::wstring path = KnownFolder(csidl);
	if(csidl & CSIDL_FLAG_CREATE) [[NSFileManager defaultManager] createDirectoryAtPath:W2NS(path.c_str()) withIntermediateDirectories:YES attributes:nil error:nil];
	CopyOut(path, pszPath, MAX_PATH);
	return S_OK;
}

BOOL WINAPI SHGetSpecialFolderPathW(HWND hwnd, LPWSTR pszPath, int csidl, BOOL fCreate)
{
	return SUCCEEDED(SHGetFolderPathW(hwnd, csidl | (fCreate ? CSIDL_FLAG_CREATE : 0), nullptr, 0, pszPath));
}

// The ITEMIDLIST we hand out is just a NUL-terminated wide path after the size header.
// The browse callback picks the start folder by sending BFFM_SETSELECTION to the dialog; this window records it.
static std::wstring g_browseSelection;
static LRESULT CALLBACK BrowseSelectionProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	if(msg == BFFM_SETSELECTIONW && wParam && lParam) g_browseSelection = reinterpret_cast<LPCWSTR>(lParam);
	return msg == BFFM_SETSELECTIONW ? 0 : DefWindowProcW(hWnd, msg, wParam, lParam);
}

LPITEMIDLIST WINAPI SHBrowseForFolderW(LPBROWSEINFOW lpbi)
{
	g_browseSelection.clear();
	if(lpbi && lpbi->lpfn)
	{
		static const bool registered = [] {
			WNDCLASSW wc{};
			wc.lpfnWndProc = BrowseSelectionProc;
			wc.lpszClassName = L"MacBrowseForFolder";
			return RegisterClassW(&wc) != 0;
		}();
		if(HWND hWnd = registered ? CreateWindowExW(0, L"MacBrowseForFolder", L"", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr, nullptr, nullptr) : nullptr)
		{
			lpbi->lpfn(hWnd, BFFM_INITIALIZED, 0, lpbi->lParam);
			DestroyWindow(hWnd);
		}
	}
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	if(!g_browseSelection.empty()) panel.directoryURL = [NSURL fileURLWithPath:W2NS(g_browseSelection.c_str()) isDirectory:YES];
	panel.canChooseFiles = NO;
	panel.canChooseDirectories = YES;
	panel.canCreateDirectories = YES;
	panel.allowsMultipleSelection = NO;
	if(lpbi && lpbi->lpszTitle) panel.message = W2NS(lpbi->lpszTitle);
	if([panel runModal] != NSModalResponseOK || !panel.URL) return nullptr;
	const std::wstring path = NS2W(panel.URL.path);
	const size_t bytes = sizeof(USHORT) + (path.size() + 1) * sizeof(wchar_t);
	auto *pidl = static_cast<ITEMIDLIST *>(calloc(1, bytes + sizeof(wchar_t)));
	pidl->cb = (USHORT)std::min<size_t>(bytes, 0xFFFF);
	auto *text = reinterpret_cast<wchar_t *>(reinterpret_cast<char *>(pidl) + sizeof(wchar_t));
	std::copy(path.begin(), path.end(), text);
	if(lpbi && lpbi->pszDisplayName) CopyOut(NS2W(panel.URL.lastPathComponent), lpbi->pszDisplayName, MAX_PATH);
	return pidl;
}

BOOL WINAPI SHGetPathFromIDListW(LPCITEMIDLIST pidl, LPWSTR pszPath)
{
	if(!pidl || !pszPath) return FALSE;
	const auto *text = reinterpret_cast<const wchar_t *>(reinterpret_cast<const char *>(pidl) + sizeof(wchar_t));
	CopyOut(std::wstring(text), pszPath, MAX_PATH);
	return TRUE;
}

DWORD_PTR WINAPI SHGetFileInfoW(LPCWSTR pszPath, DWORD, SHFILEINFOW *psfi, UINT cbFileInfo, UINT uFlags)
{
	if(!psfi || cbFileInfo < sizeof(SHFILEINFOW)) return 0;
	*psfi = {};
	NSString *path = W2NS(pszPath);
	if(uFlags & SHGFI_DISPLAYNAME) CopyOut(NS2W([[NSFileManager defaultManager] displayNameAtPath:path]), psfi->szDisplayName, MAX_PATH);
	if(uFlags & SHGFI_ICON)
	{
		auto *icon = new HICON__();
		icon->image = [[NSWorkspace sharedWorkspace] iconForFile:path];
		psfi->hIcon = icon;
	}
	return 1;
}

BOOL WINAPI ChooseColorW(LPCHOOSECOLORW lpcc)
{
	if(!lpcc) return FALSE;
	// NSColorPanel is modeless; run it modally so the Win32 call semantics hold.
	NSColorPanel *panel = [NSColorPanel sharedColorPanel];
	const COLORREF c = lpcc->rgbResult;
	panel.color = [NSColor colorWithSRGBRed:GetRValue(c) / 255.0 green:GetGValue(c) / 255.0 blue:GetBValue(c) / 255.0 alpha:1.0];
	panel.showsAlpha = NO;
	[NSApp runModalForWindow:panel];
	NSColor *chosen = [panel.color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
	lpcc->rgbResult = RGB((int)lround(chosen.redComponent * 255), (int)lround(chosen.greenComponent * 255), (int)lround(chosen.blueComponent * 255));
	return TRUE;
}

// ---------------------------------------------------------------------------------------------
// GDI extras and MFC GDI wrappers
// ---------------------------------------------------------------------------------------------

HGDIOBJ WINAPI GetStockObject(int i)
{
	static std::map<int, HGDIOBJ> stock;
	auto &obj = stock[i];
	if(obj) return obj;
	switch(i)
	{
	case WHITE_BRUSH: obj = CreateSolidBrush(RGB(255, 255, 255)); break;
	case LTGRAY_BRUSH: obj = CreateSolidBrush(RGB(192, 192, 192)); break;
	case GRAY_BRUSH: obj = CreateSolidBrush(RGB(128, 128, 128)); break;
	case DKGRAY_BRUSH: obj = CreateSolidBrush(RGB(64, 64, 64)); break;
	case BLACK_BRUSH: obj = CreateSolidBrush(RGB(0, 0, 0)); break;
	case NULL_BRUSH: { auto *b = new MacBrush(); b->style = BS_NULL; obj = b; break; }
	case WHITE_PEN: obj = CreatePen(PS_SOLID, 1, RGB(255, 255, 255)); break;
	case BLACK_PEN: obj = CreatePen(PS_SOLID, 1, RGB(0, 0, 0)); break;
	case NULL_PEN: obj = CreatePen(PS_NULL, 0, 0); break;
	case DC_BRUSH: obj = CreateSolidBrush(RGB(255, 255, 255)); break;
	case DC_PEN: obj = CreatePen(PS_SOLID, 1, RGB(0, 0, 0)); break;
	default:
	{
		// DEFAULT_GUI_FONT / SYSTEM_FONT / ANSI_VAR_FONT: Windows 10 dialog font.
		LOGFONTW lf{};
		lf.lfHeight = -11;
		lf.lfWeight = FW_NORMAL;
		wcscpy(lf.lfFaceName, L"Segoe UI");
		obj = CreateFontIndirectW(&lf);
		break;
	}
	}
	if(obj) static_cast<MacGdiObject *>(obj)->isStock = true;
	return obj;
}

int WINAPI SetDIBits(HDC, HBITMAP hbm, UINT start, UINT cLines, const VOID *lpBits, const BITMAPINFO *lpbmi, UINT)
{
	if(!hbm || !lpBits || !lpbmi || lpbmi->bmiHeader.biBitCount != 32) return 0;
	const int width = std::min<int>(hbm->width, lpbmi->bmiHeader.biWidth);
	const bool bottomUp = lpbmi->bmiHeader.biHeight > 0;
	const size_t dstStride = (size_t)hbm->width * 4;
	const size_t srcStride = (size_t)lpbmi->bmiHeader.biWidth * 4;
	// 32-bit BI_RGB DIBs usually leave alpha at 0, meaning "no alpha": treat those as opaque.
	bool hasAlpha = false;
	for(size_t i = 3; i < srcStride * cLines && !hasAlpha; i += 4) hasAlpha = static_cast<const uint8_t *>(lpBits)[i] != 0;
	UINT copied = 0;
	for(UINT line = 0; line < cLines; line++)
	{
		const int y = (int)(start + line);
		const int dstRow = bottomUp ? hbm->height - 1 - y : y;
		if(dstRow < 0 || dstRow >= hbm->height) continue;
		const auto *src = static_cast<const uint8_t *>(lpBits) + line * srcStride;
		uint8_t *dst = hbm->pixelData.data() + (size_t)dstRow * dstStride;
		for(int x = 0; x < width; x++)
		{
			// BGRA (DIB) -> premultiplied RGBA (CGBitmapContext).
			const uint8_t alpha = hasAlpha ? src[x * 4 + 3] : 0xFF;
			dst[x * 4 + 0] = (uint8_t)(src[x * 4 + 2] * alpha / 255);
			dst[x * 4 + 1] = (uint8_t)(src[x * 4 + 1] * alpha / 255);
			dst[x * 4 + 2] = (uint8_t)(src[x * 4 + 0] * alpha / 255);
			dst[x * 4 + 3] = alpha;
		}
		copied++;
	}
	return (int)copied;
}

BOOL WINAPI AlphaBlend(HDC hdcDest, int xoriginDest, int yoriginDest, int wDest, int hDest, HDC hdcSrc, int xoriginSrc, int yoriginSrc, int wSrc, int hSrc, BLENDFUNCTION ftn)
{
	if(!hdcDest || !hdcDest->cgContext) return FALSE;
	CGContextSaveGState(hdcDest->cgContext);
	CGContextSetAlpha(hdcDest->cgContext, ftn.SourceConstantAlpha / 255.0);
	const BOOL result = StretchBlt(hdcDest, xoriginDest, yoriginDest, wDest, hDest, hdcSrc, xoriginSrc, yoriginSrc, wSrc, hSrc, SRCCOPY);
	CGContextRestoreGState(hdcDest->cgContext);
	return result;
}

BOOL WINAPI TransparentBlt(HDC hdcDest, int xoriginDest, int yoriginDest, int wDest, int hDest, HDC hdcSrc, int xoriginSrc, int yoriginSrc, int wSrc, int hSrc, UINT crTransparent)
{
	if(!hdcDest || !hdcDest->cgContext || !hdcSrc || !hdcSrc->currentBitmap || !hdcSrc->currentBitmap->bitmapContext) return FALSE;
	MacBitmap *src = hdcSrc->currentBitmap;
	CGImageRef image = CGBitmapContextCreateImage(src->bitmapContext);
	if(!image) return FALSE;
	const CGFloat r = GetRValue(crTransparent), g = GetGValue(crTransparent), b = GetBValue(crTransparent);
	const CGFloat mask[6] = {r, r, g, g, b, b};
	CGImageRef opaque = CGImageCreateCopyWithColorSpace(image, CGImageGetColorSpace(image));
	CGImageRelease(image);
	// Masking colours requires an image without alpha; redraw into an RGB context first.
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
	CGContextRef noAlpha = CGBitmapContextCreate(nullptr, src->width, src->height, 8, 0, rgb, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
	CGContextDrawImage(noAlpha, CGRectMake(0, 0, src->width, src->height), opaque);
	CGImageRelease(opaque);
	CGImageRef flat = CGBitmapContextCreateImage(noAlpha);
	CGContextRelease(noAlpha);
	CGColorSpaceRelease(rgb);
	CGImageRef masked = CGImageCreateWithMaskingColors(flat, mask);
	CGImageRelease(flat);
	if(!masked) return FALSE;
	CGImageRef sub = CGImageCreateWithImageInRect(masked, CGRectMake(xoriginSrc, src->bottomUp ? src->height - (yoriginSrc + hSrc) : yoriginSrc, wSrc, hSrc));
	CGImageRelease(masked);
	if(!sub) return FALSE;
	CGContextRef ctx = hdcDest->cgContext;
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, xoriginDest + hdcDest->viewportOrg.x, yoriginDest + hdcDest->viewportOrg.y + hDest);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextDrawImage(ctx, CGRectMake(0, 0, wDest, hDest), sub);
	CGContextRestoreGState(ctx);
	CGImageRelease(sub);
	return TRUE;
}


// MFC's FromHandle returns temporary wrappers; these are kept for the process lifetime (and
// never own the handle) because callers routinely hold on to them across messages.
template <typename Wrapper, typename Handle>
static Wrapper *WrapperFor(Handle h)
{
	if(!h) return nullptr;
	static std::map<Handle, Wrapper *> wrappers;
	Wrapper *&w = wrappers[h];
	if(!w) w = new Wrapper();
	if constexpr(std::is_same_v<Wrapper, CDC>) w->m_hDC = w->m_hAttribDC = h;
	else w->m_hObject = h;
	return w;
}

CDC *CDC::FromHandle(HDC hDC) { return WrapperFor<CDC>(hDC); }
CFont *CFont::FromHandle(HFONT hFont) { return WrapperFor<CFont>(hFont); }
CBrush *CBrush::FromHandle(HBRUSH hBrush) { return WrapperFor<CBrush>(hBrush); }
CBitmap *CBitmap::FromHandle(HBITMAP hBitmap) { return WrapperFor<CBitmap>(hBitmap); }

IMPLEMENT_DYNAMIC(CDC, CObject)

CGdiObject *CDC::SelectObject(CGdiObject *pObject)
{
	return pObject ? WrapperFor<CGdiObject>(::SelectObject(m_hDC, pObject->GetSafeHandle())) : nullptr;
}

CFont *CDC::SelectObject(CFont *pFont)
{
	return pFont ? CFont::FromHandle((HFONT)::SelectObject(m_hDC, pFont->GetSafeHandle())) : nullptr;
}

CBitmap *CDC::SelectObject(CBitmap *pBitmap)
{
	return pBitmap ? CBitmap::FromHandle((HBITMAP)::SelectObject(m_hDC, pBitmap->GetSafeHandle())) : nullptr;
}

CGdiObject *CDC::SelectStockObject(int nIndex)
{
	return WrapperFor<CGdiObject>(::SelectObject(m_hDC, ::GetStockObject(nIndex)));
}

BOOL CBitmap::CreateCompatibleBitmap(CDC *pDC, int nWidth, int nHeight)
{
	return Attach(::CreateCompatibleBitmap(pDC ? pDC->GetSafeHdc() : nullptr, nWidth, nHeight));
}

BOOL CBrush::CreatePatternBrush(CBitmap *pBitmap)
{
	auto *brush = new MacBrush();
	brush->style = BS_PATTERN;
	brush->pattern = pBitmap ? (HBITMAP)pBitmap->GetSafeHandle() : nullptr;
	return Attach(brush);
}

// ---------------------------------------------------------------------------------------------
// MFC runtime pieces
// ---------------------------------------------------------------------------------------------

const CRuntimeClass CObject::classCObject = {"CObject", sizeof(CObject), 0xFFFF, nullptr, nullptr, nullptr};

IMPLEMENT_DYNAMIC(CWinApp, CWinThread)
BEGIN_MESSAGE_MAP(CWinApp, CWinThread)
END_MESSAGE_MAP()

// MFC falls back to an INI file when no registry key is set; macOS always uses this path.
static std::wstring AppProfilePath(const CWinApp &app)
{
	if(app.m_pszProfileName) return app.m_pszProfileName;
	wchar_t folder[MAX_PATH] = {};
	SHGetFolderPathW(nullptr, CSIDL_APPDATA | CSIDL_FLAG_CREATE, nullptr, 0, folder);
	std::wstring dir = std::wstring(folder) + L"/OpenMPT";
	[[NSFileManager defaultManager] createDirectoryAtPath:W2NS(dir.c_str()) withIntermediateDirectories:YES attributes:nil error:nil];
	return dir + L"/OpenMPT-profile.ini";
}

UINT CWinApp::GetProfileInt(LPCTSTR lpszSection, LPCTSTR lpszEntry, int nDefault)
{
	return GetPrivateProfileIntW(lpszSection, lpszEntry, nDefault, AppProfilePath(*this).c_str());
}

BOOL CWinApp::WriteProfileInt(LPCTSTR lpszSection, LPCTSTR lpszEntry, int nValue)
{
	return WritePrivateProfileStringW(lpszSection, lpszEntry, std::to_wstring(nValue).c_str(), AppProfilePath(*this).c_str());
}

CString CWinApp::GetProfileString(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPCTSTR lpszDefault)
{
	std::vector<wchar_t> buf(4096);
	GetPrivateProfileStringW(lpszSection, lpszEntry, lpszDefault ? lpszDefault : L"", buf.data(), (DWORD)buf.size(), AppProfilePath(*this).c_str());
	return CString(buf.data());
}

BOOL CWinApp::WriteProfileString(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPCTSTR lpszValue)
{
	return WritePrivateProfileStringW(lpszSection, lpszEntry, lpszValue, AppProfilePath(*this).c_str());
}

// Binary values use MFC's INI encoding: one letter per nibble, 'A' + value.
BOOL CWinApp::GetProfileBinary(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPBYTE *ppData, UINT *pBytes)
{
	if(!ppData || !pBytes) return FALSE;
	*ppData = nullptr;
	*pBytes = 0;
	const CString encoded = GetProfileString(lpszSection, lpszEntry, nullptr);
	const int len = encoded.GetLength();
	if(len == 0 || (len % 2) != 0) return FALSE;
	*pBytes = (UINT)len / 2;
	*ppData = new BYTE[*pBytes];
	for(UINT i = 0; i < *pBytes; i++)
		(*ppData)[i] = (BYTE)(((encoded[(int)i * 2 + 1] - L'A') << 4) | (encoded[(int)i * 2] - L'A'));
	return TRUE;
}

BOOL CWinApp::WriteProfileBinary(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPBYTE pData, UINT nBytes)
{
	std::wstring encoded;
	for(UINT i = 0; i < nBytes; i++)
	{
		encoded += (wchar_t)(L'A' + (pData[i] & 0x0F));
		encoded += (wchar_t)(L'A' + ((pData[i] >> 4) & 0x0F));
	}
	return WriteProfileString(lpszSection, lpszEntry, encoded.c_str());
}

// Decodes a BITMAP/PNG resource from mptrack.rc into a 32-bit GDI bitmap.
BOOL CBitmap::LoadBitmap(LPCTSTR lpszResourceName)
{
	const std::vector<uint8_t> *data = nullptr;
	if(IS_INTRESOURCE(lpszResourceName))
		data = MacResourceManager::Instance().GetImageData((int)(uintptr_t)lpszResourceName);
	else
		data = MacResourceManager::Instance().GetImageData(W2U(lpszResourceName).c_str());
	if(!data || data->empty()) return FALSE;
	CFDataRef cfData = CFDataCreate(nullptr, data->data(), (CFIndex)data->size());
	CGImageSourceRef source = CGImageSourceCreateWithData(cfData, nullptr);
	CFRelease(cfData);
	if(!source) return FALSE;
	CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, nullptr);
	CFRelease(source);
	if(!image) return FALSE;
	const int width = (int)CGImageGetWidth(image), height = (int)CGImageGetHeight(image);
	HBITMAP bitmap = ::CreateBitmap(width, height, 1, 32, nullptr);
	if(bitmap && bitmap->bitmapContext)
	{
		// The context is y-down for GDI; undo that so the image lands upright.
		CGContextSaveGState(bitmap->bitmapContext);
		CGContextTranslateCTM(bitmap->bitmapContext, 0, height);
		CGContextScaleCTM(bitmap->bitmapContext, 1, -1);
		CGContextDrawImage(bitmap->bitmapContext, CGRectMake(0, 0, width, height), image);
		CGContextRestoreGState(bitmap->bitmapContext);
	}
	CGImageRelease(image);
	return Attach(bitmap);
}

void CRecentFileList::UpdateMenu(CCmdUI *pCmdUI)
{
	if(!pCmdUI) return;
	pCmdUI->Enable(m_nSize > 0 && !m_arrNames[0].IsEmpty());
}

BOOL COleDropTarget::Register(CWnd *pWnd)
{
	if(!pWnd) return FALSE;
	m_hWnd = pWnd->GetSafeHwnd();
	DragAcceptFiles(m_hWnd, TRUE);
	return TRUE;
}

void COleDropTarget::Revoke()
{
	if(m_hWnd) DragAcceptFiles(m_hWnd, FALSE);
	m_hWnd = nullptr;
}

// ---------------------------------------------------------------------------------------------
// Entry point: the equivalent of AfxWinMain.
// ---------------------------------------------------------------------------------------------

void MacRegisterCommonControls();
void MacRegisterListTreeControls();

int main(int argc, char *argv[])
{
	(void)argc; (void)argv;
	@autoreleasepool
	{
		[NSApplication sharedApplication];
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

		NSString *resources = [[NSBundle mainBundle] resourcePath];
		MacRegisterCommonControls();
		MacRegisterListTreeControls();
		MacResourceManager::Instance().Initialize(
			[[resources stringByAppendingPathComponent:@"resource.h"] UTF8String],
			[[resources stringByAppendingPathComponent:@"mptrack.rc"] UTF8String],
			[resources UTF8String]);

		CWinApp *app = AfxGetApp();
		if(!app) return 1;
		if(!app->InitInstance())
		{
			app->ExitInstance();
			return 1;
		}
		[NSApp activateIgnoringOtherApps:YES];
		// Debug aid: MPT_SNAPSHOT_DIR=<dir> renders every window to PNG after startup (needs no screen-recording permission).
		if(const char *snapshotDir = getenv("MPT_SNAPSHOT_DIR"))
		{
			NSString *dir = [NSString stringWithUTF8String:snapshotDir];
			// MPT_SNAPSHOT_COMMAND=<id> sends that menu command first, e.g. 32782 (View > Patterns).
			if(const char *command = getenv("MPT_SNAPSHOT_COMMAND"))
			{
				const WPARAM id = (WPARAM)strtoul(command, nullptr, 0);
				// Runs before the snapshot below.
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					if(CWnd *main = AfxGetMainWnd()) main->SendMessage(WM_COMMAND, MAKEWPARAM(id, 0), 0);
				});
			}
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				// Window tree dump: class, id, rect (parent-relative), visibility, text.
				std::function<void(HWND, int)> dump = [&](HWND hWnd, int depth) {
					WindowRecord *rec = GetWindowRecord(hWnd);
					if(!rec) return;
					fprintf(stderr, "%*s%s id=%d rect=(%d,%d %dx%d)%s%s \"%s\"\n", depth * 2, "", rec->className.c_str(), (int)rec->id,
						(int)rec->rect.left, (int)rec->rect.top, (int)(rec->rect.right - rec->rect.left), (int)(rec->rect.bottom - rec->rect.top),
						rec->isVisible ? "" : " hidden", rec->wndProc ? " proc" : "", rec->windowText.c_str());
					if(rec->className == "SysTabControl32")
					{
						int cnt = (int)::SendMessageW(hWnd, TCM_GETITEMCOUNT, 0, 0);
						fprintf(stderr, "%*s  [Tabs %d]: ", depth * 2, "", cnt);
						for(int i = 0; i < cnt; i++) {
							wchar_t buf[64] = {};
							TCITEMW item{}; item.mask = TCIF_TEXT | TCIF_PARAM; item.pszText = buf; item.cchTextMax = 64;
							::SendMessageW(hWnd, TCM_GETITEMW, i, (LPARAM)&item);
							fprintf(stderr, "(%d: \"%ls\", param=%ld) ", i, buf, item.lParam);
						}
						fprintf(stderr, "\n");
					}
					for(HWND child : rec->children) dump(child, depth + 1);
				};
				for(HWND hWnd : GetAllWindowHandles())
					if(WindowRecord *rec = GetWindowRecord(hWnd); rec && !rec->parent) dump(hWnd, 0);
				int index = 0;
				for(NSWindow *window in [NSApp windows])
				{
					NSView *view = window.contentView;
					if(!window.visible || !view) continue;
					NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
					[view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
					NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
					[png writeToFile:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"window%d.png", index++]] atomically:YES];
				}
			});
		}
		return app->Run();
	}
}
