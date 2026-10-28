#pragma once

#include "windows.h"

extern "C" {
BOOL WINAPI PathIsRelativeA(LPCSTR lpszPath);
BOOL WINAPI PathIsRelativeW(LPCWSTR lpszPath);
BOOL WINAPI PathRelativePathToA(LPSTR pszPath, LPCSTR pszFrom, DWORD dwAttrFrom, LPCSTR pszTo, DWORD dwAttrTo);
BOOL WINAPI PathRelativePathToW(LPWSTR pszPath, LPCWSTR pszFrom, DWORD dwAttrFrom, LPCWSTR pszTo, DWORD dwAttrTo);
BOOL WINAPI PathCanonicalizeA(LPSTR lpszDst, LPCSTR lpszSrc);
BOOL WINAPI PathCanonicalizeW(LPWSTR lpszDst, LPCWSTR lpszSrc);
BOOL WINAPI PathFileExistsA(LPCSTR pszPath);
BOOL WINAPI PathFileExistsW(LPCWSTR pszPath);
LPSTR WINAPI PathFindFileNameA(LPCSTR pszPath);
LPWSTR WINAPI PathFindFileNameW(LPCWSTR pszPath);
LPSTR WINAPI PathFindExtensionA(LPCSTR pszPath);
LPWSTR WINAPI PathFindExtensionW(LPCWSTR pszPath);
BOOL WINAPI PathRemoveFileSpecA(LPSTR pszPath);
BOOL WINAPI PathRemoveFileSpecW(LPWSTR pszPath);

}

inline BOOL PathIsRelative(LPCSTR pszPath) { return PathIsRelativeA(pszPath); }
inline BOOL PathIsRelative(LPCWSTR pszPath) { return PathIsRelativeW(pszPath); }
inline BOOL PathRelativePathTo(LPSTR pszPath, LPCSTR pszFrom, DWORD dwAttrFrom, LPCSTR pszTo, DWORD dwAttrTo) {
    return PathRelativePathToA(pszPath, pszFrom, dwAttrFrom, pszTo, dwAttrTo);
}
inline BOOL PathRelativePathTo(LPWSTR pszPath, LPCWSTR pszFrom, DWORD dwAttrFrom, LPCWSTR pszTo, DWORD dwAttrTo) {
    return PathRelativePathToW(pszPath, pszFrom, dwAttrFrom, pszTo, dwAttrTo);
}
inline BOOL PathCanonicalize(LPSTR lpszDst, LPCSTR lpszSrc) { return PathCanonicalizeA(lpszDst, lpszSrc); }
inline BOOL PathCanonicalize(LPWSTR lpszDst, LPCWSTR lpszSrc) { return PathCanonicalizeW(lpszDst, lpszSrc); }
inline BOOL PathFileExists(LPCSTR pszPath) { return PathFileExistsA(pszPath); }
inline BOOL PathFileExists(LPCWSTR pszPath) { return PathFileExistsW(pszPath); }
inline LPSTR PathFindFileName(LPCSTR pszPath) { return PathFindFileNameA(pszPath); }
inline LPWSTR PathFindFileName(LPCWSTR pszPath) { return PathFindFileNameW(pszPath); }
inline LPSTR PathFindExtension(LPCSTR pszPath) { return PathFindExtensionA(pszPath); }
inline LPWSTR PathFindExtension(LPCWSTR pszPath) { return PathFindExtensionW(pszPath); }
inline BOOL PathRemoveFileSpec(LPSTR pszPath) { return PathRemoveFileSpecA(pszPath); }
inline BOOL PathRemoveFileSpec(LPWSTR pszPath) { return PathRemoveFileSpecW(pszPath); }

#include <fnmatch.h>

inline BOOL PathMatchSpecA(LPCSTR pszFile, LPCSTR pszSpec) {
    if (!pszFile || !pszSpec) return FALSE;
    return fnmatch(pszSpec, pszFile, FNM_CASEFOLD) == 0 ? TRUE : FALSE;
}

inline BOOL PathMatchSpecW(LPCWSTR pszFile, LPCWSTR pszSpec) {
    if (!pszFile || !pszSpec) return FALSE;
    int lenF = WideCharToMultiByte(CP_UTF8, 0, pszFile, -1, nullptr, 0, nullptr, nullptr);
    int lenS = WideCharToMultiByte(CP_UTF8, 0, pszSpec, -1, nullptr, 0, nullptr, nullptr);
    std::string sFile(lenF > 0 ? lenF : 1, 0);
    std::string sSpec(lenS > 0 ? lenS : 1, 0);
    WideCharToMultiByte(CP_UTF8, 0, pszFile, -1, &sFile[0], lenF, nullptr, nullptr);
    WideCharToMultiByte(CP_UTF8, 0, pszSpec, -1, &sSpec[0], lenS, nullptr, nullptr);
    return fnmatch(sSpec.c_str(), sFile.c_str(), FNM_CASEFOLD) == 0 ? TRUE : FALSE;
}

inline BOOL PathMatchSpecW(LPCSTR pszFile, LPCWSTR pszSpec) {
    int lenS = WideCharToMultiByte(CP_UTF8, 0, pszSpec, -1, nullptr, 0, nullptr, nullptr);
    std::string sSpec(lenS > 0 ? lenS : 1, 0);
    WideCharToMultiByte(CP_UTF8, 0, pszSpec, -1, &sSpec[0], lenS, nullptr, nullptr);
    return PathMatchSpecA(pszFile, sSpec.c_str());
}

#ifdef UNICODE
#define PathMatchSpec PathMatchSpecW
#else
#define PathMatchSpec PathMatchSpecA
#endif
