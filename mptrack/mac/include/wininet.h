#pragma once

#include "windows.h"

typedef LPVOID HINTERNET;
typedef WORD INTERNET_PORT;
typedef int INTERNET_SCHEME;

#define INTERNET_INVALID_PORT_NUMBER    0
#define INTERNET_DEFAULT_FTP_PORT       21
#define INTERNET_DEFAULT_HTTP_PORT      80
#define INTERNET_DEFAULT_HTTPS_PORT     443

#define INTERNET_OPEN_TYPE_PRECONFIG    0
#define INTERNET_OPEN_TYPE_DIRECT       1
#define INTERNET_OPEN_TYPE_PROXY        3

#define INTERNET_SERVICE_FTP            1
#define INTERNET_SERVICE_GOPHER         2
#define INTERNET_SERVICE_HTTP           3

#define INTERNET_SCHEME_HTTP            3
#define INTERNET_SCHEME_HTTPS           4

#define INTERNET_FLAG_RELOAD            0x80000000
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000
#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100
#define INTERNET_FLAG_SECURE            0x00800000
#define INTERNET_FLAG_KEEP_CONNECTION   0x00400000
#define INTERNET_FLAG_NO_AUTO_REDIRECT  0x00200000
#define INTERNET_FLAG_READ_PREFETCH     0x00100000
#define INTERNET_FLAG_NO_COOKIES        0x00080000
#define INTERNET_FLAG_NO_AUTH           0x00040000
#define INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTP   0x00008000
#define INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTPS  0x00004000
#define INTERNET_FLAG_IGNORE_CERT_DATE_INVALID  0x00002000
#define INTERNET_FLAG_IGNORE_CERT_CN_INVALID    0x00001000

#define HTTP_QUERY_STATUS_CODE          19
#define HTTP_QUERY_CONTENT_LENGTH       5
#define HTTP_QUERY_FLAG_NUMBER          0x20000000

inline BOOL WINAPI InternetGetConnectedState(LPDWORD lpdwFlags, DWORD) {
    if (lpdwFlags) *lpdwFlags = 0;
    return TRUE;
}

inline BOOL WINAPI InternetCloseHandle(HINTERNET hInternet) {
    (void)hInternet;
    return TRUE;
}

inline HINTERNET WINAPI InternetOpenW(LPCWSTR lpszAgent, DWORD dwAccessType, LPCWSTR lpszProxy, LPCWSTR lpszProxyBypass, DWORD dwFlags) {
    (void)lpszAgent; (void)dwAccessType; (void)lpszProxy; (void)lpszProxyBypass; (void)dwFlags;
    return (HINTERNET)(uintptr_t)1;
}
inline HINTERNET WINAPI InternetOpenA(LPCSTR lpszAgent, DWORD dwAccessType, LPCSTR lpszProxy, LPCSTR lpszProxyBypass, DWORD dwFlags) {
    (void)lpszAgent; (void)dwAccessType; (void)lpszProxy; (void)lpszProxyBypass; (void)dwFlags;
    return (HINTERNET)(uintptr_t)1;
}
#ifdef UNICODE
#define InternetOpen InternetOpenW
#else
#define InternetOpen InternetOpenA
#endif

inline HINTERNET WINAPI InternetConnectW(HINTERNET hInternet, LPCWSTR lpszServerName, INTERNET_PORT nServerPort, LPCWSTR lpszUserName, LPCWSTR lpszPassword, DWORD dwService, DWORD dwFlags, DWORD_PTR dwContext) {
    (void)hInternet; (void)lpszServerName; (void)nServerPort; (void)lpszUserName; (void)lpszPassword; (void)dwService; (void)dwFlags; (void)dwContext;
    return (HINTERNET)(uintptr_t)2;
}
inline HINTERNET WINAPI InternetConnectA(HINTERNET hInternet, LPCSTR lpszServerName, INTERNET_PORT nServerPort, LPCSTR lpszUserName, LPCSTR lpszPassword, DWORD dwService, DWORD dwFlags, DWORD_PTR dwContext) {
    (void)hInternet; (void)lpszServerName; (void)nServerPort; (void)lpszUserName; (void)lpszPassword; (void)dwService; (void)dwFlags; (void)dwContext;
    return (HINTERNET)(uintptr_t)2;
}
#ifdef UNICODE
#define InternetConnect InternetConnectW
#else
#define InternetConnect InternetConnectA
#endif

inline HINTERNET WINAPI HttpOpenRequestW(HINTERNET hConnect, LPCWSTR lpszVerb, LPCWSTR lpszObjectName, LPCWSTR lpszVersion, LPCWSTR lpszReferrer, LPCWSTR *lplpszAcceptTypes, DWORD dwFlags, DWORD_PTR dwContext) {
    (void)hConnect; (void)lpszVerb; (void)lpszObjectName; (void)lpszVersion; (void)lpszReferrer; (void)lplpszAcceptTypes; (void)dwFlags; (void)dwContext;
    return (HINTERNET)(uintptr_t)3;
}
inline HINTERNET WINAPI HttpOpenRequestA(HINTERNET hConnect, LPCSTR lpszVerb, LPCSTR lpszObjectName, LPCSTR lpszVersion, LPCSTR lpszReferrer, LPCSTR *lplpszAcceptTypes, DWORD dwFlags, DWORD_PTR dwContext) {
    (void)hConnect; (void)lpszVerb; (void)lpszObjectName; (void)lpszVersion; (void)lpszReferrer; (void)lplpszAcceptTypes; (void)dwFlags; (void)dwContext;
    return (HINTERNET)(uintptr_t)3;
}
#ifdef UNICODE
#define HttpOpenRequest HttpOpenRequestW
#else
#define HttpOpenRequest HttpOpenRequestA
#endif

inline BOOL WINAPI HttpSendRequestW(HINTERNET hRequest, LPCWSTR lpszHeaders, DWORD dwHeadersLength, LPVOID lpOptional, DWORD dwOptionalLength) {
    (void)hRequest; (void)lpszHeaders; (void)dwHeadersLength; (void)lpOptional; (void)dwOptionalLength;
    return FALSE;
}
inline BOOL WINAPI HttpSendRequestA(HINTERNET hRequest, LPCSTR lpszHeaders, DWORD dwHeadersLength, LPVOID lpOptional, DWORD dwOptionalLength) {
    (void)hRequest; (void)lpszHeaders; (void)dwHeadersLength; (void)lpOptional; (void)dwOptionalLength;
    return FALSE;
}
#ifdef UNICODE
#define HttpSendRequest HttpSendRequestW
#else
#define HttpSendRequest HttpSendRequestA
#endif

inline BOOL WINAPI HttpQueryInfoW(HINTERNET hRequest, DWORD dwInfoLevel, LPVOID lpBuffer, LPDWORD lpdwBufferLength, LPDWORD lpdwIndex) {
    (void)hRequest; (void)dwInfoLevel; (void)lpBuffer; (void)lpdwBufferLength; (void)lpdwIndex;
    return FALSE;
}
inline BOOL WINAPI HttpQueryInfoA(HINTERNET hRequest, DWORD dwInfoLevel, LPVOID lpBuffer, LPDWORD lpdwBufferLength, LPDWORD lpdwIndex) {
    (void)hRequest; (void)dwInfoLevel; (void)lpBuffer; (void)lpdwBufferLength; (void)lpdwIndex;
    return FALSE;
}
#ifdef UNICODE
#define HttpQueryInfo HttpQueryInfoW
#else
#define HttpQueryInfo HttpQueryInfoA
#endif

inline BOOL WINAPI InternetQueryDataAvailable(HINTERNET hFile, LPDWORD lpdwNumberOfBytesAvailable, DWORD dwFlags, DWORD_PTR dwContext) {
    (void)hFile; (void)dwFlags; (void)dwContext;
    if (lpdwNumberOfBytesAvailable) *lpdwNumberOfBytesAvailable = 0;
    return FALSE;
}

inline BOOL WINAPI InternetReadFile(HINTERNET hFile, LPVOID lpBuffer, DWORD dwNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead) {
    (void)hFile; (void)lpBuffer; (void)dwNumberOfBytesToRead;
    if (lpNumberOfBytesRead) *lpNumberOfBytesRead = 0;
    return FALSE;
}
