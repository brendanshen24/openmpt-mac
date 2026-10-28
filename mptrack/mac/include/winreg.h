#pragma once

#include "windows.h"

typedef LONG LSTATUS;

#define HKEY_CLASSES_ROOT       ((HKEY)(ULONG_PTR)((LONG)0x80000000))
#define HKEY_CURRENT_USER       ((HKEY)(ULONG_PTR)((LONG)0x80000001))
#define HKEY_LOCAL_MACHINE      ((HKEY)(ULONG_PTR)((LONG)0x80000002))
#define HKEY_USERS              ((HKEY)(ULONG_PTR)((LONG)0x80000003))
#define HKEY_CURRENT_CONFIG     ((HKEY)(ULONG_PTR)((LONG)0x80000005))

#define KEY_QUERY_VALUE         (0x0001)
#define KEY_SET_VALUE           (0x0002)
#define KEY_CREATE_SUB_KEY      (0x0004)
#define KEY_ENUMERATE_SUB_KEYS  (0x0008)
#define KEY_NOTIFY              (0x0010)
#define KEY_CREATE_LINK         (0x0020)
#define KEY_WOW64_32KEY         (0x0200)
#define KEY_WOW64_64KEY         (0x0100)
#define KEY_READ                (0x20019)
#define KEY_WRITE               (0x20006)
#define KEY_EXECUTE             KEY_READ
#define KEY_ALL_ACCESS          (0xF003F)

#define REG_NONE                0
#define REG_SZ                  1
#define REG_EXPAND_SZ           2
#define REG_BINARY              3
#define REG_DWORD               4
#define REG_DWORD_LITTLE_ENDIAN 4
#define REG_DWORD_BIG_ENDIAN    5
#define REG_LINK                6
#define REG_MULTI_SZ            7
#define REG_QWORD               11

extern "C" {
inline LSTATUS WINAPI RegOpenKeyExA(HKEY, LPCSTR, DWORD, REGSAM, PHKEY) { return ERROR_FILE_NOT_FOUND; }
inline LSTATUS WINAPI RegOpenKeyExW(HKEY, LPCWSTR, DWORD, REGSAM, PHKEY) { return ERROR_FILE_NOT_FOUND; }
inline LSTATUS WINAPI RegQueryValueExA(HKEY, LPCSTR, LPDWORD, LPDWORD, LPBYTE, LPDWORD) { return ERROR_FILE_NOT_FOUND; }
inline LSTATUS WINAPI RegQueryValueExW(HKEY, LPCWSTR, LPDWORD, LPDWORD, LPBYTE, LPDWORD) { return ERROR_FILE_NOT_FOUND; }
inline LSTATUS WINAPI RegCloseKey(HKEY) { return ERROR_SUCCESS; }
inline LSTATUS WINAPI RegEnumKeyExA(HKEY, DWORD, LPSTR, LPDWORD, LPDWORD, LPSTR, LPDWORD, PFILETIME) { return ERROR_NO_MORE_FILES; }
inline LSTATUS WINAPI RegEnumKeyExW(HKEY, DWORD, LPWSTR, LPDWORD, LPDWORD, LPWSTR, LPDWORD, PFILETIME) { return ERROR_NO_MORE_FILES; }
inline LSTATUS WINAPI RegEnumValueA(HKEY, DWORD, LPSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD) { return ERROR_NO_MORE_FILES; }
inline LSTATUS WINAPI RegEnumValueW(HKEY, DWORD, LPWSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD) { return ERROR_NO_MORE_FILES; }

inline LSTATUS WINAPI RegOpenKeyA(HKEY hKey, LPCSTR lpSubKey, PHKEY phkResult) { return RegOpenKeyExA(hKey, lpSubKey, 0, KEY_READ, phkResult); }
inline LSTATUS WINAPI RegOpenKeyW(HKEY hKey, LPCWSTR lpSubKey, PHKEY phkResult) { return RegOpenKeyExW(hKey, lpSubKey, 0, KEY_READ, phkResult); }

#ifdef UNICODE
#define RegOpenKey RegOpenKeyW
#define RegOpenKeyEx RegOpenKeyExW
#define RegQueryValueEx RegQueryValueExW
#define RegEnumKeyEx RegEnumKeyExW
#define RegEnumValue RegEnumValueW
#else
#define RegOpenKey RegOpenKeyA
#define RegOpenKeyEx RegOpenKeyExA
#define RegQueryValueEx RegQueryValueExA
#define RegEnumKeyEx RegEnumKeyExA
#define RegEnumValue RegEnumValueA
#endif
}
