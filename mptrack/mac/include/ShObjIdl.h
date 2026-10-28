#pragma once

#include "windows.h"

typedef enum TBPFLAG {
    TBPF_NOPROGRESS    = 0,
    TBPF_INDETERMINATE = 0x1,
    TBPF_NORMAL        = 0x2,
    TBPF_ERROR         = 0x4,
    TBPF_PAUSED        = 0x8
} TBPFLAG;

struct ITaskbarList3 : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE HrInit() = 0;
    virtual HRESULT STDMETHODCALLTYPE AddTab(HWND hwnd) = 0;
    virtual HRESULT STDMETHODCALLTYPE DeleteTab(HWND hwnd) = 0;
    virtual HRESULT STDMETHODCALLTYPE ActivateTab(HWND hwnd) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetActiveAlt(HWND hwnd) = 0;
    virtual HRESULT STDMETHODCALLTYPE MarkFullscreenWindow(HWND hwnd, BOOL fFullscreen) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetProgressValue(HWND hwnd, ULONGLONG ullCompleted, ULONGLONG ullTotal) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetProgressState(HWND hwnd, TBPFLAG tbpFlags) = 0;
};

static const CLSID CLSID_TaskbarList = {0x56fdf344, 0xfd6d, 0x11d0, {0x95, 0x8a, 0x00, 0x60, 0x97, 0xc9, 0xa0, 0x90}};
static const IID IID_ITaskbarList3 = {0xea1afb91, 0x9e28, 0x4b86, {0x90, 0xe9, 0x9e, 0x9f, 0x8a, 0x5e, 0xef, 0xaf}};

struct IShellItem : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE BindToHandler(void*, REFGUID, REFIID, void**) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetParent(IShellItem**) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetDisplayName(DWORD, LPWSTR*) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetAttributes(ULONG, ULONG*) = 0;
    virtual HRESULT STDMETHODCALLTYPE Compare(IShellItem*, DWORD, int*) = 0;
};

struct IShellLinkW : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE GetPath(LPWSTR pszFile, int cch, WIN32_FIND_DATAW *pfd, DWORD fFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetIDList(void **ppidl) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetIDList(const void *pidl) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetDescription(LPWSTR pszName, int cch) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetDescription(LPCWSTR pszName) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetWorkingDirectory(LPWSTR pszDir, int cch) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetWorkingDirectory(LPCWSTR pszDir) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetArguments(LPWSTR pszArgs, int cch) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetArguments(LPCWSTR pszArgs) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetHotkey(WORD *pwHotkey) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetHotkey(WORD wHotkey) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetShowCmd(int *piShowCmd) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetShowCmd(int iShowCmd) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetIconLocation(LPWSTR pszIconPath, int cch, int *piIcon) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetIconLocation(LPCWSTR pszIconPath, int iIcon) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetRelativePath(LPCWSTR pszPathRel, DWORD dwReserved) = 0;
    virtual HRESULT STDMETHODCALLTYPE Resolve(HWND hwnd, DWORD fFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetPath(LPCWSTR pszFile) = 0;
};
typedef IShellLinkW IShellLink;

struct IPersistFile : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE GetClassID(CLSID *pClassID) = 0;
    virtual HRESULT STDMETHODCALLTYPE IsDirty(void) = 0;
    virtual HRESULT STDMETHODCALLTYPE Load(LPCOLESTR pszFileName, DWORD dwMode) = 0;
    virtual HRESULT STDMETHODCALLTYPE Save(LPCOLESTR pszFileName, BOOL fRemember) = 0;
    virtual HRESULT STDMETHODCALLTYPE SaveCompleted(LPCOLESTR pszFileName) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetCurFile(LPOLESTR *ppszFileName) = 0;
};

static const CLSID CLSID_ShellLink = {0x00021401, 0x0000, 0x0000, {0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46}};
static const CLSID CLSID_FolderShortcut = {0x0afaced1, 0xe828, 0x11d1, {0x91, 0x87, 0xb5, 0x32, 0xf1, 0xe9, 0x57, 0x5d}};
static const IID IID_IShellLinkW = {0x000214f9, 0x0000, 0x0000, {0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46}};
#define IID_IShellLink IID_IShellLinkW
static const IID IID_IPersistFile = {0x0000010b, 0x0000, 0x0000, {0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46}};

#define SLGP_SHORTPATH      0x1
#define SLGP_UNCPRIORITY    0x2
#define SLGP_RAWPATH        0x4
#define SLR_NO_UI           0x1
#define SLR_ANY_MATCH       0x2
#define SLR_UPDATE          0x4
#define SLR_NOUPDATE        0x8
#define SLR_NOSEARCH        0x10
#define SLR_NOTRACK         0x20
#define SLR_NOLINKINFO      0x40
#define STGM_READ           0x00000000L

#ifndef T2COLE
#define T2COLE(x) (x)
#endif
#ifndef USES_CONVERSION
#define USES_CONVERSION
#endif


