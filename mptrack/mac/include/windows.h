#pragma once

#include <cstdint>
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <cstdarg>
#include <cwchar>
#include <cwctype>
#include <cmath>
#include <ctime>
#include <climits>
#include <algorithm>
#include <string>
#include <vector>
#include <unistd.h>

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

#define CALLBACK
#define WINAPI
#define WINAPIV
#define APIENTRY
#define APIPRIVATE
#define PASCAL
#define CDECL
#define STDMETHODCALLTYPE
#define __stdcall
#define __cdecl
#ifndef interface
#define interface struct
#endif
#define __fastcall
#define DECLSPEC_UUID(x)

// SAL annotations
#ifndef _In_
#define _In_
#define _In_opt_
#define _In_z_
#define _In_opt_z_
#define _Out_
#define _Out_opt_
#define _Inout_
#define _Inout_opt_
#define _Ret_maybenull_
#define _Ret_notnull_
#define _Success_(x)
#define _Check_return_
#define _Acquires_lock_(x)
#define _Releases_lock_(x)
#define _Guarded_by_(x)
#define _Post_equal_to_(x)
#endif

// Basic types
// Win32 BOOL must be int in every translation unit so C++ and Objective-C++ objects link.
// In ObjC++ the Cocoa headers are pulled in first, then BOOL is redirected to the Win32 type.
typedef int WINBOOL;
#ifdef __OBJC__
#import <AppKit/AppKit.h>
#define BOOL WINBOOL
#else
typedef int BOOL;
#endif
typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef uint32_t DWORD;
typedef int32_t LONG;
typedef uint32_t ULONG;
typedef int INT;
typedef unsigned int UINT;
typedef uint32_t UINT32;
typedef int32_t INT32;
typedef unsigned short USHORT;
typedef short SHORT;
typedef int64_t LONGLONG;
typedef uint64_t ULONGLONG;
typedef uint64_t DWORD64;
typedef uint64_t DWORDLONG;
typedef intptr_t INT_PTR;
typedef uintptr_t UINT_PTR;
typedef intptr_t LONG_PTR;
typedef uintptr_t ULONG_PTR;
typedef uintptr_t DWORD_PTR;
typedef size_t SIZE_T;
typedef ptrdiff_t SSIZE_T;
typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;
typedef LONG_PTR LRESULT;
typedef int32_t HRESULT;
typedef int32_t SCODE;
typedef WORD ATOM;
typedef DWORD COLORREF;
typedef float FLOAT;
typedef double DOUBLE;

typedef DWORD LCID;
typedef WORD LANGID;
typedef DWORD LCTYPE;
#define _CVTBUFSIZE (309 + 40)
#define LOCALE_USER_DEFAULT 0x0400
#define LOCALE_SDECIMAL 0x0000000E
#define LOCALE_SNEGATIVESIGN 0x00000051

typedef char CHAR;
typedef wchar_t WCHAR;
typedef wchar_t OLECHAR;
typedef WCHAR* BSTR;
typedef OLECHAR* LPOLESTR;
typedef const OLECHAR* LPCOLESTR;

typedef short VARIANT_BOOL;
#define VARIANT_TRUE ((VARIANT_BOOL)-1)
#define VARIANT_FALSE ((VARIANT_BOOL)0)

typedef unsigned short VARTYPE;
enum VARENUM {
    VT_EMPTY = 0,
    VT_NULL = 1,
    VT_I2 = 2,
    VT_I4 = 3,
    VT_R4 = 4,
    VT_R8 = 5,
    VT_CY = 6,
    VT_DATE = 7,
    VT_BSTR = 8,
    VT_DISPATCH = 9,
    VT_ERROR = 10,
    VT_BOOL = 11,
    VT_VARIANT = 12,
    VT_UNKNOWN = 13,
    VT_DECIMAL = 14,
    VT_I1 = 16,
    VT_UI1 = 17,
    VT_UI2 = 18,
    VT_UI4 = 19,
    VT_I8 = 20,
    VT_UI8 = 21,
    VT_INT = 22,
    VT_UINT = 23,
    VT_VOID = 24,
    VT_HRESULT = 25,
    VT_PTR = 26,
    VT_SAFEARRAY = 27,
    VT_CARRAY = 28,
    VT_USERDEFINED = 29,
    VT_LPSTR = 30,
    VT_LPWSTR = 31,
    VT_RECORD = 36,
    VT_INT_PTR = 37,
    VT_UINT_PTR = 38,
    VT_FILETIME = 64,
    VT_BLOB = 65,
    VT_STREAM = 66,
    VT_STORAGE = 67,
    VT_STREAMED_OBJECT = 68,
    VT_STORED_OBJECT = 69,
    VT_BLOB_OBJECT = 70,
    VT_CF = 71,
    VT_CLSID = 72,
    VT_VERSIONED_STREAM = 73,
    VT_BSTR_BLOB = 0xfff,
    VT_VECTOR = 0x1000,
    VT_ARRAY = 0x2000,
    VT_BYREF = 0x4000,
    VT_RESERVED = 0x8000,
    VT_ILLEGAL = 0xffff
};

struct VARIANT {
    VARTYPE vt = 0;
    WORD wReserved1 = 0, wReserved2 = 0, wReserved3 = 0;
    union {
        LONG lVal;
        BYTE bVal;
        SHORT iVal;
        FLOAT fltVal;
        DOUBLE dblVal;
        VARIANT_BOOL boolVal;
        int32_t scode;
        BSTR bstrVal;
        void *punkVal;
        void *pdispVal;
        void *byref;
        int64_t llVal;
    };
};
typedef VARIANT VARIANTARG;
#define CHILDID_SELF 0

#ifdef UNICODE
typedef WCHAR TCHAR;
#define _T(x) L##x
#define TEXT(x) L##x
#else
typedef CHAR TCHAR;
#define _T(x) x
#define TEXT(x) x
#endif

typedef CHAR* LPSTR;
typedef const CHAR* LPCSTR;
typedef WCHAR* LPWSTR;
typedef const WCHAR* LPCWSTR;
typedef const WCHAR* PCWSTR;
typedef const CHAR* PCSTR;
typedef TCHAR* LPTSTR;
typedef const TCHAR* LPCTSTR;
typedef const TCHAR* PCTSTR;
typedef BYTE* LPBYTE;
typedef const BYTE* LPCBYTE;
typedef DWORD* LPDWORD;
typedef WORD* LPWORD;
typedef LONG* LPLONG;
typedef ULONG* LPULONG;
typedef INT* LPINT;
typedef UINT* LPUINT;
typedef void* LPVOID;
typedef void VOID;
typedef void* PVOID;
typedef const void* PCVOID;
typedef const void* LPCVOID;
typedef BYTE* PBYTE;
typedef const BYTE* PCBYTE;
typedef WORD* PWORD;
typedef DWORD* PDWORD;
typedef LONG* PLONG;
typedef ULONG* PULONG;
typedef INT* PINT;
typedef UINT* PUINT;
typedef BOOL* PBOOL;
typedef BOOL* LPBOOL;
typedef FLOAT* PFLOAT;

inline int WINAPI GetLocaleInfoW(LCID Locale, LCTYPE LCType, LPWSTR lpLCData, int cchData) {
    (void)Locale;
    const wchar_t* val = L".";
    if (LCType == LOCALE_SNEGATIVESIGN) val = L"-";
    else if (LCType == LOCALE_SDECIMAL) val = L".";
    int len = (int)wcslen(val) + 1;
    if (cchData <= 0 || !lpLCData) return len;
    wcsncpy(lpLCData, val, cchData);
    return len;
}
inline int WINAPI GetLocaleInfoA(LCID Locale, LCTYPE LCType, LPSTR lpLCData, int cchData) {
    (void)Locale;
    const char* val = ".";
    if (LCType == LOCALE_SNEGATIVESIGN) val = "-";
    else if (LCType == LOCALE_SDECIMAL) val = ".";
    int len = (int)strlen(val) + 1;
    if (cchData <= 0 || !lpLCData) return len;
    strncpy(lpLCData, val, cchData);
    return len;
}
#ifdef UNICODE
#define GetLocaleInfo GetLocaleInfoW
#else
#define GetLocaleInfo GetLocaleInfoA
#endif

#define CP_ACP 0
#define CP_OEMCP 1
#define CP_MACCP 2
#define CP_THREAD_ACP 3
#define CP_SYMBOL 42
#define CP_UTF7 65000
#define CP_UTF8 65001

// Handles
typedef void* HANDLE;
typedef HANDLE* LPHANDLE;
struct HWND__; typedef HWND__* HWND;
#define HWND_DESKTOP ((HWND)0)
struct HDC__; typedef HDC__* HDC;
struct HGDIOBJ__; typedef void* HGDIOBJ;
struct HFONT__; typedef HFONT__* HFONT;
struct HBITMAP__; typedef HBITMAP__* HBITMAP;
struct HBRUSH__; typedef HBRUSH__* HBRUSH;
struct HPEN__; typedef HPEN__* HPEN;
struct HRGN__; typedef HRGN__* HRGN;
struct HPALETTE__; typedef HPALETTE__* HPALETTE;
struct HICON__; typedef HICON__* HICON;
typedef HICON HCURSOR;
struct HMENU__; typedef HMENU__* HMENU;
struct HINSTANCE__; typedef HINSTANCE__* HINSTANCE;
typedef HINSTANCE HMODULE;
typedef void* HGLOBAL;
typedef void* HLOCAL;
struct HACCEL__; typedef HACCEL__* HACCEL;
struct ITaskbarList3;
struct HDROP__; typedef HDROP__* HDROP;
struct HMETAFILE__; typedef HMETAFILE__* HMETAFILE;
struct HENHMETAFILE__; typedef HENHMETAFILE__* HENHMETAFILE;
struct HDWP__; typedef HDWP__* HDWP;
struct HHOOK__; typedef HHOOK__* HHOOK;
struct HMONITOR__; typedef HMONITOR__* HMONITOR;
struct HTHEME__; typedef HTHEME__* HTHEME;
struct HKEY__; typedef HKEY__* HKEY;
typedef HKEY* PHKEY;
struct HMIDIIN__; typedef HMIDIIN__* HMIDIIN;
typedef HMIDIIN* LPHMIDIIN;
struct HMIDIOUT__; typedef HMIDIOUT__* HMIDIOUT;
typedef void* HINTERNET;
struct _IMAGELIST; typedef _IMAGELIST* HIMAGELIST;
struct _TREEITEM; typedef _TREEITEM* HTREEITEM;

#define INVALID_HANDLE_VALUE ((HANDLE)(LONG_PTR)-1)
#define INVALID_FILE_ATTRIBUTES ((DWORD)-1)

// Macros
#ifndef MAX_PATH
#define MAX_PATH 1024
#endif
#ifndef _MAX_PATH
#define _MAX_PATH 1024
#endif

#define LOWORD(l) ((WORD)(((DWORD_PTR)(l)) & 0xffff))
#define LODWORD(l) ((DWORD)(((DWORD_PTR)(l)) & 0xffffffff))
#define HIDWORD(l) ((DWORD)((((DWORD_PTR)(l)) >> 32) & 0xffffffff))
#define HIWORD(l) ((WORD)((((DWORD_PTR)(l)) >> 16) & 0xffff))
#define LOBYTE(w) ((BYTE)(((DWORD_PTR)(w)) & 0xff))
#define HIBYTE(w) ((BYTE)((((DWORD_PTR)(w)) >> 8) & 0xff))
#define MAKELONG(a, b) ((LONG)(((WORD)(((DWORD_PTR)(a)) & 0xffff)) | ((DWORD)((WORD)(((DWORD_PTR)(b)) & 0xffff))) << 16))
#define MAKEWORD(a, b) ((WORD)(((BYTE)(((DWORD_PTR)(a)) & 0xff)) | ((WORD)((BYTE)(((DWORD_PTR)(b)) & 0xff))) << 8))
#define MAKEWPARAM(l, h) ((WPARAM)(DWORD)MAKELONG(l, h))
#define MAKELPARAM(l, h) ((LPARAM)(DWORD)MAKELONG(l, h))
#define MAKELRESULT(l, h) ((LRESULT)(DWORD)MAKELONG(l, h))
#define GET_X_LPARAM(lp) ((int)(short)LOWORD(lp))
#define GET_Y_LPARAM(lp) ((int)(short)HIWORD(lp))
#define GET_WHEEL_DELTA_WPARAM(wParam) ((short)HIWORD(wParam))
#define GET_KEYSTATE_WPARAM(wParam) (LOWORD(wParam))
#define GET_XBUTTON_WPARAM(wParam) (HIWORD(wParam))
#define WHEEL_DELTA 120
#define XBUTTON1 0x0001
#define XBUTTON2 0x0002

#define RGB(r,g,b) ((COLORREF)(((BYTE)(r)|((WORD)((BYTE)(g))<<8))|(((DWORD)(BYTE)(b))<<16)))
#define GetRValue(rgb) (LOBYTE(rgb))
#define GetGValue(rgb) (LOBYTE(((WORD)(rgb)) >> 8))
#define GetBValue(rgb) (LOBYTE((rgb)>>16))

#define MAKEINTRESOURCEA(i) ((LPSTR)((ULONG_PTR)((WORD)(i))))
#define MAKEINTRESOURCEW(i) ((LPWSTR)((ULONG_PTR)((WORD)(i))))
#ifdef UNICODE
#define MAKEINTRESOURCE MAKEINTRESOURCEW
#else
#define MAKEINTRESOURCE MAKEINTRESOURCEA
#endif
#define MAKEINTATOM(i) ((LPTSTR)((ULONG_PTR)((WORD)(i))))
#define IS_INTRESOURCE(_r) ((((ULONG_PTR)(_r)) >> 16) == 0)

#define RT_CURSOR           MAKEINTRESOURCE(1)
#define RT_BITMAP           MAKEINTRESOURCE(2)
#define RT_ICON             MAKEINTRESOURCE(3)
#define RT_MENU             MAKEINTRESOURCE(4)
#define RT_DIALOG           MAKEINTRESOURCE(5)
#define RT_STRING           MAKEINTRESOURCE(6)
#define RT_FONTDIR          MAKEINTRESOURCE(7)
#define RT_FONT             MAKEINTRESOURCE(8)
#define RT_ACCELERATOR      MAKEINTRESOURCE(9)
#define RT_RCDATA           MAKEINTRESOURCE(10)
#define RT_MESSAGETABLE     MAKEINTRESOURCE(11)
#define RT_GROUP_CURSOR     MAKEINTRESOURCE(12)
#define RT_GROUP_ICON       MAKEINTRESOURCE(14)
#define RT_VERSION          MAKEINTRESOURCE(16)
#define RT_DLGINCLUDE       MAKEINTRESOURCE(17)
#define RT_PLUGPLAY         MAKEINTRESOURCE(19)
#define RT_VXD              MAKEINTRESOURCE(20)
#define RT_ANICURSOR        MAKEINTRESOURCE(21)
#define RT_ANIICON          MAKEINTRESOURCE(22)
#define RT_HTML             MAKEINTRESOURCE(23)
#define RT_MANIFEST         MAKEINTRESOURCE(24)
#define RT_DIALOG_LAYOUT    MAKEINTRESOURCE(0x00F1)

#define SUCCEEDED(hr) (((HRESULT)(hr)) >= 0)
#define FAILED(hr) (((HRESULT)(hr)) < 0)
#define S_OK ((HRESULT)0L)
#define S_FALSE ((HRESULT)1L)
#define NOERROR 0
#define E_FAIL ((HRESULT)0x80004005L)
#define E_NOINTERFACE ((HRESULT)0x80004002L)
#define E_NOTIMPL ((HRESULT)0x80004001L)
#define E_OUTOFMEMORY ((HRESULT)0x8007000EL)
#define E_INVALIDARG ((HRESULT)0x80070057L)
#define E_POINTER ((HRESULT)0x80004003L)
#define E_ABORT ((HRESULT)0x80004004L)
#define E_UNEXPECTED ((HRESULT)0x8000FFFFL)

#define ERROR_SUCCESS 0L
#define ERROR_FILE_NOT_FOUND 2L
#define ERROR_NOT_READY 21L
#define ERROR_PATH_NOT_FOUND 3L
#define ERROR_ACCESS_DENIED 5L
#define ERROR_INVALID_HANDLE 6L
#define ERROR_NOT_ENOUGH_MEMORY 8L
#define ERROR_OUTOFMEMORY 14L
#define ERROR_NO_MORE_FILES 18L
#define ERROR_DISK_FULL 112L
#define ERROR_INSUFFICIENT_BUFFER 122L
#define ERROR_MOD_NOT_FOUND 126L
#define ERROR_PROC_NOT_FOUND 127L
#define ERROR_ALREADY_EXISTS 183L
#define ERROR_MORE_DATA 234L
#define ERROR_NO_MORE_ITEMS 259L
#define ERROR_DLL_INIT_FAILED 1114L
#define ERROR_CANCELLED 1223L

#define FORMAT_MESSAGE_ALLOCATE_BUFFER 0x00000100
#define FORMAT_MESSAGE_IGNORE_INSERTS  0x00000200
#define FORMAT_MESSAGE_FROM_STRING     0x00000400
#define FORMAT_MESSAGE_FROM_HMODULE    0x00000800
#define FORMAT_MESSAGE_FROM_SYSTEM     0x00001000
#define FORMAT_MESSAGE_ARGUMENT_ARRAY  0x00002000
#define LANG_NEUTRAL                   0x00
#define LANG_GERMAN                    0x07
#define LANG_SPANISH                   0x0a
#define LANG_FRENCH                    0x0c
#define LANG_NORWEGIAN                 0x14
#define SUBLANG_NEUTRAL                0x00
#define SUBLANG_DEFAULT                0x01
#define SUBLANG_SPANISH                0x01
#define SUBLANG_SPANISH_MODERN         0x03
#define MAKELANGID(p, s)               ((((WORD)(s)) << 10) | (WORD)(p))

#define __try try
#define __except(x) catch(...)
#define EXCEPTION_EXECUTE_HANDLER 1
#define EXCEPTION_CONTINUE_SEARCH 0
#define EXCEPTION_CONTINUE_EXECUTION (-1)

// Structs
struct GUID {
    uint32_t Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t  Data4[8];
    friend constexpr bool operator==(const GUID& a, const GUID& b) noexcept {
        for(int i=0;i<8;++i) if(a.Data4[i]!=b.Data4[i]) return false;
        return a.Data1==b.Data1 && a.Data2==b.Data2 && a.Data3==b.Data3;
    }
    friend constexpr bool operator!=(const GUID& a, const GUID& b) noexcept {
        return !(a == b);
    }
};
typedef GUID IID;
typedef GUID CLSID;
typedef GUID UUID;
typedef const GUID& REFGUID;
typedef const IID& REFIID;
typedef const CLSID& REFCLSID;

struct tagPOINT {
    LONG x;
    LONG y;
};
typedef struct tagPOINT POINT;
typedef POINT* PPOINT;
typedef POINT* LPPOINT;

struct tagPOINTL {
    LONG x;
    LONG y;
};
typedef struct tagPOINTL POINTL;

struct tagSIZE {
    LONG cx;
    LONG cy;
};
typedef struct tagSIZE SIZE;
typedef SIZE* PSIZE;
typedef SIZE* LPSIZE;

struct tagRECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
};
typedef struct tagRECT RECT;
typedef RECT* PRECT;
typedef RECT* LPRECT;
typedef const RECT* LPCRECT;

struct FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
};
typedef FILETIME* LPFILETIME;
typedef FILETIME* PFILETIME;
typedef DWORD REGSAM;

struct SYSTEMTIME {
    WORD wYear;
    WORD wMonth;
    WORD wDayOfWeek;
    WORD wDay;
    WORD wHour;
    WORD wMinute;
    WORD wSecond;
    WORD wMilliseconds;
};
typedef SYSTEMTIME* LPSYSTEMTIME;

union LARGE_INTEGER {
    struct {
        DWORD LowPart;
        LONG HighPart;
    };
    struct {
        DWORD LowPart;
        LONG HighPart;
    } u;
    LONGLONG QuadPart;
};

union ULARGE_INTEGER {
    struct {
        DWORD LowPart;
        DWORD HighPart;
    };
    struct {
        DWORD LowPart;
        DWORD HighPart;
    } u;
    ULONGLONG QuadPart;
};
typedef LARGE_INTEGER* PLARGE_INTEGER;
typedef ULARGE_INTEGER* PULARGE_INTEGER;

struct MSG {
    HWND hwnd;
    UINT message;
    WPARAM wParam;
    LPARAM lParam;
    DWORD time;
    POINT pt;
};
typedef MSG* PMSG;
typedef MSG* LPMSG;

struct PAINTSTRUCT {
    HDC hdc;
    BOOL fErase;
    RECT rcPaint;
    BOOL fRestore;
    BOOL fIncUpdate;
    BYTE rgbReserved[32];
};
typedef PAINTSTRUCT* LPPAINTSTRUCT;

struct CREATESTRUCTA {
    LPVOID lpCreateParams;
    HINSTANCE hInstance;
    HMENU hMenu;
    HWND hwndParent;
    int cy;
    int cx;
    int y;
    int x;
    LONG style;
    LPCSTR lpszName;
    LPCSTR lpszClass;
    DWORD dwExStyle;
};
struct CREATESTRUCTW {
    LPVOID lpCreateParams;
    HINSTANCE hInstance;
    HMENU hMenu;
    HWND hwndParent;
    int cy;
    int cx;
    int y;
    int x;
    LONG style;
    LPCWSTR lpszName;
    LPCWSTR lpszClass;
    DWORD dwExStyle;
};
#ifdef UNICODE
typedef CREATESTRUCTW CREATESTRUCT;
#else
typedef CREATESTRUCTA CREATESTRUCT;
#endif
typedef CREATESTRUCT* LPCREATESTRUCT;

struct WINDOWPLACEMENT {
    UINT length;
    UINT flags;
    UINT showCmd;
    POINT ptMinPosition;
    POINT ptMaxPosition;
    RECT rcNormalPosition;
};
typedef WINDOWPLACEMENT* LPWINDOWPLACEMENT;

struct tagWINDOWPOS {
    HWND hwnd;
    HWND hwndInsertAfter;
    int x;
    int y;
    int cx;
    int cy;
    UINT flags;
};
typedef struct tagWINDOWPOS WINDOWPOS;
typedef WINDOWPOS* LPWINDOWPOS;

struct MINMAXINFO {
    POINT ptReserved;
    POINT ptMaxSize;
    POINT ptMaxPosition;
    POINT ptMinTrackSize;
    POINT ptMaxTrackSize;
};
typedef MINMAXINFO* LPMINMAXINFO;

struct NMHDR {
    HWND hwndFrom;
    UINT_PTR idFrom;
    UINT code;
};
typedef NMHDR* LPNMHDR;

struct DRAWITEMSTRUCT {
    UINT CtlType;
    UINT CtlID;
    UINT itemID;
    UINT itemAction;
    UINT itemState;
    HWND hwndItem;
    HDC hDC;
    RECT rcItem;
    ULONG_PTR itemData;
};
typedef DRAWITEMSTRUCT* LPDRAWITEMSTRUCT;

struct MEASUREITEMSTRUCT {
    UINT CtlType;
    UINT CtlID;
    UINT itemID;
    UINT itemWidth;
    UINT itemHeight;
    ULONG_PTR itemData;
};
typedef MEASUREITEMSTRUCT* LPMEASUREITEMSTRUCT;

struct COMPAREITEMSTRUCT {
    UINT CtlType;
    UINT CtlID;
    HWND hwndItem;
    UINT itemID1;
    ULONG_PTR itemData1;
    UINT itemID2;
    ULONG_PTR itemData2;
    DWORD dwLocaleId;
};
typedef COMPAREITEMSTRUCT* LPCOMPAREITEMSTRUCT;

struct DELETEITEMSTRUCT {
    UINT CtlType;
    UINT CtlID;
    UINT itemID;
    HWND hwndItem;
    ULONG_PTR itemData;
};
typedef DELETEITEMSTRUCT* LPDELETEITEMSTRUCT;

struct COPYDATASTRUCT {
    ULONG_PTR dwData;
    DWORD cbData;
    LPVOID lpData;
};
typedef COPYDATASTRUCT* PCOPYDATASTRUCT;

struct HELPINFO {
    UINT cbSize;
    int iContextType;
    int iCtrlId;
    HANDLE hItemHandle;
    DWORD_PTR dwContextId;
    POINT MousePos;
};
typedef HELPINFO* LPHELPINFO;

struct NCCALCSIZE_PARAMS {
    RECT rgrc[3];
     void* lppos;
};
typedef NCCALCSIZE_PARAMS* LPNCCALCSIZE_PARAMS;

// GDI structs
#define LF_FACESIZE 32
struct LOGFONTA {
    LONG lfHeight;
    LONG lfWidth;
    LONG lfEscapement;
    LONG lfOrientation;
    LONG lfWeight;
    BYTE lfItalic;
    BYTE lfUnderline;
    BYTE lfStrikeOut;
    BYTE lfCharSet;
    BYTE lfOutPrecision;
    BYTE lfClipPrecision;
    BYTE lfQuality;
    BYTE lfPitchAndFamily;
    CHAR lfFaceName[LF_FACESIZE];
};
struct LOGFONTW {
    LONG lfHeight;
    LONG lfWidth;
    LONG lfEscapement;
    LONG lfOrientation;
    LONG lfWeight;
    BYTE lfItalic;
    BYTE lfUnderline;
    BYTE lfStrikeOut;
    BYTE lfCharSet;
    BYTE lfOutPrecision;
    BYTE lfClipPrecision;
    BYTE lfQuality;
    BYTE lfPitchAndFamily;
    WCHAR lfFaceName[LF_FACESIZE];
};
#ifdef UNICODE
typedef LOGFONTW LOGFONT;
#else
typedef LOGFONTA LOGFONT;
#endif
typedef LOGFONT* LPLOGFONT;

struct NONCLIENTMETRICSA {
    UINT cbSize;
    int iBorderWidth;
    int iScrollWidth;
    int iScrollHeight;
    int iCaptionWidth;
    int iCaptionHeight;
    LOGFONTA lfCaptionFont;
    int iSmCaptionWidth;
    int iSmCaptionHeight;
    LOGFONTA lfSmCaptionFont;
    int iMenuWidth;
    int iMenuHeight;
    LOGFONTA lfMenuFont;
    LOGFONTA lfStatusFont;
    LOGFONTA lfMessageFont;
    int iPaddedBorderWidth;
};
struct NONCLIENTMETRICSW {
    UINT cbSize;
    int iBorderWidth;
    int iScrollWidth;
    int iScrollHeight;
    int iCaptionWidth;
    int iCaptionHeight;
    LOGFONTW lfCaptionFont;
    int iSmCaptionWidth;
    int iSmCaptionHeight;
    LOGFONTW lfSmCaptionFont;
    int iMenuWidth;
    int iMenuHeight;
    LOGFONTW lfMenuFont;
    LOGFONTW lfStatusFont;
    LOGFONTW lfMessageFont;
    int iPaddedBorderWidth;
};
#ifdef UNICODE
typedef NONCLIENTMETRICSW NONCLIENTMETRICS;
#else
typedef NONCLIENTMETRICSA NONCLIENTMETRICS;
#endif

struct TEXTMETRICA {
    LONG tmHeight;
    LONG tmAscent;
    LONG tmDescent;
    LONG tmInternalLeading;
    LONG tmExternalLeading;
    LONG tmAveCharWidth;
    LONG tmMaxCharWidth;
    LONG tmWeight;
    LONG tmOverhang;
    LONG tmDigitizedAspectX;
    LONG tmDigitizedAspectY;
    BYTE tmFirstChar;
    BYTE tmLastChar;
    BYTE tmDefaultChar;
    BYTE tmBreakChar;
    BYTE tmItalic;
    BYTE tmUnderlined;
    BYTE tmStruckOut;
    BYTE tmPitchAndFamily;
    BYTE tmCharSet;
};
typedef TEXTMETRICA TEXTMETRICW;
typedef TEXTMETRICA* LPTEXTMETRICA;
typedef TEXTMETRICW* LPTEXTMETRICW;
#ifdef UNICODE
typedef TEXTMETRICW TEXTMETRIC;
#else
typedef TEXTMETRICA TEXTMETRIC;
#endif
typedef TEXTMETRIC* LPTEXTMETRIC;

struct BITMAP {
    LONG bmType;
    LONG bmWidth;
    LONG bmHeight;
    LONG bmWidthBytes;
    WORD bmPlanes;
    WORD bmBitsPixel;
    LPVOID bmBits;
};
typedef BITMAP* LPBITMAP;

#pragma pack(push, 1)
struct BITMAPFILEHEADER {
    WORD bfType;
    DWORD bfSize;
    WORD bfReserved1;
    WORD bfReserved2;
    DWORD bfOffBits;
};

struct BITMAPINFOHEADER {
    DWORD biSize;
    LONG biWidth;
    LONG biHeight;
    WORD biPlanes;
    WORD biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG biXPelsPerMeter;
    LONG biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
};
typedef BITMAPINFOHEADER* LPBITMAPINFOHEADER;

struct RGBQUAD {
    BYTE rgbBlue;
    BYTE rgbGreen;
    BYTE rgbRed;
    BYTE rgbReserved;
};
typedef RGBQUAD* LPRGBQUAD;

struct BITMAPINFO {
    BITMAPINFOHEADER bmiHeader;
    RGBQUAD bmiColors[1];
};
typedef BITMAPINFO* LPBITMAPINFO;
#pragma pack(pop)

typedef struct tagDIBSECTION {
    BITMAP dsBm;
    BITMAPINFOHEADER dsBmih;
    DWORD dsBitfields[3];
    HANDLE dshSection;
    DWORD dsOffset;
} DIBSECTION, *LPDIBSECTION;

struct LOGBRUSH {
    UINT lbStyle;
    COLORREF lbColor;
    ULONG_PTR lbHatch;
};
typedef LOGBRUSH* LPLOGBRUSH;
struct LOGPEN {
    UINT lopnStyle;
    POINT lopnWidth;
    COLORREF lopnColor;
};
typedef LOGPEN* LPLOGPEN;
struct BLENDFUNCTION {
    BYTE BlendOp;
    BYTE BlendFlags;
    BYTE SourceConstantAlpha;
    BYTE AlphaFormat;
};
#define AC_SRC_OVER 0x00
#define AC_SRC_ALPHA 0x01

struct SCROLLINFO {
    UINT cbSize;
    UINT fMask;
    int nMin;
    int nMax;
    UINT nPage;
    int nPos;
    int nTrackPos;
};
typedef SCROLLINFO* LPSCROLLINFO;
typedef const SCROLLINFO* LPCSCROLLINFO;

struct MENUITEMINFOA {
    UINT cbSize;
    UINT fMask;
    UINT fType;
    UINT fState;
    UINT wID;
    HMENU hSubMenu;
    HBITMAP hbmpChecked;
    HBITMAP hbmpUnchecked;
    ULONG_PTR dwItemData;
    LPSTR dwTypeData;
    UINT cch;
    HBITMAP hbmpItem;
};
struct MENUITEMINFOW {
    UINT cbSize;
    UINT fMask;
    UINT fType;
    UINT fState;
    UINT wID;
    HMENU hSubMenu;
    HBITMAP hbmpChecked;
    HBITMAP hbmpUnchecked;
    ULONG_PTR dwItemData;
    LPWSTR dwTypeData;
    UINT cch;
    HBITMAP hbmpItem;
};
typedef MENUITEMINFOA* LPMENUITEMINFOA;
typedef const MENUITEMINFOA* LPCMENUITEMINFOA;
typedef MENUITEMINFOW* LPMENUITEMINFOW;
typedef const MENUITEMINFOW* LPCMENUITEMINFOW;
#ifdef UNICODE
typedef MENUITEMINFOW MENUITEMINFO;
typedef LPMENUITEMINFOW LPMENUITEMINFO;
typedef LPCMENUITEMINFOW LPCMENUITEMINFO;
#else
typedef MENUITEMINFOA MENUITEMINFO;
typedef LPMENUITEMINFOA LPMENUITEMINFO;
typedef LPCMENUITEMINFOA LPCMENUITEMINFO;
#endif

struct ACCEL {
    BYTE fVirt;
    WORD key;
    WORD cmd;
};
typedef ACCEL* LPACCEL;

struct TRACKMOUSEEVENT {
    DWORD cbSize;
    DWORD dwFlags;
    HWND hwndTrack;
    DWORD dwHoverTime;
};
typedef TRACKMOUSEEVENT* LPTRACKMOUSEEVENT;

struct TPMPARAMS {
    UINT cbSize;
    RECT rcExclude;
};
typedef TPMPARAMS* LPTPMPARAMS;

struct COMBOBOXINFO {
    DWORD cbSize;
    RECT rcItem;
    RECT rcButton;
    DWORD stateButton;
    HWND hwndCombo;
    HWND hwndItem;
    HWND hwndList;
};
typedef COMBOBOXINFO* PCOMBOBOXINFO;

struct WIN32_FIND_DATAA {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
    DWORD dwReserved0;
    DWORD dwReserved1;
    CHAR cFileName[MAX_PATH];
    CHAR cAlternateFileName[14];
};
struct WIN32_FIND_DATAW {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
    DWORD dwReserved0;
    DWORD dwReserved1;
    WCHAR cFileName[MAX_PATH];
    WCHAR cAlternateFileName[14];
};
#ifdef UNICODE
typedef WIN32_FIND_DATAW WIN32_FIND_DATA;
#else
typedef WIN32_FIND_DATAA WIN32_FIND_DATA;
#endif
typedef WIN32_FIND_DATA* LPWIN32_FIND_DATA;

struct SECURITY_ATTRIBUTES {
    DWORD nLength;
    LPVOID lpSecurityDescriptor;
    BOOL bInheritHandle;
};
typedef SECURITY_ATTRIBUTES* LPSECURITY_ATTRIBUTES;

struct OVERLAPPED {
    ULONG_PTR Internal;
    ULONG_PTR InternalHigh;
    union {
        struct {
            DWORD Offset;
            DWORD OffsetHigh;
        };
        LPVOID Pointer;
    };
    HANDLE hEvent;
};
typedef OVERLAPPED* LPOVERLAPPED;

struct EXCEPTION_RECORD {
    DWORD ExceptionCode;
    DWORD ExceptionFlags;
    EXCEPTION_RECORD* ExceptionRecord;
    LPVOID ExceptionAddress;
    DWORD NumberParameters;
    ULONG_PTR ExceptionInformation[15];
};
typedef EXCEPTION_RECORD* PEXCEPTION_RECORD;

struct CONTEXT {
    DWORD ContextFlags;
};
typedef CONTEXT* PCONTEXT;

struct EXCEPTION_POINTERS {
    PEXCEPTION_RECORD ExceptionRecord;
    PCONTEXT ContextRecord;
};
typedef EXCEPTION_POINTERS* PEXCEPTION_POINTERS;
typedef EXCEPTION_POINTERS* LPEXCEPTION_POINTERS;
typedef LONG (WINAPI *PTOP_LEVEL_EXCEPTION_FILTER)(struct _EXCEPTION_POINTERS *ExceptionInfo);
typedef PTOP_LEVEL_EXCEPTION_FILTER LPTOP_LEVEL_EXCEPTION_FILTER;

#define PROCESSOR_ARCHITECTURE_INTEL            0
#define PROCESSOR_ARCHITECTURE_MIPS             1
#define PROCESSOR_ARCHITECTURE_ALPHA            2
#define PROCESSOR_ARCHITECTURE_PPC              3
#define PROCESSOR_ARCHITECTURE_SHX              4
#define PROCESSOR_ARCHITECTURE_ARM              5
#define PROCESSOR_ARCHITECTURE_IA64             6
#define PROCESSOR_ARCHITECTURE_ALPHA64          7
#define PROCESSOR_ARCHITECTURE_MSIL             8
#define PROCESSOR_ARCHITECTURE_AMD64            9
#define PROCESSOR_ARCHITECTURE_IA32_ON_WIN64    10
#define PROCESSOR_ARCHITECTURE_NEUTRAL          11
#define PROCESSOR_ARCHITECTURE_ARM64            12
#define PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64   13
#define PROCESSOR_ARCHITECTURE_IA32_ON_ARM64    14
#define PROCESSOR_ARCHITECTURE_UNKNOWN          0xFFFF

struct SYSTEM_INFO {
    union {
        DWORD dwOemId;
        struct {
            WORD wProcessorArchitecture;
            WORD wReserved;
        };
    };
    DWORD dwPageSize;
    LPVOID lpMinimumApplicationAddress;
    LPVOID lpMaximumApplicationAddress;
    DWORD_PTR dwActiveProcessorMask;
    DWORD dwNumberOfProcessors;
    DWORD dwProcessorType;
    DWORD dwAllocationGranularity;
    WORD wProcessorLevel;
    WORD wProcessorRevision;
};
typedef SYSTEM_INFO* LPSYSTEM_INFO;

struct MEMORYSTATUSEX {
    DWORD dwLength;
    DWORD dwMemoryLoad;
    ULONGLONG ullTotalPhys;
    ULONGLONG ullAvailPhys;
    ULONGLONG ullTotalPageFile;
    ULONGLONG ullAvailPageFile;
    ULONGLONG ullTotalVirtual;
    ULONGLONG ullAvailVirtual;
    ULONGLONG ullAvailExtendedVirtual;
};
typedef MEMORYSTATUSEX* LPMEMORYSTATUSEX;

typedef LRESULT (CALLBACK* WNDPROC)(HWND, UINT, WPARAM, LPARAM);
typedef void (*FARPROC)(void);
typedef void (*NEARPROC)(void);
typedef void (*PROC)(void);
typedef INT_PTR (CALLBACK* DLGPROC)(HWND, UINT, WPARAM, LPARAM);
typedef VOID (CALLBACK* TIMERPROC)(HWND, UINT, UINT_PTR, DWORD);
typedef LRESULT (CALLBACK* HOOKPROC)(int code, WPARAM wParam, LPARAM lParam);
typedef BOOL (CALLBACK* WNDENUMPROC)(HWND, LPARAM);

struct WNDCLASSA {
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCSTR lpszMenuName;
    LPCSTR lpszClassName;
};
struct WNDCLASSW {
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCWSTR lpszMenuName;
    LPCWSTR lpszClassName;
};
#ifdef UNICODE
typedef WNDCLASSW WNDCLASS;
#else
typedef WNDCLASSA WNDCLASS;
#endif

struct WNDCLASSEXA {
    UINT cbSize;
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCSTR lpszMenuName;
    LPCSTR lpszClassName;
    HICON hIconSm;
};
struct WNDCLASSEXW {
    UINT cbSize;
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCWSTR lpszMenuName;
    LPCWSTR lpszClassName;
    HICON hIconSm;
};
#ifdef UNICODE
typedef WNDCLASSEXW WNDCLASSEX;
#else
typedef WNDCLASSEXA WNDCLASSEX;
#endif

// Window Messages
#define WM_NULL                         0x0000
#define WM_CREATE                       0x0001
#define WM_DESTROY                      0x0002
#define WM_MOVE                         0x0003
#define WM_SIZE                         0x0005
#define WM_ACTIVATE                     0x0006
#define WM_SETFOCUS                     0x0007
#define WM_KILLFOCUS                    0x0008
#define WM_ENABLE                       0x000A
#define WM_SETREDRAW                    0x000B
#define WM_SETTEXT                      0x000C
#define WM_GETTEXT                      0x000D
#define WM_GETTEXTLENGTH                0x000E
#define WM_PAINT                        0x000F
#define WM_CLOSE                        0x0010
#define WM_QUERYENDSESSION              0x0011
#define WM_QUIT                         0x0012
#define WM_QUERYOPEN                    0x0013
#define WM_ERASEBKGND                   0x0014
#define WM_SYSCOLORCHANGE               0x0015
#define WM_ENDSESSION                   0x0016
#define WM_SHOWWINDOW                   0x0018
#define WM_WININICHANGE                 0x001A
#define WM_SETTINGCHANGE                WM_WININICHANGE
#define WM_DEVMODECHANGE                0x001B
#define WM_ACTIVATEAPP                  0x001C
#define WM_FONTCHANGE                   0x001D
#define WM_TIMECHANGE                   0x001E
#define WM_CANCELMODE                   0x001F
#define WM_SETCURSOR                    0x0020
#define WM_MOUSEACTIVATE                0x0021
#define MA_ACTIVATE         1
#define MA_ACTIVATEANDEAT   2
#define MA_NOACTIVATE       3
#define MA_NOACTIVATEANDEAT 4
#define WM_CHILDACTIVATE                0x0022
#define WM_QUEUESYNC                    0x0023
#define WM_GETMINMAXINFO                0x0024
#define WM_PAINTICON                    0x0026
#define WM_ICONERASEBKGND               0x0027
#define WM_NEXTDLGCTL                   0x0028
#define WM_SPOOLERSTATUS                0x002A
#define WM_DRAWITEM                     0x002B
#define WM_MEASUREITEM                  0x002C
#define WM_DELETEITEM                   0x002D
#define WM_VKEYTOITEM                   0x002E
#define WM_CHARTOITEM                   0x002F
#define WM_SETFONT                      0x0030
#define WM_GETFONT                      0x0031
#define WM_SETHOTKEY                    0x0032
#define WM_GETHOTKEY                    0x0033
#define WM_QUERYDRAGICON                0x0037
#define WM_COMPAREITEM                  0x0039
#define WM_GETOBJECT                    0x003D
#define WM_COMPACTING                   0x0041
#define WM_WINDOWPOSCHANGING            0x0046
#define WM_WINDOWPOSCHANGED             0x0047
#define WM_COPYDATA                     0x004A
#define WM_NOTIFY                       0x004E
#define WM_INPUTLANGCHANGEREQUEST       0x0050
#define WM_INPUTLANGCHANGE              0x0051
#define WM_TCARD                        0x0052
#define WM_HELP                         0x0053
#define WM_USERCHANGED                  0x0054
#define WM_NOTIFYFORMAT                 0x0055
#define WM_CONTEXTMENU                  0x007B
#define WM_STYLECHANGING                0x007C
#define WM_STYLECHANGED                 0x007D
#define WM_DISPLAYCHANGE                0x007E
#define WM_GETICON                      0x007F
#define WM_SETICON                      0x0080
#define ICON_SMALL          0
#define ICON_BIG            1
#define ICON_SMALL2         2
#define WM_NCCREATE                     0x0081
#define WM_NCDESTROY                    0x0082
#define WM_NCCALCSIZE                   0x0083
#define WM_NCHITTEST                    0x0084
#define WM_NCPAINT                      0x0085
#define WM_NCACTIVATE                   0x0086
#define WM_GETDLGCODE                   0x0087
#define WM_SYNCPAINT                    0x0088
#define WM_NCMOUSEMOVE                  0x00A0
#define WM_NCLBUTTONDOWN                0x00A1
#define WM_NCLBUTTONUP                  0x00A2
#define WM_NCLBUTTONDBLCLK              0x00A3
#define WM_NCRBUTTONDOWN                0x00A4
#define WM_NCRBUTTONUP                  0x00A5
#define WM_NCRBUTTONDBLCLK              0x00A6
#define WM_NCMBUTTONDOWN                0x00A7
#define WM_NCMBUTTONUP                  0x00A8
#define WM_NCMBUTTONDBLCLK              0x00A9
#define WM_KEYFIRST                     0x0100
#define WM_KEYDOWN                      0x0100
#define WM_KEYUP                        0x0101
#define WM_CHAR                         0x0102
#define WM_DEADCHAR                     0x0103
#define WM_SYSKEYDOWN                   0x0104
#define WM_SYSKEYUP                     0x0105
#define WM_SYSCHAR                      0x0106
#define WM_SYSDEADCHAR                  0x0107
#define WM_UNICHAR                      0x0109
#define WM_KEYLAST                      0x0109
#define WM_INITDIALOG                   0x0110
#define WM_COMMAND                      0x0111
#define WM_SYSCOMMAND                   0x0112
#define WM_TIMER                        0x0113
#define WM_HSCROLL                      0x0114
#define WM_VSCROLL                      0x0115
#define WM_INITMENU                     0x0116
#define WM_INITMENUPOPUP                0x0117
#define WM_MENUSELECT                   0x011F
#define WM_MENUCHAR                     0x0120
#define WM_ENTERIDLE                    0x0121
#define WM_CTLCOLOR                     0x0019
#define WM_CTLCOLORMSGBOX               0x0132
#define WM_CTLCOLOREDIT                 0x0133
#define WM_CTLCOLORLISTBOX              0x0134
#define WM_CTLCOLORBTN                  0x0135
#define WM_CTLCOLORDLG                  0x0136
#define WM_CTLCOLORSCROLLBAR            0x0137
#define WM_CTLCOLORSTATIC               0x0138
#define WM_MOUSEFIRST                   0x0200
#define WM_MOUSEMOVE                    0x0200
#define WM_LBUTTONDOWN                  0x0201
#define WM_LBUTTONUP                    0x0202
#define WM_LBUTTONDBLCLK                0x0203
#define WM_RBUTTONDOWN                  0x0204
#define WM_RBUTTONUP                    0x0205
#define WM_RBUTTONDBLCLK                0x0206
#define WM_MBUTTONDOWN                  0x0207
#define WM_MBUTTONUP                    0x0208
#define WM_MBUTTONDBLCLK                0x0209
#define WM_MOUSEWHEEL                   0x020A
#define WM_XBUTTONDOWN                  0x020B
#define WM_XBUTTONUP                    0x020C
#define WM_XBUTTONDBLCLK                0x020D
#define WM_MOUSEHWHEEL                  0x020E
#define WM_MOUSELAST                    0x020E
#define WM_PARENTNOTIFY                 0x0210
#define WM_ENTERMENULOOP                0x0211
#define WM_EXITMENULOOP                 0x0212
#define WM_SIZING                       0x0214
#define WM_CAPTURECHANGED               0x0215
#define WM_MOVING                       0x0216
#define WM_DEVICECHANGE                 0x0219
#define WM_MDICREATE                    0x0220
#define WM_MDIDESTROY                   0x0221
#define WM_MDIACTIVATE                  0x0222
#define WM_MDIRESTORE                   0x0223
#define WM_MDINEXT                      0x0224
#define WM_MDIMAXIMIZE                  0x0225
#define WM_MDITILE                      0x0226
#define WM_MDICASCADE                   0x0227
#define WM_MDIICONARRANGE               0x0228
#define WM_MDIGETACTIVE                 0x0229
#define WM_MDISETMENU                   0x0230
#define WM_ENTERSIZEMOVE                0x0231
#define WM_EXITSIZEMOVE                 0x0232
#define WM_DROPFILES                    0x0233
#define WM_MDIREFRESHMENU               0x0234
#define WM_MOUSEHOVER                   0x02A1
#define WM_MOUSELEAVE                   0x02A3
#define WM_DPICHANGED                   0x02E0
#define WM_CUT                          0x0300
#define WM_COPY                         0x0301
#define WM_PASTE                        0x0302
#define WM_CLEAR                        0x0303
#define WM_UNDO                         0x0304
#define WM_APP                          0x8000
#define WM_USER                         0x0400

// Activate states
#define WA_INACTIVE     0
#define WA_ACTIVE       1
#define WA_CLICKACTIVE  2

// Size commands
#define SIZE_RESTORED   0
#define SIZE_MINIMIZED  1
#define SIZE_MAXIMIZED  2
#define SIZE_MAXSHOW    3
#define SIZE_MAXHIDE    4

// ShowWindow commands
#define SW_HIDE             0
#define SW_SHOWNORMAL       1
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2
#define SW_SHOWMAXIMIZED    3
#define SW_MAXIMIZE         3
#define SW_SHOWNOACTIVATE   4
#define SW_SHOW             5
#define SW_MINIMIZE         6
#define SW_SHOWMINNOACTIVE  7
#define SW_SHOWNA           8
#define SW_RESTORE          9
#define SW_SHOWDEFAULT      10

// SetWindowPos flags
#define SWP_NOSIZE          0x0001
#define SWP_NOMOVE          0x0002
#define SWP_NOZORDER        0x0004
#define SWP_NOREDRAW        0x0008
#define SWP_NOACTIVATE      0x0010
#define SWP_FRAMECHANGED    0x0020
#define SWP_SHOWWINDOW      0x0040
#define SWP_HIDEWINDOW      0x0080
#define SWP_NOCOPYBITS      0x0100
#define SWP_NOOWNERZORDER   0x0200
#define SWP_NOSENDCHANGING  0x0400
#define SWP_DRAWFRAME       SWP_FRAMECHANGED
#define SWP_NOREPOSITION    SWP_NOOWNERZORDER
#define SWP_DEFERERASE      0x2000
#define SWP_ASYNCWINDOWPOS  0x4000

#define HWND_TOP        ((HWND)0)
#define HWND_BOTTOM     ((HWND)1)
#define HWND_TOPMOST    ((HWND)-1)
#define HWND_NOTOPMOST  ((HWND)-2)

// Window Styles
#define WS_OVERLAPPED       0x00000000L
#define WS_POPUP            0x80000000L
#define WS_CHILD            0x40000000L
#define WS_MINIMIZE         0x20000000L
#define WS_VISIBLE          0x10000000L
#define WS_DISABLED         0x08000000L
#define WS_CLIPSIBLINGS     0x04000000L
#define WS_CLIPCHILDREN     0x02000000L
#define WS_MAXIMIZE         0x01000000L
#define WS_CAPTION          0x00C00000L
#define WS_BORDER           0x00800000L
#define WS_DLGFRAME         0x00400000L
#define WS_VSCROLL          0x00200000L
#define WS_HSCROLL          0x00100000L
#define WS_SYSMENU          0x00080000L
#define WS_THICKFRAME       0x00040000L
#define WS_GROUP            0x00020000L
#define WS_TABSTOP          0x00010000L
#define WS_MINIMIZEBOX      0x00020000L
#define WS_MAXIMIZEBOX      0x00010000L
#define WS_TILED            WS_OVERLAPPED
#define WS_ICONIC           WS_MINIMIZE
#define WS_SIZEBOX          WS_THICKFRAME
#define WS_OVERLAPPEDWINDOW (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX)
#define WS_POPUPWINDOW      (WS_POPUP | WS_BORDER | WS_SYSMENU)
#define WS_CHILDWINDOW      (WS_CHILD)

// Extended Window Styles
#define WS_EX_DLGMODALFRAME     0x00000001L
#define WS_EX_NOPARENTNOTIFY    0x00000004L
#define WS_EX_TOPMOST           0x00000008L
#define WS_EX_ACCEPTFILES       0x00000010L
#define WS_EX_TRANSPARENT       0x00000020L
#define WS_EX_MDICHILD          0x00000040L
#define WS_EX_TOOLWINDOW        0x00000080L
#define WS_EX_WINDOWEDGE        0x00000100L
#define WS_EX_CLIENTEDGE        0x00000200L
#define WS_EX_CONTEXTHELP       0x00000400L
#define WS_EX_RIGHT             0x00001000L
#define WS_EX_LEFT              0x00000000L
#define WS_EX_RTLREADING        0x00002000L
#define WS_EX_LTRREADING        0x00000000L
#define WS_EX_LEFTSCROLLBAR     0x00004000L
#define WS_EX_RIGHTSCROLLBAR    0x00000000L
#define WS_EX_CONTROLPARENT     0x00010000L
#define WS_EX_STATICEDGE        0x00020000L
#define WS_EX_APPWINDOW         0x00040000L
#define WS_EX_OVERLAPPEDWINDOW  (WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE)
#define WS_EX_PALETTEWINDOW     (WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST)
#define WS_EX_LAYERED           0x00080000
#define WS_EX_COMPOSITED        0x02000000L

// Class styles
#define CS_VREDRAW          0x0001
#define CS_HREDRAW          0x0002
#define CS_DBLCLKS          0x0008
#define CS_OWNDC            0x0020
#define CS_CLASSDC          0x0040
#define CS_PARENTDC         0x0080
#define CS_NOCLOSE          0x0200
#define CS_SAVEBITS         0x0800
#define CS_BYTEALIGNCLIENT  0x1000
#define CS_BYTEALIGNWINDOW  0x2000
#define CS_GLOBALCLASS      0x4000

// Dialog styles
#define DS_ABSALIGN         0x01L
#define DS_SYSMODAL         0x02L
#define DS_LOCALEDIT        0x20L
#define DS_SETFONT          0x40L
#define DS_MODALFRAME       0x80L
#define DS_NOIDLEMSG        0x100L
#define DS_SETFOREGROUND    0x200L
#define DS_3DLOOK           0x0004L
#define DS_FIXEDSYS         0x0008L
#define DS_NOFAILCREATE     0x0010L
#define DS_CONTROL          0x0400L
#define DS_CENTER           0x0800L
#define DS_CENTERMOUSE      0x1000L
#define DS_CONTEXTHELP      0x2000L
#define DS_SHELLFONT        (DS_SETFONT | DS_FIXEDSYS)

// GetWindow / GetWindowLong
#define GW_HWNDFIRST        0
#define GW_HWNDLAST         1
#define GW_HWNDNEXT         2
#define GW_HWNDPREV         3
#define GW_OWNER            4
#define GW_CHILD            5
#define GWL_WNDPROC         (-4)
#define GWL_HINSTANCE       (-6)
#define GWL_HWNDPARENT      (-8)
#define GWL_STYLE           (-16)
#define GWL_EXSTYLE         (-20)
#define GWL_USERDATA        (-21)
#define GWL_ID              (-12)
#define GWLP_WNDPROC        (-4)
#define GWLP_HINSTANCE      (-6)
#define GWLP_HWNDPARENT     (-8)
#define GWLP_USERDATA       (-21)
#define GWLP_ID             (-12)

// HitTest codes
#define HTERROR             (-2)
#define HTTRANSPARENT       (-1)
#define HTNOWHERE           0
#define HTCLIENT            1
#define HTCAPTION           2
#define HTSYSMENU           3
#define HTGROWBOX           4
#define HTSIZE              HTGROWBOX
#define HTMENU              5
#define HTHSCROLL           6
#define HTVSCROLL           7
#define HTMINBUTTON         8
#define HTMAXBUTTON         9
#define HTLEFT              10
#define HTRIGHT             11
#define HTTOP               12
#define HTTOPLEFT           13
#define HTTOPRIGHT          14
#define HTBOTTOM            15
#define HTBOTTOMLEFT        16
#define HTBOTTOMRIGHT       17
#define HTBORDER            18
#define HTOBJECT            19
#define HTCLOSE             20
#define HTHELP              21

// SysCommands
#define SC_SIZE         0xF000
#define SC_MOVE         0xF010
#define SC_MINIMIZE     0xF020
#define SC_MAXIMIZE     0xF030
#define SC_NEXTWINDOW   0xF040
#define SC_PREVWINDOW   0xF050
#define SC_CLOSE        0xF060
#define SC_VSCROLL      0xF070
#define SC_HSCROLL      0xF080
#define SC_MOUSEMENU    0xF090
#define SC_KEYMENU      0xF100
#define SC_ARRANGE      0xF110
#define SC_RESTORE      0xF120
#define SC_TASKLIST     0xF130
#define SC_SCREENSAVE   0xF140
#define SC_HOTKEY       0xF150
#define SC_DEFAULT      0xF160
#define SC_MONITORPOWER 0xF170
#define SC_CONTEXTHELP  0xF180

// Virtual Keys
#define VK_LBUTTON        0x01
#define VK_RBUTTON        0x02
#define VK_CANCEL         0x03
#define VK_MBUTTON        0x04
#define VK_XBUTTON1       0x05
#define VK_XBUTTON2       0x06
#define VK_BACK           0x08
#define VK_TAB            0x09
#define VK_CLEAR          0x0C
#define VK_RETURN         0x0D
#define VK_SHIFT          0x10
#define VK_CONTROL        0x11
#define VK_MENU           0x12
#define VK_PAUSE          0x13
#define VK_CAPITAL        0x14
#define VK_KANA           0x15
#define VK_ESCAPE         0x1B
#define VK_CONVERT        0x1C
#define VK_NONCONVERT     0x1D
#define VK_ACCEPT         0x1E
#define VK_MODECHANGE     0x1F
#define VK_SPACE          0x20
#define VK_PRIOR          0x21
#define VK_NEXT           0x22
#define VK_END            0x23
#define VK_HOME           0x24
#define VK_LEFT           0x25
#define VK_UP             0x26
#define VK_RIGHT          0x27
#define VK_DOWN           0x28
#define VK_SELECT         0x29
#define VK_PRINT          0x2A
#define VK_EXECUTE        0x2B
#define VK_SNAPSHOT       0x2C
#define VK_INSERT         0x2D
#define VK_DELETE         0x2E
#define VK_HELP           0x2F
#define VK_LWIN           0x5B
#define VK_RWIN           0x5C
#define VK_APPS           0x5D
#define VK_SLEEP          0x5F
#define VK_NUMPAD0        0x60
#define VK_NUMPAD1        0x61
#define VK_NUMPAD2        0x62
#define VK_NUMPAD3        0x63
#define VK_NUMPAD4        0x64
#define VK_NUMPAD5        0x65
#define VK_NUMPAD6        0x66
#define VK_NUMPAD7        0x67
#define VK_NUMPAD8        0x68
#define VK_NUMPAD9        0x69
#define VK_MULTIPLY       0x6A
#define VK_ADD            0x6B
#define VK_SEPARATOR      0x6C
#define VK_SUBTRACT       0x6D
#define VK_DECIMAL        0x6E
#define VK_DIVIDE         0x6F
#define VK_F1             0x70
#define VK_F2             0x71
#define VK_F3             0x72
#define VK_F4             0x73
#define VK_F5             0x74
#define VK_F6             0x75
#define VK_F7             0x76
#define VK_F8             0x77
#define VK_F9             0x78
#define VK_F10            0x79
#define VK_F11            0x7A
#define VK_F12            0x7B
#define VK_F13            0x7C
#define VK_F14            0x7D
#define VK_F15            0x7E
#define VK_F16            0x7F
#define VK_F17            0x80
#define VK_F18            0x81
#define VK_F19            0x82
#define VK_F20            0x83
#define VK_F21            0x84
#define VK_F22            0x85
#define VK_F23            0x86
#define VK_F24            0x87
#define VK_NUMLOCK        0x90
#define VK_SCROLL         0x91
#define VK_LSHIFT         0xA0
#define VK_RSHIFT         0xA1
#define VK_LCONTROL       0xA2
#define VK_RCONTROL       0xA3
#define VK_LMENU          0xA4
#define VK_RMENU          0xA5
#define VK_BROWSER_BACK        0xA6
#define VK_BROWSER_FORWARD     0xA7
#define VK_BROWSER_REFRESH     0xA8
#define VK_BROWSER_STOP        0xA9
#define VK_BROWSER_SEARCH      0xAA
#define VK_BROWSER_FAVORITES   0xAB
#define VK_BROWSER_HOME        0xAC
#define VK_VOLUME_MUTE         0xAD
#define VK_VOLUME_DOWN         0xAE
#define VK_VOLUME_UP           0xAF
#define VK_MEDIA_NEXT_TRACK    0xB0
#define VK_MEDIA_PREV_TRACK    0xB1
#define VK_MEDIA_STOP          0xB2
#define VK_MEDIA_PLAY_PAUSE    0xB3
#define VK_LAUNCH_MAIL         0xB4
#define VK_LAUNCH_MEDIA_SELECT 0xB5
#define VK_LAUNCH_APP1         0xB6
#define VK_LAUNCH_APP2         0xB7
#define VK_OEM_1          0xBA
#define VK_OEM_PLUS       0xBB
#define VK_OEM_COMMA      0xBC
#define VK_OEM_MINUS      0xBD
#define VK_OEM_PERIOD     0xBE
#define VK_OEM_2          0xBF
#define VK_OEM_3          0xC0
#define VK_OEM_4          0xDB
#define VK_OEM_5          0xDC
#define VK_OEM_6          0xDD
#define VK_OEM_7          0xDE
#define VK_OEM_8          0xDF
#define VK_OEM_102        0xE2
#define VK_PACKET         0xE7

#define MK_LBUTTON          0x0001
#define MK_RBUTTON          0x0002
#define MK_SHIFT            0x0004
#define MK_CONTROL          0x0008
#define MK_MBUTTON          0x0010
#define MK_XBUTTON1         0x0020
#define MK_XBUTTON2         0x0040

#define HOTKEYF_SHIFT       0x01
#define HOTKEYF_CONTROL     0x02
#define HOTKEYF_ALT         0x04
#define HOTKEYF_EXT         0x08

#define MAPVK_VK_TO_VSC     0
#define MAPVK_VSC_TO_VK     1
#define MAPVK_VK_TO_CHAR    2
#define MAPVK_VSC_TO_VK_EX  3
#define MAPVK_VK_TO_VSC_EX  4

// Dialog Codes & IDs
#define DLGC_WANTARROWS     0x0001
#define DLGC_WANTTAB        0x0002
#define DLGC_WANTALLKEYS    0x0004
#define DLGC_WANTMESSAGE    0x0004
#define DLGC_HASSETSEL      0x0008
#define DLGC_DEFPUSHBUTTON  0x0010
#define DLGC_UNDEFPUSHBUTTON 0x0020
#define DLGC_RADIOBUTTON    0x0040
#define DLGC_WANTCHARS      0x0080
#define DLGC_STATIC         0x0100
#define DLGC_BUTTON         0x2000

#define IDOK                1
#define IDCANCEL            2
#define IDABORT             3
#define IDRETRY             4
#define IDIGNORE            5
#define IDYES               6
#define IDNO                7
#define IDCLOSE             8
#define IDHELP              9
#define IDTRYAGAIN          10
#define IDCONTINUE          11
#ifndef IDC_STATIC
#define IDC_STATIC          (-1)
#endif

// MessageBox flags
#define MB_OK                       0x00000000L
#define MB_OKCANCEL                 0x00000001L
#define MB_ABORTRETRYIGNORE         0x00000002L
#define MB_YESNOCANCEL              0x00000003L
#define MB_YESNO                    0x00000004L
#define MB_RETRYCANCEL              0x00000005L
#define MB_CANCELTRYCONTINUE        0x00000006L
#define MB_ICONHAND                 0x00000010L
#define MB_ICONQUESTION             0x00000020L
#define MB_ICONEXCLAMATION          0x00000030L
#define MB_ICONASTERISK             0x00000040L
#define MB_USERICON                 0x00000080L
#define MB_ICONWARNING              MB_ICONEXCLAMATION
#define MB_ICONERROR                MB_ICONHAND
#define MB_ICONINFORMATION          MB_ICONASTERISK
#define MB_ICONSTOP                 MB_ICONHAND
#define MB_DEFBUTTON1               0x00000000L
#define MB_DEFBUTTON2               0x00000100L
#define MB_DEFBUTTON3               0x00000200L
#define MB_DEFBUTTON4               0x00000300L
#define MB_APPLMODAL                0x00000000L
#define MB_SYSTEMMODAL              0x00001000L
#define MB_TASKMODAL                0x00002000L
#define MB_HELP                     0x00004000L
#define MB_NOFOCUS                  0x00008000L
#define MB_SETFOREGROUND            0x00010000L
#define MB_DEFAULT_DESKTOP_ONLY     0x00020000L
#define MB_TOPMOST                  0x00040000L
#define MB_RIGHT                    0x00080000L

// Menus
#define MF_INSERT           0x00000000L
#define MF_CHANGE           0x00000080L
#define MF_APPEND           0x00000100L
#define MF_DELETE           0x00000200L
#define MF_REMOVE           0x00001000L
#define MF_BYCOMMAND        0x00000000L
#define MF_BYPOSITION       0x00000400L
#define MF_SEPARATOR        0x00000800L
#define MF_ENABLED          0x00000000L
#define MF_GRAYED           0x00000001L
#define MF_DISABLED         0x00000002L
#define MF_UNCHECKED        0x00000000L
#define MF_CHECKED          0x00000008L
#define MF_USECHECKBITMAPS  0x00000200L
#define MF_STRING           0x00000000L
#define MF_BITMAP           0x00000004L
#define MF_OWNERDRAW        0x00000100L
#define MF_POPUP            0x00000010L
#define MF_MENUBARBREAK     0x00000020L
#define MF_MENUBREAK        0x00000040L
#define MF_UNHILITE         0x00000000L
#define MF_HILITE           0x00000080L
#define MF_DEFAULT          0x00001000L
#define MF_SYSMENU          0x00002000L
#define MF_HELP             0x00004000L
#define MF_RIGHTJUSTIFY     0x00004000L
#define MF_MOUSESELECT      0x00008000L

#define MFT_STRING          MF_STRING
#define MFT_BITMAP          MF_BITMAP
#define MFT_MENUBARBREAK    MF_MENUBARBREAK
#define MFT_MENUBREAK       MF_MENUBREAK
#define MFT_OWNERDRAW       MF_OWNERDRAW
#define MFT_RADIOCHECK      0x00000200L
#define MFT_SEPARATOR       MF_SEPARATOR
#define MFT_RIGHTORDER      0x00002000L
#define MFT_RIGHTJUSTIFY    MF_RIGHTJUSTIFY

#define MFS_GRAYED          0x00000003L
#define MFS_DISABLED        MFS_GRAYED
#define MFS_CHECKED         MF_CHECKED
#define MFS_HILITE          MF_HILITE
#define MFS_ENABLED         MF_ENABLED
#define MFS_UNCHECKED       MF_UNCHECKED
#define MFS_UNHILITE        MF_UNHILITE
#define MFS_DEFAULT         MF_DEFAULT

#define MIIM_STATE          0x00000001
#define MIIM_ID             0x00000002
#define MIIM_SUBMENU        0x00000004
#define MIIM_CHECKMARKS     0x00000008
#define MIIM_TYPE           0x00000010
#define MIIM_DATA           0x00000020
#define MIIM_STRING         0x00000040
#define MIIM_BITMAP         0x00000080
#define MIIM_FTYPE          0x00000100

#define TPM_LEFTBUTTON      0x0000L
#define TPM_RIGHTBUTTON     0x0002L
#define TPM_LEFTALIGN       0x0000L
#define TPM_CENTERALIGN     0x0004L
#define TPM_RIGHTALIGN      0x0008L
#define TPM_TOPALIGN        0x0000L
#define TPM_VCENTERALIGN    0x0010L
#define TPM_BOTTOMALIGN     0x0020L
#define TPM_HORIZONTAL      0x0000L
#define TPM_VERTICAL        0x0040L
#define TPM_NONOTIFY        0x0080L
#define TPM_RETURNCMD       0x0100L
#define TPM_RECURSE         0x0001L

// Scrollbars
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3

#define SB_LINEUP           0
#define SB_LINELEFT         0
#define SB_LINEDOWN         1
#define SB_LINERIGHT        1
#define SB_PAGEUP           2
#define SB_PAGELEFT         2
#define SB_PAGEDOWN         3
#define SB_PAGERIGHT        3
#define SB_THUMBPOSITION    4
#define SB_THUMBTRACK       5
#define SB_TOP              6
#define SB_LEFT             6
#define SB_BOTTOM           7
#define SB_RIGHT            7
#define SB_ENDSCROLL        8

#define SIF_RANGE           0x0001
#define SIF_PAGE            0x0002
#define SIF_POS             0x0004
#define SIF_DISABLENOSCROLL 0x0008
#define SIF_TRACKPOS        0x0010
#define SIF_ALL             (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS)

#define ESB_ENABLE_BOTH     0x0000
#define ESB_DISABLE_BOTH    0x0003
#define ESB_DISABLE_LEFT    0x0001
#define ESB_DISABLE_RIGHT   0x0002
#define ESB_DISABLE_UP      0x0001
#define ESB_DISABLE_DOWN    0x0002

#define SW_SCROLLCHILDREN   0x0001
#define SW_INVALIDATE       0x0002
#define SW_ERASE            0x0004
#define SW_SMOOTHSCROLL     0x0010

// RedrawWindow
#define RDW_INVALIDATE          0x0001
#define RDW_INTERNALPAINT       0x0002
#define RDW_ERASE               0x0004
#define RDW_VALIDATE            0x0008
#define RDW_NOINTERNALPAINT     0x0010
#define RDW_NOERASE             0x0020
#define RDW_NOCHILDREN          0x0040
#define RDW_ALLCHILDREN         0x0080
#define RDW_UPDATENOW           0x0100
#define RDW_ERASENOW            0x0200
#define RDW_FRAME               0x0400
#define RDW_NOFRAME             0x0800

// System colors
#define COLOR_SCROLLBAR         0
#define COLOR_BACKGROUND        1
#define COLOR_ACTIVECAPTION     2
#define COLOR_INACTIVECAPTION   3
#define COLOR_MENU              4
#define COLOR_WINDOW            5
#define COLOR_WINDOWFRAME       6
#define COLOR_MENUTEXT          7
#define COLOR_WINDOWTEXT        8
#define COLOR_CAPTIONTEXT       9
#define COLOR_ACTIVEBORDER      10
#define COLOR_INACTIVEBORDER    11
#define COLOR_APPWORKSPACE      12
#define COLOR_HIGHLIGHT         13
#define COLOR_HIGHLIGHTTEXT     14
#define COLOR_BTNFACE           15
#define COLOR_BTNSHADOW         16
#define COLOR_GRAYTEXT          17
#define COLOR_BTNTEXT           18
#define COLOR_INACTIVECAPTIONTEXT 19
#define COLOR_BTNHIGHLIGHT      20
#define COLOR_3DDKSHADOW        21
#define COLOR_3DLIGHT           22
#define COLOR_INFOTEXT          23
#define COLOR_INFOBK            24
#define COLOR_HOTLIGHT          26
#define COLOR_GRADIENTACTIVECAPTION 27
#define COLOR_GRADIENTINACTIVECAPTION 28
#define COLOR_MENUHILIGHT       29
#define COLOR_MENUBAR           30
#define COLOR_3DFACE            COLOR_BTNFACE
#define COLOR_3DSHADOW          COLOR_BTNSHADOW
#define COLOR_3DHIGHLIGHT       COLOR_BTNHIGHLIGHT
#define COLOR_3DHILIGHT         COLOR_BTNHIGHLIGHT
#define COLOR_BTNHILIGHT        COLOR_BTNHIGHLIGHT

// System Metrics
#define SM_CXSCREEN             0
#define SM_CYSCREEN             1
#define SM_CXVSCROLL            2
#define SM_CYHSCROLL            3
#define SM_CYCAPTION            4
#define SM_CXBORDER             5
#define SM_CYBORDER             6
#define SM_CXDLGFRAME           7
#define SM_CYDLGFRAME           8
#define SM_CYVTHUMB             9
#define SM_CXHTHUMB             10
#define SM_CXICON               11
#define SM_CYICON               12
#define SM_CXCURSOR             13
#define SM_CYCURSOR             14
#define SM_CYMENU               15
#define SM_CXFULLSCREEN         16
#define SM_CYFULLSCREEN         17
#define SM_CYKANJIWINDOW        18
#define SM_MOUSEPRESENT         19
#define SM_CYVSCROLL            20
#define SM_CXHSCROLL            21
#define SM_DEBUG                22
#define SM_SWAPBUTTON           23
#define SM_CXMIN                28
#define SM_CYMIN                29
#define SM_CXSIZE               30
#define SM_CYSIZE               31
#define SM_CXFRAME              32
#define SM_CYFRAME              33
#define SM_CXMINTRACK           34
#define SM_CYMINTRACK           35
#define SM_CXDOUBLECLK          36
#define SM_CYDOUBLECLK          37
#define SM_CXICONSPACING        38
#define SM_CYICONSPACING        39
#define SM_MENUDROPALIGNMENT    40
#define SM_PENWINDOWS           41
#define SM_DBCSENABLED          42
#define SM_CMOUSEBUTTONS        43
#define SM_CXFIXEDFRAME         SM_CXDLGFRAME
#define SM_CYFIXEDFRAME         SM_CYDLGFRAME
#define SM_CXSIZEFRAME          SM_CXFRAME
#define SM_CYSIZEFRAME          SM_CYFRAME
#define SM_SECURE               44
#define SM_CXEDGE               45
#define SM_CYEDGE               46
#define SM_CXMINSPACING         47
#define SM_CYMINSPACING         48
#define SM_CXSMICON             49
#define SM_CYSMICON             50
#define SM_CYSMCAPTION          51
#define SM_CXSMSIZE             52
#define SM_CYSMSIZE             53
#define SM_CXMENUSIZE           54
#define SM_CYMENUSIZE           55
#define SM_ARRANGE              56
#define SM_CXMINIMIZED          57
#define SM_CYMINIMIZED          58
#define SM_CXMAXTRACK           59
#define SM_CYMAXTRACK           60
#define SM_CXMAXIMIZED          61
#define SM_CYMAXIMIZED          62
#define SM_NETWORK              63
#define SM_CLEANBOOT            67
#define SM_CXDRAG               68
#define SM_CYDRAG               69
#define SM_SHOWSOUNDS           70
#define SM_CXMENUCHECK          71
#define SM_CYMENUCHECK          72
#define SM_SLOWMACHINE          73
#define SM_MIDEASTENABLED       74
#define SM_MOUSEWHEELPRESENT    75
#define SM_XVIRTUALSCREEN       76
#define SM_YVIRTUALSCREEN       77
#define SM_CXVIRTUALSCREEN      78
#define SM_CYVIRTUALSCREEN      79
#define SM_CMONITORS            80
#define SM_SAMEDISPLAYFORMAT    81
#define SM_IMMENABLED           82
#define SM_CXFOCUSBORDER        83
#define SM_CYFOCUSBORDER        84

#define SPI_GETBEEP                 0x0001
#define SPI_SETBEEP                 0x0002
#define SPI_GETNONCLIENTMETRICS     0x0029
#define SPI_GETWORKAREA             0x0030
#define SPI_GETICONTITLELOGFONT     0x001F
#define SPI_GETWHEELSCROLLLINES     0x0068
#define SPI_GETWHEELSCROLLCHARS     0x006C

// GDI Constants
#define TRANSPARENT         1
#define OPAQUE              2

#define R2_BLACK            1
#define R2_NOTMERGEPEN      2
#define R2_MASKNOTPEN       3
#define R2_NOTCOPYPEN       4
#define R2_MASKPENNOT       5
#define R2_NOT              6
#define R2_XORPEN           7
#define R2_NOTMASKPEN       8
#define R2_MASKPEN          9
#define R2_NOTXORPEN        10
#define R2_NOP              11
#define R2_MERGENOTPEN      12
#define R2_COPYPEN          13
#define R2_MERGEPENNOT      14
#define R2_MERGEPEN         15
#define R2_WHITE            16
#define R2_LAST             16

#define SRCCOPY             (DWORD)0x00CC0020
#define SRCPAINT            (DWORD)0x00EE0086
#define SRCAND              (DWORD)0x008800C6
#define SRCINVERT           (DWORD)0x00660046
#define SRCERASE            (DWORD)0x00440328
#define NOTSRCCOPY          (DWORD)0x00330008
#define NOTSRCERASE         (DWORD)0x001100A6
#define MERGECOPY           (DWORD)0x00C000CA
#define MERGEPAINT          (DWORD)0x00BB0226
#define PATCOPY             (DWORD)0x00F00021
#define PATPAINT            (DWORD)0x00FB0A09
#define PATINVERT           (DWORD)0x005A0049
#define DSTINVERT           (DWORD)0x00550009
#define BLACKNESS           (DWORD)0x00000042
#define WHITENESS           (DWORD)0x00FF0062

#define PS_SOLID            0
#define PS_DASH             1
#define PS_DOT              2
#define PS_DASHDOT          3
#define PS_DASHDOTDOT       4
#define PS_NULL             5
#define PS_INSIDEFRAME      6

#define BS_SOLID            0
#define BS_NULL             1
#define BS_HOLLOW           BS_NULL
#define BS_HATCHED          2
#define BS_PATTERN          3

#define WHITE_BRUSH         0
#define LTGRAY_BRUSH        1
#define GRAY_BRUSH          2
#define DKGRAY_BRUSH        3
#define BLACK_BRUSH         4
#define NULL_BRUSH          5
#define HOLLOW_BRUSH        NULL_BRUSH
#define WHITE_PEN           6
#define BLACK_PEN           7
#define NULL_PEN            8
#define OEM_FIXED_FONT      10
#define ANSI_FIXED_FONT     11
#define ANSI_VAR_FONT       12
#define SYSTEM_FONT         13
#define DEVICE_DEFAULT_FONT 14
#define DEFAULT_PALETTE     15
#define SYSTEM_FIXED_FONT   16
#define DEFAULT_GUI_FONT    17
#define DC_BRUSH            18
#define DC_PEN              19

#define FW_DONTCARE         0
#define FW_THIN             100
#define FW_EXTRALIGHT       200
#define FW_LIGHT            300
#define FW_NORMAL           400
#define FW_REGULAR          400
#define FW_MEDIUM           500
#define FW_SEMIBOLD         600
#define FW_BOLD             700
#define FW_EXTRABOLD        800
#define FW_HEAVY            900

#define ANSI_CHARSET            0
#define DEFAULT_CHARSET         1
#define SYMBOL_CHARSET          2
#define SHIFTJIS_CHARSET        128
#define OEM_CHARSET             255

#define OUT_DEFAULT_PRECIS      0
#define OUT_STRING_PRECIS       1
#define OUT_CHARACTER_PRECIS    2
#define OUT_STROKE_PRECIS       3
#define OUT_TT_PRECIS           4
#define OUT_DEVICE_PRECIS       5
#define OUT_RASTER_PRECIS       6
#define OUT_TT_ONLY_PRECIS      7

#define CLIP_DEFAULT_PRECIS     0
#define CLIP_CHARACTER_PRECIS   1
#define CLIP_STROKE_PRECIS      2

#define DEFAULT_QUALITY         0
#define DRAFT_QUALITY           1
#define PROOF_QUALITY           2
#define NONANTIALIASED_QUALITY  3
#define ANTIALIASED_QUALITY     4
#define CLEARTYPE_QUALITY       5

#define DEFAULT_PITCH           0
#define FIXED_PITCH             1
#define VARIABLE_PITCH          2
#define FF_DONTCARE             (0<<4)
#define FF_ROMAN                (1<<4)
#define FF_SWISS                (2<<4)
#define FF_MODERN               (3<<4)
#define FF_SCRIPT               (4<<4)
#define FF_DECORATIVE           (5<<4)

#define BI_RGB              0L
#define BI_RLE8             1L
#define BI_RLE4             2L
#define BI_BITFIELDS        3L
#define DIB_RGB_COLORS      0
#define DIB_PAL_COLORS      1

#define DT_TOP              0x00000000
#define DT_LEFT             0x00000000
#define DT_CENTER           0x00000001
#define DT_RIGHT            0x00000002
#define DT_VCENTER          0x00000004
#define DT_BOTTOM           0x00000008
#define DT_WORDBREAK        0x00000010
#define DT_SINGLELINE       0x00000020
#define DT_EXPANDTABS       0x00000040
#define DT_TABSTOP          0x00000080
#define DT_NOCLIP           0x00000100
#define DT_EXTERNALLEADING  0x00000200
#define DT_CALCRECT         0x00000400
#define DT_NOPREFIX         0x00000800
#define DT_INTERNAL         0x00001000
#define DT_EDITCONTROL      0x00002000
#define DT_PATH_ELLIPSIS    0x00004000
#define DT_END_ELLIPSIS     0x00008000
#define DT_MODIFYSTRING     0x00010000
#define DT_RTLREADING       0x00020000
#define DT_WORD_ELLIPSIS    0x00040000
#define DT_NOFULLWIDTHCHARBREAK 0x00080000
#define DT_HIDEPREFIX       0x00100000

#define TA_NOUPDATECP       0
#define TA_UPDATECP         1
#define TA_LEFT             0
#define TA_RIGHT            2
#define TA_CENTER           6
#define TA_TOP              0
#define TA_BOTTOM           8
#define TA_BASELINE         24

#define ETO_OPAQUE          0x0002
#define ETO_CLIPPED         0x0004

#define BDR_RAISEDOUTER     0x0001
#define BDR_SUNKENOUTER     0x0002
#define BDR_RAISEDINNER     0x0004
#define BDR_SUNKENINNER     0x0008
#define BDR_OUTER           (BDR_RAISEDOUTER | BDR_SUNKENOUTER)
#define BDR_INNER           (BDR_RAISEDINNER | BDR_SUNKENINNER)
#define BDR_RAISED          (BDR_RAISEDOUTER | BDR_RAISEDINNER)
#define BDR_SUNKEN          (BDR_SUNKENOUTER | BDR_SUNKENINNER)
#define EDGE_RAISED         (BDR_RAISEDOUTER | BDR_RAISEDINNER)
#define EDGE_SUNKEN         (BDR_SUNKENOUTER | BDR_SUNKENINNER)
#define EDGE_ETCHED         (BDR_SUNKENOUTER | BDR_RAISEDINNER)
#define EDGE_BUMP           (BDR_RAISEDOUTER | BDR_SUNKENINNER)

#define BF_LEFT             0x0001
#define BF_TOP              0x0002
#define BF_RIGHT            0x0004
#define BF_BOTTOM           0x0008
#define BF_TOPLEFT          (BF_TOP | BF_LEFT)
#define BF_TOPRIGHT         (BF_TOP | BF_RIGHT)
#define BF_BOTTOMLEFT       (BF_BOTTOM | BF_LEFT)
#define BF_BOTTOMRIGHT      (BF_BOTTOM | BF_RIGHT)
#define BF_RECT             (BF_LEFT | BF_TOP | BF_RIGHT | BF_BOTTOM)
#define BF_DIAGONAL         0x0010
#define BF_MIDDLE           0x0800
#define BF_SOFT             0x1000
#define BF_ADJUST           0x2000
#define BF_FLAT             0x4000
#define BF_MONO             0x8000

#define DFC_CAPTION         1
#define DFC_MENU            2
#define DFC_SCROLL          3
#define DFC_BUTTON          4
#define DFC_POPUPMENU       5

#define DFCS_BUTTONCHECK    0x0000
#define DFCS_BUTTONRADIO    0x0004
#define DFCS_BUTTON3STATE   0x0008
#define DFCS_BUTTONPUSH     0x0010
#define DFCS_INACTIVE       0x0100
#define DFCS_PUSHED         0x0200
#define DFCS_CHECKED        0x0400
#define DFCS_TRANSPARENT    0x0800
#define DFCS_HOT            0x1000
#define DFCS_ADJUSTRECT     0x2000
#define DFCS_FLAT           0x4000
#define DFCS_MONO           0x8000

#define LOGPIXELSX          88
#define LOGPIXELSY          90
#define BITSPIXEL           12
#define PLANES              14
#define HORZRES             8
#define VERTRES             10
#define NUMCOLORS           24
#define RASTERCAPS          38
#define RC_BITBLT           1
#define RC_STRETCHBLT       2048
#define RC_DI_BITMAP        128

#ifndef ERROR
#define ERROR               0
#endif
#ifndef NULLREGION
#define NULLREGION          1
#endif
#ifndef SIMPLEREGION
#define SIMPLEREGION        2
#endif
#ifndef COMPLEXREGION
#define COMPLEXREGION       3
#endif
#ifndef RGN_ERROR
#define RGN_ERROR           ERROR
#endif

#define MM_TEXT             1
#define MM_LOMETRIC         2
#define MM_HIMETRIC         3
#define MM_LOENGLISH        4
#define MM_HIENGLISH        5
#define MM_TWIPS            6
#define MM_ISOTROPIC        7
#define MM_ANISOTROPIC      8

// Cursors & Icons
#define IDC_ARROW           MAKEINTRESOURCE(32512)
#define IDC_IBEAM           MAKEINTRESOURCE(32513)
#define IDC_WAIT            MAKEINTRESOURCE(32514)
#define IDC_CROSS           MAKEINTRESOURCE(32515)
#define IDC_UPARROW         MAKEINTRESOURCE(32516)
#define IDC_SIZE            MAKEINTRESOURCE(32640)
#define IDC_ICON            MAKEINTRESOURCE(32641)
#define IDC_SIZENWSE        MAKEINTRESOURCE(32642)
#define IDC_SIZENESW        MAKEINTRESOURCE(32643)
#define IDC_SIZEWE          MAKEINTRESOURCE(32644)
#define IDC_SIZENS          MAKEINTRESOURCE(32645)
#define IDC_SIZEALL         MAKEINTRESOURCE(32646)
#define IDC_NO              MAKEINTRESOURCE(32648)
#define IDC_HAND            MAKEINTRESOURCE(32649)
#define IDC_APPSTARTING     MAKEINTRESOURCE(32650)
#define IDC_HELP            MAKEINTRESOURCE(32651)

#define IDI_APPLICATION     MAKEINTRESOURCE(32512)
#define IDI_HAND            MAKEINTRESOURCE(32513)
#define IDI_QUESTION        MAKEINTRESOURCE(32514)
#define IDI_EXCLAMATION     MAKEINTRESOURCE(32515)
#define IDI_ASTERISK        MAKEINTRESOURCE(32516)
#define IDI_WINLOGO         MAKEINTRESOURCE(32517)
#define IDI_SHIELD          MAKEINTRESOURCE(32518)
#define IDI_WARNING         IDI_EXCLAMATION
#define IDI_ERROR           IDI_HAND
#define IDI_INFORMATION     IDI_ASTERISK

#define IMAGE_BITMAP        0
#define IMAGE_ICON          1
#define IMAGE_CURSOR        2
#define LR_DEFAULTCOLOR     0x00000000
#define LR_MONOCHROME       0x00000001
#define LR_COLOR            0x00000002
#define LR_COPYRETURNORG    0x00000004
#define LR_COPYDELETEORG    0x00000008
#define LR_LOADFROMFILE     0x00000010
#define LR_LOADTRANSPARENT  0x00000020
#define LR_DEFAULTSIZE      0x00000040
#define LR_VGACOLOR         0x00000080
#define LR_LOADMAP3DCOLORS  0x00001000
#define LR_CREATEDIBSECTION 0x00002000
#define LR_COPYFROMRESOURCE 0x00004000
#define LR_SHARED           0x00008000

#define DI_MASK             0x0001
#define DI_IMAGE            0x0002
#define DI_NORMAL           0x0003
#define DI_COMPAT           0x0004
#define DI_DEFAULTSIZE      0x0008

// Clipboard & GlobalAlloc
#define CF_TEXT             1
#define CF_BITMAP           2
#define CF_METAFILEPICT     3
#define CF_SYLK             4
#define CF_DIF              5
#define CF_TIFF             6
#define CF_OEMTEXT          7
#define CF_DIB              8
#define CF_PALETTE          9
#define CF_PENDATA          10
#define CF_RIFF             11
#define CF_WAVE             12
#define CF_UNICODETEXT      13
#define CF_ENHMETAFILE      14
#define CF_HDROP            15
#define CF_LOCALE           16
#define CF_DIBV5            17

#define GMEM_FIXED          0x0000
#define GMEM_MOVEABLE       0x0002
#define GMEM_NOCOMPACT      0x0010
#define GMEM_NODISCARD      0x0020
#define GMEM_ZEROINIT       0x0040
#define GMEM_MODIFY         0x0080
#define GMEM_DISCARDABLE    0x0100
#define GMEM_NOT_BANKED     0x1000
#define GMEM_SHARE          0x2000
#define GMEM_DDESHARE       0x2000
#define GMEM_NOTIFY         0x4000
#define GHND                (GMEM_MOVEABLE | GMEM_ZEROINIT)
#define GPTR                (GMEM_FIXED | GMEM_ZEROINIT)

// Standard Controls: Button, Edit, ComboBox, ListBox, Static
#define BS_PUSHBUTTON       0x00000000L
#define BS_DEFPUSHBUTTON    0x00000001L
#define BS_CHECKBOX         0x00000002L
#define BS_AUTOCHECKBOX     0x00000003L
#define BS_RADIOBUTTON      0x00000004L
#define BS_3STATE           0x00000005L
#define BS_AUTO3STATE       0x00000006L
#define BS_GROUPBOX         0x00000007L
#define BS_USERBUTTON       0x00000008L
#define BS_AUTORADIOBUTTON  0x00000009L
#define BS_PUSHBOX          0x0000000AL
#define BS_OWNERDRAW        0x0000000BL
#define BS_TYPEMASK         0x0000000FL
#define BS_LEFTTEXT         0x00000020L
#define BS_TEXT             0x00000000L
#define BS_ICON             0x00000040L
#define BS_BITMAP           0x00000080L
#define BS_LEFT             0x00000100L
#define BS_RIGHT            0x00000200L
#define BS_CENTER           0x00000300L
#define BS_TOP              0x00000400L
#define BS_BOTTOM           0x00000800L
#define BS_VCENTER          0x00000C00L
#define BS_PUSHLIKE         0x00001000L
#define BS_MULTILINE        0x00002000L
#define BS_NOTIFY           0x00004000L
#define BS_FLAT             0x00008000L
#define BS_SPLITBUTTON      0x0000000CL
#define BS_DEFSPLITBUTTON   0x0000000DL

#define BST_UNCHECKED       0x0000
#define BST_CHECKED         0x0001
#define BST_INDETERMINATE   0x0002
#define BST_PUSHED          0x0004
#define BST_FOCUS           0x0008

#define BN_CLICKED          0
#define BN_PAINT            1
#define BN_HILITE           2
#define BN_UNHILITE         3
#define BN_DISABLE          4
#define BN_DOUBLECLICKED    5
#define BN_PUSHED           BN_HILITE
#define BN_UNPUSHED         BN_UNHILITE
#define BN_DBLCLK           BN_DOUBLECLICKED
#define BN_SETFOCUS         6
#define BN_KILLFOCUS        7

#define BM_GETCHECK         0x00F0
#define BM_SETCHECK         0x00F1
#define BM_GETSTATE         0x00F2
#define BM_SETSTATE         0x00F3
#define BM_SETSTYLE         0x00F4
#define BM_CLICK            0x00F5
#define BM_GETIMAGE         0x00F6
#define BM_SETIMAGE         0x00F7

#define BCN_FIRST           (0U-1250U)
#define BCN_DROPDOWN        (BCN_FIRST + 0x0002)
struct NMBCDROPDOWN {
    NMHDR hdr;
    RECT rcButton;
};

#define ES_LEFT             0x0000L
#define ES_CENTER           0x0001L
#define ES_RIGHT            0x0002L
#define ES_MULTILINE        0x0004L
#define ES_UPPERCASE        0x0008L
#define ES_LOWERCASE        0x0010L
#define ES_PASSWORD         0x0020L
#define ES_AUTOVSCROLL      0x0040L
#define ES_AUTOHSCROLL      0x0080L
#define ES_NOHIDESEL        0x0100L
#define ES_OEMCONVERT       0x0400L
#define ES_READONLY         0x0800L
#define ES_WANTRETURN       0x1000L
#define ES_NUMBER           0x2000L

#define EN_SETFOCUS         0x0100
#define EN_KILLFOCUS        0x0200
#define EN_CHANGE           0x0300
#define EN_UPDATE           0x0400
#define EN_ERRSPACE         0x0500
#define EN_MAXTEXT          0x0501
#define EN_HSCROLL          0x0601
#define EN_VSCROLL          0x0602

#define EM_GETSEL               0x00B0
#define EM_SETSEL               0x00B1
#define EM_GETRECT              0x00B2
#define EM_SETRECT              0x00B3
#define EM_SETRECTNP            0x00B4
#define EM_SCROLL               0x00B5
#define EM_LINESCROLL           0x00B6
#define EM_SCROLLCARET          0x00B7
#define EM_GETMODIFY            0x00B8
#define EM_SETMODIFY            0x00B9
#define EM_GETLINECOUNT         0x00BA
#define EM_LINEINDEX            0x00BB
#define EM_SETHANDLE            0x00BC
#define EM_GETHANDLE            0x00BD
#define EM_GETTHUMB             0x00BE
#define EM_LINELENGTH           0x00C1
#define EM_REPLACESEL           0x00C2
#define EM_GETLINE              0x00C4
#define EM_LIMITTEXT            0x00C5
#define EM_CANUNDO              0x00C6
#define EM_UNDO                 0x00C7
#define EM_FMTLINES             0x00C8
#define EM_LINEFROMCHAR         0x00C9
#define EM_SETTABSTOPS          0x00CB
#define EM_SETPASSWORDCHAR      0x00CC
#define EM_EMPTYUNDOBUFFER      0x00CD
#define EM_GETFIRSTVISIBLELINE  0x00CE
#define EM_SETREADONLY          0x00CF
#define EM_SETWORDBREAKPROC     0x00D0
#define EM_GETWORDBREAKPROC     0x00D1
#define EM_GETPASSWORDCHAR      0x00D2
#define EM_SETMARGINS           0x00D3
#define EM_GETMARGINS           0x00D4
#define EM_SETLIMITTEXT         EM_LIMITTEXT
#define EM_GETLIMITTEXT         0x00D5
#define EM_POSFROMCHAR          0x00D6
#define EM_CHARFROMPOS          0x00D7
#define EC_LEFTMARGIN           0x0001
#define EC_RIGHTMARGIN          0x0002

#define CBS_SIMPLE            0x0001L
#define CBS_DROPDOWN          0x0002L
#define CBS_DROPDOWNLIST      0x0003L
#define CBS_OWNERDRAWFIXED    0x0010L
#define CBS_OWNERDRAWVARIABLE 0x0020L
#define CBS_AUTOHSCROLL       0x0040L
#define CBS_OEMCONVERT        0x0080L
#define CBS_SORT              0x0100L
#define CBS_HASSTRINGS        0x0200L
#define CBS_NOINTEGRALHEIGHT  0x0400L
#define CBS_DISABLENOSCROLL   0x0800L

#define CBN_ERRSPACE        (-1)
#define CBN_SELCHANGE       1
#define CBN_DBLCLK          2
#define CBN_SETFOCUS        3
#define CBN_KILLFOCUS       4
#define CBN_EDITCHANGE      5
#define CBN_EDITUPDATE      6
#define CBN_DROPDOWN        7
#define CBN_CLOSEUP         8
#define CBN_SELENDOK        9
#define CBN_SELENDCANCEL    10

#define CB_OKAY             0
#define CB_ERR              (-1)
#define CB_ERRSPACE         (-2)
#define CB_GETEDITSEL       0x0140
#define CB_LIMITTEXT        0x0141
#define CB_SETEDITSEL       0x0142
#define CB_ADDSTRING        0x0143
#define CB_DELETESTRING     0x0144
#define CB_DIR              0x0145
#define CB_GETCOUNT         0x0146
#define CB_GETCURSEL        0x0147
#define CB_GETLBTEXT        0x0148
#define CB_GETLBTEXTLEN     0x0149
#define CB_INSERTSTRING     0x014A
#define CB_RESETCONTENT     0x014B
#define CB_FINDSTRING       0x014C
#define CB_SELECTSTRING     0x014D
#define CB_SETCURSEL        0x014E
#define CB_SHOWDROPDOWN     0x014F
#define CB_GETITEMDATA      0x0150
#define CB_SETITEMDATA      0x0151
#define CB_GETDROPPEDCONTROLRECT 0x0152
#define CB_SETITEMHEIGHT    0x0153
#define CB_GETITEMHEIGHT    0x0154
#define CB_SETEXTENDEDUI    0x0155
#define CB_GETEXTENDEDUI    0x0156
#define CB_GETDROPPEDSTATE  0x0157
#define CB_FINDSTRINGEXACT  0x0158
#define CB_SETLOCALE        0x0159
#define CB_GETLOCALE        0x015A
#define CB_GETTOPINDEX      0x015b
#define CB_SETTOPINDEX      0x015c
#define CB_GETHORIZONTALEXTENT 0x015d
#define CB_SETHORIZONTALEXTENT 0x015e
#define CB_GETDROPPEDWIDTH  0x015f
#define CB_SETDROPPEDWIDTH  0x0160
#define CB_INITSTORAGE      0x0161

typedef COMBOBOXINFO* LPCOMBOBOXINFO;
BOOL WINAPI GetComboBoxInfo(HWND hwndCombo, PCOMBOBOXINFO pcbi);

#define LBS_NOTIFY            0x0001L
#define LBS_SORT              0x0002L
#define LBS_NOREDRAW          0x0004L
#define LBS_MULTIPLESEL       0x0008L
#define LBS_OWNERDRAWFIXED    0x0010L
#define LBS_OWNERDRAWVARIABLE 0x0020L
#define LBS_HASSTRINGS        0x0040L
#define LBS_USETABSTOPS       0x0080L
#define LBS_NOINTEGRALHEIGHT  0x0100L
#define LBS_MULTICOLUMN       0x0200L
#define LBS_WANTKEYBOARDINPUT 0x0400L
#define LBS_EXTENDEDSEL       0x0800L
#define LBS_DISABLENOSCROLL   0x1000L
#define LBS_NODATA            0x2000L
#define LBS_NOSEL             0x4000L
#define LBS_STANDARD          (LBS_NOTIFY | LBS_SORT | WS_VSCROLL | WS_BORDER)

#define LBN_ERRSPACE        (-2)
#define LBN_SELCHANGE       1
#define LBN_DBLCLK          2
#define LBN_SELCANCEL       3
#define LBN_SETFOCUS        4
#define LBN_KILLFOCUS       5
#define CLBN_CHKCHANGE      40

#define LB_OKAY             0
#define LB_ERR              (-1)
#define LB_ERRSPACE         (-2)

#define LB_ADDSTRING            0x0180
#define LB_INSERTSTRING         0x0181
#define LB_DELETESTRING         0x0182
#define LB_SELITEMRANGEEX       0x0183
#define LB_RESETCONTENT         0x0184
#define LB_SETSEL               0x0185
#define LB_SETCURSEL            0x0186
#define LB_GETSEL               0x0187
#define LB_GETCURSEL            0x0188
#define LB_GETTEXT              0x0189
#define LB_GETTEXTLEN           0x018A
#define LB_GETCOUNT             0x018B
#define LB_SELECTSTRING         0x018C
#define LB_DIR                  0x018D
#define LB_GETTOPINDEX          0x018E
#define LB_FINDSTRING           0x018F
#define LB_GETSELCOUNT          0x0190
#define LB_GETSELITEMS          0x0191
#define LB_SETTABSTOPS          0x0192
#define LB_GETHORIZONTALEXTENT  0x0193
#define LB_SETHORIZONTALEXTENT  0x0194
#define LB_SETCOLUMNWIDTH       0x0195
#define LB_ADDFILE              0x0196
#define LB_SETTOPINDEX          0x0197
#define LB_GETITEMRECT          0x0198
#define LB_GETITEMDATA          0x0199
#define LB_SETITEMDATA          0x019A
#define LB_SELITEMRANGE         0x019B
#define LB_SETANCHORINDEX       0x019C
#define LB_GETANCHORINDEX       0x019D
#define LB_SETCARETINDEX        0x019E
#define LB_GETCARETINDEX        0x019F
#define LB_SETITEMHEIGHT        0x01A0
#define LB_GETITEMHEIGHT        0x01A1
#define LB_FINDSTRINGEXACT      0x01A2
#define LB_SETLOCALE            0x01A5
#define LB_GETLOCALE            0x01A6
#define LB_SETCOUNT             0x01A7
#define LB_INITSTORAGE          0x01A8
#define LB_ITEMFROMPOINT        0x01A9

#define SS_LEFT             0x00000000L
#define SS_CENTER           0x00000001L
#define SS_RIGHT            0x00000002L
#define SS_ICON             0x00000003L
#define SS_BLACKRECT        0x00000004L
#define SS_GRAYRECT         0x00000005L
#define SS_WHITERECT        0x00000006L
#define SS_BLACKFRAME       0x00000007L
#define SS_GRAYFRAME        0x00000008L
#define SS_WHITEFRAME       0x00000009L
#define SS_USERITEM         0x0000000AL
#define SS_SIMPLE           0x0000000BL
#define SS_LEFTNOWORDWRAP   0x0000000CL
#define SS_OWNERDRAW        0x0000000DL
#define SS_BITMAP           0x0000000EL
#define SS_ENHMETAFILE      0x0000000FL
#define SS_ETCHEDHORZ       0x00000010L
#define SS_ETCHEDVERT       0x00000011L
#define SS_ETCHEDFRAME      0x00000012L
#define SS_TYPEMASK         0x0000001FL
#define SS_REALSIZECONTROL  0x00000040L
#define SS_NOPREFIX         0x00000080L
#define SS_NOTIFY           0x00000100L
#define SS_CENTERIMAGE      0x00000200L
#define SS_RIGHTJUST        0x00000400L
#define SS_REALSIZEIMAGE    0x00000800L
#define SS_SUNKEN           0x00001000L
#define SS_EDITCONTROL      0x00002000L
#define SS_ENDELLIPSIS      0x00004000L
#define SS_PATHELLIPSIS     0x00008000L
#define SS_WORDELLIPSIS     0x0000C000L

#define STM_SETICON         0x0170
#define STM_GETICON         0x0171
#define STM_SETIMAGE        0x0172
#define STM_GETIMAGE        0x0173
#define STM_MSGMAX          0x0174

#define ODT_MENU        1
#define ODT_LISTBOX     2
#define ODT_COMBOBOX    3
#define ODT_BUTTON      4
#define ODT_STATIC      5
#define ODA_DRAWENTIRE  0x0001
#define ODA_SELECT      0x0002
#define ODA_FOCUS       0x0004
#define ODS_SELECTED    0x0001
#define ODS_GRAYED      0x0002
#define ODS_DISABLED    0x0004
#define ODS_CHECKED     0x0008
#define ODS_FOCUS       0x0010
#define ODS_DEFAULT     0x0020
#define ODS_HOTLIGHT    0x0040
#define ODS_INACTIVE    0x0080
#define ODS_NOACCEL     0x0100
#define ODS_NOFOCUSRECT 0x0200

// File / Directory / Thread / Process constants
#define FILE_ATTRIBUTE_READONLY             0x00000001
#define FILE_ATTRIBUTE_HIDDEN               0x00000002
#define FILE_ATTRIBUTE_OFFLINE              0x00001000
#define FILE_READ_ATTRIBUTES                0x0080
#define IOCTL_STORAGE_CHECK_VERIFY2         0x002D0800
#define FILE_ATTRIBUTE_SYSTEM               0x00000004
#define FILE_ATTRIBUTE_DIRECTORY            0x00000010
#define FILE_ATTRIBUTE_ARCHIVE              0x00000020
#define FILE_ATTRIBUTE_DEVICE               0x00000040
#define FILE_ATTRIBUTE_NORMAL               0x00000080
#define FILE_ATTRIBUTE_TEMPORARY            0x00000100
#define FILE_ATTRIBUTE_SPARSE_FILE          0x00000200
#define FILE_ATTRIBUTE_REPARSE_POINT        0x00000400
#define FILE_ATTRIBUTE_COMPRESSED           0x00000800

#define GENERIC_READ                     (0x80000000L)
#define GENERIC_WRITE                    (0x40000000L)
#define GENERIC_EXECUTE                  (0x20000000L)
#define GENERIC_ALL                      (0x10000000L)
#define FILE_SHARE_READ                  0x00000001
#define FILE_SHARE_WRITE                 0x00000002
#define FILE_SHARE_DELETE                0x00000004
#define CREATE_NEW                       1
#define CREATE_ALWAYS                    2
#define OPEN_EXISTING                    3
#define OPEN_ALWAYS                      4
#define TRUNCATE_EXISTING                5

#define FILE_NOTIFY_CHANGE_FILE_NAME    0x00000001
#define FILE_NOTIFY_CHANGE_DIR_NAME     0x00000002
#define FILE_NOTIFY_CHANGE_ATTRIBUTES   0x00000004
#define FILE_NOTIFY_CHANGE_SIZE         0x00000008
#define FILE_NOTIFY_CHANGE_LAST_WRITE   0x00000010

#define DRIVE_UNKNOWN     0
#define DRIVE_NO_ROOT_DIR 1
#define DRIVE_REMOVABLE   2
#define DRIVE_FIXED       3
#define DRIVE_REMOTE      4
#define DRIVE_CDROM       5
#define DRIVE_RAMDISK     6

#define WAIT_OBJECT_0       0x00000000L
#define WAIT_ABANDONED      0x00000080L
#define WAIT_TIMEOUT        0x00000102L
#define WAIT_FAILED         ((DWORD)0xFFFFFFFF)
#define INFINITE            0xFFFFFFFF

#define IDLE_PRIORITY_CLASS         0x00000040
#define BELOW_NORMAL_PRIORITY_CLASS 0x00004000
#define NORMAL_PRIORITY_CLASS       0x00000020
#define ABOVE_NORMAL_PRIORITY_CLASS 0x00008000
#define HIGH_PRIORITY_CLASS         0x00000080
#define REALTIME_PRIORITY_CLASS     0x00000100
inline BOOL SetPriorityClass(HANDLE hProcess, DWORD dwPriorityClass) { (void)hProcess; (void)dwPriorityClass; return TRUE; }
inline DWORD GetPriorityClass(HANDLE hProcess) { (void)hProcess; return NORMAL_PRIORITY_CLASS; }

#define THREAD_PRIORITY_LOWEST          (-2)
#define THREAD_PRIORITY_BELOW_NORMAL    (-1)
#define THREAD_PRIORITY_NORMAL          0
#define THREAD_PRIORITY_HIGHEST         2
#define THREAD_PRIORITY_ABOVE_NORMAL    1
#define THREAD_PRIORITY_TIME_CRITICAL   15
#define THREAD_PRIORITY_IDLE            (-15)

#define PM_NOREMOVE         0x0000
#define PM_REMOVE           0x0001
#define PM_NOYIELD          0x0002

#define QS_KEY              0x0001
#define QS_MOUSEMOVE        0x0002
#define QS_MOUSEBUTTON      0x0004
#define QS_POSTMESSAGE      0x0008
#define QS_TIMER            0x0010
#define QS_PAINT            0x0020
#define QS_SENDMESSAGE      0x0040
#define QS_HOTKEY           0x0080
#define QS_ALLPOSTMESSAGE   0x0100
#define QS_RAWINPUT         0x0400
#define QS_MOUSE            (QS_MOUSEMOVE | QS_MOUSEBUTTON)
#define QS_INPUT            (QS_MOUSE | QS_KEY | QS_RAWINPUT)
#define QS_ALLEVENTS        (QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY)
#define QS_ALLINPUT         (QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY | QS_SENDMESSAGE)

#define PM_QS_INPUT         (QS_INPUT << 16)
#define PM_QS_POSTMESSAGE   (QS_POSTMESSAGE << 16)
#define PM_QS_PAINT         (QS_PAINT << 16)
#define PM_QS_SENDMESSAGE   (QS_SENDMESSAGE << 16)

#define WH_KEYBOARD         2
#define WH_GETMESSAGE       3
#define WH_CALLWNDPROC      4
#define WH_CBT              5
#define WH_MSGFILTER        (-1)
#define WH_MOUSE            7
#define HC_ACTION           0

#define HCBT_MOVESIZE       0
#define HCBT_MINMAX         1
#define HCBT_QS             2
#define HCBT_CREATEWND      3
#define HCBT_DESTROYWND     4
#define HCBT_ACTIVATE       5
#define HCBT_CLICKSKIPPED   6
#define HCBT_KEYSKIPPED     7
#define HCBT_SYSCOMMAND     8
#define HCBT_SETFOCUS       9

#define TME_HOVER           0x00000001
#define TME_LEAVE           0x00000002
#define TME_NONCLIENT       0x00000010
#define TME_QUERY           0x40000000
#define TME_CANCEL          0x80000000

#define FLASHW_STOP         0
#define FLASHW_CAPTION      0x00000001
#define FLASHW_TRAY         0x00000002
#define FLASHW_ALL          (FLASHW_CAPTION | FLASHW_TRAY)
#define FLASHW_TIMER        0x00000004
#define FLASHW_TIMERNFG     0x0000000C

#define EVENT_OBJECT_NAMECHANGE 0x800C
#define CHILDID_SELF            0

#define LOCALE_USER_DEFAULT 0x0400
#define LOCALE_SYSTEM_DEFAULT 0x0800
#define NORM_IGNORECASE     0x00000001
#define NORM_IGNORENONSPACE 0x00000002
#define NORM_IGNORESYMBOLS  0x00000004
#define NORM_IGNOREKANATYPE 0x00010000
#define NORM_IGNOREWIDTH    0x00020000
#define SORT_STRINGSORT     0x00001000
#define CSTR_LESS_THAN      1
#define CSTR_EQUAL          2
#define CSTR_GREATER_THAN   3

#define SEM_FAILCRITICALERRORS      0x0001
#define SEM_NOGPFAULTERRORBOX       0x0002
#define SEM_NOALIGNMENTFAULTEXCEPT  0x0004
#define SEM_NOOPENFILEERRORBOX      0x8000

// Common Controls constants & structs
#define NM_FIRST                (0U-  0U)
#define NM_OUTOFMEMORY          (NM_FIRST-1)
#define NM_CLICK                (NM_FIRST-2)
#define NM_DBLCLK               (NM_FIRST-3)
#define NM_RETURN               (NM_FIRST-4)
#define NM_RCLICK               (NM_FIRST-5)
#define NM_RDBLCLK              (NM_FIRST-6)
#define NM_SETFOCUS             (NM_FIRST-7)
#define NM_KILLFOCUS            (NM_FIRST-8)
#define NM_CUSTOMDRAW           (NM_FIRST-12)
#define NM_HOVER                (NM_FIRST-13)
#define NM_NCHITTEST            (NM_FIRST-14)
#define NM_KEYDOWN              (NM_FIRST-15)
#define NM_RELEASEDCAPTURE      (NM_FIRST-16)
#define NM_SETCURSOR            (NM_FIRST-17)
#define NM_CHAR                 (NM_FIRST-18)
#define NM_TOOLTIPSCREATED      (NM_FIRST-19)
#define NM_LDOWN                (NM_FIRST-20)
#define NM_RDOWN                (NM_FIRST-21)
#define NM_THEMECHANGED         (NM_FIRST-22)

struct NMITEMACTIVATE {
    NMHDR hdr;
    int iItem;
    int iSubItem;
    UINT uNewState;
    UINT uOldState;
    UINT uChanged;
    POINT ptAction;
    LPARAM lParam;
    UINT uKeyFlags;
};
typedef NMITEMACTIVATE* LPNMITEMACTIVATE;

struct NMCUSTOMDRAW {
    NMHDR hdr;
    DWORD dwDrawStage;
    HDC hdc;
    RECT rc;
    DWORD_PTR dwItemSpec;
    UINT uItemState;
    LPARAM lItemlParam;
};
typedef NMCUSTOMDRAW* LPNMCUSTOMDRAW;

struct NMLVCUSTOMDRAW {
    NMCUSTOMDRAW nmcd;
    COLORREF clrText;
    COLORREF clrTextBk;
    int iSubItem;
    DWORD dwItemType;
    COLORREF clrFace;
    int iIconEffect;
    int iIconPhase;
    int iPartId;
    int iStateId;
    RECT rcText;
    UINT uAlign;
};
typedef NMLVCUSTOMDRAW* LPNMLVCUSTOMDRAW;

struct NMTVCUSTOMDRAW {
    NMCUSTOMDRAW nmcd;
    COLORREF clrText;
    COLORREF clrTextBk;
    int iLevel;
};
typedef NMTVCUSTOMDRAW* LPNMTVCUSTOMDRAW;

#define CDRF_DODEFAULT          0x00000000
#define CDRF_NEWFONT            0x00000002
#define CDRF_SKIPDEFAULT        0x00000004
#define CDRF_DOERASE            0x00000008
#define CDRF_SKIPPOSTPAINT      0x00000100
#define CDRF_NOTIFYPOSTPAINT    0x00000010
#define CDRF_NOTIFYITEMDRAW     0x00000020
#define CDRF_NOTIFYSUBITEMDRAW  0x00000020
#define CDRF_NOTIFYPOSTERASE    0x00000040

#define CDDS_PREPAINT           0x00000001
#define CDDS_POSTPAINT          0x00000002
#define CDDS_PREERASE           0x00000003
#define CDDS_POSTERASE          0x00000004
#define CDDS_ITEM               0x00010000
#define CDDS_ITEMPREPAINT       (CDDS_ITEM | CDDS_PREPAINT)
#define CDDS_ITEMPOSTPAINT      (CDDS_ITEM | CDDS_POSTPAINT)
#define CDDS_ITEMPREERASE       (CDDS_ITEM | CDDS_PREERASE)
#define CDDS_ITEMPOSTERASE      (CDDS_ITEM | CDDS_POSTERASE)
#define CDDS_SUBITEM            0x00020000

#define CDIS_SELECTED           0x0001
#define CDIS_GRAYED             0x0002
#define CDIS_DISABLED           0x0004
#define CDIS_CHECKED            0x0008
#define CDIS_FOCUS              0x0010
#define CDIS_DEFAULT            0x0020
#define CDIS_HOT                0x0040
#define CDIS_MARKED             0x0080
#define CDIS_INDETERMINATE      0x0100

// Header Control
#define WC_HEADERA              "SysHeader32"
#define WC_HEADERW              L"SysHeader32"
#ifdef UNICODE
#define WC_HEADER               WC_HEADERW
#else
#define WC_HEADER               WC_HEADERA
#endif

#define HDI_WIDTH               0x0001
#define HDI_HEIGHT              HDI_WIDTH
#define HDI_TEXT                0x0002
#define HDI_FORMAT              0x0004
#define HDI_LPARAM              0x0008
#define HDI_BITMAP              0x0010
#define HDI_IMAGE               0x0020
#define HDI_DI_SETITEM          0x0040
#define HDI_ORDER               0x0080
#define HDI_FILTER              0x0100
#define HDI_STATE               0x0200

#define HDF_LEFT                0x0000
#define HDF_RIGHT               0x0001
#define HDF_CENTER              0x0002
#define HDF_JUSTIFYMASK         0x0003
#define HDF_RTLREADING          0x0004
#define HDF_BITMAP              0x2000
#define HDF_STRING              0x4000
#define HDF_OWNERDRAW           0x8000
#define HDF_IMAGE               0x0800
#define HDF_BITMAP_ON_RIGHT     0x1000
#define HDF_SORTUP              0x0400
#define HDF_SORTDOWN            0x0200

#define HDM_FIRST               0x1200
#define HDM_GETITEMCOUNT        (HDM_FIRST + 0)
#define HDM_INSERTITEMA         (HDM_FIRST + 1)
#define HDM_INSERTITEMW         (HDM_FIRST + 10)
#define HDM_DELETEITEM          (HDM_FIRST + 2)
#define HDM_GETITEMA            (HDM_FIRST + 3)
#define HDM_GETITEMW            (HDM_FIRST + 11)
#define HDM_SETITEMA            (HDM_FIRST + 4)
#define HDM_SETITEMW            (HDM_FIRST + 12)
#define HDM_LAYOUT              (HDM_FIRST + 5)
#define HDM_HITTEST             (HDM_FIRST + 6)
#define HDM_GETITEMRECT         (HDM_FIRST + 7)
#define HDM_SETIMAGELIST        (HDM_FIRST + 8)
#define HDM_GETIMAGELIST        (HDM_FIRST + 9)
#define HDM_ORDERTOINDEX        (HDM_FIRST + 15)
#define HDM_CREATEDRAGIMAGE     (HDM_FIRST + 16)
#define HDM_GETORDERARRAY       (HDM_FIRST + 17)
#define HDM_SETORDERARRAY       (HDM_FIRST + 18)
#define HDM_SETHOTDIVIDER       (HDM_FIRST + 19)

#ifdef UNICODE
#define HDM_INSERTITEM          HDM_INSERTITEMW
#define HDM_GETITEM             HDM_GETITEMW
#define HDM_SETITEM             HDM_SETITEMW
#else
#define HDM_INSERTITEM          HDM_INSERTITEMA
#define HDM_GETITEM             HDM_GETITEMA
#define HDM_SETITEM             HDM_SETITEMA
#endif

struct HDITEMA {
    UINT    mask;
    int     cxy;
    LPSTR   pszText;
    HBITMAP hbm;
    int     cchTextMax;
    int     fmt;
    LPARAM  lParam;
    int     iImage;
    int     iOrder;
    UINT    type;
    void *  pvFilter;
    UINT    state;
};
struct HDITEMW {
    UINT    mask;
    int     cxy;
    LPWSTR  pszText;
    HBITMAP hbm;
    int     cchTextMax;
    int     fmt;
    LPARAM  lParam;
    int     iImage;
    int     iOrder;
    UINT    type;
    void *  pvFilter;
    UINT    state;
};
#ifdef UNICODE
typedef HDITEMW HDITEM;
#else
typedef HDITEMA HDITEM;
#endif
typedef HDITEM* LPHDITEM;

// ListView
#define WC_LISTVIEWA            "SysListView32"
#define WC_LISTVIEWW            L"SysListView32"
#ifdef UNICODE
#define WC_LISTVIEW             WC_LISTVIEWW
#else
#define WC_LISTVIEW             WC_LISTVIEWA
#endif

#define LVSICF_NOINVALIDATEALL  0x00000001
#define LVSICF_NOSCROLL         0x00000002

#define LVS_ICON                0x0000
#define LVS_REPORT              0x0001
#define LVS_SMALLICON           0x0002
#define LVS_LIST                0x0003
#define LVS_TYPEMASK            0x0003
#define LVS_SINGLESEL           0x0004
#define LVS_SHOWSELALWAYS       0x0008
#define LVS_SORTASCENDING       0x0010
#define LVS_SORTDESCENDING      0x0020
#define LVS_SHAREIMAGELISTS     0x0040
#define LVS_NOLABELWRAP         0x0080
#define LVS_AUTOARRANGE         0x0100
#define LVS_EDITLABELS          0x0200
#define LVS_OWNERDATA           0x1000
#define LVS_NOSCROLL            0x2000
#define LVS_ALIGNTOP            0x0000
#define LVS_ALIGNLEFT           0x0800
#define LVS_OWNERDRAWFIXED      0x0400
#define LVS_NOCOLUMNHEADER      0x4000
#define LVS_NOSORTHEADER        0x8000

#define LVS_EX_GRIDLINES        0x00000001
#define LVS_EX_SUBITEMIMAGES    0x00000002
#define LVS_EX_CHECKBOXES       0x00000004
#define LVS_EX_TRACKSELECT      0x00000008
#define LVS_EX_HEADERDRAGDROP   0x00000010
#define LVS_EX_FULLROWSELECT    0x00000020
#define LVS_EX_ONECLICKACTIVATE 0x00000040
#define LVS_EX_TWOCLICKACTIVATE 0x00000080
#define LVS_EX_FLATSB           0x00000100
#define LVS_EX_REGIONAL         0x00000200
#define LVS_EX_INFOTIP          0x00000400
#define LVS_EX_UNDERLINEHOT     0x00000800
#define LVS_EX_UNDERLINECOLD    0x00001000
#define LVS_EX_MULTIWORKAREAS   0x00002000
#define LVS_EX_LABELTIP         0x00004000
#define LVS_EX_BORDERSELECT     0x00008000
#define LVS_EX_DOUBLEBUFFER     0x00010000
#define LVS_EX_HIDELABELS       0x00020000
#define LVS_EX_SINGLEROW        0x00040000
#define LVS_EX_SNAPTOGRID       0x00080000
#define LVS_EX_SIMPLESELECT     0x00100000

#define LVIF_TEXT               0x00000001
#define LVIF_IMAGE              0x00000002
#define LVIF_PARAM              0x00000004
#define LVIF_STATE              0x00000008
#define LVIF_INDENT             0x00000010
#define LVIF_NORECOMPUTE        0x00000800
#define LVIF_GROUPID            0x00000100
#define LVIF_COLUMNS            0x00000200

#define LVIS_FOCUSED            0x0001
#define LVIS_SELECTED           0x0002
#define LVIS_CUT                0x0004
#define LVIS_DROPHILITED        0x0008
#define LVIS_OVERLAYMASK        0x0F00
#define LVIS_STATEIMAGEMASK     0xF000
#define INDEXTOSTATEIMAGEMASK(i) ((i) << 12)

#define LVNI_ALL                0x0000
#define LVNI_FOCUSED            0x0001
#define LVNI_SELECTED           0x0002
#define LVNI_CUT                0x0004
#define LVNI_DROPHILITED        0x0008
#define LVNI_ABOVE              0x0100
#define LVNI_BELOW              0x0200
#define LVNI_TOLEFT             0x0400
#define LVNI_TORIGHT            0x0800

#define LVCFMT_LEFT             0x0000
#define LVCFMT_RIGHT            0x0001
#define LVCFMT_CENTER           0x0002
#define LVCFMT_JUSTIFYMASK      0x0003

#define LVSCW_AUTOSIZE              (-1)
#define LVSCW_AUTOSIZE_USEHEADER    (-2)

#define LVIR_BOUNDS             0
#define LVIR_ICON               1
#define LVIR_LABEL              2
#define LVIR_SELECTBOUNDS       3

#define LVHT_NOWHERE            0x00000001
#define LVHT_ONITEMICON         0x00000002
#define LVHT_ONITEMLABEL        0x00000004
#define LVHT_ONITEMSTATEICON    0x00000008
#define LVHT_ONITEM             (LVHT_ONITEMICON | LVHT_ONITEMLABEL | LVHT_ONITEMSTATEICON)
#define LVHT_ABOVE              0x00000008
#define LVHT_BELOW              0x00000010
#define LVHT_TORIGHT            0x00000020
#define LVHT_TOLEFT             0x00000040

#define LVSIL_NORMAL            0
#define LVSIL_SMALL             1
#define LVSIL_STATE             2
#define LVSIL_GROUPHEADER       3

#define LVM_FIRST               0x1000
#define LVM_GETBKCOLOR          (LVM_FIRST + 0)
#define LVM_SETBKCOLOR          (LVM_FIRST + 1)
#define LVM_GETIMAGELIST        (LVM_FIRST + 2)
#define LVM_SETIMAGELIST        (LVM_FIRST + 3)
#define LVM_GETITEMCOUNT        (LVM_FIRST + 4)
#define LVM_GETITEMA            (LVM_FIRST + 5)
#define LVM_GETITEMW            (LVM_FIRST + 75)
#define LVM_SETITEMA            (LVM_FIRST + 6)
#define LVM_SETITEMW            (LVM_FIRST + 76)
#define LVM_INSERTITEMA         (LVM_FIRST + 7)
#define LVM_INSERTITEMW         (LVM_FIRST + 77)
#define LVM_DELETEITEM          (LVM_FIRST + 8)
#define LVM_DELETEALLITEMS      (LVM_FIRST + 9)
#define LVM_GETCALLBACKMASK     (LVM_FIRST + 10)
#define LVM_SETCALLBACKMASK     (LVM_FIRST + 11)
#define LVM_GETNEXTITEM         (LVM_FIRST + 12)
#define LVM_FINDITEMA           (LVM_FIRST + 13)
#define LVM_FINDITEMW           (LVM_FIRST + 83)
#define LVM_GETITEMRECT         (LVM_FIRST + 14)
#define LVM_SETITEMPOSITION     (LVM_FIRST + 15)
#define LVM_GETITEMPOSITION     (LVM_FIRST + 16)
#define LVM_GETSTRINGWIDTHA     (LVM_FIRST + 17)
#define LVM_GETSTRINGWIDTHW     (LVM_FIRST + 87)
#define LVM_HITTEST             (LVM_FIRST + 18)
#define LVM_ENSUREVISIBLE       (LVM_FIRST + 19)
#define LVM_SCROLL              (LVM_FIRST + 20)
#define LVM_REDRAWITEMS         (LVM_FIRST + 21)
#define LVM_ARRANGE             (LVM_FIRST + 22)
#define LVM_EDITLABELA          (LVM_FIRST + 23)
#define LVM_EDITLABELW          (LVM_FIRST + 118)
#define LVM_GETEDITCONTROL      (LVM_FIRST + 24)
#define LVM_GETCOLUMNA          (LVM_FIRST + 25)
#define LVM_GETCOLUMNW          (LVM_FIRST + 95)
#define LVM_SETCOLUMNA          (LVM_FIRST + 26)
#define LVM_SETCOLUMNW          (LVM_FIRST + 96)
#define LVM_INSERTCOLUMNA       (LVM_FIRST + 27)
#define LVM_INSERTCOLUMNW       (LVM_FIRST + 97)
#define LVM_DELETECOLUMN        (LVM_FIRST + 28)
#define LVM_GETCOLUMNWIDTH      (LVM_FIRST + 29)
#define LVM_SETCOLUMNWIDTH      (LVM_FIRST + 30)
#define LVM_GETHEADER           (LVM_FIRST + 31)
#define LVM_CREATEDRAGIMAGE     (LVM_FIRST + 33)
#define LVM_GETVIEWRECT         (LVM_FIRST + 34)
#define LVM_GETTEXTCOLOR        (LVM_FIRST + 35)
#define LVM_SETTEXTCOLOR        (LVM_FIRST + 36)
#define LVM_GETTEXTBKCOLOR      (LVM_FIRST + 37)
#define LVM_SETTEXTBKCOLOR      (LVM_FIRST + 38)
#define LVM_GETTOPINDEX         (LVM_FIRST + 39)
#define LVM_GETCOUNTPERPAGE     (LVM_FIRST + 40)
#define LVM_GETORIGIN           (LVM_FIRST + 41)
#define LVM_UPDATE              (LVM_FIRST + 42)
#define LVM_SETITEMSTATE        (LVM_FIRST + 43)
#define LVM_GETITEMSTATE        (LVM_FIRST + 44)
#define LVM_GETITEMTEXTA        (LVM_FIRST + 45)
#define LVM_GETITEMTEXTW        (LVM_FIRST + 115)
#define LVM_SETITEMTEXTA        (LVM_FIRST + 46)
#define LVM_SETITEMTEXTW        (LVM_FIRST + 116)
#define LVM_SETITEMCOUNT        (LVM_FIRST + 47)
#define LVM_SORTITEMS           (LVM_FIRST + 48)
#define LVM_SETITEMPOSITION32   (LVM_FIRST + 49)
#define LVM_GETSELECTEDCOUNT    (LVM_FIRST + 50)
#define LVM_GETITEMSPACING      (LVM_FIRST + 51)
#define LVM_GETISEARCHSTRINGA   (LVM_FIRST + 52)
#define LVM_GETISEARCHSTRINGW   (LVM_FIRST + 117)
#define LVM_SETICONSPACING      (LVM_FIRST + 53)
#define LVM_SETEXTENDEDLISTVIEWSTYLE (LVM_FIRST + 54)
#define LVM_GETEXTENDEDLISTVIEWSTYLE (LVM_FIRST + 55)
#define LVM_GETSUBITEMRECT      (LVM_FIRST + 56)
#define LVM_SUBITEMHITTEST      (LVM_FIRST + 57)
#define LVM_SETCOLUMNORDERARRAY (LVM_FIRST + 58)
#define LVM_GETCOLUMNORDERARRAY (LVM_FIRST + 59)
#define LVM_SETHOTITEM          (LVM_FIRST + 60)
#define LVM_GETHOTITEM          (LVM_FIRST + 61)
#define LVM_SETHOTCURSOR        (LVM_FIRST + 62)
#define LVM_GETHOTCURSOR        (LVM_FIRST + 63)
#define LVM_APPROXIMATEVIEWRECT (LVM_FIRST + 64)
#define LVM_SETWORKAREAS        (LVM_FIRST + 65)
#define LVM_GETSELECTIONMARK    (LVM_FIRST + 66)
#define LVM_SETSELECTIONMARK    (LVM_FIRST + 67)
#define LVM_SETBKIMAGEA         (LVM_FIRST + 68)
#define LVM_SETBKIMAGEW         (LVM_FIRST + 138)
#define LVM_GETBKIMAGEA         (LVM_FIRST + 69)
#define LVM_GETBKIMAGEW         (LVM_FIRST + 139)
#define LVM_GETWORKAREAS        (LVM_FIRST + 70)
#define LVM_SETHOVERTIME        (LVM_FIRST + 71)
#define LVM_GETHOVERTIME        (LVM_FIRST + 72)
#define LVM_GETNUMBEROFWORKAREAS (LVM_FIRST + 73)
#define LVM_SETTOOLTIPS         (LVM_FIRST + 74)
#define LVM_GETTOOLTIPS         (LVM_FIRST + 78)
#define LVM_SORTITEMSEX         (LVM_FIRST + 81)
#define LVM_GETGROUPSTATE       (LVM_FIRST + 92)
#define LVM_INSERTGROUP         (LVM_FIRST + 145)
#define LVM_SETGROUPINFO        (LVM_FIRST + 147)
#define LVM_GETGROUPINFO        (LVM_FIRST + 149)
#define LVM_REMOVEGROUP         (LVM_FIRST + 150)
#define LVM_ENABLEGROUPVIEW     (LVM_FIRST + 157)
#define LVM_REMOVEALLGROUPS     (LVM_FIRST + 160)
#define LVM_ISGROUPVIEWENABLED  (LVM_FIRST + 175)

#ifdef UNICODE
#define LVM_GETITEM             LVM_GETITEMW
#define LVM_SETITEM             LVM_SETITEMW
#define LVM_INSERTITEM          LVM_INSERTITEMW
#define LVM_GETITEMTEXT         LVM_GETITEMTEXTW
#define LVM_SETITEMTEXT         LVM_SETITEMTEXTW
#define LVM_GETCOLUMN           LVM_GETCOLUMNW
#define LVM_SETCOLUMN           LVM_SETCOLUMNW
#define LVM_INSERTCOLUMN        LVM_INSERTCOLUMNW
#define LVM_GETSTRINGWIDTH      LVM_GETSTRINGWIDTHW
#define LVM_FINDITEM            LVM_FINDITEMW
#define LVM_EDITLABEL           LVM_EDITLABELW
#else
#define LVM_GETITEM             LVM_GETITEMA
#define LVM_SETITEM             LVM_SETITEMA
#define LVM_INSERTITEM          LVM_INSERTITEMA
#define LVM_GETITEMTEXT         LVM_GETITEMTEXTA
#define LVM_SETITEMTEXT         LVM_SETITEMTEXTA
#define LVM_GETCOLUMN           LVM_GETCOLUMNA
#define LVM_SETCOLUMN           LVM_SETCOLUMNA
#define LVM_INSERTCOLUMN        LVM_INSERTCOLUMNA
#define LVM_GETSTRINGWIDTH      LVM_GETSTRINGWIDTHA
#define LVM_FINDITEM            LVM_FINDITEMA
#define LVM_EDITLABEL           LVM_EDITLABELA
#endif

#define LVN_FIRST               (0U-100U)
#define LVN_ITEMCHANGING        (LVN_FIRST-0)
#define LVN_ITEMCHANGED         (LVN_FIRST-1)
#define LVN_INSERTITEM          (LVN_FIRST-2)
#define LVN_DELETEITEM          (LVN_FIRST-3)
#define LVN_DELETEALLITEMS      (LVN_FIRST-4)
#define LVN_BEGINLABELEDITA     (LVN_FIRST-5)
#define LVN_BEGINLABELEDITW     (LVN_FIRST-75)
#define LVN_ENDLABELEDITA       (LVN_FIRST-6)
#define LVN_ENDLABELEDITW       (LVN_FIRST-76)
#define LVN_COLUMNCLICK         (LVN_FIRST-8)
#define LVN_BEGINDRAG           (LVN_FIRST-9)
#define LVN_BEGINRDRAG          (LVN_FIRST-11)
#define LVN_ODCACHEHINT         (LVN_FIRST-13)
#define LVN_ITEMACTIVATE        (LVN_FIRST-14)
#define LVN_ODSTATECHANGED      (LVN_FIRST-15)
#define LVN_HOTTRACK            (LVN_FIRST-21)
#define LVN_GETDISPINFOA        (LVN_FIRST-50)
#define LVN_GETDISPINFOW        (LVN_FIRST-77)
#define LVN_SETDISPINFOA        (LVN_FIRST-51)
#define LVN_SETDISPINFOW        (LVN_FIRST-78)
#define LVN_KEYDOWN             (LVN_FIRST-55)
#ifdef UNICODE
#define LVN_BEGINLABELEDIT LVN_BEGINLABELEDITW
#define LVN_ENDLABELEDIT   LVN_ENDLABELEDITW
#define LVN_GETDISPINFO    LVN_GETDISPINFOW
#define LVN_SETDISPINFO    LVN_SETDISPINFOW
#else
#define LVN_BEGINLABELEDIT LVN_BEGINLABELEDITA
#define LVN_ENDLABELEDIT   LVN_ENDLABELEDITA
#define LVN_GETDISPINFO    LVN_GETDISPINFOA
#define LVN_SETDISPINFO    LVN_SETDISPINFOA
#endif

struct LVITEMA {
    UINT mask;
    int iItem;
    int iSubItem;
    UINT state;
    UINT stateMask;
    LPSTR pszText;
    int cchTextMax;
    int iImage;
    LPARAM lParam;
    int iIndent;
    int iGroupId;
    UINT cColumns;
    PUINT puColumns;
};
struct LVITEMW {
    UINT mask;
    int iItem;
    int iSubItem;
    UINT state;
    UINT stateMask;
    LPWSTR pszText;
    int cchTextMax;
    int iImage;
    LPARAM lParam;
    int iIndent;
    int iGroupId;
    UINT cColumns;
    PUINT puColumns;
};
#ifdef UNICODE
typedef LVITEMW LVITEM;
#else
typedef LVITEMA LVITEM;
#endif
typedef LVITEM* LPLVITEM;

struct LVCOLUMNA {
    UINT mask;
    int fmt;
    int cx;
    LPSTR pszText;
    int cchTextMax;
    int iSubItem;
    int iImage;
    int iOrder;
};
struct LVCOLUMNW {
    UINT mask;
    int fmt;
    int cx;
    LPWSTR pszText;
    int cchTextMax;
    int iSubItem;
    int iImage;
    int iOrder;
};
#ifdef UNICODE
typedef LVCOLUMNW LVCOLUMN;
#else
typedef LVCOLUMNA LVCOLUMN;
#endif
typedef LVCOLUMN* LPLVCOLUMN;

struct LVHITTESTINFO {
    POINT pt;
    UINT flags;
    int iItem;
    int iSubItem;
    int iGroup;
};
typedef LVHITTESTINFO* LPLVHITTESTINFO;

struct NMLISTVIEW {
    NMHDR hdr;
    int iItem;
    int iSubItem;
    UINT uNewState;
    UINT uOldState;
    UINT uChanged;
    POINT ptAction;
    LPARAM lParam;
};
typedef NMLISTVIEW* LPNMLISTVIEW;

struct NMLVDISPINFOA {
    NMHDR hdr;
    LVITEMA item;
};
struct NMLVDISPINFOW {
    NMHDR hdr;
    LVITEMW item;
};
#ifdef UNICODE
typedef NMLVDISPINFOW NMLVDISPINFO;
#else
typedef NMLVDISPINFOA NMLVDISPINFO;
#endif
typedef LVITEM LV_ITEM;
typedef NMLVDISPINFO LV_DISPINFO;

struct LVGROUP {
    UINT cbSize;
    UINT mask;
    LPWSTR pszHeader;
    int cchHeader;
    LPWSTR pszFooter;
    int cchFooter;
    int iGroupId;
    UINT stateMask;
    UINT state;
    UINT uAlign;
};
typedef LVGROUP* PLVGROUP;
#define LVGROUP_V5_SIZE sizeof(LVGROUP)
#define LVGF_NONE           0x00000000
#define LVGF_HEADER         0x00000001
#define LVGF_FOOTER         0x00000002
#define LVGF_STATE          0x00000004
#define LVGF_ALIGN          0x00000008
#define LVGF_GROUPID        0x00000010
#define LVGS_NORMAL         0x00000000
#define LVGS_COLLAPSED      0x00000001
#define LVGS_HIDDEN         0x00000002
#define LVGS_NOHEADER       0x00000004
#define LVGS_COLLAPSIBLE    0x00000008
#define LVGA_HEADER_LEFT    0x00000001
#define LVGA_HEADER_CENTER  0x00000002
#define LVGA_HEADER_RIGHT   0x00000004

typedef int (CALLBACK *PFNLVCOMPARE)(LPARAM, LPARAM, LPARAM);

// TreeView
#define TVS_HASBUTTONS          0x0001
#define TVS_HASLINES            0x0002
#define TVS_LINESATROOT         0x0004
#define TVS_EDITLABELS          0x0008
#define TVS_DISABLEDRAGDROP     0x0010
#define TVS_SHOWSELALWAYS       0x0020
#define TVS_RTLREADING          0x0040
#define TVS_NOTOOLTIPS          0x0080
#define TVS_CHECKBOXES          0x0100
#define TVS_TRACKSELECT         0x0200
#define TVS_SINGLEEXPAND        0x0400
#define TVS_INFOTIP             0x0800
#define TVS_FULLROWSELECT       0x1000
#define TVS_NOSCROLL            0x2000
#define TVS_NONEVENHEIGHT       0x4000
#define TVS_NOHSCROLL           0x8000

#define TVIF_TEXT               0x0001
#define TVIF_IMAGE              0x0002
#define TVIF_PARAM              0x0004
#define TVIF_STATE              0x0008
#define TVIF_HANDLE             0x0010
#define TVIF_SELECTEDIMAGE      0x0020
#define TVIF_CHILDREN           0x0040
#define TVIF_INTEGRAL           0x0080

#define TVIS_SELECTED           0x0002
#define TVIS_CUT                0x0004
#define TVIS_DROPHILITED        0x0008
#define TVIS_BOLD               0x0010
#define TVIS_EXPANDED           0x0020
#define TVIS_EXPANDEDONCE       0x0040
#define TVIS_EXPANDPARTIAL      0x0080
#define TVIS_OVERLAYMASK        0x0F00
#define TVIS_STATEIMAGEMASK     0xF000
#define TVIS_USERMASK           0xF000

#define TVI_ROOT                ((HTREEITEM)(ULONG_PTR)-0x10000)
#define TVI_FIRST               ((HTREEITEM)(ULONG_PTR)-0x0FFFF)
#define TVI_LAST                ((HTREEITEM)(ULONG_PTR)-0x0FFFE)
#define TVI_SORT                ((HTREEITEM)(ULONG_PTR)-0x0FFFD)

#define TVE_COLLAPSE            0x0001
#define TVE_EXPAND              0x0002
#define TVE_TOGGLE              0x0003
#define TVE_EXPANDPARTIAL       0x4000
#define TVE_COLLAPSERESET       0x8000

#define TVGN_ROOT               0x0000
#define TVGN_NEXT               0x0001
#define TVGN_PREVIOUS           0x0002
#define TVGN_PARENT             0x0003
#define TVGN_CHILD              0x0004
#define TVGN_FIRSTVISIBLE       0x0005
#define TVGN_NEXTVISIBLE        0x0006
#define TVGN_PREVIOUSVISIBLE    0x0007
#define TVGN_DROPHILITE         0x0008
#define TVGN_CARET              0x0009
#define TVGN_LASTVISIBLE        0x000A

#define TVHT_NOWHERE            0x0001
#define TVHT_ONITEMICON         0x0002
#define TVHT_ONITEMLABEL        0x0004
#define TVHT_ONITEM             (TVHT_ONITEMICON | TVHT_ONITEMLABEL | TVHT_ONITEMSTATEICON)
#define TVHT_ONITEMINDENT       0x0008
#define TVHT_ONITEMBUTTON       0x0010
#define TVHT_ONITEMRIGHT        0x0020
#define TVHT_ONITEMSTATEICON    0x0040
#define TVHT_ABOVE              0x0100
#define TVHT_BELOW              0x0200
#define TVHT_TORIGHT            0x0400
#define TVHT_TOLEFT             0x0800

#define TVSIL_NORMAL            0
#define TVSIL_STATE             2

#define WC_TREEVIEWA            "SysTreeView32"
#define WC_TREEVIEWW            L"SysTreeView32"
#ifdef UNICODE
#define WC_TREEVIEW             WC_TREEVIEWW
#else
#define WC_TREEVIEW             WC_TREEVIEWA
#endif

#define TV_FIRST                0x1100
#define TVM_INSERTITEMA         (TV_FIRST + 0)
#define TVM_INSERTITEMW         (TV_FIRST + 50)
#define TVM_DELETEITEM          (TV_FIRST + 1)
#define TVM_EXPAND              (TV_FIRST + 2)
#define TVM_GETITEMRECT         (TV_FIRST + 4)
#define TVM_GETCOUNT            (TV_FIRST + 5)
#define TVM_GETINDENT           (TV_FIRST + 6)
#define TVM_SETINDENT           (TV_FIRST + 7)
#define TVM_GETIMAGELIST        (TV_FIRST + 8)
#define TVM_SETIMAGELIST        (TV_FIRST + 9)
#define TVM_GETNEXTITEM         (TV_FIRST + 10)
#define TVM_SELECTITEM          (TV_FIRST + 11)
#define TVM_GETITEMA            (TV_FIRST + 12)
#define TVM_GETITEMW            (TV_FIRST + 62)
#define TVM_SETITEMA            (TV_FIRST + 13)
#define TVM_SETITEMW            (TV_FIRST + 63)
#define TVM_EDITLABELA          (TV_FIRST + 14)
#define TVM_EDITLABELW          (TV_FIRST + 65)
#define TVM_GETEDITCONTROL      (TV_FIRST + 15)
#define TVM_GETVISIBLECOUNT     (TV_FIRST + 16)
#define TVM_HITTEST             (TV_FIRST + 17)
#define TVM_CREATEDRAGIMAGE     (TV_FIRST + 18)
#define TVM_SORTCHILDREN        (TV_FIRST + 19)
#define TVM_ENSUREVISIBLE       (TV_FIRST + 20)
#define TVM_SORTCHILDRENCB      (TV_FIRST + 21)
#define TVM_ENDEDITLABELNOW     (TV_FIRST + 22)
#define TVM_GETISEARCHSTRINGA   (TV_FIRST + 23)
#define TVM_GETISEARCHSTRINGW   (TV_FIRST + 64)
#define TVM_SETTOOLTIPS         (TV_FIRST + 24)
#define TVM_GETTOOLTIPS         (TV_FIRST + 25)
#define TVM_GETITEMSTATE        (TV_FIRST + 39)
#define TVM_SETITEMSTATE        (TV_FIRST + 63)

#ifdef UNICODE
#define TVM_INSERTITEM          TVM_INSERTITEMW
#define TVM_GETITEM             TVM_GETITEMW
#define TVM_SETITEM             TVM_SETITEMW
#define TVM_EDITLABEL           TVM_EDITLABELW
#else
#define TVM_INSERTITEM          TVM_INSERTITEMA
#define TVM_GETITEM             TVM_GETITEMA
#define TVM_SETITEM             TVM_SETITEMA
#define TVM_EDITLABEL           TVM_EDITLABELA
#endif

#define TVN_FIRST               (0U-400U)
#define TVN_SELCHANGINGA        (TVN_FIRST-1)
#define TVN_SELCHANGINGW        (TVN_FIRST-50)
#define TVN_SELCHANGEDA         (TVN_FIRST-2)
#define TVN_SELCHANGEDW         (TVN_FIRST-51)
#define TVN_GETDISPINFOA        (TVN_FIRST-3)
#define TVN_GETDISPINFOW        (TVN_FIRST-52)
#define TVN_SETDISPINFOA        (TVN_FIRST-4)
#define TVN_SETDISPINFOW        (TVN_FIRST-53)
#define TVN_ITEMEXPANDINGA      (TVN_FIRST-5)
#define TVN_ITEMEXPANDINGW      (TVN_FIRST-54)
#define TVN_ITEMEXPANDEDA       (TVN_FIRST-6)
#define TVN_ITEMEXPANDEDW       (TVN_FIRST-55)
#define TVN_BEGINDRAGA          (TVN_FIRST-7)
#define TVN_BEGINDRAGW          (TVN_FIRST-56)
#define TVN_BEGINRDRAGA         (TVN_FIRST-8)
#define TVN_BEGINRDRAGW         (TVN_FIRST-57)
#define TVN_DELETEITEMA         (TVN_FIRST-9)
#define TVN_DELETEITEMW         (TVN_FIRST-58)
#define TVN_BEGINLABELEDITA     (TVN_FIRST-10)
#define TVN_BEGINLABELEDITW     (TVN_FIRST-59)
#define TVN_ENDLABELEDITA       (TVN_FIRST-11)
#define TVN_ENDLABELEDITW       (TVN_FIRST-60)
#define TVN_KEYDOWN             (TVN_FIRST-12)
#ifdef UNICODE
#define TVN_SELCHANGING     TVN_SELCHANGINGW
#define TVN_SELCHANGED      TVN_SELCHANGEDW
#define TVN_GETDISPINFO     TVN_GETDISPINFOW
#define TVN_SETDISPINFO     TVN_SETDISPINFOW
#define TVN_ITEMEXPANDING   TVN_ITEMEXPANDINGW
#define TVN_ITEMEXPANDED    TVN_ITEMEXPANDEDW
#define TVN_BEGINDRAG       TVN_BEGINDRAGW
#define TVN_BEGINRDRAG      TVN_BEGINRDRAGW
#define TVN_DELETEITEM      TVN_DELETEITEMW
#define TVN_BEGINLABELEDIT  TVN_BEGINLABELEDITW
#define TVN_ENDLABELEDIT    TVN_ENDLABELEDITW
#else
#define TVN_SELCHANGING     TVN_SELCHANGINGA
#define TVN_SELCHANGED      TVN_SELCHANGEDA
#define TVN_GETDISPINFO     TVN_GETDISPINFOA
#define TVN_SETDISPINFO     TVN_SETDISPINFOA
#define TVN_ITEMEXPANDING   TVN_ITEMEXPANDINGA
#define TVN_ITEMEXPANDED    TVN_ITEMEXPANDEDA
#define TVN_BEGINDRAG       TVN_BEGINDRAGA
#define TVN_BEGINRDRAG      TVN_BEGINRDRAGA
#define TVN_DELETEITEM      TVN_DELETEITEMA
#define TVN_BEGINLABELEDIT  TVN_BEGINLABELEDITA
#define TVN_ENDLABELEDIT    TVN_ENDLABELEDITA
#endif

struct TVITEMA {
    UINT mask;
    HTREEITEM hItem;
    UINT state;
    UINT stateMask;
    LPSTR pszText;
    int cchTextMax;
    int iImage;
    int iSelectedImage;
    int cChildren;
    LPARAM lParam;
};
struct TVITEMW {
    UINT mask;
    HTREEITEM hItem;
    UINT state;
    UINT stateMask;
    LPWSTR pszText;
    int cchTextMax;
    int iImage;
    int iSelectedImage;
    int cChildren;
    LPARAM lParam;
};
struct TVITEMEXA : public TVITEMA {
    int iIntegral;
    UINT uStateEx;
    HWND hwnd;
    int iExpandedImage;
    int iReserved;
};
struct TVITEMEXW : public TVITEMW {
    int iIntegral;
    UINT uStateEx;
    HWND hwnd;
    int iExpandedImage;
    int iReserved;
};
#ifdef UNICODE
typedef TVITEMW TVITEM;
typedef TVITEMEXW TVITEMEX;
#else
typedef TVITEMA TVITEM;
typedef TVITEMEXA TVITEMEX;
#endif
typedef TVITEM* LPTVITEM;
typedef TVITEMEX* LPTVITEMEX;

struct TVINSERTSTRUCTA {
    HTREEITEM hParent;
    HTREEITEM hInsertAfter;
    union {
        TVITEMEXA itemex;
        TVITEMA item;
    };
};
struct TVINSERTSTRUCTW {
    HTREEITEM hParent;
    HTREEITEM hInsertAfter;
    union {
        TVITEMEXW itemex;
        TVITEMW item;
    };
};
#ifdef UNICODE
typedef TVINSERTSTRUCTW TVINSERTSTRUCT;
#else
typedef TVINSERTSTRUCTA TVINSERTSTRUCT;
#endif
typedef TVINSERTSTRUCT* LPTVINSERTSTRUCT;

struct TVHITTESTINFO {
    POINT pt;
    UINT flags;
    HTREEITEM hItem;
};
typedef TVHITTESTINFO* LPTVHITTESTINFO;

struct NMTREEVIEWA {
    NMHDR hdr;
    UINT action;
    TVITEMA itemOld;
    TVITEMA itemNew;
    POINT ptDrag;
};
struct NMTREEVIEWW {
    NMHDR hdr;
    UINT action;
    TVITEMW itemOld;
    TVITEMW itemNew;
    POINT ptDrag;
};
#ifdef UNICODE
typedef NMTREEVIEWW NMTREEVIEW;
#else
typedef NMTREEVIEWA NMTREEVIEW;
#endif
typedef NMTREEVIEW* LPNMTREEVIEW;

struct NMTVDISPINFOA {
    NMHDR hdr;
    TVITEMA item;
};
struct NMTVDISPINFOW {
    NMHDR hdr;
    TVITEMW item;
};
#ifdef UNICODE
typedef NMTVDISPINFOW NMTVDISPINFO;
#else
typedef NMTVDISPINFOA NMTVDISPINFO;
#endif
typedef NMTVDISPINFO* LPNMTVDISPINFO;

struct NMTVKEYDOWN {
    NMHDR hdr;
    WORD wVKey;
    UINT flags;
};

typedef int (CALLBACK *PFNTVCOMPARE)(LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort);
struct TVSORTCB {
    HTREEITEM hParent;
    PFNTVCOMPARE lpfnCompare;
    LPARAM lParam;
};
typedef TVSORTCB* LPTVSORTCB;

// TabCtrl
#define WC_TABCONTROLA          "SysTabControl32"
#define WC_TABCONTROLW          L"SysTabControl32"
#ifdef UNICODE
#define WC_TABCONTROL           WC_TABCONTROLW
#else
#define WC_TABCONTROL           WC_TABCONTROLA
#endif

#define TCS_TABS                0x0000
#define TCS_FORCELABELLEFT      0x0020
#define TCS_BUTTONS             0x0100
#define TCS_SINGLELINE          0x0000
#define TCS_MULTILINE           0x0200
#define TCS_RIGHTJUSTIFY        0x0000
#define TCS_FIXEDWIDTH          0x0400
#define TCS_RAGGEDRIGHT         0x0800
#define TCS_FOCUSONBUTTONDOWN   0x1000
#define TCS_OWNERDRAWFIXED      0x2000
#define TCS_TOOLTIPS            0x4000
#define TCS_FOCUSNEVER          0x8000

#define TCIF_TEXT               0x0001
#define TCIF_IMAGE              0x0002
#define TCIF_RTLREADING         0x0004
#define TCIF_PARAM              0x0008
#define TCIF_STATE              0x0010

#define TCM_FIRST               0x1300
#define TCM_GETIMAGELIST        (TCM_FIRST + 2)
#define TCM_SETIMAGELIST        (TCM_FIRST + 3)
#define TCM_GETITEMCOUNT        (TCM_FIRST + 4)
#define TCM_GETITEMA            (TCM_FIRST + 5)
#define TCM_GETITEMW            (TCM_FIRST + 60)
#define TCM_SETITEMA            (TCM_FIRST + 6)
#define TCM_SETITEMW            (TCM_FIRST + 61)
#define TCM_INSERTITEMA         (TCM_FIRST + 7)
#define TCM_INSERTITEMW         (TCM_FIRST + 62)
#define TCM_DELETEITEM          (TCM_FIRST + 8)
#define TCM_DELETEALLITEMS      (TCM_FIRST + 9)
#define TCM_GETITEMRECT         (TCM_FIRST + 10)
#define TCM_GETCURSEL           (TCM_FIRST + 11)
#define TCM_SETCURSEL           (TCM_FIRST + 12)
#define TCM_HITTEST             (TCM_FIRST + 13)
#define TCM_SETITEMEXTRA        (TCM_FIRST + 14)
#define TCM_ADJUSTRECT          (TCM_FIRST + 40)
#define TCM_SETITEMSIZE         (TCM_FIRST + 41)
#define TCM_REMOVEIMAGE         (TCM_FIRST + 42)
#define TCM_SETPADDING          (TCM_FIRST + 43)
#define TCM_GETROWCOUNT         (TCM_FIRST + 44)
#define TCM_GETTOOLTIPS         (TCM_FIRST + 45)
#define TCM_SETTOOLTIPS         (TCM_FIRST + 46)
#define TCM_GETCURFOCUS         (TCM_FIRST + 47)
#define TCM_SETCURFOCUS         (TCM_FIRST + 48)

#ifdef UNICODE
#define TCM_GETITEM             TCM_GETITEMW
#define TCM_SETITEM             TCM_SETITEMW
#define TCM_INSERTITEM          TCM_INSERTITEMW
#else
#define TCM_GETITEM             TCM_GETITEMA
#define TCM_SETITEM             TCM_SETITEMA
#define TCM_INSERTITEM          TCM_INSERTITEMA
#endif

struct TCHITTESTINFO {
    POINT pt;
    UINT flags;
};
typedef TCHITTESTINFO* LPTCHITTESTINFO;

#define TCN_FIRST               (0U-550U)
#define TCN_KEYDOWN             (TCN_FIRST - 0)
#define TCN_SELCHANGE           (TCN_FIRST - 1)
#define TCN_SELCHANGING         (TCN_FIRST - 2)

struct TCITEMA {
    UINT mask;
    DWORD dwState;
    DWORD dwStateMask;
    LPSTR pszText;
    int cchTextMax;
    int iImage;
    LPARAM lParam;
};
struct TCITEMW {
    UINT mask;
    DWORD dwState;
    DWORD dwStateMask;
    LPWSTR pszText;
    int cchTextMax;
    int iImage;
    LPARAM lParam;
};
#ifdef UNICODE
typedef TCITEMW TCITEM;
typedef TCITEMW TC_ITEM;
#else
typedef TCITEMA TCITEM;
typedef TCITEMA TC_ITEM;
#endif
typedef TCITEM* LPTCITEM;
typedef TC_ITEM* LPTC_ITEM;
typedef TCITEMA TC_ITEMA;
typedef TCITEMW TC_ITEMW;

// Trackbar / Slider
#define TRACKBAR_CLASSA         "msctls_trackbar32"
#define TRACKBAR_CLASSW         L"msctls_trackbar32"
#ifdef UNICODE
#define TRACKBAR_CLASS          TRACKBAR_CLASSW
#else
#define TRACKBAR_CLASS          TRACKBAR_CLASSA
#endif

#define TBS_AUTOTICKS           0x0001
#define TBS_VERT                0x0002
#define TBS_HORZ                0x0000
#define TBS_TOP                 0x0004
#define TBS_BOTTOM              0x0000
#define TBS_LEFT                0x0004
#define TBS_RIGHT               0x0000
#define TBS_BOTH                0x0008
#define TBS_NOTICKS             0x0010
#define TBS_ENABLESELRANGE      0x0020
#define TBS_FIXEDLENGTH         0x0040
#define TBS_NOTHUMB             0x0080
#define TBS_TOOLTIPS            0x0100
#define TBS_DOWNISLEFT          0x0400

#define TB_LINEUP               0
#define TB_LINEDOWN             1
#define TB_PAGEUP               2
#define TB_PAGEDOWN             3
#define TB_THUMBPOSITION        4
#define TB_THUMBTRACK           5
#define TB_TOP                  6
#define TB_BOTTOM               7
#define TB_ENDTRACK             8

#define TBM_GETPOS              (WM_USER)
#define TBM_GETRANGEMIN         (WM_USER+1)
#define TBM_GETRANGEMAX         (WM_USER+2)
#define TBM_GETTIC              (WM_USER+3)
#define TBM_SETTIC              (WM_USER+4)
#define TBM_SETPOS              (WM_USER+5)
#define TBM_SETRANGE            (WM_USER+6)
#define TBM_SETRANGEMIN         (WM_USER+7)
#define TBM_SETRANGEMAX         (WM_USER+8)
#define TBM_CLEARTICS           (WM_USER+9)
#define TBM_SETSEL              (WM_USER+10)
#define TBM_SETSELSTART         (WM_USER+11)
#define TBM_SETSELEND           (WM_USER+12)
#define TBM_GETPTICS            (WM_USER+14)
#define TBM_GETTICPOS           (WM_USER+15)
#define TBM_GETNUMTICS          (WM_USER+16)
#define TBM_GETSELSTART         (WM_USER+17)
#define TBM_GETSELEND           (WM_USER+18)
#define TBM_CLEARSEL            (WM_USER+19)
#define TBM_SETTICFREQ          (WM_USER+20)
#define TBM_SETPAGESIZE         (WM_USER+21)
#define TBM_GETPAGESIZE         (WM_USER+22)
#define TBM_SETLINESIZE         (WM_USER+23)
#define TBM_GETLINESIZE         (WM_USER+24)
#define TBM_GETTHUMBRECT        (WM_USER+25)
#define TBM_GETCHANNELRECT      (WM_USER+26)

// UpDown / Spin
#define UPDOWN_CLASSA           "msctls_updown32"
#define UPDOWN_CLASSW           L"msctls_updown32"
#ifdef UNICODE
#define UPDOWN_CLASS            UPDOWN_CLASSW
#else
#define UPDOWN_CLASS            UPDOWN_CLASSA
#endif

#define UDS_WRAP                0x0001
#define UDS_SETBUDDYINT         0x0002
#define UDS_ALIGNRIGHT          0x0004
#define UDS_ALIGNLEFT           0x0008
#define UDS_AUTOBUDDY           0x0010
#define UDS_ARROWKEYS           0x0020
#define UDS_HORZ                0x0040
#define UDS_NOTHOUSANDS         0x0080
#define UDS_HOTTRACK            0x0100

#define UDM_SETRANGE            (WM_USER+101)
#define UDM_GETRANGE            (WM_USER+102)
#define UDM_SETPOS              (WM_USER+103)
#define UDM_GETPOS              (WM_USER+104)
#define UDM_SETBUDDY            (WM_USER+105)
#define UDM_GETBUDDY            (WM_USER+106)
#define UDM_SETACCEL            (WM_USER+107)
#define UDM_GETACCEL            (WM_USER+108)
#define UDM_SETBASE             (WM_USER+109)
#define UDM_GETBASE             (WM_USER+110)
#define UDM_SETRANGE32          (WM_USER+111)
#define UDM_GETRANGE32          (WM_USER+112)
#define UDM_SETPOS32            (WM_USER+113)
#define UDM_GETPOS32            (WM_USER+114)

#define UDN_FIRST               (0U-721U)
#define UDN_DELTAPOS            (UDN_FIRST - 1)
struct NMUPDOWN {
    NMHDR hdr;
    int iPos;
    int iDelta;
};
typedef NMUPDOWN* LPNMUPDOWN;

struct UDACCEL {
    UINT nSec;
    UINT nInc;
};
typedef UDACCEL* LPUDACCEL;

// ProgressBar
#define PROGRESS_CLASSA         "msctls_progress32"
#define PROGRESS_CLASSW         L"msctls_progress32"
#ifdef UNICODE
#define PROGRESS_CLASS          PROGRESS_CLASSW
#else
#define PROGRESS_CLASS          PROGRESS_CLASSA
#endif

#define PBS_SMOOTH              0x01
#define PBS_VERTICAL            0x04
#define PBS_MARQUEE             0x08
#define PBM_SETRANGE            (WM_USER+1)
#define PBM_SETPOS              (WM_USER+2)
#define PBM_DELTAPOS            (WM_USER+3)
#define PBM_SETSTEP             (WM_USER+4)
#define PBM_STEPIT              (WM_USER+5)
#define PBM_SETRANGE32          (WM_USER+6)
#define PBM_GETRANGE            (WM_USER+7)
#define PBM_GETPOS              (WM_USER+8)
#define PBM_SETBARCOLOR         (WM_USER+9)
#define PBM_SETMARQUEE          (WM_USER+10)

struct PBRANGE {
    int iLow;
    int iHigh;
};

// ToolBar
#define TOOLBARCLASSNAMEA       "ToolbarWindow32"
#define TOOLBARCLASSNAMEW       L"ToolbarWindow32"
#ifdef UNICODE
#define TOOLBARCLASSNAME        TOOLBARCLASSNAMEW
#else
#define TOOLBARCLASSNAME        TOOLBARCLASSNAMEA
#endif

#define TBSTATE_CHECKED         0x01
#define TBSTATE_PRESSED         0x02
#define TBSTATE_ENABLED         0x04
#define TBSTATE_HIDDEN          0x08
#define TBSTATE_INDETERMINATE   0x10
#define TBSTATE_WRAP            0x20
#define TBSTATE_ELLIPSES        0x40
#define TBSTATE_MARKED          0x80

#define TBSTYLE_BUTTON          0x0000
#define TBSTYLE_SEP             0x0001
#define TBSTYLE_CHECK           0x0002
#define TBSTYLE_GROUP           0x0004
#define TBSTYLE_CHECKGROUP      (TBSTYLE_GROUP | TBSTYLE_CHECK)
#define TBSTYLE_DROPDOWN        0x0008
#define TBSTYLE_AUTOSIZE        0x0010
#define TBSTYLE_NOPREFIX        0x0020
#define TBSTYLE_TOOLTIPS        0x0100
#define TBSTYLE_WRAPABLE        0x0200
#define TBSTYLE_ALTDRAG         0x0400
#define TBSTYLE_FLAT            0x0800
#define TBSTYLE_LIST            0x1000
#define TBSTYLE_CUSTOMERASE     0x2000
#define TBSTYLE_REGISTERDROP    0x4000
#define TBSTYLE_TRANSPARENT     0x8000
#define TBSTYLE_EX_DRAWDDARROWS 0x00000001
#define TBSTYLE_EX_MIXEDBUTTONS 0x00000008
#define TBSTYLE_EX_HIDECLIPPEDBUTTONS 0x00000010
#define TBSTYLE_EX_DOUBLEBUFFER 0x00000080

#define BTNS_BUTTON             TBSTYLE_BUTTON
#define BTNS_SEP                TBSTYLE_SEP
#define BTNS_CHECK              TBSTYLE_CHECK
#define BTNS_GROUP              TBSTYLE_GROUP
#define BTNS_CHECKGROUP         TBSTYLE_CHECKGROUP
#define BTNS_DROPDOWN           TBSTYLE_DROPDOWN
#define BTNS_AUTOSIZE           TBSTYLE_AUTOSIZE
#define BTNS_WHOLEDROPDOWN      0x0080

#define CCS_TOP                 0x00000001L
#define CCS_NOMOVEY             0x00000002L
#define CCS_BOTTOM              0x00000003L
#define CCS_NORESIZE            0x00000004L
#define CCS_NOPARENTALIGN       0x00000008L
#define CCS_ADJUSTABLE          0x00000020L
#define CCS_NODIVIDER           0x00000040L
#define CCS_VERT                0x00000080L
#define CCS_LEFT                (CCS_VERT | CCS_TOP)
#define CCS_RIGHT               (CCS_VERT | CCS_BOTTOM)
#define CCS_NOMOVEX             (CCS_VERT | CCS_NOMOVEY)

#define TB_ENABLEBUTTON         (WM_USER + 1)
#define TB_CHECKBUTTON          (WM_USER + 2)
#define TB_PRESSBUTTON          (WM_USER + 3)
#define TB_HIDEBUTTON           (WM_USER + 4)
#define TB_INDETERMINATE        (WM_USER + 5)
#define TB_MARKBUTTON           (WM_USER + 6)
#define TB_ISBUTTONENABLED      (WM_USER + 9)
#define TB_ISBUTTONCHECKED      (WM_USER + 10)
#define TB_ISBUTTONPRESSED      (WM_USER + 11)
#define TB_ISBUTTONHIDDEN       (WM_USER + 12)
#define TB_ISBUTTONINDETERMINATE (WM_USER + 13)
#define TB_ISBUTTONHIGHLIGHTED  (WM_USER + 14)
#define TB_SETSTATE             (WM_USER + 17)
#define TB_GETSTATE             (WM_USER + 18)
#define TB_ADDBUTTONSA          (WM_USER + 20)
#define TB_INSERTBUTTONA        (WM_USER + 21)
#define TB_DELETEBUTTON         (WM_USER + 22)
#define TB_GETBUTTON            (WM_USER + 23)
#define TB_BUTTONCOUNT          (WM_USER + 24)
#define TB_COMMANDTOINDEX       (WM_USER + 25)
#define TB_SAVERESTOREA         (WM_USER + 26)
#define TB_CUSTOMIZE            (WM_USER + 27)
#define TB_ADDSTRINGA           (WM_USER + 28)
#define TB_GETITEMRECT          (WM_USER + 29)
#define TB_BUTTONSTRUCTSIZE     (WM_USER + 30)
#define TB_SETBUTTONSIZE        (WM_USER + 31)
#define TB_SETBITMAPSIZE        (WM_USER + 32)
#define TB_AUTOSIZE             (WM_USER + 33)
#define TB_SETINDENT            (WM_USER + 47)
#define TB_CHANGEBITMAP         (WM_USER + 43)
#define TB_GETTOOLTIPS          (WM_USER + 35)
#define TB_SETTOOLTIPS          (WM_USER + 36)
#define TB_SETPARENT            (WM_USER + 37)
#define TB_SETROWS              (WM_USER + 39)
#define TB_GETROWS              (WM_USER + 40)
#define TB_SETCMDID             (WM_USER + 42)
#define TB_CHANGEBITMAP         (WM_USER + 43)
#define TB_GETBITMAP            (WM_USER + 44)
#define TB_GETBUTTONTEXTA       (WM_USER + 45)
#define TB_REPLACEBITMAP        (WM_USER + 46)
#define TB_SETINDENT            (WM_USER + 47)
#define TB_SETIMAGELIST         (WM_USER + 48)
#define TB_GETIMAGELIST         (WM_USER + 49)
#define TB_LOADIMAGES           (WM_USER + 50)
#define TB_GETRECT              (WM_USER + 51)
#define TB_SETHOTIMAGELIST      (WM_USER + 52)
#define TB_GETHOTIMAGELIST      (WM_USER + 53)
#define TB_SETDISABLEDIMAGELIST (WM_USER + 54)
#define TB_GETDISABLEDIMAGELIST (WM_USER + 55)
#define TB_SETSTYLE             (WM_USER + 56)
#define TB_GETSTYLE             (WM_USER + 57)
#define TB_GETBUTTONSIZE        (WM_USER + 58)
#define TB_SETBUTTONWIDTH       (WM_USER + 59)
#define TB_SETMAXTEXTROWS       (WM_USER + 60)
#define TB_GETTEXTROWS          (WM_USER + 61)
#define TB_INSERTBUTTONW        (WM_USER + 67)
#define TB_ADDBUTTONSW          (WM_USER + 68)
#define TB_GETBUTTONTEXTW       (WM_USER + 75)
#define TB_SAVERESTOREW         (WM_USER + 76)
#define TB_ADDSTRINGW           (WM_USER + 77)
#define TB_SETEXTENDEDSTYLE     (WM_USER + 84)
#define TB_GETEXTENDEDSTYLE     (WM_USER + 85)

#ifdef UNICODE
#define TB_GETBUTTONTEXT        TB_GETBUTTONTEXTW
#define TB_SAVERESTORE          TB_SAVERESTOREW
#define TB_ADDSTRING            TB_ADDSTRINGW
#define TB_INSERTBUTTON         TB_INSERTBUTTONW
#define TB_ADDBUTTONS           TB_ADDBUTTONSW
#else
#define TB_GETBUTTONTEXT        TB_GETBUTTONTEXTA
#define TB_SAVERESTORE          TB_SAVERESTOREA
#define TB_ADDSTRING            TB_ADDSTRINGA
#define TB_INSERTBUTTON         TB_INSERTBUTTONA
#define TB_ADDBUTTONS           TB_ADDBUTTONSA
#endif

#define TBN_FIRST               (0U-700U)
#define TBN_DROPDOWN            (TBN_FIRST - 10)
#define TBDDRET_DEFAULT         0
#define TBDDRET_NODEFAULT       1
#define TBDDRET_TREATPRESSED    2

struct TBBUTTON {
    int iBitmap;
    int idCommand;
    BYTE fsState;
    BYTE fsStyle;
    BYTE bReserved[6];
    DWORD_PTR dwData;
    INT_PTR iString;
};
typedef TBBUTTON* LPTBBUTTON;
typedef const TBBUTTON* LPCTBBUTTON;

struct NMTOOLBARA {
    NMHDR hdr;
    int iItem;
    TBBUTTON tbButton;
    int cchText;
    LPSTR pszText;
    RECT rcButton;
};
struct NMTOOLBARW {
    NMHDR hdr;
    int iItem;
    TBBUTTON tbButton;
    int cchText;
    LPWSTR pszText;
    RECT rcButton;
};
#ifdef UNICODE
typedef NMTOOLBARW NMTOOLBAR;
#else
typedef NMTOOLBARA NMTOOLBAR;
#endif
typedef NMTOOLBAR* LPNMTOOLBAR;

// StatusBar
#define STATUSCLASSNAMEA        "msctls_statusbar32"
#define STATUSCLASSNAMEW        L"msctls_statusbar32"
#ifdef UNICODE
#define STATUSCLASSNAME         STATUSCLASSNAMEW
#else
#define STATUSCLASSNAME         STATUSCLASSNAMEA
#endif

#define SB_SETTEXTA             (WM_USER+1)
#define SB_SETTEXTW             (WM_USER+11)
#define SB_GETTEXTA             (WM_USER+2)
#define SB_GETTEXTW             (WM_USER+13)
#define SB_GETTEXTLENGTHA       (WM_USER+3)
#define SB_GETTEXTLENGTHW       (WM_USER+12)
#define SB_SETPARTS             (WM_USER+4)
#define SB_GETPARTS             (WM_USER+6)
#define SB_GETBORDERS           (WM_USER+7)
#define SB_SETMINHEIGHT         (WM_USER+8)
#define SB_SIMPLE               (WM_USER+9)
#define SB_GETRECT              (WM_USER+10)
#define SB_ISSIMPLE             (WM_USER+14)
#define SB_SETICON              (WM_USER+15)
#define SB_SETTIPTEXTA          (WM_USER+16)
#define SB_SETTIPTEXTW          (WM_USER+17)
#define SB_GETTIPTEXTA          (WM_USER+18)
#define SB_GETTIPTEXTW          (WM_USER+19)
#define SB_GETICON              (WM_USER+20)

#ifdef UNICODE
#define SB_SETTEXT              SB_SETTEXTW
#define SB_GETTEXT              SB_GETTEXTW
#define SB_GETTEXTLENGTH        SB_GETTEXTLENGTHW
#define SB_SETTIPTEXT           SB_SETTIPTEXTW
#define SB_GETTIPTEXT           SB_GETTIPTEXTW
#else
#define SB_SETTEXT              SB_SETTEXTA
#define SB_GETTEXT              SB_GETTEXTA
#define SB_GETTEXTLENGTH        SB_GETTEXTLENGTHA
#define SB_SETTIPTEXT           SB_SETTIPTEXTA
#define SB_GETTIPTEXT           SB_GETTIPTEXTA
#endif

// ToolTip
#define TOOLTIPS_CLASSA         "tooltips_class32"
#define TOOLTIPS_CLASSW         L"tooltips_class32"
#ifdef UNICODE
#define TOOLTIPS_CLASS          TOOLTIPS_CLASSW
#else
#define TOOLTIPS_CLASS          TOOLTIPS_CLASSA
#endif

#define LPSTR_TEXTCALLBACKA     ((LPSTR)(INT_PTR)-1)
#define LPSTR_TEXTCALLBACKW     ((LPWSTR)(INT_PTR)-1)
#ifdef UNICODE
#define LPSTR_TEXTCALLBACK      LPSTR_TEXTCALLBACKW
#else
#define LPSTR_TEXTCALLBACK      LPSTR_TEXTCALLBACKA
#endif

#define TTS_ALWAYSTIP           0x01
#define TTS_NOPREFIX            0x02
#define TTS_NOANIMATE           0x10
#define TTS_NOFADE              0x20
#define TTS_BALLOON             0x40
#define TTS_CLOSE               0x80

#define TTF_IDISHWND            0x0001
#define TTF_CENTERTIP           0x0002
#define TTF_RTLREADING          0x0004
#define TTF_SUBCLASS            0x0010
#define TTF_TRACK               0x0020
#define TTF_ABSOLUTE            0x0080
#define TTF_TRANSPARENT         0x0100
#define TTF_PARSELINKS          0x1000
#define TTF_DI_SETITEM          0x8000

#define TTM_ACTIVATE            (WM_USER + 1)
#define TTM_SETDELAYTIME        (WM_USER + 3)
#define TTM_ADDTOOLA            (WM_USER + 4)
#define TTM_ADDTOOLW            (WM_USER + 50)
#define TTM_DELTOOLA            (WM_USER + 5)
#define TTM_DELTOOLW            (WM_USER + 51)
#define TTM_NEWTOOLRECTA        (WM_USER + 6)
#define TTM_NEWTOOLRECTW        (WM_USER + 52)
#define TTM_RELAYEVENT          (WM_USER + 7)
#define TTM_GETTOOLINFOA        (WM_USER + 8)
#define TTM_GETTOOLINFOW        (WM_USER + 53)
#define TTM_SETTOOLINFOA        (WM_USER + 9)
#define TTM_SETTOOLINFOW        (WM_USER + 54)
#define TTM_HITTESTA            (WM_USER + 10)
#define TTM_HITTESTW            (WM_USER + 55)
#define TTM_GETTEXTA            (WM_USER + 11)
#define TTM_GETTEXTW            (WM_USER + 56)
#define TTM_UPDATETIPTEXTA      (WM_USER + 12)
#define TTM_UPDATETIPTEXTW      (WM_USER + 57)
#define TTM_GETTOOLCOUNT        (WM_USER + 13)
#define TTM_ENUMTOOLSA          (WM_USER + 14)
#define TTM_ENUMTOOLSW          (WM_USER + 58)
#define TTM_GETCURRENTTOOLA     (WM_USER + 15)
#define TTM_GETCURRENTTOOLW     (WM_USER + 59)
#define TTM_WINDOWFROMPOINT     (WM_USER + 16)
#define TTM_TRACKACTIVATE       (WM_USER + 17)
#define TTM_TRACKPOSITION       (WM_USER + 18)
#define TTM_SETTIPBKCOLOR       (WM_USER + 19)
#define TTM_SETTIPTEXTCOLOR     (WM_USER + 20)
#define TTM_GETDELAYTIME        (WM_USER + 21)
#define TTM_GETTIPBKCOLOR       (WM_USER + 22)
#define TTM_GETTIPTEXTCOLOR     (WM_USER + 23)
#define TTM_SETMAXTIPWIDTH      (WM_USER + 24)
#define TTM_GETMAXTIPWIDTH      (WM_USER + 25)
#define TTM_SETMARGIN           (WM_USER + 26)
#define TTM_GETMARGIN           (WM_USER + 27)
#define TTM_POP                 (WM_USER + 28)
#define TTM_UPDATE              (WM_USER + 29)

#define TTM_SETTITLEA           (WM_USER + 32)
#define TTM_SETTITLEW           (WM_USER + 33)

#ifdef UNICODE
#define TTM_ADDTOOL             TTM_ADDTOOLW
#define TTM_DELTOOL             TTM_DELTOOLW
#define TTM_NEWTOOLRECT         TTM_NEWTOOLRECTW
#define TTM_GETTOOLINFO         TTM_GETTOOLINFOW
#define TTM_SETTOOLINFO         TTM_SETTOOLINFOW
#define TTM_HITTEST             TTM_HITTESTW
#define TTM_GETTEXT             TTM_GETTEXTW
#define TTM_UPDATETIPTEXT       TTM_UPDATETIPTEXTW
#define TTM_ENUMTOOLS           TTM_ENUMTOOLSW
#define TTM_GETCURRENTTOOL      TTM_GETCURRENTTOOLW
#define TTM_SETTITLE            TTM_SETTITLEW
#else
#define TTM_ADDTOOL             TTM_ADDTOOLA
#define TTM_DELTOOL             TTM_DELTOOLA
#define TTM_NEWTOOLRECT         TTM_NEWTOOLRECTA
#define TTM_GETTOOLINFO         TTM_GETTOOLINFOA
#define TTM_SETTOOLINFO         TTM_SETTOOLINFOA
#define TTM_HITTEST             TTM_HITTESTA
#define TTM_GETTEXT             TTM_GETTEXTA
#define TTM_UPDATETIPTEXT       TTM_UPDATETIPTEXTA
#define TTM_ENUMTOOLS           TTM_ENUMTOOLSA
#define TTM_GETCURRENTTOOL      TTM_GETCURRENTTOOLA
#define TTM_SETTITLE            TTM_SETTITLEA
#endif

#define TTDT_AUTOMATIC          0
#define TTDT_RESHOW             1
#define TTDT_AUTOPOP            2
#define TTDT_INITIAL            3

#define TTN_FIRST               (0U-520U)
#define TTN_GETDISPINFOA        (TTN_FIRST - 0)
#define TTN_GETDISPINFOW        (TTN_FIRST - 10)
#define TTN_SHOW                (TTN_FIRST - 1)
#define TTN_POP                 (TTN_FIRST - 2)
#define TTN_LINKCLICK           (TTN_FIRST - 3)
#define TTN_NEEDTEXTA           TTN_GETDISPINFOA
#define TTN_NEEDTEXTW           TTN_GETDISPINFOW
#ifdef UNICODE
#define TTN_GETDISPINFO TTN_GETDISPINFOW
#define TTN_NEEDTEXT    TTN_NEEDTEXTW
#else
#define TTN_GETDISPINFO TTN_GETDISPINFOA
#define TTN_NEEDTEXT    TTN_NEEDTEXTA
#endif

struct TOOLINFOA {
    UINT cbSize;
    UINT uFlags;
    HWND hwnd;
    UINT_PTR uId;
    RECT rect;
    HINSTANCE hinst;
    LPSTR lpszText;
    LPARAM lParam;
    void *lpReserved;
};
struct TOOLINFOW {
    UINT cbSize;
    UINT uFlags;
    HWND hwnd;
    UINT_PTR uId;
    RECT rect;
    HINSTANCE hinst;
    LPWSTR lpszText;
    LPARAM lParam;
    void *lpReserved;
};
#ifdef UNICODE
typedef TOOLINFOW TOOLINFO;
#else
typedef TOOLINFOA TOOLINFO;
#endif
typedef TOOLINFO* LPTOOLINFO;

#define TTTOOLINFOA_V1_SIZE sizeof(TOOLINFOA)
#define TTTOOLINFOW_V1_SIZE sizeof(TOOLINFOW)
#define TTTOOLINFO_V1_SIZE sizeof(TOOLINFO)

#define TTI_NONE 0
#define TTI_INFO 1
#define TTI_WARNING 2
#define TTI_ERROR 3

struct NMTTDISPINFOA {
    NMHDR hdr;
    LPSTR lpszText;
    char szText[80];
    HINSTANCE hinst;
    UINT uFlags;
    LPARAM lParam;
};
struct NMTTDISPINFOW {
    NMHDR hdr;
    LPWSTR lpszText;
    WCHAR szText[80];
    HINSTANCE hinst;
    UINT uFlags;
    LPARAM lParam;
};
#ifdef UNICODE
typedef NMTTDISPINFOW NMTTDISPINFO;
typedef NMTTDISPINFOW TOOLTIPTEXTW;
typedef NMTTDISPINFOW TOOLTIPTEXT;
#else
typedef NMTTDISPINFOA NMTTDISPINFO;
typedef NMTTDISPINFOA TOOLTIPTEXTA;
typedef NMTTDISPINFOA TOOLTIPTEXT;
#endif
typedef NMTTDISPINFOA TOOLTIPTEXTA;
typedef NMTTDISPINFOW TOOLTIPTEXTW;
typedef NMTTDISPINFO* LPNMTTDISPINFO;
typedef TOOLTIPTEXT* LPTOOLTIPTEXT;

// ComboBoxEx
#define WC_COMBOBOXEXA          "ComboBoxEx32"
#define WC_COMBOBOXEXW          L"ComboBoxEx32"
#ifdef UNICODE
#define WC_COMBOBOXEX           WC_COMBOBOXEXW
#else
#define WC_COMBOBOXEX           WC_COMBOBOXEXA
#endif

#define CBEIF_TEXT              0x00000001
#define CBEIF_IMAGE             0x00000002
#define CBEIF_SELECTEDIMAGE     0x00000004
#define CBEIF_OVERLAY           0x00000008
#define CBEIF_INDENT            0x00000010
#define CBEIF_LPARAM            0x00000020
#define CBEIF_DI_SETITEM        0x10000000

typedef struct tagCOMBOBOXEXITEMA {
    UINT mask;
    INT_PTR iItem;
    LPSTR pszText;
    int cchTextMax;
    int iImage;
    int iSelectedImage;
    int iOverlay;
    int iIndent;
    LPARAM lParam;
} COMBOBOXEXITEMA, *PCOMBOBOXEXITEMA, *LPCOMBOBOXEXITEMA;
typedef const COMBOBOXEXITEMA *LPCCOMBOBOXEXITEMA;

typedef struct tagCOMBOBOXEXITEMW {
    UINT mask;
    INT_PTR iItem;
    LPWSTR pszText;
    int cchTextMax;
    int iImage;
    int iSelectedImage;
    int iOverlay;
    int iIndent;
    LPARAM lParam;
} COMBOBOXEXITEMW, *PCOMBOBOXEXITEMW, *LPCOMBOBOXEXITEMW;
typedef const COMBOBOXEXITEMW *LPCCOMBOBOXEXITEMW;

#ifdef UNICODE
typedef COMBOBOXEXITEMW COMBOBOXEXITEM;
typedef PCOMBOBOXEXITEMW PCOMBOBOXEXITEM;
typedef LPCOMBOBOXEXITEMW LPCOMBOBOXEXITEM;
typedef LPCCOMBOBOXEXITEMW LPCCOMBOBOXEXITEM;
#else
typedef COMBOBOXEXITEMA COMBOBOXEXITEM;
typedef PCOMBOBOXEXITEMA PCOMBOBOXEXITEM;
typedef LPCOMBOBOXEXITEMA LPCOMBOBOXEXITEM;
typedef LPCCOMBOBOXEXITEMA LPCCOMBOBOXEXITEM;
#endif

#define CBEM_INSERTITEMA        (WM_USER + 1)
#define CBEM_SETIMAGELIST       (WM_USER + 2)
#define CBEM_GETIMAGELIST       (WM_USER + 3)
#define CBEM_GETITEMA           (WM_USER + 4)
#define CBEM_SETITEMA           (WM_USER + 5)
#define CBEM_DELETEITEM         CB_DELETESTRING
#define CBEM_GETCOMBOCONTROL    (WM_USER + 6)
#define CBEM_GETEDITCONTROL     (WM_USER + 7)
#define CBEM_SETEXSTYLE         (WM_USER + 8)
#define CBEM_GETEXSTYLE         (WM_USER + 9)
#define CBEM_HASEDITCHANGED     (WM_USER + 10)
#define CBEM_INSERTITEMW        (WM_USER + 11)
#define CBEM_SETITEMW           (WM_USER + 12)
#define CBEM_GETITEMW           (WM_USER + 13)

#ifdef UNICODE
#define CBEM_INSERTITEM         CBEM_INSERTITEMW
#define CBEM_SETITEM            CBEM_SETITEMW
#define CBEM_GETITEM            CBEM_GETITEMW
#else
#define CBEM_INSERTITEM         CBEM_INSERTITEMA
#define CBEM_SETITEM            CBEM_SETITEMA
#define CBEM_GETITEM            CBEM_GETITEMA
#endif

// ImageList
#define ILC_MASK                0x00000001
#define ILC_COLOR               0x00000000
#define ILC_COLORDDB            0x000000FE
#define ILC_COLOR4              0x00000004
#define ILC_COLOR8              0x00000008
#define ILC_COLOR16             0x00000010
#define ILC_COLOR24             0x00000018
#define ILC_COLOR32             0x00000020
#define ILD_NORMAL              0x00000000
#define ILD_TRANSPARENT         0x00000001
#define ILD_MASK                0x00000010
#define ILD_IMAGE               0x00000020
#define ILD_BLEND25             0x00000002
#define ILD_BLEND50             0x00000004
#define ILD_OVERLAYMASK         0x00000F00
#define ILD_SELECTED            ILD_BLEND50
#define ILD_FOCUS               ILD_BLEND25
#define ILD_BLEND               ILD_BLEND50
#define CLR_NONE                0xFFFFFFFFL
#define CLR_DEFAULT             0xFF000000L

struct IMAGEINFO {
    HBITMAP hbmImage;
    HBITMAP hbmMask;
    int Unused1;
    int Unused2;
    RECT rcImage;
};
typedef IMAGEINFO* LPIMAGEINFO;

// Common Dialogs (OPENFILENAME, CHOOSECOLOR, CHOOSEFONT, PROPSHEETHEADER)
#define OFN_READONLY                 0x00000001
#define OFN_OVERWRITEPROMPT          0x00000002
#define OFN_HIDEREADONLY             0x00000004
#define OFN_NOCHANGEDIR              0x00000008
#define OFN_SHOWHELP                 0x00000010
#define OFN_ENABLEHOOK               0x00000020
#define OFN_ENABLETEMPLATE           0x00000040
#define OFN_ENABLETEMPLATEHANDLE     0x00000080
#define OFN_NOVALIDATE               0x00000100
#define OFN_ALLOWMULTISELECT         0x00000200
#define OFN_EXTENSIONDIFFERENT       0x00000400
#define OFN_PATHMUSTEXIST            0x00000800
#define OFN_FILEMUSTEXIST            0x00001000
#define OFN_CREATEPROMPT             0x00002000
#define OFN_SHAREAWARE               0x00004000
#define OFN_NOREADONLYRETURN         0x00008000
#define OFN_NOTESTFILECREATE         0x00010000
#define OFN_NONETWORKBUTTON          0x00020000
#define OFN_NOLONGNAMES              0x00040000
#define OFN_EXPLORER                 0x00080000
#define OFN_NODEREFERENCELINKS       0x00100000
#define OFN_LONGNAMES                0x00200000
#define OFN_ENABLEINCLUDENOTIFY      0x00400000
#define OFN_ENABLESIZING             0x00800000
#define OFN_DONTADDTORECENT          0x02000000
#define OFN_FORCESHOWHIDDEN          0x10000000

struct OPENFILENAMEA {
    DWORD lStructSize;
    HWND hwndOwner;
    HINSTANCE hInstance;
    LPCSTR lpstrFilter;
    LPSTR lpstrCustomFilter;
    DWORD nMaxCustFilter;
    DWORD nFilterIndex;
    LPSTR lpstrFile;
    DWORD nMaxFile;
    LPSTR lpstrFileTitle;
    DWORD nMaxFileTitle;
    LPCSTR lpstrInitialDir;
    LPCSTR lpstrTitle;
    DWORD Flags;
    WORD nFileOffset;
    WORD nFileExtension;
    LPCSTR lpstrDefExt;
    LPARAM lCustData;
    LPVOID lpfnHook;
    LPCSTR lpTemplateName;
    void* pvReserved;
    DWORD dwReserved;
    DWORD FlagsEx;
};
struct OPENFILENAMEW {
    DWORD lStructSize;
    HWND hwndOwner;
    HINSTANCE hInstance;
    LPCWSTR lpstrFilter;
    LPWSTR lpstrCustomFilter;
    DWORD nMaxCustFilter;
    DWORD nFilterIndex;
    LPWSTR lpstrFile;
    DWORD nMaxFile;
    LPWSTR lpstrFileTitle;
    DWORD nMaxFileTitle;
    LPCWSTR lpstrInitialDir;
    LPCWSTR lpstrTitle;
    DWORD Flags;
    WORD nFileOffset;
    WORD nFileExtension;
    LPCWSTR lpstrDefExt;
    LPARAM lCustData;
    LPVOID lpfnHook;
    LPCWSTR lpTemplateName;
    void* pvReserved;
    DWORD dwReserved;
    DWORD FlagsEx;
};
typedef OPENFILENAMEA* LPOPENFILENAMEA;
typedef OPENFILENAMEW* LPOPENFILENAMEW;
#ifdef UNICODE
typedef OPENFILENAMEW OPENFILENAME;
typedef LPOPENFILENAMEW LPOPENFILENAME;
#else
typedef OPENFILENAMEA OPENFILENAME;
typedef LPOPENFILENAMEA LPOPENFILENAME;
#endif

#define CC_RGBINIT              0x00000001
#define CC_FULLOPEN             0x00000002
#define CC_PREVENTFULLOPEN      0x00000004
#define CC_SHOWHELP             0x00000008
#define CC_ENABLEHOOK           0x00000010
#define CC_ENABLETEMPLATE       0x00000020
#define CC_ENABLETEMPLATEHANDLE 0x00000040
#define CC_SOLIDCOLOR           0x00000080
#define CC_ANYCOLOR             0x00000100

struct CHOOSECOLORA {
    DWORD lStructSize;
    HWND hwndOwner;
    HWND hInstance;
    COLORREF rgbResult;
    COLORREF *lpCustColors;
    DWORD Flags;
    LPARAM lCustData;
    LPVOID lpfnHook;
    LPCSTR lpTemplateName;
};
struct CHOOSECOLORW {
    DWORD lStructSize;
    HWND hwndOwner;
    HWND hInstance;
    COLORREF rgbResult;
    COLORREF *lpCustColors;
    DWORD Flags;
    LPARAM lCustData;
    LPVOID lpfnHook;
    LPCWSTR lpTemplateName;
};
typedef CHOOSECOLORA* LPCHOOSECOLORA;
typedef CHOOSECOLORW* LPCHOOSECOLORW;
#ifdef UNICODE
typedef CHOOSECOLORW CHOOSECOLOR;
typedef LPCHOOSECOLORW LPCHOOSECOLOR;
#else
typedef CHOOSECOLORA CHOOSECOLOR;
typedef LPCHOOSECOLORA LPCHOOSECOLOR;
#endif

#define CF_SCREENFONTS          0x00000001
#define CF_PRINTERFONTS         0x00000002
#define CF_BOTH                 (CF_SCREENFONTS | CF_PRINTERFONTS)
#define CF_SHOWHELP             0x00000004L
#define CF_ENABLEHOOK           0x00000008L
#define CF_ENABLETEMPLATE       0x00000010L
#define CF_ENABLETEMPLATEHANDLE 0x00000020L
#define CF_INITTOLOGFONTSTRUCT  0x00000040L
#define CF_USESTYLE             0x00000080L
#define CF_EFFECTS              0x00000100L
#define CF_APPLY                0x00000200L
#define CF_ANSIONLY             0x00000400L
#define CF_SCRIPTSONLY          CF_ANSIONLY
#define CF_NOVECTORFONTS        0x00000800L
#define CF_NOOEMFONTS           CF_NOVECTORFONTS
#define CF_NOSIMULATIONS        0x00001000L
#define CF_LIMITSIZE            0x00002000L
#define CF_FIXEDPITCHONLY       0x00004000L
#define CF_WYSIWYG              0x00008000L
#define CF_FORCEFONTEXIST       0x00010000L
#define CF_SCALABLEONLY         0x00020000L
#define CF_TTONLY               0x00040000L
#define CF_NOFACESEL            0x00080000L
#define CF_NOSTYLESEL           0x00100000L
#define CF_NOSIZESEL            0x00200000L
#define CF_NOSCRIPTSEL          0x00800000L
#define CF_NOVERTFONTS          0x01000000L

struct CHOOSEFONTA {
    DWORD lStructSize;
    HWND hwndOwner;
    HDC hDC;
    LOGFONTA* lpLogFont;
    INT iPointSize;
    DWORD Flags;
    COLORREF rgbColors;
    LPARAM lCustData;
    LPVOID lpfnHook;
    LPCSTR lpTemplateName;
    HINSTANCE hInstance;
    LPSTR lpszStyle;
    WORD nFontType;
    WORD ___MISSING_ALIGNMENT__;
    INT nSizeMin;
    INT nSizeMax;
};
struct CHOOSEFONTW {
    DWORD lStructSize;
    HWND hwndOwner;
    HDC hDC;
    LOGFONTW* lpLogFont;
    INT iPointSize;
    DWORD Flags;
    COLORREF rgbColors;
    LPARAM lCustData;
    LPVOID lpfnHook;
    LPCWSTR lpTemplateName;
    HINSTANCE hInstance;
    LPWSTR lpszStyle;
    WORD nFontType;
    WORD ___MISSING_ALIGNMENT__;
    INT nSizeMin;
    INT nSizeMax;
};
#ifdef UNICODE
typedef CHOOSEFONTW CHOOSEFONT;
#else
typedef CHOOSEFONTA CHOOSEFONT;
#endif
typedef CHOOSEFONT* LPCHOOSEFONT;

// PropertySheet
#define PSH_DEFAULT             0x00000000
#define PSH_PROPTITLE           0x00000001
#define PSH_USEHICON            0x00000002
#define PSH_USEICONID           0x00000004
#define PSH_PROPSHEETPAGE       0x00000008
#define PSH_WIZARDHASFINISH     0x00000010
#define PSH_WIZARD              0x00000020
#define PSH_USEPSTARTPAGE       0x00000040
#define PSH_NOAPPLYNOW          0x00000080
#define PSH_USECALLBACK         0x00000100
#define PSH_HASHELP             0x00000200
#define PSH_MODELESS            0x00000400
#define PSH_RTLREADING          0x00000800
#define PSH_WIZARDCONTEXTHELP   0x00001000
#define PSH_AEROWIZARD          0x00004000
#define PSH_NOCONTEXTHELP       0x02000000

#define PSP_DEFAULT             0x00000000
#define PSP_DLGINDIRECT         0x00000001
#define PSP_USEHICON            0x00000002
#define PSP_USEICONID           0x00000004
#define PSP_USETITLE            0x00000008
#define PSP_RTLREADING          0x00000010
#define PSP_HASHELP             0x00000020
#define PSP_USEREFPARENT        0x00000040
#define PSP_USECALLBACK         0x00000080
#define PSP_PREMATURE           0x00000400

#define PSBTN_BACK              0
#define PSBTN_NEXT              1
#define PSBTN_FINISH            2
#define PSBTN_OK                3
#define PSBTN_APPLYNOW          4
#define PSBTN_CANCEL            5
#define PSBTN_HELP              6

struct PROPSHEETPAGEA {
    DWORD dwSize;
    DWORD dwFlags;
    HINSTANCE hInstance;
    LPCSTR pszTemplate;
    HICON hIcon;
    LPCSTR pszTitle;
    DLGPROC pfnDlgProc;
    LPARAM lParam;
    LPVOID pfnCallback;
    UINT *pcRefParent;
    LPCSTR pszHeaderTitle;
    LPCSTR pszHeaderSubTitle;
};
struct PROPSHEETPAGEW {
    DWORD dwSize;
    DWORD dwFlags;
    HINSTANCE hInstance;
    LPCWSTR pszTemplate;
    HICON hIcon;
    LPCWSTR pszTitle;
    DLGPROC pfnDlgProc;
    LPARAM lParam;
    LPVOID pfnCallback;
    UINT *pcRefParent;
    LPCWSTR pszHeaderTitle;
    LPCWSTR pszHeaderSubTitle;
};
#ifdef UNICODE
typedef PROPSHEETPAGEW PROPSHEETPAGE;
#else
typedef PROPSHEETPAGEA PROPSHEETPAGE;
#endif

struct PROPSHEETHEADERA {
    DWORD dwSize;
    DWORD dwFlags;
    HWND hwndParent;
    HINSTANCE hInstance;
    HICON hIcon;
    LPCSTR pszCaption;
    UINT nPages;
    UINT nStartPage;
    const PROPSHEETPAGEA* ppsp;
    LPVOID pfnCallback;
};
struct PROPSHEETHEADERW {
    DWORD dwSize;
    DWORD dwFlags;
    HWND hwndParent;
    HINSTANCE hInstance;
    HICON hIcon;
    LPCWSTR pszCaption;
    UINT nPages;
    UINT nStartPage;
    const PROPSHEETPAGEW* ppsp;
    LPVOID pfnCallback;
};
#ifdef UNICODE
typedef PROPSHEETHEADERW PROPSHEETHEADER;
#else
typedef PROPSHEETHEADERA PROPSHEETHEADER;
#endif

// Shell Constants & Structs
#define CSIDL_PERSONAL                  0x0005
#define CSIDL_MYDOCUMENTS               0x0005
#define CSIDL_APPDATA                   0x001a
#define CSIDL_LOCAL_APPDATA             0x001c
#define CSIDL_COMMON_APPDATA            0x0023
#define CSIDL_WINDOWS                   0x0024
#define CSIDL_SYSTEM                    0x0025
#define CSIDL_PROGRAM_FILES             0x0026
#define CSIDL_MYPICTURES                0x0027
#define CSIDL_PROFILE                   0x0028
#define CSIDL_SYSTEMX86                 0x0029
#define CSIDL_PROGRAM_FILESX86          0x002a
#define CSIDL_COMMON_DOCUMENTS          0x002e
#define CSIDL_MYMUSIC                   0x000d
#define CSIDL_FLAG_CREATE               0x8000
#define SHGFP_TYPE_CURRENT              0
#define SHGFP_TYPE_DEFAULT              1

#define FO_MOVE                    0x0001
#define FO_COPY                    0x0002
#define FO_DELETE                  0x0003
#define FO_RENAME                  0x0004
#define FOF_MULTIDESTFILES         0x0001
#define FOF_CONFIRMMOUSE           0x0002
#define FOF_SILENT                 0x0004
#define FOF_RENAMEONCOLLISION      0x0008
#define FOF_NOCONFIRMATION         0x0010
#define FOF_WANTMAPPINGHANDLE      0x0020
#define FOF_ALLOWUNDO              0x0040
#define FOF_FILESONLY              0x0080
#define FOF_SIMPLEPROGRESS         0x0100
#define FOF_NOCONFIRMMKDIR         0x0200
#define FOF_NOERRORUI              0x0400
#define FOF_NOCOPYSECURITYATTRIBS  0x0800
#define FOF_NORECURSION            0x1000
#define FOF_NO_UI                  (FOF_SILENT | FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_NOCONFIRMMKDIR)

struct SHFILEOPSTRUCTA {
    HWND hwnd;
    UINT wFunc;
    LPCSTR pFrom;
    LPCSTR pTo;
    WORD fFlags;
    BOOL fAnyOperationsAborted;
    LPVOID hNameMappings;
    LPCSTR lpszProgressTitle;
};
struct SHFILEOPSTRUCTW {
    HWND hwnd;
    UINT wFunc;
    LPCWSTR pFrom;
    LPCWSTR pTo;
    WORD fFlags;
    BOOL fAnyOperationsAborted;
    LPVOID hNameMappings;
    LPCWSTR lpszProgressTitle;
};
typedef SHFILEOPSTRUCTA* LPSHFILEOPSTRUCTA;
typedef SHFILEOPSTRUCTW* LPSHFILEOPSTRUCTW;
#ifdef UNICODE
typedef SHFILEOPSTRUCTW SHFILEOPSTRUCT;
typedef LPSHFILEOPSTRUCTW LPSHFILEOPSTRUCT;
#else
typedef SHFILEOPSTRUCTA SHFILEOPSTRUCT;
typedef LPSHFILEOPSTRUCTA LPSHFILEOPSTRUCT;
#endif

#define SHGFI_ICON              0x000000100
#define SHGFI_DISPLAYNAME       0x000000200
#define SHGFI_TYPENAME          0x000000400
#define SHGFI_ATTRIBUTES        0x000000800
#define SHGFI_ICONLOCATION      0x000001000
#define SHGFI_EXETYPE           0x000002000
#define SHGFI_SYSICONINDEX      0x000004000
#define SHGFI_LINKOVERLAY       0x000008000
#define SHGFI_SELECTED          0x000010000
#define SHGFI_ATTR_SPECIFIED    0x000020000
#define SHGFI_LARGEICON         0x000000000
#define SHGFI_SMALLICON         0x000000001
#define SHGFI_OPENICON          0x000000002
#define SHGFI_SHELLICONSIZE     0x000000004
#define SHGFI_PIDL              0x000000008
#define SHGFI_USEFILEATTRIBUTES 0x000000010
#define SFGAO_LINK              0x00010000L
#define SFGAO_FOLDER            0x20000000L
#define SFGAO_FILESYSTEM        0x40000000L

struct SHFILEINFOA {
    HICON hIcon;
    int iIcon;
    DWORD dwAttributes;
    CHAR szDisplayName[MAX_PATH];
    CHAR szTypeName[80];
};
struct SHFILEINFOW {
    HICON hIcon;
    int iIcon;
    DWORD dwAttributes;
    WCHAR szDisplayName[MAX_PATH];
    WCHAR szTypeName[80];
};
#ifdef UNICODE
typedef SHFILEINFOW SHFILEINFO;
#else
typedef SHFILEINFOA SHFILEINFO;
#endif

struct ITEMIDLIST {
    USHORT cb;
};
typedef ITEMIDLIST* LPITEMIDLIST;
typedef const ITEMIDLIST* LPCITEMIDLIST;

typedef int (CALLBACK* BFFCALLBACK)(HWND hwnd, UINT uMsg, LPARAM lParam, LPARAM lpData);
struct BROWSEINFOA {
    HWND hwndOwner;
    LPCITEMIDLIST pidlRoot;
    LPSTR pszDisplayName;
    LPCSTR lpszTitle;
    UINT ulFlags;
    BFFCALLBACK lpfn;
    LPARAM lParam;
    int iImage;
};
struct BROWSEINFOW {
    HWND hwndOwner;
    LPCITEMIDLIST pidlRoot;
    LPWSTR pszDisplayName;
    LPCWSTR lpszTitle;
    UINT ulFlags;
    BFFCALLBACK lpfn;
    LPARAM lParam;
    int iImage;
};
typedef BROWSEINFOA* LPBROWSEINFOA;
typedef BROWSEINFOW* LPBROWSEINFOW;
#ifdef UNICODE
typedef BROWSEINFOW BROWSEINFO;
typedef LPBROWSEINFOW LPBROWSEINFO;
#else
typedef BROWSEINFOA BROWSEINFO;
typedef LPBROWSEINFOA LPBROWSEINFO;
#endif

#define BIF_RETURNONLYFSDIRS    0x00000001
#define BIF_DONTGOBELOWDOMAIN   0x00000002
#define BIF_STATUSTEXT          0x00000004
#define BIF_RETURNFSANCESTORS   0x00000008
#define BIF_EDITBOX             0x00000010
#define BIF_VALIDATE            0x00000020
#define BIF_NEWDIALOGSTYLE      0x00000040
#define BIF_USENEWUI            (BIF_NEWDIALOGSTYLE | BIF_EDITBOX)
#define BFFM_INITIALIZED        1
#define BFFM_SELCHANGED         2
#define BFFM_VALIDATEFAILEDA    3
#define BFFM_VALIDATEFAILEDW    4
#define BFFM_SETSTATUSTEXTA     (WM_USER + 100)
#define BFFM_ENABLEOK           (WM_USER + 101)
#define BFFM_SETSELECTIONA      (WM_USER + 102)
#define BFFM_SETSELECTIONW      (WM_USER + 103)
#define BFFM_SETSTATUSTEXTW     (WM_USER + 104)
#ifdef UNICODE
#define BFFM_SETSELECTION       BFFM_SETSELECTIONW
#define BFFM_VALIDATEFAILED     BFFM_VALIDATEFAILEDW
#else
#define BFFM_SETSELECTION       BFFM_SETSELECTIONA
#define BFFM_VALIDATEFAILED     BFFM_VALIDATEFAILEDA
#endif

// Input / Keyboard structs
struct KEYBDINPUT {
    WORD wVk;
    WORD wScan;
    DWORD dwFlags;
    DWORD time;
    ULONG_PTR dwExtraInfo;
};
struct MOUSEINPUT {
    LONG dx;
    LONG dy;
    DWORD mouseData;
    DWORD dwFlags;
    DWORD time;
    ULONG_PTR dwExtraInfo;
};
struct HARDWAREINPUT {
    DWORD uMsg;
    WORD wParamL;
    WORD wParamH;
};
struct INPUT {
    DWORD type;
    union {
        MOUSEINPUT mi;
        KEYBDINPUT ki;
        HARDWAREINPUT hi;
    };
};
typedef INPUT* LPINPUT;
#define INPUT_MOUSE     0
#define INPUT_KEYBOARD  1
#define INPUT_HARDWARE  2
#define KEYEVENTF_EXTENDEDKEY 0x0001
#define KEYEVENTF_KEYUP       0x0002
#define KEYEVENTF_UNICODE     0x0004
#define KEYEVENTF_SCANCODE    0x0008

struct HKL__; typedef HKL__* HKL;

// Inline geometry helpers
inline int MulDiv(int nNumber, int nNumerator, int nDenominator) {
    if (nDenominator == 0) return -1;
    int64_t res = (int64_t)nNumber * (int64_t)nNumerator;
    if (res >= 0) return (int)((res + nDenominator / 2) / nDenominator);
    else return (int)((res - nDenominator / 2) / nDenominator);
}

inline BOOL SetRect(LPRECT lprc, int xLeft, int yTop, int xRight, int yBottom) {
    if (!lprc) return FALSE;
    lprc->left = xLeft; lprc->top = yTop; lprc->right = xRight; lprc->bottom = yBottom;
    return TRUE;
}
inline BOOL SetRectEmpty(LPRECT lprc) {
    if (!lprc) return FALSE;
    lprc->left = lprc->top = lprc->right = lprc->bottom = 0;
    return TRUE;
}
inline BOOL CopyRect(LPRECT lprcDst, LPCRECT lprcSrc) {
    if (!lprcDst || !lprcSrc) return FALSE;
    *lprcDst = *lprcSrc;
    return TRUE;
}
inline BOOL InflateRect(LPRECT lprc, int dx, int dy) {
    if (!lprc) return FALSE;
    lprc->left -= dx; lprc->top -= dy; lprc->right += dx; lprc->bottom += dy;
    return TRUE;
}
inline BOOL OffsetRect(LPRECT lprc, int dx, int dy) {
    if (!lprc) return FALSE;
    lprc->left += dx; lprc->top += dy; lprc->right += dx; lprc->bottom += dy;
    return TRUE;
}
inline BOOL IsRectEmpty(LPCRECT lprc) {
    if (!lprc) return TRUE;
    return (lprc->left >= lprc->right) || (lprc->top >= lprc->bottom);
}
inline BOOL PtInRect(LPCRECT lprc, POINT pt) {
    if (!lprc) return FALSE;
    return (pt.x >= lprc->left && pt.x < lprc->right && pt.y >= lprc->top && pt.y < lprc->bottom);
}
inline BOOL IntersectRect(LPRECT lprcDst, LPCRECT lprcSrc1, LPCRECT lprcSrc2) {
    if (!lprcDst || !lprcSrc1 || !lprcSrc2) return FALSE;
    lprcDst->left = std::max(lprcSrc1->left, lprcSrc2->left);
    lprcDst->top = std::max(lprcSrc1->top, lprcSrc2->top);
    lprcDst->right = std::min(lprcSrc1->right, lprcSrc2->right);
    lprcDst->bottom = std::min(lprcSrc1->bottom, lprcSrc2->bottom);
    if (IsRectEmpty(lprcDst)) { SetRectEmpty(lprcDst); return FALSE; }
    return TRUE;
}
inline BOOL UnionRect(LPRECT lprcDst, LPCRECT lprcSrc1, LPCRECT lprcSrc2) {
    if (!lprcDst || !lprcSrc1 || !lprcSrc2) return FALSE;
    bool e1 = IsRectEmpty(lprcSrc1), e2 = IsRectEmpty(lprcSrc2);
    if (e1 && e2) { SetRectEmpty(lprcDst); return FALSE; }
    if (e1) { *lprcDst = *lprcSrc2; return TRUE; }
    if (e2) { *lprcDst = *lprcSrc1; return TRUE; }
    lprcDst->left = std::min(lprcSrc1->left, lprcSrc2->left);
    lprcDst->top = std::min(lprcSrc1->top, lprcSrc2->top);
    lprcDst->right = std::max(lprcSrc1->right, lprcSrc2->right);
    lprcDst->bottom = std::max(lprcSrc1->bottom, lprcSrc2->bottom);
    return TRUE;
}
inline BOOL EqualRect(LPCRECT lprc1, LPCRECT lprc2) {
    if (!lprc1 || !lprc2) return FALSE;
    return lprc1->left == lprc2->left && lprc1->top == lprc2->top &&
           lprc1->right == lprc2->right && lprc1->bottom == lprc2->bottom;
}
inline BOOL SubtractRect(LPRECT lprcDst, LPCRECT lprcSrc1, LPCRECT lprcSrc2) {
    if (!lprcDst || !lprcSrc1) return FALSE;
    if (!lprcSrc2 || IsRectEmpty(lprcSrc2)) {
        *lprcDst = *lprcSrc1;
        return !IsRectEmpty(lprcDst);
    }
    RECT rI;
    if (!IntersectRect(&rI, lprcSrc1, lprcSrc2)) {
        *lprcDst = *lprcSrc1;
        return TRUE;
    }
    if (EqualRect(&rI, lprcSrc1)) {
        SetRectEmpty(lprcDst);
        return FALSE;
    }
    *lprcDst = *lprcSrc1;
    if (rI.top == lprcSrc1->top && rI.bottom == lprcSrc1->bottom) {
        if (rI.left == lprcSrc1->left) lprcDst->left = rI.right;
        else if (rI.right == lprcSrc1->right) lprcDst->right = rI.left;
    } else if (rI.left == lprcSrc1->left && rI.right == lprcSrc1->right) {
        if (rI.top == lprcSrc1->top) lprcDst->top = rI.bottom;
        else if (rI.bottom == lprcSrc1->bottom) lprcDst->bottom = rI.top;
    }
    return !IsRectEmpty(lprcDst);
}

// Atomic / Interlocked functions
inline LONG InterlockedExchange(volatile LONG* Target, LONG Value) {
    return __atomic_exchange_n(Target, Value, __ATOMIC_SEQ_CST);
}
inline LONG InterlockedExchangeAdd(volatile LONG* Addend, LONG Value) {
    return __atomic_fetch_add(Addend, Value, __ATOMIC_SEQ_CST);
}
inline LONG InterlockedAdd(volatile LONG* Addend, LONG Value) {
    return __atomic_add_fetch(Addend, Value, __ATOMIC_SEQ_CST);
}
inline LONG InterlockedCompareExchange(volatile LONG* Destination, LONG Exchange, LONG Comperand) {
    __atomic_compare_exchange_n(Destination, &Comperand, Exchange, false, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    return Comperand;
}
inline LONG InterlockedIncrement(volatile LONG* Addend) {
    return __atomic_add_fetch(Addend, 1, __ATOMIC_SEQ_CST);
}
inline LONG InterlockedDecrement(volatile LONG* Addend) {
    return __atomic_sub_fetch(Addend, 1, __ATOMIC_SEQ_CST);
}
inline LONG _InterlockedExchange(volatile LONG* target, LONG val) {
    return InterlockedExchange(target, val);
}
inline LONG _InterlockedExchangeAdd(volatile LONG* target, LONG val) {
    return InterlockedExchangeAdd(target, val);
}
inline LONG _InterlockedCompareExchange(volatile LONG* target, LONG val, LONG comperand) {
    return InterlockedCompareExchange(target, val, comperand);
}

inline errno_t _fcvt_s(char* buffer, size_t sizeInBytes, double value, int count, int* dec, int* sign) {
    if (!buffer || sizeInBytes == 0 || !dec || !sign) return EINVAL;
    *sign = (value < 0.0) ? 1 : 0;
    if (value < 0.0) value = -value;
    char fmt[32];
    snprintf(fmt, sizeof(fmt), "%%.%df", count >= 0 ? count : 0);
    char tmp[128];
    snprintf(tmp, sizeof(tmp), fmt, value);
    char* dot = strchr(tmp, '.');
    if (dot) {
        *dec = (int)(dot - tmp);
        memmove(dot, dot + 1, strlen(dot));
    } else {
        *dec = (int)strlen(tmp);
    }
    size_t len = strlen(tmp);
    if (len >= sizeInBytes) len = sizeInBytes - 1;
    memcpy(buffer, tmp, len);
    buffer[len] = '\0';
    return 0;
}

template <size_t size>
inline errno_t _fcvt_s(char (&buffer)[size], double value, int count, int* dec, int* sign) {
    return _fcvt_s(buffer, size, value, count, dec, sign);
}

inline errno_t _ecvt_s(char* buffer, size_t sizeInBytes, double value, int count, int* dec, int* sign) {
    if (!buffer || sizeInBytes == 0 || !dec || !sign) return EINVAL;
    *sign = (value < 0.0) ? 1 : 0;
    if (value < 0.0) value = -value;
    double d = value;
    int exponent = 0;
    if (d > 0.0) {
        exponent = (int)floor(log10(d)) + 1;
    }
    *dec = exponent;
    char ffmt[32];
    snprintf(ffmt, sizeof(ffmt), "%%.%df", std::max(0, count - exponent));
    char tmp[128];
    snprintf(tmp, sizeof(tmp), ffmt, value);
    char* dot = strchr(tmp, '.');
    if (dot) memmove(dot, dot + 1, strlen(dot));
    size_t len = strlen(tmp);
    if ((int)len > count) len = (size_t)count;
    if (len >= sizeInBytes) len = sizeInBytes - 1;
    memcpy(buffer, tmp, len);
    buffer[len] = '\0';
    return 0;
}

template <size_t size>
inline errno_t _ecvt_s(char (&buffer)[size], double value, int count, int* dec, int* sign) {
    return _ecvt_s(buffer, size, value, count, dec, sign);
}

// Win32 API Declarations (implemented in MacWin32Afx.mm)
int WINAPI MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr, int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar);
int WINAPI WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar);

int WINAPI lstrlenA(LPCSTR lpString);
int WINAPI lstrlenW(LPCWSTR lpString);
LPSTR WINAPI lstrcpyA(LPSTR lpString1, LPCSTR lpString2);
LPWSTR WINAPI lstrcpyW(LPWSTR lpString1, LPCWSTR lpString2);
LPSTR WINAPI lstrcatA(LPSTR lpString1, LPCSTR lpString2);
LPWSTR WINAPI lstrcatW(LPWSTR lpString1, LPCWSTR lpString2);
int WINAPI lstrcmpA(LPCSTR lpString1, LPCSTR lpString2);
int WINAPI lstrcmpW(LPCWSTR lpString1, LPCWSTR lpString2);
int WINAPI lstrcmpiA(LPCSTR lpString1, LPCSTR lpString2);
int WINAPI lstrcmpiW(LPCWSTR lpString1, LPCWSTR lpString2);
LPSTR WINAPI lstrcpynA(LPSTR lpString1, LPCSTR lpString2, int iMaxLength);
LPWSTR WINAPI lstrcpynW(LPWSTR lpString1, LPCWSTR lpString2, int iMaxLength);

#ifdef UNICODE
#define lstrlen lstrlenW
#define lstrcpy lstrcpyW
#define lstrcat lstrcatW
#define lstrcpyn lstrcpynW
#else
#define lstrlen lstrlenA
#define lstrcpy lstrcpyA
#define lstrcat lstrcatA
#define lstrcpyn lstrcpynA
#endif

inline int lstrcmp(LPCSTR s1, LPCSTR s2) { return lstrcmpA(s1, s2); }
inline int lstrcmp(LPCWSTR s1, LPCWSTR s2) { return lstrcmpW(s1, s2); }
inline int lstrcmpi(LPCSTR s1, LPCSTR s2) { return lstrcmpiA(s1, s2); }
inline int lstrcmpi(LPCWSTR s1, LPCWSTR s2) { return lstrcmpiW(s1, s2); }

DWORD WINAPI GetLastError();
void WINAPI SetLastError(DWORD dwErrCode);
DWORD WINAPI GetCurrentThreadId();
HANDLE WINAPI GetCurrentThread();
BOOL WINAPI SetThreadPriority(HANDLE hThread, int nPriority);
DWORD WINAPI GetCurrentProcessId();
HANDLE WINAPI GetCurrentProcess();
void WINAPI Sleep(DWORD dwMilliseconds);
void WINAPI ExitProcess(UINT uExitCode);
BOOL WINAPI IsDebuggerPresent();
void WINAPI DebugBreak();
void WINAPI OutputDebugStringA(LPCSTR lpOutputString);
void WINAPI OutputDebugStringW(LPCWSTR lpOutputString);
#ifdef UNICODE
#define OutputDebugString OutputDebugStringW
#else
#define OutputDebugString OutputDebugStringA
#endif
UINT WINAPI SetErrorMode(UINT uMode);
UINT WINAPI GetErrorMode();
LPTOP_LEVEL_EXCEPTION_FILTER WINAPI SetUnhandledExceptionFilter(LPTOP_LEVEL_EXCEPTION_FILTER lpTopLevelExceptionFilter);
LPEXCEPTION_POINTERS GetExceptionInformation();
DWORD GetExceptionCode();

BOOL WINAPI QueryPerformanceCounter(LARGE_INTEGER *lpPerformanceCount);
BOOL WINAPI QueryPerformanceFrequency(LARGE_INTEGER *lpFrequency);
DWORD WINAPI GetTickCount();
ULONGLONG WINAPI GetTickCount64();
void WINAPI GetSystemTimeAsFileTime(LPFILETIME lpSystemTimeAsFileTime);
BOOL WINAPI FileTimeToSystemTime(const FILETIME *lpFileTime, LPSYSTEMTIME lpSystemTime);
BOOL WINAPI SystemTimeToFileTime(const SYSTEMTIME *lpSystemTime, LPFILETIME lpFileTime);
void WINAPI GetSystemInfo(LPSYSTEM_INFO lpSystemInfo);
void WINAPI GetNativeSystemInfo(LPSYSTEM_INFO lpSystemInfo);
BOOL WINAPI GlobalMemoryStatusEx(LPMEMORYSTATUSEX lpBuffer);

DWORD WINAPI FormatMessageA(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPSTR lpBuffer, DWORD nSize, va_list *Arguments);
DWORD WINAPI FormatMessageW(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPWSTR lpBuffer, DWORD nSize, va_list *Arguments);
#ifdef UNICODE
#define FormatMessage FormatMessageW
#else
#define FormatMessage FormatMessageA
#endif

// Global Memory & Clipboard
HGLOBAL WINAPI GlobalAlloc(UINT uFlags, SIZE_T dwBytes);
HGLOBAL WINAPI GlobalFree(HGLOBAL hMem);
LPVOID WINAPI GlobalLock(HGLOBAL hMem);
BOOL WINAPI GlobalUnlock(HGLOBAL hMem);
SIZE_T WINAPI GlobalSize(HGLOBAL hMem);
HLOCAL WINAPI LocalFree(HLOCAL hMem);

BOOL WINAPI OpenClipboard(HWND hWndNewOwner);
BOOL WINAPI CloseClipboard();
BOOL WINAPI EmptyClipboard();
HANDLE WINAPI SetClipboardData(UINT uFormat, HANDLE hMem);
HANDLE WINAPI GetClipboardData(UINT uFormat);
BOOL WINAPI IsClipboardFormatAvailable(UINT format);
UINT WINAPI RegisterClipboardFormatA(LPCSTR lpszFormat);
UINT WINAPI RegisterClipboardFormatW(LPCWSTR lpszFormat);
#ifdef UNICODE
#define RegisterClipboardFormat RegisterClipboardFormatW
#else
#define RegisterClipboardFormat RegisterClipboardFormatA
#endif

// File System & Paths
DWORD WINAPI GetFileAttributesA(LPCSTR lpFileName);
DWORD WINAPI GetFileAttributesW(LPCWSTR lpFileName);
BOOL WINAPI CreateDirectoryA(LPCSTR lpPathName, LPSECURITY_ATTRIBUTES lpSecurityAttributes);
BOOL WINAPI CreateDirectoryW(LPCWSTR lpPathName, LPSECURITY_ATTRIBUTES lpSecurityAttributes);
BOOL WINAPI RemoveDirectoryA(LPCSTR lpPathName);
BOOL WINAPI RemoveDirectoryW(LPCWSTR lpPathName);
BOOL WINAPI DeleteFileA(LPCSTR lpFileName);
BOOL WINAPI DeleteFileW(LPCWSTR lpFileName);
BOOL WINAPI CopyFileA(LPCSTR lpExistingFileName, LPCSTR lpNewFileName, BOOL bFailIfExists);
BOOL WINAPI CopyFileW(LPCWSTR lpExistingFileName, LPCWSTR lpNewFileName, BOOL bFailIfExists);
BOOL WINAPI MoveFileA(LPCSTR lpExistingFileName, LPCSTR lpNewFileName);
BOOL WINAPI MoveFileW(LPCWSTR lpExistingFileName, LPCWSTR lpNewFileName);
DWORD WINAPI GetFullPathNameA(LPCSTR lpFileName, DWORD nBufferLength, LPSTR lpBuffer, LPSTR *lpFilePart);
DWORD WINAPI GetFullPathNameW(LPCWSTR lpFileName, DWORD nBufferLength, LPWSTR lpBuffer, LPWSTR *lpFilePart);
DWORD WINAPI GetCurrentDirectoryA(DWORD nBufferLength, LPSTR lpBuffer);
DWORD WINAPI GetCurrentDirectoryW(DWORD nBufferLength, LPWSTR lpBuffer);
BOOL WINAPI SetCurrentDirectoryA(LPCSTR lpPathName);
BOOL WINAPI SetCurrentDirectoryW(LPCWSTR lpPathName);
DWORD WINAPI GetTempPathA(DWORD nBufferLength, LPSTR lpBuffer);
DWORD WINAPI GetTempPathW(DWORD nBufferLength, LPWSTR lpBuffer);
UINT WINAPI GetSystemDirectoryA(LPSTR lpBuffer, UINT uSize);
UINT WINAPI GetSystemDirectoryW(LPWSTR lpBuffer, UINT uSize);
UINT WINAPI GetDriveTypeA(LPCSTR lpRootPathName);
UINT WINAPI GetDriveTypeW(LPCWSTR lpRootPathName);
DWORD WINAPI GetLogicalDrives();
HANDLE WINAPI CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
HANDLE WINAPI CreateFileW(LPCWSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
BOOL WINAPI CloseHandle(HANDLE hObject);

#define DUPLICATE_CLOSE_SOURCE      0x00000001
#define DUPLICATE_SAME_ACCESS        0x00000002

inline BOOL WINAPI DuplicateHandle(HANDLE /*hSourceProcessHandle*/, HANDLE hSourceHandle, HANDLE /*hTargetProcessHandle*/, LPHANDLE lpTargetHandle, DWORD /*dwDesiredAccess*/, BOOL /*bInheritHandle*/, DWORD /*dwOptions*/) {
    if (lpTargetHandle) *lpTargetHandle = hSourceHandle;
    return TRUE;
}

#define PAGE_NOACCESS          0x01
#define PAGE_READONLY          0x02
#define PAGE_READWRITE         0x04
#define PAGE_WRITECOPY         0x08
#define PAGE_EXECUTE           0x10
#define PAGE_EXECUTE_READ      0x20
#define PAGE_EXECUTE_READWRITE 0x40

#define SECTION_QUERY       0x0001
#define SECTION_MAP_WRITE   0x0002
#define SECTION_MAP_READ    0x0004
#define SECTION_MAP_EXECUTE 0x0008
#define SECTION_EXTEND_SIZE 0x0010
#define SECTION_ALL_ACCESS  0x000F001F

#define FILE_MAP_WRITE           SECTION_MAP_WRITE
#define FILE_MAP_READ            SECTION_MAP_READ
#define FILE_MAP_ALL_ACCESS      SECTION_ALL_ACCESS
#define FILE_MAP_EXECUTE         SECTION_MAP_EXECUTE
#define FILE_MAP_COPY            0x00000001
#define FILE_MAP_RESERVE         0x80000000

inline HANDLE WINAPI CreateFileMappingA(HANDLE, LPSECURITY_ATTRIBUTES, DWORD, DWORD, DWORD, LPCSTR) { return NULL; }
inline HANDLE WINAPI CreateFileMappingW(HANDLE, LPSECURITY_ATTRIBUTES, DWORD, DWORD, DWORD, LPCWSTR) { return NULL; }
inline HANDLE WINAPI OpenFileMappingA(DWORD, BOOL, LPCSTR) { return NULL; }
inline HANDLE WINAPI OpenFileMappingW(DWORD, BOOL, LPCWSTR) { return NULL; }
inline LPVOID WINAPI MapViewOfFile(HANDLE, DWORD, DWORD, DWORD, SIZE_T) { return NULL; }
inline BOOL WINAPI UnmapViewOfFile(LPCVOID) { return TRUE; }

#define HWND_MESSAGE ((HWND)(intptr_t)-3)

#define IMAGE_DOS_SIGNATURE 0x5A4D
#define IMAGE_NT_SIGNATURE  0x00004550

struct IMAGE_DOS_HEADER {
    WORD   e_magic;
    WORD   e_cblp;
    WORD   e_cp;
    WORD   e_crlc;
    WORD   e_cparhdr;
    WORD   e_minalloc;
    WORD   e_maxalloc;
    WORD   e_ss;
    WORD   e_sp;
    WORD   e_csum;
    WORD   e_ip;
    WORD   e_cs;
    WORD   e_lfarlc;
    WORD   e_ovno;
    WORD   e_res[4];
    WORD   e_oemid;
    WORD   e_oeminfo;
    WORD   e_res2[10];
    LONG   e_lfanew;
};

struct IMAGE_FILE_HEADER {
    WORD    Machine;
    WORD    NumberOfSections;
    DWORD   TimeDateStamp;
    DWORD   PointerToSymbolTable;
    DWORD   NumberOfSymbols;
    WORD    SizeOfOptionalHeader;
    WORD    Characteristics;
};

#define IMAGE_FILE_MACHINE_I386  0x014c
#define IMAGE_FILE_MACHINE_AMD64 0x8664
#define IMAGE_FILE_MACHINE_ARM   0x01c0
#define IMAGE_FILE_MACHINE_ARM64 0xaa64
#define IMAGE_FILE_DLL           0x2000

struct IMAGE_DATA_DIRECTORY {
    DWORD   VirtualAddress;
    DWORD   Size;
};

struct IMAGE_OPTIONAL_HEADER32 {
    WORD    Magic;
    BYTE    MajorLinkerVersion;
    BYTE    MinorLinkerVersion;
    DWORD   SizeOfCode;
    DWORD   SizeOfInitializedData;
    DWORD   SizeOfUninitializedData;
    DWORD   AddressOfEntryPoint;
    DWORD   BaseOfCode;
    DWORD   BaseOfData;
    DWORD   ImageBase;
    DWORD   SectionAlignment;
    DWORD   FileAlignment;
    WORD    MajorOperatingSystemVersion;
    WORD    MinorOperatingSystemVersion;
    WORD    MajorImageVersion;
    WORD    MinorImageVersion;
    WORD    MajorSubsystemVersion;
    WORD    MinorSubsystemVersion;
    DWORD   Win32VersionValue;
    DWORD   SizeOfImage;
    DWORD   SizeOfHeaders;
    DWORD   CheckSum;
    WORD    Subsystem;
    WORD    DllCharacteristics;
    DWORD   SizeOfStackReserve;
    DWORD   SizeOfStackCommit;
    DWORD   SizeOfHeapReserve;
    DWORD   SizeOfHeapCommit;
    DWORD   LoaderFlags;
    DWORD   NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY DataDirectory[16];
};

struct IMAGE_NT_HEADERS32 {
    DWORD Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER32 OptionalHeader;
};
typedef IMAGE_NT_HEADERS32 IMAGE_NT_HEADERS;

struct VS_FIXEDFILEINFO {
    DWORD   dwSignature;
    DWORD   dwStrucVersion;
    DWORD   dwFileVersionMS;
    DWORD   dwFileVersionLS;
    DWORD   dwProductVersionMS;
    DWORD   dwProductVersionLS;
    DWORD   dwFileFlagsMask;
    DWORD   dwFileFlags;
    DWORD   dwFileOS;
    DWORD   dwFileType;
    DWORD   dwFileSubtype;
    DWORD   dwFileDateMS;
    DWORD   dwFileDateLS;
};

inline DWORD WINAPI GetFileVersionInfoSizeA(LPCSTR, LPDWORD) { return 0; }
inline DWORD WINAPI GetFileVersionInfoSizeW(LPCWSTR, LPDWORD) { return 0; }
inline BOOL WINAPI GetFileVersionInfoA(LPCSTR, DWORD, DWORD, LPVOID) { return FALSE; }
inline BOOL WINAPI GetFileVersionInfoW(LPCWSTR, DWORD, DWORD, LPVOID) { return FALSE; }
inline BOOL WINAPI VerQueryValueA(LPCVOID, LPCSTR, LPVOID*, PUINT) { return FALSE; }
inline BOOL WINAPI VerQueryValueW(LPCVOID, LPCWSTR, LPVOID*, PUINT) { return FALSE; }
#ifdef UNICODE
#define GetFileVersionInfoSize GetFileVersionInfoSizeW
#define GetFileVersionInfo GetFileVersionInfoW
#define VerQueryValue VerQueryValueW
#else
#define GetFileVersionInfoSize GetFileVersionInfoSizeA
#define GetFileVersionInfo GetFileVersionInfoA
#define VerQueryValue VerQueryValueA
#endif

#define FILE_BEGIN           0
#define FILE_CURRENT         1
#define FILE_END             2

BOOL WINAPI ReadFile(HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped);
BOOL WINAPI WriteFile(HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);
BOOL WINAPI SetFilePointerEx(HANDLE hFile, LARGE_INTEGER liDistanceToMove, PLARGE_INTEGER lpNewFilePointer, DWORD dwMoveMethod);
BOOL WINAPI GetFileSizeEx(HANDLE hFile, PLARGE_INTEGER lpFileSize);
BOOL WINAPI SetEndOfFile(HANDLE hFile);
BOOL WINAPI FlushFileBuffers(HANDLE hFile);
HANDLE WINAPI FindFirstFileA(LPCSTR lpFileName, WIN32_FIND_DATAA* lpFindFileData);
HANDLE WINAPI FindFirstFileW(LPCWSTR lpFileName, WIN32_FIND_DATAW* lpFindFileData);
BOOL WINAPI FindNextFileA(HANDLE hFindFile, WIN32_FIND_DATAA* lpFindFileData);
BOOL WINAPI FindNextFileW(HANDLE hFindFile, WIN32_FIND_DATAW* lpFindFileData);
BOOL WINAPI FindClose(HANDLE hFindFile);
HANDLE WINAPI FindFirstChangeNotificationA(LPCSTR lpPathName, BOOL bWatchSubtree, DWORD dwNotifyFilter);
HANDLE WINAPI FindFirstChangeNotificationW(LPCWSTR lpPathName, BOOL bWatchSubtree, DWORD dwNotifyFilter);
BOOL WINAPI FindNextChangeNotification(HANDLE hChangeHandle);
BOOL WINAPI FindCloseChangeNotification(HANDLE hChangeHandle);

inline DWORD GetFileAttributes(LPCSTR lp) { return GetFileAttributesA(lp); }
inline DWORD GetFileAttributes(LPCWSTR lp) { return GetFileAttributesW(lp); }

inline BOOL CreateDirectory(LPCSTR lp, LPSECURITY_ATTRIBUTES sa) { return CreateDirectoryA(lp, sa); }
inline BOOL CreateDirectory(LPCWSTR lp, LPSECURITY_ATTRIBUTES sa) { return CreateDirectoryW(lp, sa); }

inline BOOL RemoveDirectory(LPCSTR lp) { return RemoveDirectoryA(lp); }
inline BOOL RemoveDirectory(LPCWSTR lp) { return RemoveDirectoryW(lp); }

inline BOOL DeleteFile(LPCSTR lp) { return DeleteFileA(lp); }
inline BOOL DeleteFile(LPCWSTR lp) { return DeleteFileW(lp); }

inline BOOL CopyFile(LPCSTR s, LPCSTR d, BOOL f) { return CopyFileA(s, d, f); }
inline BOOL CopyFile(LPCWSTR s, LPCWSTR d, BOOL f) { return CopyFileW(s, d, f); }

inline BOOL MoveFile(LPCSTR s, LPCSTR d) { return MoveFileA(s, d); }
inline BOOL MoveFile(LPCWSTR s, LPCWSTR d) { return MoveFileW(s, d); }

#define LOCKFILE_FAIL_IMMEDIATELY   0x00000001
#define LOCKFILE_EXCLUSIVE_LOCK     0x00000002

inline BOOL WINAPI LockFile(HANDLE hFile, DWORD dwFileOffsetLow, DWORD dwFileOffsetHigh, DWORD nNumberOfBytesToLockLow, DWORD nNumberOfBytesToLockHigh) {
    (void)hFile; (void)dwFileOffsetLow; (void)dwFileOffsetHigh; (void)nNumberOfBytesToLockLow; (void)nNumberOfBytesToLockHigh;
    return TRUE;
}
inline BOOL WINAPI UnlockFile(HANDLE hFile, DWORD dwFileOffsetLow, DWORD dwFileOffsetHigh, DWORD nNumberOfBytesToUnlockLow, DWORD nNumberOfBytesToUnlockHigh) {
    (void)hFile; (void)dwFileOffsetLow; (void)dwFileOffsetHigh; (void)nNumberOfBytesToUnlockLow; (void)nNumberOfBytesToUnlockHigh;
    return TRUE;
}
inline BOOL WINAPI LockFileEx(HANDLE hFile, DWORD dwFlags, DWORD dwReserved, DWORD nNumberOfBytesToLockLow, DWORD nNumberOfBytesToLockHigh, LPOVERLAPPED lpOverlapped) {
    (void)hFile; (void)dwFlags; (void)dwReserved; (void)nNumberOfBytesToLockLow; (void)nNumberOfBytesToLockHigh; (void)lpOverlapped;
    return TRUE;
}
inline BOOL WINAPI UnlockFileEx(HANDLE hFile, DWORD dwReserved, DWORD nNumberOfBytesToUnlockLow, DWORD nNumberOfBytesToUnlockHigh, LPOVERLAPPED lpOverlapped) {
    (void)hFile; (void)dwReserved; (void)nNumberOfBytesToUnlockLow; (void)nNumberOfBytesToUnlockHigh; (void)lpOverlapped;
    return TRUE;
}

template <typename TBuf, typename TPart>
inline DWORD GetFullPathName(LPCSTR lp, DWORD len, TBuf buf, TPart fp) {
    if constexpr (std::is_same_v<std::decay_t<TBuf>, LPWSTR> || std::is_same_v<std::decay_t<TBuf>, WCHAR*>) {
        if (!lp) return 0;
        std::wstring wlp;
        int needed = MultiByteToWideChar(CP_UTF8, 0, lp, -1, nullptr, 0);
        if (needed > 0) {
            wlp.resize(needed);
            MultiByteToWideChar(CP_UTF8, 0, lp, -1, wlp.data(), needed);
            return GetFullPathNameW(wlp.c_str(), len, (LPWSTR)buf, (LPWSTR*)fp);
        }
        return 0;
    } else {
        return GetFullPathNameA(lp, len, (LPSTR)buf, (LPSTR*)fp);
    }
}

template <typename TBuf, typename TPart>
inline DWORD GetFullPathName(LPCWSTR lp, DWORD len, TBuf buf, TPart fp) {
    if constexpr (std::is_same_v<std::decay_t<TBuf>, LPSTR> || std::is_same_v<std::decay_t<TBuf>, CHAR*>) {
        if (!lp) return 0;
        std::string alp;
        int needed = WideCharToMultiByte(CP_UTF8, 0, lp, -1, nullptr, 0, nullptr, nullptr);
        if (needed > 0) {
            alp.resize(needed);
            WideCharToMultiByte(CP_UTF8, 0, lp, -1, alp.data(), needed, nullptr, nullptr);
            return GetFullPathNameA(alp.c_str(), len, (LPSTR)buf, (LPSTR*)fp);
        }
        return 0;
    } else {
        return GetFullPathNameW(lp, len, (LPWSTR)buf, (LPWSTR*)fp);
    }
}

template <typename TBuf = LPWSTR>
inline DWORD GetCurrentDirectory(DWORD len, TBuf buf) {
    if constexpr (std::is_same_v<std::decay_t<TBuf>, LPSTR> || std::is_same_v<std::decay_t<TBuf>, CHAR*>) {
        return GetCurrentDirectoryA(len, (LPSTR)buf);
    } else {
        return GetCurrentDirectoryW(len, (LPWSTR)buf);
    }
}

inline BOOL SetCurrentDirectory(LPCSTR lp) { return SetCurrentDirectoryA(lp); }
inline BOOL SetCurrentDirectory(LPCWSTR lp) { return SetCurrentDirectoryW(lp); }

template <typename TBuf = LPWSTR>
inline DWORD GetTempPath(DWORD len, TBuf buf) {
    if constexpr (std::is_same_v<std::decay_t<TBuf>, LPSTR> || std::is_same_v<std::decay_t<TBuf>, CHAR*>) {
        return GetTempPathA(len, (LPSTR)buf);
    } else {
        return GetTempPathW(len, (LPWSTR)buf);
    }
}

template <typename TBuf = LPWSTR>
inline UINT GetSystemDirectory(TBuf buf, UINT sz) {
    if constexpr (std::is_same_v<std::decay_t<TBuf>, LPSTR> || std::is_same_v<std::decay_t<TBuf>, CHAR*>) {
        return GetSystemDirectoryA((LPSTR)buf, sz);
    } else {
        return GetSystemDirectoryW((LPWSTR)buf, sz);
    }
}

inline UINT GetDriveType(LPCSTR lp) { return GetDriveTypeA(lp); }
inline UINT GetDriveType(LPCWSTR lp) { return GetDriveTypeW(lp); }

inline HANDLE CreateFile(LPCSTR fn, DWORD da, DWORD sm, LPSECURITY_ATTRIBUTES sa, DWORD cd, DWORD fa, HANDLE tm) {
    return CreateFileA(fn, da, sm, sa, cd, fa, tm);
}
inline HANDLE CreateFile(LPCWSTR fn, DWORD da, DWORD sm, LPSECURITY_ATTRIBUTES sa, DWORD cd, DWORD fa, HANDLE tm) {
    return CreateFileW(fn, da, sm, sa, cd, fa, tm);
}

inline HANDLE FindFirstFile(LPCSTR fn, WIN32_FIND_DATAA* fd) { return FindFirstFileA(fn, fd); }
inline HANDLE FindFirstFile(LPCWSTR fn, WIN32_FIND_DATAW* fd) { return FindFirstFileW(fn, fd); }
inline HANDLE FindFirstFile(LPCSTR fn, WIN32_FIND_DATAW* fd) {
    if (!fn) return INVALID_HANDLE_VALUE;
    std::wstring wfn;
    int needed = MultiByteToWideChar(CP_UTF8, 0, fn, -1, nullptr, 0);
    if (needed > 0) {
        wfn.resize(needed);
        MultiByteToWideChar(CP_UTF8, 0, fn, -1, wfn.data(), needed);
        return FindFirstFileW(wfn.c_str(), fd);
    }
    return INVALID_HANDLE_VALUE;
}

inline BOOL FindNextFile(HANDLE h, WIN32_FIND_DATAA* fd) { return FindNextFileA(h, fd); }
inline BOOL FindNextFile(HANDLE h, WIN32_FIND_DATAW* fd) { return FindNextFileW(h, fd); }

inline HANDLE FindFirstChangeNotification(LPCSTR lp, BOOL b, DWORD f) { return FindFirstChangeNotificationA(lp, b, f); }
inline HANDLE FindFirstChangeNotification(LPCWSTR lp, BOOL b, DWORD f) { return FindFirstChangeNotificationW(lp, b, f); }

// Synchronization Events
HANDLE WINAPI CreateEventA(LPSECURITY_ATTRIBUTES lpEventAttributes, BOOL bManualReset, BOOL bInitialState, LPCSTR lpName);
HANDLE WINAPI CreateEventW(LPSECURITY_ATTRIBUTES lpEventAttributes, BOOL bManualReset, BOOL bInitialState, LPCWSTR lpName);
#ifdef UNICODE
#define CreateEvent CreateEventW
#else
#define CreateEvent CreateEventA
#endif
BOOL WINAPI SetEvent(HANDLE hEvent);
BOOL WINAPI ResetEvent(HANDLE hEvent);
DWORD WINAPI WaitForSingleObject(HANDLE hHandle, DWORD dwMilliseconds);
DWORD WINAPI WaitForMultipleObjects(DWORD nCount, const HANDLE *lpHandles, BOOL bWaitAll, DWORD dwMilliseconds);

// Dynamic Libraries & Resources
HMODULE WINAPI LoadLibraryA(LPCSTR lpLibFileName);
HMODULE WINAPI LoadLibraryW(LPCWSTR lpLibFileName);
// mpt native paths are UTF-8 on macOS.
inline HMODULE WINAPI LoadLibraryW(LPCSTR lpLibFileName) { return LoadLibraryA(lpLibFileName); }
#ifdef UNICODE
#define LoadLibrary LoadLibraryW
#else
#define LoadLibrary LoadLibraryA
#endif
BOOL WINAPI FreeLibrary(HMODULE hLibModule);
FARPROC WINAPI GetProcAddress(HMODULE hModule, LPCSTR lpProcName);
HMODULE WINAPI GetModuleHandleA(LPCSTR lpModuleName);
HMODULE WINAPI GetModuleHandleW(LPCWSTR lpModuleName);
DWORD WINAPI GetModuleFileNameA(HMODULE hModule, LPSTR lpFilename, DWORD nSize);
DWORD WINAPI GetModuleFileNameW(HMODULE hModule, LPWSTR lpFilename, DWORD nSize);
#ifdef UNICODE
#define GetModuleHandle GetModuleHandleW
#define GetModuleFileName GetModuleFileNameW
#else
#define GetModuleHandle GetModuleHandleA
#define GetModuleFileName GetModuleFileNameA
#endif

struct HRSRC__; typedef HRSRC__* HRSRC;
HRSRC WINAPI FindResourceA(HMODULE hModule, LPCSTR lpName, LPCSTR lpType);
HRSRC WINAPI FindResourceW(HMODULE hModule, LPCWSTR lpName, LPCWSTR lpType);
#ifdef UNICODE
#define FindResource FindResourceW
#else
#define FindResource FindResourceA
#endif
HGLOBAL WINAPI LoadResource(HMODULE hModule, HRSRC hResInfo);
LPVOID WINAPI LockResource(HGLOBAL hResData);
DWORD WINAPI SizeofResource(HMODULE hModule, HRSRC hResInfo);
int WINAPI LoadStringA(HINSTANCE hInstance, UINT uID, LPSTR lpBuffer, int cchBufferMax);
int WINAPI LoadStringW(HINSTANCE hInstance, UINT uID, LPWSTR lpBuffer, int cchBufferMax);
#ifdef UNICODE
#define LoadString LoadStringW
#else
#define LoadString LoadStringA
#endif

// Strings & Environment
int WINAPI lstrcmpA(LPCSTR lpString1, LPCSTR lpString2);
int WINAPI lstrcmpW(LPCWSTR lpString1, LPCWSTR lpString2);
int WINAPI lstrcmpiA(LPCSTR lpString1, LPCSTR lpString2);
int WINAPI lstrcmpiW(LPCWSTR lpString1, LPCWSTR lpString2);
int WINAPI CompareStringA(DWORD Locale, DWORD dwCmpFlags, LPCSTR lpString1, int cchCount1, LPCSTR lpString2, int cchCount2);
int WINAPI CompareStringW(DWORD Locale, DWORD dwCmpFlags, LPCWSTR lpString1, int cchCount1, LPCWSTR lpString2, int cchCount2);
DWORD WINAPI ExpandEnvironmentStringsA(LPCSTR lpSrc, LPSTR lpDst, DWORD nSize);
DWORD WINAPI ExpandEnvironmentStringsW(LPCWSTR lpSrc, LPWSTR lpDst, DWORD nSize);
LPWSTR WINAPI GetCommandLineW();
LPSTR WINAPI GetCommandLineA();
LPWSTR* WINAPI CommandLineToArgvW(LPCWSTR lpCmdLine, int* pNumArgs);
int wsprintfA(LPSTR lpOut, LPCSTR lpFmt, ...);
int wsprintfW(LPWSTR lpOut, LPCWSTR lpFmt, ...);
#ifdef UNICODE
#define ExpandEnvironmentStrings ExpandEnvironmentStringsW
#define GetCommandLine GetCommandLineW
#define wsprintf wsprintfW
#else
#define ExpandEnvironmentStrings ExpandEnvironmentStringsA
#define GetCommandLine GetCommandLineA
#define wsprintf wsprintfA
#endif

inline int CompareString(DWORD Locale, DWORD dwCmpFlags, LPCSTR lpString1, int cchCount1, LPCSTR lpString2, int cchCount2) {
    return CompareStringA(Locale, dwCmpFlags, lpString1, cchCount1, lpString2, cchCount2);
}
inline int CompareString(DWORD Locale, DWORD dwCmpFlags, LPCWSTR lpString1, int cchCount1, LPCWSTR lpString2, int cchCount2) {
    return CompareStringW(Locale, dwCmpFlags, lpString1, cchCount1, lpString2, cchCount2);
}

// INI PrivateProfile APIs
UINT WINAPI GetPrivateProfileIntA(LPCSTR lpAppName, LPCSTR lpKeyName, INT nDefault, LPCSTR lpFileName);
UINT WINAPI GetPrivateProfileIntW(LPCWSTR lpAppName, LPCWSTR lpKeyName, INT nDefault, LPCWSTR lpFileName);
DWORD WINAPI GetPrivateProfileStringA(LPCSTR lpAppName, LPCSTR lpKeyName, LPCSTR lpDefault, LPSTR lpReturnedString, DWORD nSize, LPCSTR lpFileName);
DWORD WINAPI GetPrivateProfileStringW(LPCWSTR lpAppName, LPCWSTR lpKeyName, LPCWSTR lpDefault, LPWSTR lpReturnedString, DWORD nSize, LPCWSTR lpFileName);
BOOL WINAPI WritePrivateProfileStringA(LPCSTR lpAppName, LPCSTR lpKeyName, LPCSTR lpString, LPCSTR lpFileName);
BOOL WINAPI WritePrivateProfileStringW(LPCWSTR lpAppName, LPCWSTR lpKeyName, LPCWSTR lpString, LPCWSTR lpFileName);
DWORD WINAPI GetPrivateProfileSectionA(LPCSTR lpAppName, LPSTR lpReturnedString, DWORD nSize, LPCSTR lpFileName);
DWORD WINAPI GetPrivateProfileSectionW(LPCWSTR lpAppName, LPWSTR lpReturnedString, DWORD nSize, LPCWSTR lpFileName);
BOOL WINAPI WritePrivateProfileSectionA(LPCSTR lpAppName, LPCSTR lpString, LPCSTR lpFileName);
BOOL WINAPI WritePrivateProfileSectionW(LPCWSTR lpAppName, LPCWSTR lpString, LPCWSTR lpFileName);
DWORD WINAPI GetPrivateProfileSectionNamesA(LPSTR lpszReturnBuffer, DWORD nSize, LPCSTR lpFileName);
DWORD WINAPI GetPrivateProfileSectionNamesW(LPWSTR lpszReturnBuffer, DWORD nSize, LPCWSTR lpFileName);
BOOL WINAPI GetPrivateProfileStructA(LPCSTR lpszSection, LPCSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCSTR szFile);
BOOL WINAPI GetPrivateProfileStructW(LPCWSTR lpszSection, LPCWSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCWSTR szFile);
BOOL WINAPI WritePrivateProfileStructA(LPCSTR lpszSection, LPCSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCSTR szFile);
BOOL WINAPI WritePrivateProfileStructW(LPCWSTR lpszSection, LPCWSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCWSTR szFile);

inline UINT WINAPI GetPrivateProfileIntW(LPCWSTR lpAppName, LPCWSTR lpKeyName, INT nDefault, LPCSTR lpFileName) {
    if (!lpFileName) return nDefault;
    std::wstring wFile;
    int len = (int)strlen(lpFileName);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFileName[i];
    return GetPrivateProfileIntW(lpAppName, lpKeyName, nDefault, wFile.c_str());
}
inline DWORD WINAPI GetPrivateProfileStringW(LPCWSTR lpAppName, LPCWSTR lpKeyName, LPCWSTR lpDefault, LPWSTR lpReturnedString, DWORD nSize, LPCSTR lpFileName) {
    if (!lpFileName) return 0;
    std::wstring wFile;
    int len = (int)strlen(lpFileName);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFileName[i];
    return GetPrivateProfileStringW(lpAppName, lpKeyName, lpDefault, lpReturnedString, nSize, wFile.c_str());
}
inline BOOL WINAPI WritePrivateProfileStringW(LPCWSTR lpAppName, LPCWSTR lpKeyName, LPCWSTR lpString, LPCSTR lpFileName) {
    if (!lpFileName) return FALSE;
    std::wstring wFile;
    int len = (int)strlen(lpFileName);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFileName[i];
    return WritePrivateProfileStringW(lpAppName, lpKeyName, lpString, wFile.c_str());
}
inline DWORD WINAPI GetPrivateProfileSectionW(LPCWSTR lpAppName, LPWSTR lpReturnedString, DWORD nSize, LPCSTR lpFileName) {
    if (!lpFileName) return 0;
    std::wstring wFile;
    int len = (int)strlen(lpFileName);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFileName[i];
    return GetPrivateProfileSectionW(lpAppName, lpReturnedString, nSize, wFile.c_str());
}
inline BOOL WINAPI WritePrivateProfileSectionW(LPCWSTR lpAppName, LPCWSTR lpString, LPCSTR lpFileName) {
    if (!lpFileName) return FALSE;
    std::wstring wFile;
    int len = (int)strlen(lpFileName);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFileName[i];
    return WritePrivateProfileSectionW(lpAppName, lpString, wFile.c_str());
}
inline DWORD WINAPI GetPrivateProfileSectionNamesW(LPWSTR lpszReturnBuffer, DWORD nSize, LPCSTR lpFileName) {
    if (!lpFileName) return 0;
    std::wstring wFile;
    int len = (int)strlen(lpFileName);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFileName[i];
    return GetPrivateProfileSectionNamesW(lpszReturnBuffer, nSize, wFile.c_str());
}
inline BOOL WINAPI GetPrivateProfileStructW(LPCWSTR lpszSection, LPCWSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCSTR szFile) {
    if (!szFile) return FALSE;
    std::wstring wFile;
    int len = (int)strlen(szFile);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)szFile[i];
    return GetPrivateProfileStructW(lpszSection, lpszKey, lpStruct, uSizeStruct, wFile.c_str());
}
inline BOOL WINAPI WritePrivateProfileStructW(LPCWSTR lpszSection, LPCWSTR lpszKey, LPVOID lpStruct, UINT uSizeStruct, LPCSTR szFile) {
    if (!szFile) return FALSE;
    std::wstring wFile;
    int len = (int)strlen(szFile);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)szFile[i];
    return WritePrivateProfileStructW(lpszSection, lpszKey, lpStruct, uSizeStruct, wFile.c_str());
}
#ifdef UNICODE
#define GetPrivateProfileInt GetPrivateProfileIntW
#define GetPrivateProfileString GetPrivateProfileStringW
#define WritePrivateProfileString WritePrivateProfileStringW
#define GetPrivateProfileSection GetPrivateProfileSectionW
#define WritePrivateProfileSection WritePrivateProfileSectionW
#define GetPrivateProfileSectionNames GetPrivateProfileSectionNamesW
#define GetPrivateProfileStruct GetPrivateProfileStructW
#define WritePrivateProfileStruct WritePrivateProfileStructW
#else
#define GetPrivateProfileInt GetPrivateProfileIntA
#define GetPrivateProfileString GetPrivateProfileStringA
#define WritePrivateProfileString WritePrivateProfileStringA
#define GetPrivateProfileSection GetPrivateProfileSectionA
#define WritePrivateProfileSection WritePrivateProfileSectionA
#define GetPrivateProfileSectionNames GetPrivateProfileSectionNamesA
#define GetPrivateProfileStruct GetPrivateProfileStructA
#define WritePrivateProfileStruct WritePrivateProfileStructA
#endif

// Windowing / User32 APIs
#define CW_USEDEFAULT ((int)0x80000000)
ATOM WINAPI RegisterClassA(const WNDCLASSA *lpWndClass);
ATOM WINAPI RegisterClassW(const WNDCLASSW *lpWndClass);
ATOM WINAPI RegisterClassExA(const WNDCLASSEXA *lpwcx);
ATOM WINAPI RegisterClassExW(const WNDCLASSEXW *lpwcx);
HWND WINAPI CreateWindowExA(DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam);
HWND WINAPI CreateWindowExW(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam);
#define CreateWindowA(lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam) \
    CreateWindowExA(0L, lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam)
#define CreateWindowW(lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam) \
    CreateWindowExW(0L, lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam)
#ifdef UNICODE
#define RegisterClass RegisterClassW
#define RegisterClassEx RegisterClassExW
#define CreateWindowEx CreateWindowExW
#define CreateWindow CreateWindowW
#else
#define RegisterClass RegisterClassA
#define RegisterClassEx RegisterClassExA
#define CreateWindowEx CreateWindowExA
#define CreateWindow CreateWindowA
#endif

BOOL WINAPI DestroyWindow(HWND hWnd);
BOOL WINAPI IsWindow(HWND hWnd);
BOOL WINAPI IsWindowVisible(HWND hWnd);
BOOL WINAPI IsWindowEnabled(HWND hWnd);
BOOL WINAPI IsIconic(HWND hWnd);
BOOL WINAPI IsZoomed(HWND hWnd);
BOOL WINAPI EnableWindow(HWND hWnd, BOOL bEnable);
BOOL WINAPI ShowWindow(HWND hWnd, int nCmdShow);
BOOL WINAPI UpdateWindow(HWND hWnd);
BOOL WINAPI LockWindowUpdate(HWND hWndLock);
BOOL WINAPI RedrawWindow(HWND hWnd, const RECT *lprcUpdate, HRGN hrgnUpdate, UINT flags);
BOOL WINAPI InvalidateRect(HWND hWnd, const RECT *lpRect, BOOL bErase);
BOOL WINAPI ValidateRect(HWND hWnd, const RECT *lpRect);
BOOL WINAPI GetUpdateRect(HWND hWnd, LPRECT lpRect, BOOL bErase);
HWND WINAPI GetDesktopWindow();
HWND WINAPI GetParent(HWND hWnd);
HWND WINAPI SetParent(HWND hWndChild, HWND hWndNewParent);
BOOL WINAPI IsChild(HWND hWndParent, HWND hWnd);
HWND WINAPI GetWindow(HWND hWnd, UINT uCmd);
BOOL WINAPI EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
BOOL WINAPI EnumChildWindows(HWND hWndParent, WNDENUMPROC lpEnumFunc, LPARAM lParam);
HWND WINAPI WindowFromPoint(POINT Point);
HWND WINAPI ChildWindowFromPoint(HWND hWndParent, POINT Point);
HWND WINAPI ChildWindowFromPointEx(HWND hWnd, POINT pt, UINT flags);
HMENU WINAPI GetSystemMenu(HWND hWnd, BOOL bRevert);

BOOL WINAPI CreateCaret(HWND hWnd, HBITMAP hBitmap, int nWidth, int nHeight);
BOOL WINAPI DestroyCaret();
BOOL WINAPI ShowCaret(HWND hWnd);
BOOL WINAPI HideCaret(HWND hWnd);
BOOL WINAPI GetCaretPos(LPPOINT lpPoint);
BOOL WINAPI SetCaretPos(int X, int Y);
int WINAPI GetClassNameA(HWND hWnd, LPSTR lpClassName, int nMaxCount);
int WINAPI GetClassNameW(HWND hWnd, LPWSTR lpClassName, int nMaxCount);
#ifdef UNICODE
#define GetClassName GetClassNameW
#else
#define GetClassName GetClassNameA
#endif

BOOL WINAPI SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
BOOL WINAPI MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint);
HDWP WINAPI BeginDeferWindowPos(int nNumWindows);
HDWP WINAPI DeferWindowPos(HDWP hWinPosInfo, HWND hWnd, HWND hWndInsertAfter, int x, int y, int cx, int cy, UINT uFlags);
BOOL WINAPI EndDeferWindowPos(HDWP hWinPosInfo);
BOOL WINAPI GetWindowRect(HWND hWnd, LPRECT lpRect);
BOOL WINAPI GetClientRect(HWND hWnd, LPRECT lpRect);
BOOL WINAPI ClientToScreen(HWND hWnd, LPPOINT lpPoint);
BOOL WINAPI ScreenToClient(HWND hWnd, LPPOINT lpPoint);
int WINAPI MapWindowPoints(HWND hWndFrom, HWND hWndTo, LPPOINT lpPoints, UINT cPoints);
BOOL WINAPI GetWindowPlacement(HWND hWnd, WINDOWPLACEMENT *lpwndpl);
BOOL WINAPI SetWindowPlacement(HWND hWnd, const WINDOWPLACEMENT *lpwndpl);
BOOL WINAPI AdjustWindowRectEx(LPRECT lpRect, DWORD dwStyle, BOOL bMenu, DWORD dwExStyle);

LONG WINAPI GetWindowLongA(HWND hWnd, int nIndex);
LONG WINAPI GetWindowLongW(HWND hWnd, int nIndex);
LONG WINAPI SetWindowLongA(HWND hWnd, int nIndex, LONG dwNewLong);
LONG WINAPI SetWindowLongW(HWND hWnd, int nIndex, LONG dwNewLong);
LONG_PTR WINAPI GetWindowLongPtrA(HWND hWnd, int nIndex);
LONG_PTR WINAPI GetWindowLongPtrW(HWND hWnd, int nIndex);
LONG_PTR WINAPI SetWindowLongPtrA(HWND hWnd, int nIndex, LONG_PTR dwNewLong);
LONG_PTR WINAPI SetWindowLongPtrW(HWND hWnd, int nIndex, LONG_PTR dwNewLong);
#ifdef UNICODE
#define GetWindowLong GetWindowLongW
#define SetWindowLong SetWindowLongW
#define GetWindowLongPtr GetWindowLongPtrW
#define SetWindowLongPtr SetWindowLongPtrW
#else
#define GetWindowLong GetWindowLongA
#define SetWindowLong SetWindowLongA
#define GetWindowLongPtr GetWindowLongPtrA
#define SetWindowLongPtr SetWindowLongPtrA
#endif

int WINAPI GetWindowTextA(HWND hWnd, LPSTR lpString, int nMaxCount);
int WINAPI GetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount);
int WINAPI GetWindowTextLengthA(HWND hWnd);
int WINAPI GetWindowTextLengthW(HWND hWnd);
BOOL WINAPI SetWindowTextA(HWND hWnd, LPCSTR lpString);
BOOL WINAPI SetWindowTextW(HWND hWnd, LPCWSTR lpString);
#ifdef UNICODE
#define GetWindowText GetWindowTextW
#define GetWindowTextLength GetWindowTextLengthW
#define SetWindowText SetWindowTextW
#else
#define GetWindowText GetWindowTextA
#define GetWindowTextLength GetWindowTextLengthA
#define SetWindowText SetWindowTextA
#endif

typedef struct {
    DWORD style;
    DWORD dwExtendedStyle;
    WORD cdit;
    short x;
    short y;
    short cx;
    short cy;
} DLGTEMPLATE, *LPDLGTEMPLATE;
typedef const DLGTEMPLATE *LPCDLGTEMPLATE;

typedef struct {
    DWORD style;
    DWORD dwExtendedStyle;
    short x;
    short y;
    short cx;
    short cy;
    WORD id;
} DLGITEMTEMPLATE, *LPDLGITEMTEMPLATE;
typedef const DLGITEMTEMPLATE *LPCDLGITEMTEMPLATE;

#define DM_GETDEFID             (WM_USER+0)
#define DM_SETDEFID             (WM_USER+1)
#define DM_REPOSITION           (WM_USER+2)
#define DC_HASDEFID             0x534B

BOOL WINAPI MapDialogRect(HWND hDlg, LPRECT lpRect);

HWND WINAPI GetDlgItem(HWND hDlg, int nIDDlgItem);
int WINAPI GetDlgCtrlID(HWND hWnd);
UINT WINAPI GetDlgItemInt(HWND hDlg, int nIDDlgItem, BOOL *lpTranslated, BOOL bSigned);
BOOL WINAPI SetDlgItemInt(HWND hDlg, int nIDDlgItem, UINT uValue, BOOL bSigned);
UINT WINAPI GetDlgItemTextA(HWND hDlg, int nIDDlgItem, LPSTR lpString, int cchMax);
UINT WINAPI GetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPWSTR lpString, int cchMax);
BOOL WINAPI SetDlgItemTextA(HWND hDlg, int nIDDlgItem, LPCSTR lpString);
BOOL WINAPI SetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPCWSTR lpString);
BOOL WINAPI CheckDlgButton(HWND hDlg, int nIDButton, UINT uCheck);
BOOL WINAPI CheckRadioButton(HWND hDlg, int nIDFirstButton, int nIDLastButton, int nIDCheckButton);
UINT WINAPI IsDlgButtonChecked(HWND hDlg, int nIDButton);
HWND WINAPI GetNextDlgTabItem(HWND hDlg, HWND hCtl, BOOL bPrevious);
HWND WINAPI GetNextDlgGroupItem(HWND hDlg, HWND hCtl, BOOL bPrevious);
LRESULT WINAPI SendDlgItemMessageA(HWND hDlg, int nIDDlgItem, UINT Msg, WPARAM wParam, LPARAM lParam);
LRESULT WINAPI SendDlgItemMessageW(HWND hDlg, int nIDDlgItem, UINT Msg, WPARAM wParam, LPARAM lParam);
#ifdef UNICODE
#define GetDlgItemText GetDlgItemTextW
#define SetDlgItemText SetDlgItemTextW
#define SendDlgItemMessage SendDlgItemMessageW
#else
#define GetDlgItemText GetDlgItemTextA
#define SetDlgItemText SetDlgItemTextA
#define SendDlgItemMessage SendDlgItemMessageA
#endif

LRESULT WINAPI SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
LRESULT WINAPI SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI PostMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI PostThreadMessageA(DWORD idThread, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI PostThreadMessageW(DWORD idThread, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI SendNotifyMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI SendNotifyMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL WINAPI PeekMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg);
BOOL WINAPI PeekMessageW(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg);
BOOL WINAPI GetMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
BOOL WINAPI GetMessageW(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
BOOL WINAPI TranslateMessage(const MSG *lpMsg);
LRESULT WINAPI DispatchMessageA(const MSG *lpMsg);
LRESULT WINAPI DispatchMessageW(const MSG *lpMsg);
void WINAPI PostQuitMessage(int nExitCode);
LRESULT WINAPI DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
LRESULT WINAPI DefWindowProcW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
LRESULT WINAPI CallWindowProcA(WNDPROC lpPrevWndFunc, HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
LRESULT WINAPI CallWindowProcW(WNDPROC lpPrevWndFunc, HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
UINT WINAPI RegisterWindowMessageA(LPCSTR lpString);
UINT WINAPI RegisterWindowMessageW(LPCWSTR lpString);
#ifdef UNICODE
#define SendMessage SendMessageW
#define PostMessage PostMessageW
#define PostThreadMessage PostThreadMessageW
#define SendNotifyMessage SendNotifyMessageW
#define PeekMessage PeekMessageW
#define GetMessage GetMessageW
#define DispatchMessage DispatchMessageW
#define DefWindowProc DefWindowProcW
#define CallWindowProc CallWindowProcW
#define RegisterWindowMessage RegisterWindowMessageW
#else
#define SendMessage SendMessageA
#define PostMessage PostMessageA
#define PostThreadMessage PostThreadMessageA
#define SendNotifyMessage SendNotifyMessageA
#define PeekMessage PeekMessageA
#define GetMessage GetMessageA
#define DispatchMessage DispatchMessageA
#define DefWindowProc DefWindowProcA
#define CallWindowProc CallWindowProcA
#define RegisterWindowMessage RegisterWindowMessageA
#endif

HHOOK WINAPI SetWindowsHookExA(int idHook, HOOKPROC lpfn, HINSTANCE hMod, DWORD dwThreadId);
HHOOK WINAPI SetWindowsHookExW(int idHook, HOOKPROC lpfn, HINSTANCE hMod, DWORD dwThreadId);
#ifdef UNICODE
#define SetWindowsHookEx SetWindowsHookExW
#else
#define SetWindowsHookEx SetWindowsHookExA
#endif
BOOL WINAPI UnhookWindowsHookEx(HHOOK hhk);
LRESULT WINAPI CallNextHookEx(HHOOK hhk, int nCode, WPARAM wParam, LPARAM lParam);
UINT_PTR WINAPI SetTimer(HWND hWnd, UINT_PTR nIDEvent, UINT uElapse, TIMERPROC lpTimerFunc);
BOOL WINAPI KillTimer(HWND hWnd, UINT_PTR uIDEvent);

HWND WINAPI GetFocus();
HWND WINAPI SetFocus(HWND hWnd);
HWND WINAPI GetActiveWindow();
HWND WINAPI SetActiveWindow(HWND hWnd);
BOOL WINAPI SetForegroundWindow(HWND hWnd);
inline BOOL WINAPI AllowSetForegroundWindow(DWORD dwProcessId) { (void)dwProcessId; return TRUE; }
inline DWORD WINAPI GetWindowThreadProcessId(HWND hWnd, LPDWORD lpdwProcessId) {
    if (lpdwProcessId) *lpdwProcessId = (DWORD)getpid();
    return 1;
}
HWND WINAPI GetForegroundWindow();
HWND WINAPI SetCapture(HWND hWnd);
BOOL WINAPI ReleaseCapture();
HWND WINAPI GetCapture();
BOOL WINAPI TrackMouseEvent(LPTRACKMOUSEEVENT lpEventTrack);
BOOL WINAPI GetCursorPos(LPPOINT lpPoint);
BOOL WINAPI SetCursorPos(int X, int Y);
HCURSOR WINAPI SetCursor(HCURSOR hCursor);
int WINAPI ShowCursor(BOOL bShow);
HCURSOR WINAPI LoadCursorA(HINSTANCE hInstance, LPCSTR lpCursorName);
HCURSOR WINAPI LoadCursorW(HINSTANCE hInstance, LPCWSTR lpCursorName);
HICON WINAPI LoadIconA(HINSTANCE hInstance, LPCSTR lpIconName);
HICON WINAPI LoadIconW(HINSTANCE hInstance, LPCWSTR lpIconName);
HANDLE WINAPI LoadImageA(HINSTANCE hInst, LPCSTR name, UINT type, int cx, int cy, UINT fuLoad);
HANDLE WINAPI LoadImageW(HINSTANCE hInst, LPCWSTR name, UINT type, int cx, int cy, UINT fuLoad);
BOOL WINAPI DestroyIcon(HICON hIcon);
BOOL WINAPI DestroyCursor(HCURSOR hCursor);
#ifdef UNICODE
#define LoadCursor LoadCursorW
#define LoadIcon LoadIconW
#define LoadImage LoadImageW
#else
#define LoadCursor LoadCursorA
#define LoadIcon LoadIconA
#define LoadImage LoadImageA
#endif

SHORT WINAPI GetKeyState(int nVirtKey);
SHORT WINAPI GetAsyncKeyState(int vKey);
BOOL WINAPI GetKeyboardState(BYTE *lpKeyState);
UINT WINAPI SendInput(UINT cInputs, LPINPUT pInputs, int cbSize);
LPARAM WINAPI GetMessageExtraInfo();
inline LPARAM WINAPI SetMessageExtraInfo(LPARAM /*lParam*/) { return 0; }
inline HKL WINAPI GetKeyboardLayout(DWORD /*idThread*/) { return (HKL)(intptr_t)0x04090409; }
inline int WINAPI GetKeyboardLayoutList(int nBuff, HKL *lpList) {
    if (nBuff > 0 && lpList) {
        lpList[0] = (HKL)(intptr_t)0x04090409;
        return 1;
    }
    return 1;
}

inline SHORT WINAPI VkKeyScanA(CHAR ch) {
    if (ch >= 'a' && ch <= 'z') return (SHORT)(ch - 'a' + 'A');
    if (ch >= 'A' && ch <= 'Z') return (SHORT)ch;
    if (ch >= '0' && ch <= '9') return (SHORT)ch;
    if (ch == ' ') return VK_SPACE;
    if (ch == '\t') return VK_TAB;
    if (ch == '\r' || ch == '\n') return VK_RETURN;
    return (SHORT)(unsigned char)ch;
}
inline SHORT WINAPI VkKeyScanW(WCHAR ch) {
    if (ch >= L'a' && ch <= L'z') return (SHORT)(ch - L'a' + L'A');
    if (ch >= L'A' && ch <= L'Z') return (SHORT)ch;
    if (ch >= L'0' && ch <= L'9') return (SHORT)ch;
    if (ch == L' ') return VK_SPACE;
    if (ch == L'\t') return VK_TAB;
    if (ch == L'\r' || ch == L'\n') return VK_RETURN;
    if (ch < 256) return (SHORT)ch;
    return -1;
}
inline SHORT WINAPI VkKeyScanExA(CHAR ch, HKL) { return VkKeyScanA(ch); }
inline SHORT WINAPI VkKeyScanExW(WCHAR ch, HKL) { return VkKeyScanW(ch); }
#ifdef UNICODE
#define VkKeyScan VkKeyScanW
#define VkKeyScanEx VkKeyScanExW
#else
#define VkKeyScan VkKeyScanA
#define VkKeyScanEx VkKeyScanExA
#endif
UINT WINAPI MapVirtualKeyA(UINT uCode, UINT uMapType);
UINT WINAPI MapVirtualKeyW(UINT uCode, UINT uMapType);
UINT WINAPI MapVirtualKeyExA(UINT uCode, UINT uMapType, HKL dwhkl);
UINT WINAPI MapVirtualKeyExW(UINT uCode, UINT uMapType, HKL dwhkl);
int WINAPI GetKeyNameTextA(LONG lParam, LPSTR lpString, int cchSize);
int WINAPI GetKeyNameTextW(LONG lParam, LPWSTR lpString, int cchSize);
int WINAPI ToUnicodeEx(UINT wVirtKey, UINT wScanCode, const BYTE *lpKeyState, LPWSTR pwszBuff, int cchBuff, UINT wFlags, HKL dwhkl);
#ifdef UNICODE
#define MapVirtualKey MapVirtualKeyW
#define MapVirtualKeyEx MapVirtualKeyExW
#define GetKeyNameText GetKeyNameTextW
#else
#define MapVirtualKey MapVirtualKeyA
#define MapVirtualKeyEx MapVirtualKeyExA
#define GetKeyNameText GetKeyNameTextA
#endif

// Menus
HMENU WINAPI CreateMenu();
HMENU WINAPI CreatePopupMenu();
BOOL WINAPI DestroyMenu(HMENU hMenu);
HMENU WINAPI LoadMenuA(HINSTANCE hInstance, LPCSTR lpMenuName);
HMENU WINAPI LoadMenuW(HINSTANCE hInstance, LPCWSTR lpMenuName);
HMENU WINAPI GetMenu(HWND hWnd);
BOOL WINAPI SetMenu(HWND hWnd, HMENU hMenu);
HMENU WINAPI GetSubMenu(HMENU hMenu, int nPos);
int WINAPI GetMenuItemCount(HMENU hMenu);
UINT WINAPI GetMenuItemID(HMENU hMenu, int nPos);
BOOL WINAPI AppendMenuA(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCSTR lpNewItem);
BOOL WINAPI AppendMenuW(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem);
BOOL WINAPI InsertMenuA(HMENU hMenu, UINT uPosition, UINT uFlags, UINT_PTR uIDNewItem, LPCSTR lpNewItem);
BOOL WINAPI InsertMenuW(HMENU hMenu, UINT uPosition, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem);
BOOL WINAPI ModifyMenuA(HMENU hMenu, UINT uPosition, UINT uFlags, UINT_PTR uIDNewItem, LPCSTR lpNewItem);
BOOL WINAPI ModifyMenuW(HMENU hMenu, UINT uPosition, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem);
BOOL WINAPI RemoveMenu(HMENU hMenu, UINT uPosition, UINT uFlags);
BOOL WINAPI DeleteMenu(HMENU hMenu, UINT uPosition, UINT uFlags);
BOOL WINAPI EnableMenuItem(HMENU hMenu, UINT uIDEnableItem, UINT uEnable);
DWORD WINAPI CheckMenuItem(HMENU hMenu, UINT uIDCheckItem, UINT uCheck);
BOOL WINAPI CheckMenuRadioItem(HMENU hmenu, UINT first, UINT last, UINT check, UINT flags);
UINT WINAPI GetMenuState(HMENU hMenu, UINT uId, UINT uFlags);
int WINAPI GetMenuStringA(HMENU hMenu, UINT uIDItem, LPSTR lpString, int cchMax, UINT flags);
int WINAPI GetMenuStringW(HMENU hMenu, UINT uIDItem, LPWSTR lpString, int cchMax, UINT flags);
BOOL WINAPI GetMenuItemInfoA(HMENU hmenu, UINT item, BOOL fByPosition, LPMENUITEMINFOA lpmii);
BOOL WINAPI GetMenuItemInfoW(HMENU hmenu, UINT item, BOOL fByPosition, LPMENUITEMINFOW lpmii);
BOOL WINAPI SetMenuItemInfoA(HMENU hmenu, UINT item, BOOL fByPositon, const MENUITEMINFOA* lpmii);
BOOL WINAPI SetMenuItemInfoW(HMENU hmenu, UINT item, BOOL fByPositon, const MENUITEMINFOW* lpmii);
BOOL WINAPI SetMenuDefaultItem(HMENU hMenu, UINT uItem, UINT fByPos);
BOOL WINAPI SetMenuItemBitmaps(HMENU hMenu, UINT uPosition, UINT uFlags, HBITMAP hBitmapUnchecked, HBITMAP hBitmapChecked);
BOOL WINAPI DrawMenuBar(HWND hWnd);
BOOL WINAPI TrackPopupMenu(HMENU hMenu, UINT uFlags, int x, int y, int nReserved, HWND hWnd, const RECT *prcRect);
BOOL WINAPI TrackPopupMenuEx(HMENU hMenu, UINT uFlags, int x, int y, HWND hwnd, LPTPMPARAMS lptpm);

#ifndef OBJID_MENU
#define OBJID_WINDOW            0x00000000
#define OBJID_SYSMENU           0xFFFFFFFF
#define OBJID_TITLEBAR          0xFFFFFFFE
#define OBJID_MENU              0xFFFFFFFD
#define OBJID_CLIENT            0xFFFFFFFC
#define OBJID_VSCROLL           0xFFFFFFFB
#define OBJID_HSCROLL           0xFFFFFFFA
#define OBJID_SIZEGRIP          0xFFFFFFF9
#define OBJID_CARET             0xFFFFFFF8
#define OBJID_CURSOR            0xFFFFFFF7
#define OBJID_ALERT             0xFFFFFFF6
#define OBJID_SOUND             0xFFFFFFF5
#endif

typedef struct tagMENUBARINFO {
    DWORD cbSize;
    RECT  rcBar;
    HMENU hMenu;
    HWND  hwndMenu;
    BOOL  fBarFocused:1;
    BOOL  fFocused:1;
    BOOL  fUnused:30;
} MENUBARINFO, *PMENUBARINFO, *LPMENUBARINFO;

inline BOOL WINAPI GetMenuBarInfo(HWND /*hwnd*/, LONG /*idObject*/, LONG /*idItem*/, PMENUBARINFO pmbi) {
    if (pmbi) {
        memset(&pmbi->rcBar, 0, sizeof(pmbi->rcBar));
        pmbi->hMenu = nullptr;
        pmbi->hwndMenu = nullptr;
        pmbi->fBarFocused = FALSE;
        pmbi->fFocused = FALSE;
    }
    return FALSE;
}

#ifdef UNICODE
#define LoadMenu LoadMenuW
#define AppendMenu AppendMenuW
#define InsertMenu InsertMenuW
#define ModifyMenu ModifyMenuW
#define GetMenuString GetMenuStringW
#define GetMenuItemInfo GetMenuItemInfoW
#define SetMenuItemInfo SetMenuItemInfoW
#else
#define LoadMenu LoadMenuA
#define AppendMenu AppendMenuA
#define InsertMenu InsertMenuA
#define ModifyMenu ModifyMenuA
#define GetMenuString GetMenuStringA
#define GetMenuItemInfo GetMenuItemInfoA
#define SetMenuItemInfo SetMenuItemInfoA
#endif

// Scrollbars
BOOL WINAPI GetScrollInfo(HWND hwnd, int nBar, LPSCROLLINFO lpsi);
int WINAPI SetScrollInfo(HWND hwnd, int nBar, LPCSCROLLINFO lpsi, BOOL redraw);
int WINAPI GetScrollPos(HWND hWnd, int nBar);
int WINAPI SetScrollPos(HWND hWnd, int nBar, int nPos, BOOL bRedraw);
BOOL WINAPI GetScrollRange(HWND hWnd, int nBar, LPINT lpMinPos, LPINT lpMaxPos);
BOOL WINAPI SetScrollRange(HWND hWnd, int nBar, int nMinPos, int nMaxPos, BOOL bRedraw);
BOOL WINAPI ShowScrollBar(HWND hWnd, int wBar, BOOL bShow);
BOOL WINAPI EnableScrollBar(HWND hWnd, UINT wSBflags, UINT wArrows);
BOOL WINAPI ScrollWindow(HWND hWnd, int XAmount, int YAmount, const RECT *lpRect, const RECT *lpClipRect);
int WINAPI ScrollWindowEx(HWND hWnd, int dx, int dy, const RECT *prcScroll, const RECT *prcClip, HRGN hrgnUpdate, LPRECT prcUpdate, UINT flags);

// System Metrics & Dialogs
int WINAPI GetSystemMetrics(int nIndex);
BOOL WINAPI SystemParametersInfoA(UINT uiAction, UINT uiParam, PVOID pvParam, UINT fWinIni);
BOOL WINAPI SystemParametersInfoW(UINT uiAction, UINT uiParam, PVOID pvParam, UINT fWinIni);
#ifdef UNICODE
#define SystemParametersInfo SystemParametersInfoW
#else
#define SystemParametersInfo SystemParametersInfoA
#endif
int WINAPI MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType);
int WINAPI MessageBoxW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType);
#ifdef UNICODE
#define MessageBox MessageBoxW
#else
#define MessageBox MessageBoxA
#endif
BOOL WINAPI MessageBeep(UINT uType);

// GDI Functions
HDC WINAPI GetDC(HWND hWnd);
HDC WINAPI GetWindowDC(HWND hWnd);
int WINAPI ReleaseDC(HWND hWnd, HDC hDC);
HDC WINAPI BeginPaint(HWND hWnd, LPPAINTSTRUCT lpPaint);
BOOL WINAPI EndPaint(HWND hWnd, const PAINTSTRUCT *lpPaint);
HDC WINAPI CreateCompatibleDC(HDC hdc);
BOOL WINAPI DeleteDC(HDC hdc);
int WINAPI SaveDC(HDC hdc);
BOOL WINAPI RestoreDC(HDC hdc, int nSavedDC);
HGDIOBJ WINAPI SelectObject(HDC hdc, HGDIOBJ h);
BOOL WINAPI DeleteObject(HGDIOBJ ho);
HGDIOBJ WINAPI GetStockObject(int i);
int WINAPI GetDeviceCaps(HDC hdc, int index);
int WINAPI GetObjectA(HANDLE h, int c, LPVOID pv);
int WINAPI GetObjectW(HANDLE h, int c, LPVOID pv);
#ifdef UNICODE
#define GetObject GetObjectW
#else
#define GetObject GetObjectA
#endif
BOOL WINAPI GdiFlush();

HPEN WINAPI CreatePen(int iStyle, int cWidth, COLORREF color);
HBRUSH WINAPI CreateSolidBrush(COLORREF color);
HBRUSH WINAPI CreatePatternBrush(HBITMAP hbm);
COLORREF WINAPI SetDCBrushColor(HDC hdc, COLORREF color);
COLORREF WINAPI SetDCPenColor(HDC hdc, COLORREF color);
DWORD WINAPI GetSysColor(int nIndex);
HBRUSH WINAPI GetSysColorBrush(int nIndex);

HBITMAP WINAPI CreateBitmap(int nWidth, int nHeight, UINT nPlanes, UINT nBitCount, const VOID *lpBits);
HBITMAP WINAPI CreateCompatibleBitmap(HDC hdc, int cx, int cy);
HBITMAP WINAPI CreateDIBSection(HDC hdc, const BITMAPINFO *pbmi, UINT usage, VOID **ppvBits, HANDLE hSection, DWORD offset);
int WINAPI SetDIBits(HDC hdc, HBITMAP hbm, UINT start, UINT cLines, const VOID *lpBits, const BITMAPINFO *lpbmi, UINT ColorUse);
int WINAPI SetDIBitsToDevice(HDC hdc, int xDest, int yDest, DWORD w, DWORD h, int xSrc, int ySrc, UINT StartScan, UINT cLines, const VOID *lpvBits, const BITMAPINFO *lpbmi, UINT ColorUse);
int WINAPI StretchDIBits(HDC hdc, int xDest, int yDest, int DestWidth, int DestHeight, int xSrc, int ySrc, int SrcWidth, int SrcHeight, const VOID *lpBits, const BITMAPINFO *lpbmi, UINT iUsage, DWORD rop);
BOOL WINAPI BitBlt(HDC hdc, int x, int y, int cx, int cy, HDC hdcSrc, int x1, int y1, DWORD rop);
BOOL WINAPI StretchBlt(HDC hdcDest, int xDest, int yDest, int wDest, int hDest, HDC hdcSrc, int xSrc, int ySrc, int wSrc, int hSrc, DWORD rop);
BOOL WINAPI PatBlt(HDC hdc, int x, int y, int w, int h, DWORD rop);
BOOL WINAPI TransparentBlt(HDC hdcDest, int xoriginDest, int yoriginDest, int wDest, int hDest, HDC hdcSrc, int xoriginSrc, int yoriginSrc, int wSrc, int hSrc, UINT crTransparent);
BOOL WINAPI AlphaBlend(HDC hdcDest, int xoriginDest, int yoriginDest, int wDest, int hDest, HDC hdcSrc, int xoriginSrc, int yoriginSrc, int wSrc, int hSrc, BLENDFUNCTION ftn);
COLORREF WINAPI GetPixel(HDC hdc, int x, int y);
COLORREF WINAPI SetPixel(HDC hdc, int x, int y, COLORREF color);
BOOL WINAPI SetPixelV(HDC hdc, int x, int y, COLORREF color);

BOOL WINAPI MoveToEx(HDC hdc, int x, int y, LPPOINT lppt);
BOOL WINAPI LineTo(HDC hdc, int x, int y);
BOOL WINAPI Polyline(HDC hdc, const POINT *apt, int cpt);
#ifdef Polygon
#undef Polygon
#endif
#define Polygon Win32Polygon
BOOL WINAPI Polygon(HDC hdc, const POINT *apt, int cpt);
BOOL WINAPI Rectangle(HDC hdc, int left, int top, int right, int bottom);
BOOL WINAPI Ellipse(HDC hdc, int left, int top, int right, int bottom);
int WINAPI FillRect(HDC hDC, const RECT *lprc, HBRUSH hbr);
int WINAPI FrameRect(HDC hDC, const RECT *lprc, HBRUSH hbr);
BOOL WINAPI InvertRect(HDC hDC, const RECT *lprc);
BOOL WINAPI DrawFocusRect(HDC hDC, const RECT* lprc);
BOOL WINAPI DrawEdge(HDC hdc, LPRECT qrc, UINT edge, UINT grfFlags);
BOOL WINAPI DrawFrameControl(HDC hdc, LPRECT lprc, UINT uType, UINT uState);
BOOL WINAPI DrawIconEx(HDC hdc, int xLeft, int yTop, HICON hIcon, int cxWidth, int cyWidth, UINT istepIfAniCur, HBRUSH hbrFlickerFreeDraw, UINT diFlags);

int WINAPI GetClipBox(HDC hdc, LPRECT lprect);
int WINAPI IntersectClipRect(HDC hdc, int left, int top, int right, int bottom);
int WINAPI ExcludeClipRect(HDC hdc, int left, int top, int right, int bottom);
int WINAPI SelectClipRgn(HDC hdc, HRGN hrgn);
BOOL WINAPI RectVisible(HDC hdc, const RECT *lprect);

HRGN WINAPI CreateRectRgn(int x1, int y1, int x2, int y2);
HRGN WINAPI CreateRectRgnIndirect(const RECT *lprect);
HRGN WINAPI CreateRoundRectRgn(int x1, int y1, int x2, int y2, int w, int h);
HRGN WINAPI CreatePolygonRgn(const POINT *apt, int cpt, int fnPolyFillMode);
int WINAPI CombineRgn(HRGN hrgnDst, HRGN hrgnSrc1, HRGN hrgnSrc2, int iMode);
BOOL WINAPI PtInRegion(HRGN hrgn, int x, int y);
BOOL WINAPI RectInRegion(HRGN hrgn, const RECT *lprect);

int WINAPI GetROP2(HDC hdc);
int WINAPI SetROP2(HDC hdc, int rop2);
int WINAPI GetPolyFillMode(HDC hdc);
int WINAPI SetPolyFillMode(HDC hdc, int mode);
int WINAPI GetStretchBltMode(HDC hdc);
int WINAPI SetStretchBltMode(HDC hdc, int mode);

COLORREF WINAPI GetBkColor(HDC hdc);
COLORREF WINAPI SetBkColor(HDC hdc, COLORREF color);
int WINAPI GetBkMode(HDC hdc);
int WINAPI SetBkMode(HDC hdc, int mode);
COLORREF WINAPI GetTextColor(HDC hdc);
COLORREF WINAPI SetTextColor(HDC hdc, COLORREF color);

BOOL WINAPI GetViewportOrgEx(HDC hdc, LPPOINT lppt);
BOOL WINAPI SetViewportOrgEx(HDC hdc, int x, int y, LPPOINT lppt);
BOOL WINAPI OffsetViewportOrgEx(HDC hdc, int x, int y, LPPOINT lppt);
BOOL WINAPI GetWindowOrgEx(HDC hdc, LPPOINT lppt);
BOOL WINAPI SetWindowOrgEx(HDC hdc, int x, int y, LPPOINT lppt);
int WINAPI ExtSelectClipRgn(HDC hdc, HRGN hrgn, int mode);

BOOL WINAPI RoundRect(HDC hdc, int left, int top, int right, int bottom, int width, int height);
BOOL WINAPI Arc(HDC hdc, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4);
BOOL WINAPI Pie(HDC hdc, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4);
BOOL WINAPI FillRgn(HDC hdc, HRGN hrgn, HBRUSH hbr);
BOOL WINAPI DrawIcon(HDC hdc, int x, int y, HICON hIcon);

HFONT WINAPI CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut, DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName);
HFONT WINAPI CreateFontW(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut, DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality, DWORD iPitchAndFamily, LPCWSTR pszFaceName);
HFONT WINAPI CreateFontIndirectA(const LOGFONTA *lplf);
HFONT WINAPI CreateFontIndirectW(const LOGFONTW *lplf);
#ifdef UNICODE
#define CreateFont CreateFontW
#define CreateFontIndirect CreateFontIndirectW
#else
#define CreateFont CreateFontA
#define CreateFontIndirect CreateFontIndirectA
#endif
int WINAPI DrawTextA(HDC hdc, LPCSTR lpchText, int cchText, LPRECT lprc, UINT format);
int WINAPI DrawTextW(HDC hdc, LPCWSTR lpchText, int cchText, LPRECT lprc, UINT format);
#ifdef UNICODE
#define DrawText DrawTextW
#else
#define DrawText DrawTextA
#endif
BOOL WINAPI TextOutA(HDC hdc, int x, int y, LPCSTR lpString, int c);
BOOL WINAPI TextOutW(HDC hdc, int x, int y, LPCWSTR lpString, int c);
BOOL WINAPI ExtTextOutA(HDC hdc, int x, int y, UINT options, const RECT *lprect, LPCSTR lpString, UINT c, const INT *lpDx);
BOOL WINAPI ExtTextOutW(HDC hdc, int x, int y, UINT options, const RECT *lprect, LPCWSTR lpString, UINT c, const INT *lpDx);
#ifdef UNICODE
#define TextOut TextOutW
#define ExtTextOut ExtTextOutW
#else
#define TextOut TextOutA
#define ExtTextOut ExtTextOutA
#endif
BOOL WINAPI GetTextMetricsA(HDC hdc, LPTEXTMETRICA lptm);
BOOL WINAPI GetTextMetricsW(HDC hdc, LPTEXTMETRIC lptm);
#ifdef UNICODE
#define GetTextMetrics GetTextMetricsW
#else
#define GetTextMetrics GetTextMetricsA
#endif
inline BOOL WINAPI LPtoDP(HDC, LPPOINT, int) { return TRUE; }
inline BOOL WINAPI DPtoLP(HDC, LPPOINT, int) { return TRUE; }
BOOL WINAPI GetTextExtentPoint32A(HDC hdc, LPCSTR lpString, int c, LPSIZE psizl);
BOOL WINAPI GetTextExtentPoint32W(HDC hdc, LPCWSTR lpString, int c, LPSIZE psizl);
#ifdef UNICODE
#define GetTextExtentPoint32 GetTextExtentPoint32W
#else
#define GetTextExtentPoint32 GetTextExtentPoint32A
#endif
COLORREF WINAPI SetTextColor(HDC hdc, COLORREF color);
COLORREF WINAPI GetTextColor(HDC hdc);
COLORREF WINAPI SetBkColor(HDC hdc, COLORREF color);
COLORREF WINAPI GetBkColor(HDC hdc);
int WINAPI SetBkMode(HDC hdc, int mode);
int WINAPI GetBkMode(HDC hdc);
UINT WINAPI SetTextAlign(HDC hdc, UINT align);

// Common Controls C Macros & Functions
void WINAPI InitCommonControls();
BOOL WINAPI ImageList_RemoveAll(HIMAGELIST himl);
BOOL WINAPI ImageList_Draw(HIMAGELIST himl, int i, HDC hdcDst, int x, int y, UINT fStyle);
int WINAPI ImageList_ReplaceIcon(HIMAGELIST himl, int i, HICON hicon);
int WINAPI ImageList_GetImageCount(HIMAGELIST himl);
BOOL WINAPI ImageList_GetIconSize(HIMAGELIST himl, int *cx, int *cy);
#ifndef SBT_NOBORDERS
#define SBT_NOBORDERS   0x0100
#define SBT_POPOUT      0x0200
#define SBT_RTLREADING  0x0400
#define SBT_OWNERDRAW   0x1000
#endif
#ifndef LVCF_FMT
#define LVCF_FMT        0x0001
#define LVCF_WIDTH      0x0002
#define LVCF_TEXT       0x0004
#define LVCF_SUBITEM    0x0008
#endif
#ifndef TVM_SETBKCOLOR
#define TVM_SETINSERTMARK       (TV_FIRST + 26)
#define TVM_SETBKCOLOR          (TV_FIRST + 29)
#define TVM_SETTEXTCOLOR        (TV_FIRST + 30)
#define TVM_GETBKCOLOR          (TV_FIRST + 31)
#define TVM_GETTEXTCOLOR        (TV_FIRST + 32)
#define TVM_SETSCROLLTIME       (TV_FIRST + 33)
#define TVM_SETEXTENDEDSTYLE    (TV_FIRST + 44)
#endif
#ifndef LVN_KEYDOWN_STRUCT_DEFINED
#define LVN_KEYDOWN_STRUCT_DEFINED
struct NMLVKEYDOWN {
    NMHDR hdr;
    WORD wVKey;
    UINT flags;
};
typedef NMLVKEYDOWN* LPNMLVKEYDOWN;
#endif
#ifndef CB_GETCOMBOBOXINFO
#define CB_GETCOMBOBOXINFO      0x0164
#endif
#ifndef CB_SETCUEBANNER
#define CB_SETCUEBANNER         0x1703
#endif
#ifndef CBEM_SETEXTENDEDSTYLE
#define CBEM_SETEXTENDEDSTYLE   (WM_USER + 14)
#endif
#ifndef SBS_HORZ
#define SBS_HORZ        0x0000L
#define SBS_VERT        0x0001L
#endif
#ifndef WS_EX_NOACTIVATE
#define WS_EX_NOACTIVATE 0x08000000L
#endif
#ifndef STN_CLICKED
#define STN_CLICKED     0
#define STN_DBLCLK      1
#define STN_ENABLE      2
#define STN_DISABLE     3
#endif
#ifndef EM_SETCUEBANNER
#define EM_SETCUEBANNER 0x1501
#endif
BOOL WINAPI ImageList_SetIconSize(HIMAGELIST himl, int cx, int cy);
HRESULT WINAPI LoadIconWithScaleDown(HINSTANCE hinst, LPCWSTR pszName, int cx, int cy, HICON *phico);

#define ListView_EnableGroupView(hwnd, fEnable) \
    ::SendMessage((hwnd), LVM_ENABLEGROUPVIEW, (WPARAM)(fEnable), 0)
#define ListView_InsertGroup(hwnd, index, pgrp) \
    (int)::SendMessage((hwnd), LVM_INSERTGROUP, (WPARAM)(index), (LPARAM)(pgrp))
#define ListView_RemoveAllGroups(hwnd) \
    ::SendMessage((hwnd), LVM_REMOVEALLGROUPS, 0, 0)
#define ListView_SetGroupInfo(hwnd, iGroupId, pgrp) \
    (int)::SendMessage((hwnd), LVM_SETGROUPINFO, (WPARAM)(iGroupId), (LPARAM)(pgrp))
#define ListView_GetGroupState(hwnd, dwGroupId, dwMask) \
    (UINT)::SendMessage((hwnd), LVM_GETGROUPSTATE, (WPARAM)(dwGroupId), (LPARAM)(dwMask))
inline LRESULT ListView_SetGroupState(HWND hwnd, int iGroupId, UINT dwMask, UINT dwState) {
    LVGROUP lvg{};
    lvg.cbSize = sizeof(lvg);
    lvg.mask = LVGF_STATE;
    lvg.stateMask = dwMask;
    lvg.state = dwState;
    return ::SendMessage(hwnd, LVM_SETGROUPINFO, (WPARAM)iGroupId, (LPARAM)&lvg);
}

#define TabCtrl_GetCurFocus(hwnd) \
    (int)::SendMessage((hwnd), 0x132F, 0, 0)
#define TabCtrl_InsertItem(hwnd, iItem, pitem) \
    (int)::SendMessage((hwnd), 0x1307, (WPARAM)(int)(iItem), (LPARAM)(const TCITEM *)(pitem))
#define Edit_LimitText(hwndCtl, cchMax) \
    ((void)::SendMessage((hwndCtl), EM_LIMITTEXT, (WPARAM)(cchMax), 0L))

// Shell & COM Functions
void WINAPI DragAcceptFiles(HWND hWnd, BOOL fAccept);
UINT WINAPI DragQueryFileA(HDROP hDrop, UINT iFile, LPSTR lpszFile, UINT cch);
UINT WINAPI DragQueryFileW(HDROP hDrop, UINT iFile, LPWSTR lpszFile, UINT cch);
#ifdef UNICODE
#define DragQueryFile DragQueryFileW
#else
#define DragQueryFile DragQueryFileA
#endif
void WINAPI DragFinish(HDROP hDrop);

HINSTANCE WINAPI ShellExecuteA(HWND hwnd, LPCSTR lpOperation, LPCSTR lpFile, LPCSTR lpParameters, LPCSTR lpDirectory, INT nShowCmd);
HINSTANCE WINAPI ShellExecuteW(HWND hwnd, LPCWSTR lpOperation, LPCWSTR lpFile, LPCWSTR lpParameters, LPCWSTR lpDirectory, INT nShowCmd);
inline HINSTANCE WINAPI ShellExecuteW(HWND hwnd, LPCWSTR lpOperation, LPCSTR lpFile, LPCWSTR lpParameters, LPCWSTR lpDirectory, INT nShowCmd) {
    if (!lpFile) return ShellExecuteW(hwnd, lpOperation, (LPCWSTR)nullptr, lpParameters, lpDirectory, nShowCmd);
    std::wstring wFile;
    int len = (int)strlen(lpFile);
    wFile.resize(len);
    for (int i = 0; i < len; ++i) wFile[i] = (wchar_t)(unsigned char)lpFile[i];
    return ShellExecuteW(hwnd, lpOperation, wFile.c_str(), lpParameters, lpDirectory, nShowCmd);
}
HRESULT WINAPI SHGetFolderPathA(HWND hwnd, int csidl, HANDLE hToken, DWORD dwFlags, LPSTR pszPath);
HRESULT WINAPI SHGetFolderPathW(HWND hwnd, int csidl, HANDLE hToken, DWORD dwFlags, LPWSTR pszPath);
BOOL WINAPI SHGetSpecialFolderPathA(HWND hwnd, LPSTR pszPath, int csidl, BOOL fCreate);
BOOL WINAPI SHGetSpecialFolderPathW(HWND hwnd, LPWSTR pszPath, int csidl, BOOL fCreate);
LPITEMIDLIST WINAPI SHBrowseForFolderA(LPBROWSEINFOA lpbi);
LPITEMIDLIST WINAPI SHBrowseForFolderW(LPBROWSEINFOW lpbi);
BOOL WINAPI SHGetPathFromIDListA(LPCITEMIDLIST pidl, LPSTR pszPath);
BOOL WINAPI SHGetPathFromIDListW(LPCITEMIDLIST pidl, LPWSTR pszPath);
int WINAPI SHFileOperationA(LPSHFILEOPSTRUCTA lpFileOp);
int WINAPI SHFileOperationW(LPSHFILEOPSTRUCTW lpFileOp);
DWORD_PTR WINAPI SHGetFileInfoA(LPCSTR pszPath, DWORD dwFileAttributes, SHFILEINFOA *psfi, UINT cbFileInfo, UINT uFlags);
DWORD_PTR WINAPI SHGetFileInfoW(LPCWSTR pszPath, DWORD dwFileAttributes, SHFILEINFOW *psfi, UINT cbFileInfo, UINT uFlags);
int WINAPI SHCreateDirectoryExA(HWND hwnd, LPCSTR pszPath, const SECURITY_ATTRIBUTES *psa);
int WINAPI SHCreateDirectoryExW(HWND hwnd, LPCWSTR pszPath, const SECURITY_ATTRIBUTES *psa);
inline int WINAPI SHCreateDirectoryExW(HWND hwnd, LPCSTR pszPath, const SECURITY_ATTRIBUTES *psa) { return SHCreateDirectoryExA(hwnd, pszPath, psa); }
BOOL WINAPI ChooseColorA(LPCHOOSECOLORA lpcc);
BOOL WINAPI ChooseColorW(LPCHOOSECOLORW lpcc);
BOOL WINAPI GetOpenFileNameA(LPOPENFILENAMEA lpofn);
BOOL WINAPI GetOpenFileNameW(LPOPENFILENAMEW lpofn);
#ifdef UNICODE
#define ShellExecute ShellExecuteW
#define SHGetFolderPath SHGetFolderPathW
#define SHGetSpecialFolderPath SHGetSpecialFolderPathW
#define SHBrowseForFolder SHBrowseForFolderW
#define SHGetPathFromIDList SHGetPathFromIDListW
#define SHFileOperation SHFileOperationW
#define SHGetFileInfo SHGetFileInfoW
#define SHCreateDirectoryEx SHCreateDirectoryExW
#define ChooseColor ChooseColorW
#define GetOpenFileName GetOpenFileNameW
#else
#define ShellExecute ShellExecuteA
#define SHGetFolderPath SHGetFolderPathA
#define SHGetSpecialFolderPath SHGetSpecialFolderPathA
#define SHBrowseForFolder SHBrowseForFolderA
#define SHGetPathFromIDList SHGetPathFromIDListA
#define SHFileOperation SHFileOperationA
#define SHGetFileInfo SHGetFileInfoA
#define SHCreateDirectoryEx SHCreateDirectoryExA
#define ChooseColor ChooseColorA
#define GetOpenFileName GetOpenFileNameA
#endif

// COM Basics
#define COINIT_APARTMENTTHREADED 0x2
#define COINIT_MULTITHREADED     0x0
#define CLSCTX_INPROC_SERVER     0x1
#define CLSCTX_LOCAL_SERVER      0x4
#define CLSCTX_ALL               (CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER)

struct IUnknown {
    virtual HRESULT QueryInterface(REFIID riid, void **ppvObject) = 0;
    virtual ULONG AddRef() = 0;
    virtual ULONG Release() = 0;
    virtual ~IUnknown() = default;
};

#ifndef IID_IUnknown
static const IID IID_IUnknown = {0x00000000, 0x0000, 0x0000, {0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46}};
#endif
#define ResultFromScode(s) ((HRESULT)(s))

typedef struct tagSTATSTG {
    LPOLESTR pwcsName;
    DWORD type;
    ULARGE_INTEGER cbSize;
    FILETIME mtime;
    FILETIME ctime;
    FILETIME atime;
    DWORD grfMode;
    DWORD grfLocksSupported;
    CLSID clsid;
    DWORD grfStateBits;
    DWORD reserved;
} STATSTG;

struct IStream : public IUnknown {
    virtual HRESULT Read(void *pv, ULONG cb, ULONG *pcbRead) = 0;
    virtual HRESULT Write(const void *pv, ULONG cb, ULONG *pcbWritten) = 0;
    virtual HRESULT Stat(STATSTG *pstatstg, DWORD grfStatFlag) = 0;
};

HRESULT WINAPI CoInitialize(LPVOID pvReserved);
HRESULT WINAPI CoInitializeEx(LPVOID pvReserved, DWORD dwCoInit);
void WINAPI CoUninitialize();
HRESULT WINAPI CoCreateInstance(REFCLSID rclsid, IUnknown* pUnkOuter, DWORD dwClsContext, REFIID riid, LPVOID* ppv);
#define CO_E_CLASSSTRING        ((HRESULT)0x800401F3L)
#define REGDB_E_CLASSNOTREG     ((HRESULT)0x80040154L)
#define REGDB_E_READREGDB       ((HRESULT)0x80040150L)

inline LPVOID WINAPI CoTaskMemAlloc(SIZE_T cb) {
    return malloc(cb);
}
void WINAPI CoTaskMemFree(LPVOID pv);

inline HRESULT WINAPI StringFromCLSID(REFCLSID rclsid, LPOLESTR *lplpsz) {
    if (!lplpsz) return E_POINTER;
    WCHAR* buf = (WCHAR*)CoTaskMemAlloc(40 * sizeof(WCHAR));
    if (!buf) return E_OUTOFMEMORY;
    swprintf(buf, 40, L"{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        rclsid.Data1, rclsid.Data2, rclsid.Data3,
        rclsid.Data4[0], rclsid.Data4[1], rclsid.Data4[2], rclsid.Data4[3],
        rclsid.Data4[4], rclsid.Data4[5], rclsid.Data4[6], rclsid.Data4[7]);
    *lplpsz = buf;
    return S_OK;
}

inline HRESULT WINAPI CLSIDFromString(LPCOLESTR lpsz, CLSID *pclsid) {
    if (!lpsz || !pclsid) return E_INVALIDARG;
    unsigned int d1, d2, d3, d4_0, d4_1, d4_2, d4_3, d4_4, d4_5, d4_6, d4_7;
    if (swscanf(lpsz, L"{%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x}",
        &d1, &d2, &d3, &d4_0, &d4_1, &d4_2, &d4_3, &d4_4, &d4_5, &d4_6, &d4_7) == 11 ||
        swscanf(lpsz, L"%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        &d1, &d2, &d3, &d4_0, &d4_1, &d4_2, &d4_3, &d4_4, &d4_5, &d4_6, &d4_7) == 11) {
        pclsid->Data1 = d1;
        pclsid->Data2 = (unsigned short)d2;
        pclsid->Data3 = (unsigned short)d3;
        pclsid->Data4[0] = (unsigned char)d4_0;
        pclsid->Data4[1] = (unsigned char)d4_1;
        pclsid->Data4[2] = (unsigned char)d4_2;
        pclsid->Data4[3] = (unsigned char)d4_3;
        pclsid->Data4[4] = (unsigned char)d4_4;
        pclsid->Data4[5] = (unsigned char)d4_5;
        pclsid->Data4[6] = (unsigned char)d4_6;
        pclsid->Data4[7] = (unsigned char)d4_7;
        return S_OK;
    }
    return CO_E_CLASSSTRING;
}
inline HRESULT WINAPI IIDFromString(LPCOLESTR lpsz, IID *piid) {
    return CLSIDFromString(lpsz, piid);
}
inline HRESULT WINAPI StringFromIID(REFIID rclsid, LPOLESTR *lplpsz) {
    return StringFromCLSID(rclsid, lplpsz);
}
inline int WINAPI StringFromGUID2(REFGUID rguid, LPOLESTR lpsz, int cchMax) {
    if (!lpsz || cchMax < 39) return 0;
    swprintf(lpsz, cchMax, L"{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        rguid.Data1, rguid.Data2, rguid.Data3,
        rguid.Data4[0], rguid.Data4[1], rguid.Data4[2], rguid.Data4[3],
        rguid.Data4[4], rguid.Data4[5], rguid.Data4[6], rguid.Data4[7]);
    return 39;
}
inline HRESULT WINAPI CoCreateGuid(GUID *pguid) {
    if (!pguid) return E_INVALIDARG;
    arc4random_buf(pguid, sizeof(GUID));
    pguid->Data3 = (pguid->Data3 & 0x0FFF) | 0x4000;
    pguid->Data4[0] = (pguid->Data4[0] & 0x3F) | 0x80;
    return S_OK;
}
inline BSTR WINAPI SysAllocString(const OLECHAR *psz) {
    if (!psz) return nullptr;
    size_t len = wcslen(psz);
    uint32_t* p = (uint32_t*)malloc(sizeof(uint32_t) + (len + 1) * sizeof(OLECHAR));
    if (!p) return nullptr;
    *p = (uint32_t)(len * sizeof(OLECHAR));
    OLECHAR* bstr = (OLECHAR*)(p + 1);
    wcscpy(bstr, psz);
    return bstr;
}
inline void WINAPI SysFreeString(BSTR bstrString) {
    if (bstrString) {
        uint32_t* p = ((uint32_t*)bstrString) - 1;
        free(p);
    }
}
HRESULT WINAPI CreateStreamOnHGlobal(HGLOBAL hGlobal, BOOL fDeleteOnRelease, IStream **ppstm);
IStream* WINAPI SHCreateMemStream(const BYTE *pInit, UINT cbInit);

#define HELP_CONTEXT        0x0001
#define HELP_QUIT           0x0002
#define HELP_INDEX          0x0003
#define HELP_CONTENTS       0x0003
#define HELP_HELPONHELP     0x0004
#define HELP_SETINDEX       0x0005
#define HELP_KEY            0x0101
#define HELP_MULTIKEY       0x0201
#define HELP_FINDER         0x000b

BOOL WINAPI WinHelpA(HWND hWndMain, LPCSTR lpszHelp, UINT uCommand, ULONG_PTR dwData);
BOOL WINAPI WinHelpW(HWND hWndMain, LPCWSTR lpszHelp, UINT uCommand, ULONG_PTR dwData);
#ifdef UNICODE
#define WinHelp WinHelpW
#else
#define WinHelp WinHelpA
#endif

#define HH_DISPLAY_TOPIC        0x0000
#define HH_HELP_FINDER          0x0000
#define HH_DISPLAY_TOC          0x0001
#define HH_DISPLAY_INDEX        0x0002
#define HH_DISPLAY_SEARCH       0x0003
#define HH_SET_WIN_TYPE         0x0004
#define HH_GET_WIN_TYPE         0x0005
#define HH_GET_WIN_HANDLE       0x0006
#define HH_ENUM_INFO_TYPE       0x0007
#define HH_SET_INFO_TYPE        0x0008
#define HH_SYNC                 0x0009
#define HH_ADD_NAV_UI           0x000A
#define HH_ADD_URL              0x000B
#define HH_CLOSE_ALL            0x0012
#define HH_ALINK_LOOKUP         0x0013
#define HH_KEYWORD_LOOKUP       0x000D
#define HH_INITIALIZE           0x001B
#define HH_UNINITIALIZE         0x001C

inline HWND WINAPI HtmlHelpA(HWND /*hwndCaller*/, LPCSTR /*pszFile*/, UINT /*uCommand*/, DWORD_PTR /*dwData*/) { return NULL; }
inline HWND WINAPI HtmlHelpW(HWND /*hwndCaller*/, LPCWSTR /*pszFile*/, UINT /*uCommand*/, DWORD_PTR /*dwData*/) { return NULL; }
inline HWND WINAPI HtmlHelp(HWND h, LPCSTR f, UINT c, DWORD_PTR d) { return HtmlHelpA(h, f, c, d); }
inline HWND WINAPI HtmlHelp(HWND h, LPCWSTR f, UINT c, DWORD_PTR d) { return HtmlHelpW(h, f, c, d); }
inline HWND WINAPI HtmlHelp(HWND h, std::nullptr_t, UINT c, DWORD_PTR d) { return HtmlHelpW(h, nullptr, c, d); }

inline BOOL WINAPI DeviceIoControl(HANDLE, DWORD, LPVOID, DWORD, LPVOID, DWORD, LPDWORD, LPOVERLAPPED) { return FALSE; }

#include "winreg.h"
