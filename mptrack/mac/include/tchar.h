#pragma once

#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <cwchar>
#include <utility>

#ifdef UNICODE
typedef wchar_t TCHAR;
typedef wchar_t _TCHAR;
typedef wchar_t _TUCHAR;
#define _T(x) L##x
#define __T(x) L##x
#define _TEXT(x) L##x
#define _tcslen wcslen
#define _tcscpy wcscpy
#define _tcsncpy wcsncpy
#define _tcscat wcscat
#define _tcscmp wcscmp
#define _tcsncmp wcsncmp
template<typename T1, typename T2>
inline int _tcsicmp_helper(const T1* s1, const T2* s2) {
    if constexpr (sizeof(T1) == sizeof(wchar_t)) {
        return wcscasecmp(reinterpret_cast<const wchar_t*>(s1), reinterpret_cast<const wchar_t*>(s2));
    } else {
        return strcasecmp(reinterpret_cast<const char*>(s1), reinterpret_cast<const char*>(s2));
    }
}
template<typename T1, typename T2>
inline int _tcsncicmp_helper(const T1* s1, const T2* s2, size_t n) {
    if constexpr (sizeof(T1) == sizeof(wchar_t)) {
        return wcsncasecmp(reinterpret_cast<const wchar_t*>(s1), reinterpret_cast<const wchar_t*>(s2), n);
    } else {
        return strncasecmp(reinterpret_cast<const char*>(s1), reinterpret_cast<const char*>(s2), n);
    }
}
#define _tcsicmp _tcsicmp_helper
#define _tcsnicmp _tcsncicmp_helper
#define _tcsncicmp _tcsncicmp_helper
#define _tcschr wcschr
#define _tcsrchr wcsrchr
#define _tcsstr wcsstr
template<typename... Args>
inline int _stprintf_helper(wchar_t* buf, const wchar_t* format, Args&&... args) {
    return swprintf(buf, 1024, format, std::forward<Args>(args)...);
}
template<typename... Args>
inline int _stprintf_helper(wchar_t* buf, size_t maxlen, const wchar_t* format, Args&&... args) {
    return swprintf(buf, maxlen, format, std::forward<Args>(args)...);
}
#define _stprintf _stprintf_helper
#define _sntprintf swprintf
#define _vstprintf vswprintf
#define _tcstol wcstol
#define _tcstoul wcstoul
#define _tcstod wcstod
#define _tstoi(s) ((int)wcstol((s), nullptr, 10))
#define _ttoi _tstoi
#define _tstof(s) wcstod((s), nullptr)
#define _tcsdup wcsdup
#define _tfopen(p, m) fopen("", "r")
#else
typedef char TCHAR;
typedef char _TCHAR;
typedef unsigned char _TUCHAR;
#define _T(x) x
#define __T(x) x
#define _TEXT(x) x
#define _tcslen strlen
#define _tcscpy strcpy
#define _tcsncpy strncpy
#define _tcscat strcat
#define _tcscmp strcmp
#define _tcsncmp strncmp
#define _tcsicmp strcasecmp
#define _tcsnicmp strncasecmp
#define _tcsncicmp strncasecmp
#define _tcschr strchr
#define _tcsrchr strrchr
#define _tcsstr strstr
#define _stprintf sprintf
#define _sntprintf snprintf
#define _vstprintf vsnprintf
#define _tcstol strtol
#define _tcstoul strtoul
#define _tcstod strtod
#define _tstoi atoi
#define _tstof atof
#define _tcsdup strdup
#define _tfopen fopen
#define _tcscpy_s(dst, sz, src) strncpy((dst), (src), (sz))
#define _tcsncpy_s(dst, sz, src, cnt) strncpy((dst), (src), (cnt))
#define _stprintf_s snprintf
#endif

#define _stricmp strcasecmp
#define _strnicmp strncasecmp
#define _wcsicmp wcscasecmp
#define _wcsnicmp wcsncasecmp
#define _snprintf snprintf
#define _vsnprintf vsnprintf
#define _strdup strdup
#define _wcsdup wcsdup
#define strcpy_s(dst, sz, src) strncpy((dst), (src), (sz))
#define sprintf_s snprintf
