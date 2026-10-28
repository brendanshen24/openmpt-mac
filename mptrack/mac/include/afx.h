#pragma once

#include "windows.h"
#include "tchar.h"
#include "afxres.h"

#include <string>
#include <cstring>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <cwctype>
#include <vector>
#include <algorithm>
#include <stdexcept>
#include <new>

#ifndef ASSERT
#define ASSERT(f) ((void)0)
#endif
#ifndef VERIFY
#define VERIFY(f) ((void)(f))
#endif
#ifndef ASSERT_VALID
#define ASSERT_VALID(pOb) ((void)0)
#endif
#ifndef TRACE
#define TRACE(...) ((void)0)
#endif
#ifndef TRACE0
#define TRACE0(sz) ((void)0)
#endif
#ifndef DEBUG_NEW
#define DEBUG_NEW new
#endif

#ifndef AFXAPI
#define AFXAPI
#endif
#ifndef afx_msg
#define afx_msg
#endif
#ifndef AFX_CDECL
#define AFX_CDECL
#endif
#ifndef AFX_DATA
#define AFX_DATA
#endif
#ifndef AFX_DATADEF
#define AFX_DATADEF
#endif

// POSITION type for MFC collections / iteration
struct __POSITION {};
typedef __POSITION* POSITION;

// Forward declarations
class CObject;
struct CRuntimeClass;

struct CRuntimeClass {
    LPCSTR m_lpszClassName;
    int m_nObjectSize;
    UINT m_wSchema;
    CObject* (*m_pfnCreateObject)();
    const CRuntimeClass* m_pBaseClass;
    CRuntimeClass* m_pNextClass;

    CObject* CreateObject() const {
        return m_pfnCreateObject ? m_pfnCreateObject() : nullptr;
    }
    BOOL IsDerivedFrom(const CRuntimeClass* pBaseClass) const {
        const CRuntimeClass* pClassThis = this;
        while (pClassThis != nullptr) {
            if (pClassThis == pBaseClass) return TRUE;
            pClassThis = pClassThis->m_pBaseClass;
        }
        return FALSE;
    }
};

#define RUNTIME_CLASS(class_name) const_cast<CRuntimeClass*>(&class_name::class##class_name)

#define DECLARE_DYNAMIC(class_name) \
public: \
    static const CRuntimeClass class##class_name; \
    virtual CRuntimeClass* GetRuntimeClass() const;

#define DECLARE_DYNCREATE(class_name) \
    DECLARE_DYNAMIC(class_name) \
    static CObject* CreateObject();

#define DECLARE_SERIAL(class_name) \
    DECLARE_DYNCREATE(class_name)

#define IMPLEMENT_DYNAMIC(class_name, base_class_name) \
    const CRuntimeClass class_name::class##class_name = { \
        #class_name, sizeof(class_name), 0xFFFF, nullptr, &base_class_name::class##base_class_name, nullptr \
    }; \
    CRuntimeClass* class_name::GetRuntimeClass() const { \
        return const_cast<CRuntimeClass*>(&class_name::class##class_name); \
    }

#define IMPLEMENT_DYNCREATE(class_name, base_class_name) \
    CObject* class_name::CreateObject() { return new class_name; } \
    const CRuntimeClass class_name::class##class_name = { \
        #class_name, sizeof(class_name), 0xFFFF, &class_name::CreateObject, &base_class_name::class##base_class_name, nullptr \
    }; \
    CRuntimeClass* class_name::GetRuntimeClass() const { \
        return const_cast<CRuntimeClass*>(&class_name::class##class_name); \
    }

#define IMPLEMENT_SERIAL(class_name, base_class_name, wSchema) \
    IMPLEMENT_DYNCREATE(class_name, base_class_name)

class CObject {
public:
    static const CRuntimeClass classCObject;
    virtual CRuntimeClass* GetRuntimeClass() const {
        return const_cast<CRuntimeClass*>(&classCObject);
    }
    virtual ~CObject() = default;
    BOOL IsKindOf(const CRuntimeClass* pClass) const {
        CRuntimeClass* pClassThis = GetRuntimeClass();
        return pClassThis ? pClassThis->IsDerivedFrom(pClass) : FALSE;
    }
    virtual void AssertValid() const {}
};

// CException hierarchy
class CException : public CObject {
public:
    BOOL m_bAutoDelete = TRUE;
    CException(BOOL bAutoDelete = TRUE) : m_bAutoDelete(bAutoDelete) {}
    virtual ~CException() = default;
    void Delete() { if (m_bAutoDelete) delete this; }
    virtual BOOL GetErrorMessage(LPTSTR lpszError, UINT nMaxError, PUINT pnHelpContext = nullptr) const {
        if (lpszError && nMaxError > 0) lpszError[0] = 0;
        if (pnHelpContext) *pnHelpContext = 0;
        return FALSE;
    }
    virtual int ReportError(UINT nType = 0, UINT nMessageID = 0) {
        (void)nType; (void)nMessageID;
        TCHAR szError[512] = {0};
        GetErrorMessage(szError, 512);
        return 0;
    }
};

class CMemoryException : public CException {
public:
    CMemoryException() : CException(FALSE) {}
};

inline void AfxThrowMemoryException() {
    throw new CMemoryException();
}

class CFileException : public CException {
public:
    int m_cause = 0;
    LONG m_lOsError = 0;
    enum {
        none,
        genericException,
        fileNotFound,
        badPath,
        tooManyOpenFiles,
        accessDenied,
        invalidFile,
        removeCurrentDir,
        directoryFull,
        badSeek,
        hardIO,
        sharingViolation,
        lockViolation,
        diskFull,
        endOfFile
    };
};

// CStringT implementation supporting CStringA and CStringW
template <typename CharT>
class CStringT {
public:
    using std_string = std::basic_string<CharT>;
    using traits_type = std::char_traits<CharT>;
    typedef CharT XCHAR;
    typedef CharT* PXSTR;
    typedef const CharT* PCXSTR;

private:
    std_string m_str;

    static size_t safe_len(const CharT* s) {
        return s ? traits_type::length(s) : 0;
    }

public:
    CStringT() = default;
    CStringT(const CStringT&) = default;
    CStringT(CStringT&&) noexcept = default;
    CStringT& operator=(const CStringT&) = default;
    CStringT& operator=(CStringT&&) noexcept = default;

    CStringT(const CharT* psz) : m_str(psz ? psz : & NullChar()) {}
    CStringT(const CharT* psz, int nLength) : m_str(psz ? psz : &NullChar(), psz ? (nLength >= 0 ? (size_t)nLength : safe_len(psz)) : 0) {}
    CStringT(CharT ch, int nLength = 1) : m_str(nLength > 0 ? (size_t)nLength : 0, ch) {}
    CStringT(const std_string& s) : m_str(s) {}

    // basic_string with different char or traits/allocator
    template <typename OtherChar, typename Traits, typename Alloc>
    CStringT(const std::basic_string<OtherChar, Traits, Alloc>& s) {
        if constexpr (std::is_same_v<CharT, OtherChar>) {
            m_str.assign(s.data(), s.size());
        } else {
            AssignOther(s.data(), s.size());
        }
    }

    // Cross-encoding constructors
    template <typename OtherChar, typename = std::enable_if_t<!std::is_same_v<CharT, OtherChar>>>
    CStringT(const OtherChar* psz) {
        AssignOther(psz, psz ? std::char_traits<OtherChar>::length(psz) : 0);
    }
    template <typename OtherChar, typename = std::enable_if_t<!std::is_same_v<CharT, OtherChar>>>
    CStringT(const OtherChar* psz, int nLength) {
        AssignOther(psz, psz && nLength > 0 ? (size_t)nLength : 0);
    }
    template <typename OtherChar, typename = std::enable_if_t<!std::is_same_v<CharT, OtherChar>>>
    CStringT(const CStringT<OtherChar>& other) {
        AssignOther(other.GetString(), (size_t)other.GetLength());
    }

    void AssignOther(const char* src, size_t len) {
        if (!src || len == 0) { m_str.clear(); return; }
        if constexpr (std::is_same_v<CharT, char>) {
            m_str.assign(src, len);
        } else {
            int wlen = MultiByteToWideChar(CP_UTF8, 0, src, (int)len, nullptr, 0);
            if (wlen > 0) {
                m_str.resize(wlen);
                MultiByteToWideChar(CP_UTF8, 0, src, (int)len, m_str.data(), wlen);
            } else {
                m_str.clear();
            }
        }
    }
    void AssignOther(const wchar_t* src, size_t len) {
        if (!src || len == 0) { m_str.clear(); return; }
        if constexpr (std::is_same_v<CharT, wchar_t>) {
            m_str.assign(src, len);
        } else {
            int alen = WideCharToMultiByte(CP_UTF8, 0, src, (int)len, nullptr, 0, nullptr, nullptr);
            if (alen > 0) {
                m_str.resize(alen);
                WideCharToMultiByte(CP_UTF8, 0, src, (int)len, m_str.data(), alen, nullptr, nullptr);
            } else {
                m_str.clear();
            }
        }
    }

    static const CharT& NullChar() {
        static const CharT c = 0;
        return c;
    }

    CStringT& operator=(const CharT* psz) {
        if (psz) m_str = psz;
        else m_str.clear();
        return *this;
    }
    CStringT& operator=(CharT ch) {
        m_str.assign(1, ch);
        return *this;
    }
    template <typename OtherChar, typename = std::enable_if_t<!std::is_same_v<CharT, OtherChar>>>
    CStringT& operator=(const OtherChar* psz) {
        AssignOther(psz, psz ? std::char_traits<OtherChar>::length(psz) : 0);
        return *this;
    }

    operator const CharT*() const noexcept { return m_str.c_str(); }
    const CharT* GetString() const noexcept { return m_str.c_str(); }
    const CharT* c_str() const noexcept { return m_str.c_str(); }

    int GetLength() const noexcept { return (int)m_str.size(); }
    int GetAllocLength() const noexcept { return (int)m_str.capacity(); }
    bool IsEmpty() const noexcept { return m_str.empty(); }
    void Empty() noexcept { m_str.clear(); }

    CharT GetAt(int nIndex) const { return (nIndex >= 0 && (size_t)nIndex < m_str.size()) ? m_str[nIndex] : 0; }
    void SetAt(int nIndex, CharT ch) { if (nIndex >= 0 && (size_t)nIndex < m_str.size()) m_str[nIndex] = ch; }
    CharT operator[](int nIndex) const { return GetAt(nIndex); }
    CharT& operator[](int nIndex) { return m_str[nIndex]; }

    void Append(const CharT* psz) { if (psz) m_str.append(psz); }
    void Append(const CharT* psz, int nLen) { if (psz && nLen > 0) m_str.append(psz, (size_t)nLen); }
    void Append(const CStringT& str) { m_str.append(str.m_str); }
    void AppendChar(CharT ch) { m_str.push_back(ch); }

    CStringT& operator+=(const CStringT& str) { m_str += str.m_str; return *this; }
    CStringT& operator+=(const CharT* psz) { if (psz) m_str += psz; return *this; }
    CStringT& operator+=(CharT ch) { m_str.push_back(ch); return *this; }

    void SetString(const CharT* psz) {
        if (psz) m_str.assign(psz);
        else m_str.clear();
    }
    void SetString(const CharT* psz, int nLength) {
        if (psz && nLength > 0) m_str.assign(psz, (size_t)nLength);
        else m_str.clear();
    }

    CharT* GetBuffer(int nMinBufLength = 0) {
        if ((size_t)nMinBufLength > m_str.size()) {
            m_str.resize((size_t)nMinBufLength, 0);
        }
        return m_str.data();
    }
    CharT* GetBufferSetLength(int nNewLength) {
        m_str.resize(nNewLength > 0 ? (size_t)nNewLength : 0, 0);
        return m_str.data();
    }
    void ReleaseBuffer(int nNewLength = -1) {
        if (nNewLength >= 0) {
            m_str.resize((size_t)nNewLength);
        } else {
            size_t len = traits_type::length(m_str.c_str());
            m_str.resize(len);
        }
    }
    void ReleaseBufferSetLength(int nNewLength) {
        m_str.resize(nNewLength >= 0 ? (size_t)nNewLength : 0);
    }

    BSTR AllocSysString() const {
        if constexpr (std::is_same_v<CharT, wchar_t>) {
            return SysAllocString(m_str.c_str());
        } else {
            CStringT<wchar_t> w(*this);
            return SysAllocString(w.GetString());
        }
    }
    void Preallocate(int nLength) {
        if (nLength > 0) m_str.reserve((size_t)nLength);
    }

    int Compare(const CharT* psz) const noexcept {
        if (!psz) return m_str.empty() ? 0 : 1;
        return m_str.compare(psz);
    }
    int CompareNoCase(const CharT* psz) const noexcept {
        if (!psz) return m_str.empty() ? 0 : 1;
        if constexpr (std::is_same_v<CharT, char>) {
            return strcasecmp(m_str.c_str(), psz);
        } else {
            return wcscasecmp(m_str.c_str(), psz);
        }
    }

    int Find(CharT ch, int iStart = 0) const noexcept {
        if (iStart < 0 || (size_t)iStart >= m_str.size()) return -1;
        auto pos = m_str.find(ch, (size_t)iStart);
        return pos == std_string::npos ? -1 : (int)pos;
    }
    int Find(const CharT* pszSub, int iStart = 0) const noexcept {
        if (!pszSub || iStart < 0 || (size_t)iStart > m_str.size()) return -1;
        auto pos = m_str.find(pszSub, (size_t)iStart);
        return pos == std_string::npos ? -1 : (int)pos;
    }
    int ReverseFind(CharT ch) const noexcept {
        auto pos = m_str.rfind(ch);
        return pos == std_string::npos ? -1 : (int)pos;
    }
    int FindOneOf(const CharT* pszCharSet) const noexcept {
        if (!pszCharSet) return -1;
        auto pos = m_str.find_first_of(pszCharSet);
        return pos == std_string::npos ? -1 : (int)pos;
    }

    CStringT Mid(int iFirst) const {
        if (iFirst < 0) iFirst = 0;
        if ((size_t)iFirst >= m_str.size()) return CStringT();
        return CStringT(m_str.substr((size_t)iFirst));
    }
    CStringT Mid(int iFirst, int nCount) const {
        if (iFirst < 0) iFirst = 0;
        if (nCount <= 0 || (size_t)iFirst >= m_str.size()) return CStringT();
        return CStringT(m_str.substr((size_t)iFirst, (size_t)nCount));
    }
    CStringT Left(int nCount) const {
        if (nCount <= 0) return CStringT();
        if ((size_t)nCount >= m_str.size()) return *this;
        return CStringT(m_str.substr(0, (size_t)nCount));
    }
    CStringT Right(int nCount) const {
        if (nCount <= 0) return CStringT();
        if ((size_t)nCount >= m_str.size()) return *this;
        return CStringT(m_str.substr(m_str.size() - (size_t)nCount));
    }
    CStringT SpanIncluding(const CharT* pszCharSet) const {
        if (!pszCharSet) return CStringT();
        auto pos = m_str.find_first_not_of(pszCharSet);
        return Left(pos == std_string::npos ? GetLength() : (int)pos);
    }
    CStringT SpanExcluding(const CharT* pszCharSet) const {
        if (!pszCharSet) return *this;
        auto pos = m_str.find_first_of(pszCharSet);
        return Left(pos == std_string::npos ? GetLength() : (int)pos);
    }

    CStringT Tokenize(const CharT* pszTokens, int& iStart) const {
        if (iStart < 0 || (size_t)iStart >= m_str.size()) {
            iStart = -1;
            return CStringT();
        }
        if (!pszTokens || !*pszTokens) {
            CStringT ret = Mid(iStart);
            iStart = -1;
            return ret;
        }
        auto startPos = m_str.find_first_not_of(pszTokens, (size_t)iStart);
        if (startPos == std_string::npos) {
            iStart = -1;
            return CStringT();
        }
        auto endPos = m_str.find_first_of(pszTokens, startPos);
        if (endPos == std_string::npos) {
            iStart = -1;
            return CStringT(m_str.substr(startPos));
        }
        iStart = (int)(endPos + 1);
        return CStringT(m_str.substr(startPos, endPos - startPos));
    }

    int Replace(CharT chOld, CharT chNew) {
        int count = 0;
        for (auto& c : m_str) {
            if (c == chOld) { c = chNew; ++count; }
        }
        return count;
    }
    int Replace(const CharT* pszOld, const CharT* pszNew) {
        if (!pszOld || !*pszOld) return 0;
        std_string sOld(pszOld);
        std_string sNew(pszNew ? pszNew : &NullChar());
        int count = 0;
        size_t pos = 0;
        while ((pos = m_str.find(sOld, pos)) != std_string::npos) {
            m_str.replace(pos, sOld.size(), sNew);
            pos += sNew.size();
            ++count;
        }
        return count;
    }
    int Remove(CharT chRemove) {
        size_t oldLen = m_str.size();
        m_str.erase(std::remove(m_str.begin(), m_str.end(), chRemove), m_str.end());
        return (int)(oldLen - m_str.size());
    }
    int Insert(int iIndex, CharT ch) {
        if (iIndex < 0) iIndex = 0;
        if ((size_t)iIndex > m_str.size()) iIndex = (int)m_str.size();
        m_str.insert((size_t)iIndex, 1, ch);
        return (int)m_str.size();
    }
    int Insert(int iIndex, const CharT* psz) {
        if (!psz) return (int)m_str.size();
        if (iIndex < 0) iIndex = 0;
        if ((size_t)iIndex > m_str.size()) iIndex = (int)m_str.size();
        m_str.insert((size_t)iIndex, psz);
        return (int)m_str.size();
    }
    int Delete(int iIndex, int nCount = 1) {
        if (iIndex >= 0 && (size_t)iIndex < m_str.size() && nCount > 0) {
            m_str.erase((size_t)iIndex, (size_t)nCount);
        }
        return (int)m_str.size();
    }
    void Truncate(int nNewLength) {
        if (nNewLength >= 0 && (size_t)nNewLength < m_str.size()) {
            m_str.resize((size_t)nNewLength);
        }
    }

    CStringT& MakeLower() {
        for (auto& c : m_str) {
            if constexpr (std::is_same_v<CharT, char>) c = (char)std::tolower((unsigned char)c);
            else c = (wchar_t)std::towlower((wint_t)c);
        }
        return *this;
    }
    CStringT& MakeUpper() {
        for (auto& c : m_str) {
            if constexpr (std::is_same_v<CharT, char>) c = (char)std::toupper((unsigned char)c);
            else c = (wchar_t)std::towupper((wint_t)c);
        }
        return *this;
    }

    CStringT& TrimLeft() {
        size_t i = 0;
        while (i < m_str.size() && (m_str[i] == ' ' || m_str[i] == '\t' || m_str[i] == '\r' || m_str[i] == '\n')) ++i;
        m_str.erase(0, i);
        return *this;
    }
    CStringT& TrimLeft(CharT chTarget) {
        size_t i = 0;
        while (i < m_str.size() && m_str[i] == chTarget) ++i;
        m_str.erase(0, i);
        return *this;
    }
    CStringT& TrimLeft(const CharT* pszTargets) {
        if (!pszTargets) return *this;
        auto pos = m_str.find_first_not_of(pszTargets);
        if (pos == std_string::npos) m_str.clear();
        else m_str.erase(0, pos);
        return *this;
    }
    CStringT& TrimRight() {
        while (!m_str.empty() && (m_str.back() == ' ' || m_str.back() == '\t' || m_str.back() == '\r' || m_str.back() == '\n')) m_str.pop_back();
        return *this;
    }
    CStringT& TrimRight(CharT chTarget) {
        while (!m_str.empty() && m_str.back() == chTarget) m_str.pop_back();
        return *this;
    }
    CStringT& TrimRight(const CharT* pszTargets) {
        if (!pszTargets) return *this;
        auto pos = m_str.find_last_not_of(pszTargets);
        if (pos == std_string::npos) m_str.clear();
        else m_str.erase(pos + 1);
        return *this;
    }
    CStringT& Trim() { return TrimLeft().TrimRight(); }
    CStringT& Trim(CharT chTarget) { return TrimLeft(chTarget).TrimRight(chTarget); }
    CStringT& Trim(const CharT* pszTargets) { return TrimLeft(pszTargets).TrimRight(pszTargets); }

    void FormatV(const CharT* pszFormat, va_list args) {
        if (!pszFormat) { m_str.clear(); return; }
        if constexpr (std::is_same_v<CharT, char>) {
            va_list copy;
            va_copy(copy, args);
            int len = vsnprintf(nullptr, 0, pszFormat, copy);
            va_end(copy);
            if (len > 0) {
                m_str.resize((size_t)len);
                vsnprintf(m_str.data(), (size_t)len + 1, pszFormat, args);
            } else {
                m_str.clear();
            }
        } else {
            va_list copy;
            va_copy(copy, args);
            std::vector<wchar_t> buf(1024);
            int len = vswprintf(buf.data(), buf.size(), pszFormat, copy);
            va_end(copy);
            if (len >= 0) {
                m_str.assign(buf.data(), (size_t)len);
            } else {
                m_str.clear();
            }
        }
    }

    void Format(const CharT* pszFormat, ...) {
        va_list args;
        va_start(args, pszFormat);
        FormatV(pszFormat, args);
        va_end(args);
    }

    void AppendFormatV(const CharT* pszFormat, va_list args) {
        CStringT tmp;
        tmp.FormatV(pszFormat, args);
        m_str += tmp.m_str;
    }

    void AppendFormat(const CharT* pszFormat, ...) {
        va_list args;
        va_start(args, pszFormat);
        AppendFormatV(pszFormat, args);
        va_end(args);
    }

    BOOL LoadString(UINT nID) {
        CharT szBuf[512] = {};
        if constexpr (sizeof(CharT) == sizeof(wchar_t)) {
            int len = ::LoadStringW(nullptr, nID, (LPWSTR)szBuf, 512);
            if (len > 0) { m_str = szBuf; return TRUE; }
        } else {
            int len = ::LoadStringA(nullptr, nID, (LPSTR)szBuf, 512);
            if (len > 0) { m_str = szBuf; return TRUE; }
        }
        return FALSE;
    }

    friend CStringT operator+(const CStringT& a, const CStringT& b) {
        CStringT r(a); r += b; return r;
    }
    friend CStringT operator+(const CStringT& a, const CharT* b) {
        CStringT r(a); r += b; return r;
    }
    friend CStringT operator+(const CharT* a, const CStringT& b) {
        CStringT r(a); r += b; return r;
    }
    friend CStringT operator+(const CStringT& a, CharT b) {
        CStringT r(a); r += b; return r;
    }
    friend CStringT operator+(CharT a, const CStringT& b) {
        CStringT r(a); r += b; return r;
    }

    friend bool operator==(const CStringT& a, const CStringT& b) noexcept { return a.m_str == b.m_str; }
    friend bool operator==(const CStringT& a, const CharT* b) noexcept { return a.Compare(b) == 0; }
    friend bool operator==(const CharT* a, const CStringT& b) noexcept { return b.Compare(a) == 0; }
    friend bool operator!=(const CStringT& a, const CStringT& b) noexcept { return a.m_str != b.m_str; }
    friend bool operator!=(const CStringT& a, const CharT* b) noexcept { return a.Compare(b) != 0; }
    friend bool operator!=(const CharT* a, const CStringT& b) noexcept { return b.Compare(a) != 0; }
    friend bool operator<(const CStringT& a, const CStringT& b) noexcept { return a.m_str < b.m_str; }
    friend bool operator>(const CStringT& a, const CStringT& b) noexcept { return a.m_str > b.m_str; }
    friend bool operator<=(const CStringT& a, const CStringT& b) noexcept { return a.m_str <= b.m_str; }
    friend bool operator>=(const CStringT& a, const CStringT& b) noexcept { return a.m_str >= b.m_str; }
};

typedef CStringT<char> CStringA;
typedef CStringT<wchar_t> CStringW;
#ifdef UNICODE
typedef CStringW CString;
#else
typedef CStringA CString;
#endif

// Geometry classes: CSize, CPoint, CRect
class CPoint;
class CRect;

class CSize : public tagSIZE {
public:
    CSize() noexcept { cx = 0; cy = 0; }
    CSize(int initCX, int initCY) noexcept { cx = initCX; cy = initCY; }
    CSize(SIZE initSize) noexcept { *(SIZE*)this = initSize; }
    CSize(POINT initPt) noexcept { *(POINT*)this = initPt; }
    CSize(DWORD dwSize) noexcept { cx = (short)LOWORD(dwSize); cy = (short)HIWORD(dwSize); }

    bool operator==(SIZE size) const noexcept { return (cx == size.cx && cy == size.cy); }
    bool operator!=(SIZE size) const noexcept { return (cx != size.cx || cy != size.cy); }
    void operator+=(SIZE size) noexcept { cx += size.cx; cy += size.cy; }
    void operator-=(SIZE size) noexcept { cx -= size.cx; cy -= size.cy; }
    void SetSize(int CX, int CY) noexcept { cx = CX; cy = CY; }

    CSize operator+(SIZE size) const noexcept { return CSize(cx + size.cx, cy + size.cy); }
    CSize operator-(SIZE size) const noexcept { return CSize(cx - size.cx, cy - size.cy); }
    CSize operator-() const noexcept { return CSize(-cx, -cy); }
};

class CPoint : public tagPOINT {
public:
    CPoint() noexcept { x = 0; y = 0; }
    CPoint(int initX, int initY) noexcept { x = initX; y = initY; }
    CPoint(POINT initPt) noexcept { *(POINT*)this = initPt; }
    CPoint(SIZE initSize) noexcept { *(SIZE*)this = initSize; }
    CPoint(LPARAM dwPoint) noexcept { x = (short)LOWORD(dwPoint); y = (short)HIWORD(dwPoint); }

    void Offset(int xOffset, int yOffset) noexcept { x += xOffset; y += yOffset; }
    void Offset(POINT point) noexcept { x += point.x; y += point.y; }
    void Offset(SIZE size) noexcept { x += size.cx; y += size.cy; }
    void SetPoint(int X, int Y) noexcept { x = X; y = Y; }

    bool operator==(POINT point) const noexcept { return (x == point.x && y == point.y); }
    bool operator!=(POINT point) const noexcept { return (x != point.x || y != point.y); }
    void operator+=(SIZE size) noexcept { x += size.cx; y += size.cy; }
    void operator-=(SIZE size) noexcept { x -= size.cx; y -= size.cy; }
    void operator+=(POINT point) noexcept { x += point.x; y += point.y; }
    void operator-=(POINT point) noexcept { x -= point.x; y -= point.y; }

    CPoint operator+(SIZE size) const noexcept { return CPoint(x + size.cx, y + size.cy); }
    CPoint operator-(SIZE size) const noexcept { return CPoint(x - size.cx, y - size.cy); }
    CPoint operator-() const noexcept { return CPoint(-x, -y); }
    CPoint operator+(POINT point) const noexcept { return CPoint(x + point.x, y + point.y); }
    CSize operator-(POINT point) const noexcept { return CSize(x - point.x, y - point.y); }
};

class CRect : public tagRECT {
public:
    CRect() noexcept { left = 0; top = 0; right = 0; bottom = 0; }
    CRect(int l, int t, int r, int b) noexcept { left = l; top = t; right = r; bottom = b; }
    CRect(const RECT& srcRect) noexcept { ::CopyRect(this, &srcRect); }
    CRect(LPCRECT lpSrcRect) noexcept { if (lpSrcRect) ::CopyRect(this, lpSrcRect); else SetRectEmpty(); }
    CRect(POINT point, SIZE size) noexcept { right = (left = point.x) + size.cx; bottom = (top = point.y) + size.cy; }
    CRect(POINT topLeft, POINT bottomRight) noexcept { left = topLeft.x; top = topLeft.y; right = bottomRight.x; bottom = bottomRight.y; }

    int Width() const noexcept { return right - left; }
    int Height() const noexcept { return bottom - top; }
    CSize Size() const noexcept { return CSize(right - left, bottom - top); }
    CPoint& TopLeft() noexcept { return *((CPoint*)this); }
    CPoint& BottomRight() noexcept { return *((CPoint*)this + 1); }
    const CPoint& TopLeft() const noexcept { return *((const CPoint*)this); }
    const CPoint& BottomRight() const noexcept { return *((const CPoint*)this + 1); }
    CPoint CenterPoint() const noexcept { return CPoint((left + right) / 2, (top + bottom) / 2); }

    operator LPRECT() noexcept { return this; }
    operator LPCRECT() const noexcept { return this; }

    BOOL IsRectEmpty() const noexcept { return ::IsRectEmpty(this); }
    BOOL IsRectNull() const noexcept { return (left == 0 && right == 0 && top == 0 && bottom == 0); }
    BOOL PtInRect(POINT point) const noexcept { return ::PtInRect(this, point); }

    void SetRect(int x1, int y1, int x2, int y2) noexcept { ::SetRect(this, x1, y1, x2, y2); }
    void SetRect(POINT topLeft, POINT bottomRight) noexcept { ::SetRect(this, topLeft.x, topLeft.y, bottomRight.x, bottomRight.y); }
    void SetRectEmpty() noexcept { ::SetRectEmpty(this); }
    void CopyRect(LPCRECT lpSrcRect) noexcept { ::CopyRect(this, lpSrcRect); }
    BOOL EqualRect(LPCRECT lpRect) const noexcept { return ::EqualRect(this, lpRect); }

    void InflateRect(int x, int y) noexcept { ::InflateRect(this, x, y); }
    void InflateRect(SIZE size) noexcept { ::InflateRect(this, size.cx, size.cy); }
    void InflateRect(LPCRECT lpRect) noexcept { left -= lpRect->left; top -= lpRect->top; right += lpRect->right; bottom += lpRect->bottom; }
    void InflateRect(int l, int t, int r, int b) noexcept { left -= l; top -= t; right += r; bottom += b; }

    void DeflateRect(int x, int y) noexcept { ::InflateRect(this, -x, -y); }
    void DeflateRect(SIZE size) noexcept { ::InflateRect(this, -size.cx, -size.cy); }
    void DeflateRect(LPCRECT lpRect) noexcept { left += lpRect->left; top += lpRect->top; right -= lpRect->right; bottom -= lpRect->bottom; }
    void DeflateRect(int l, int t, int r, int b) noexcept { left += l; top += t; right -= r; bottom -= b; }

    void OffsetRect(int x, int y) noexcept { ::OffsetRect(this, x, y); }
    void OffsetRect(SIZE size) noexcept { ::OffsetRect(this, size.cx, size.cy); }
    void OffsetRect(POINT point) noexcept { ::OffsetRect(this, point.x, point.y); }
    void NormalizeRect() noexcept {
        if (left > right) std::swap(left, right);
        if (top > bottom) std::swap(top, bottom);
    }

    void MoveToY(int y) noexcept { bottom = Height() + y; top = y; }
    void MoveToX(int x) noexcept { right = Width() + x; left = x; }
    void MoveToXY(int x, int y) noexcept { MoveToX(x); MoveToY(y); }
    void MoveToXY(POINT pt) noexcept { MoveToX(pt.x); MoveToY(pt.y); }

    BOOL IntersectRect(LPCRECT lpRect1, LPCRECT lpRect2) noexcept { return ::IntersectRect(this, lpRect1, lpRect2); }
    BOOL UnionRect(LPCRECT lpRect1, LPCRECT lpRect2) noexcept { return ::UnionRect(this, lpRect1, lpRect2); }
    BOOL SubtractRect(LPCRECT lpRectSrc1, LPCRECT lpRectSrc2) noexcept { return ::SubtractRect(this, lpRectSrc1, lpRectSrc2); }

    bool operator==(const RECT& rect) const noexcept { return ::EqualRect(this, &rect); }
    bool operator!=(const RECT& rect) const noexcept { return !::EqualRect(this, &rect); }
    void operator+=(POINT point) noexcept { ::OffsetRect(this, point.x, point.y); }
    void operator+=(SIZE size) noexcept { ::OffsetRect(this, size.cx, size.cy); }
    void operator+=(LPCRECT lpRect) noexcept { InflateRect(lpRect); }
    void operator-=(POINT point) noexcept { ::OffsetRect(this, -point.x, -point.y); }
    void operator-=(SIZE size) noexcept { ::OffsetRect(this, -size.cx, -size.cy); }
    void operator-=(LPCRECT lpRect) noexcept { DeflateRect(lpRect); }
    void operator&=(const RECT& rect) noexcept { ::IntersectRect(this, this, &rect); }
    void operator|=(const RECT& rect) noexcept { ::UnionRect(this, this, &rect); }

    CRect operator+(POINT pt) const noexcept { CRect r(*this); r.OffsetRect(pt); return r; }
    CRect operator-(POINT pt) const noexcept { CRect r(*this); r.OffsetRect(-pt.x, -pt.y); return r; }
    CRect operator+(SIZE size) const noexcept { CRect r(*this); r.OffsetRect(size); return r; }
    CRect operator-(SIZE size) const noexcept { CRect r(*this); r.OffsetRect(-size.cx, -size.cy); return r; }
    CRect operator&(const RECT& rect2) const noexcept { CRect r; r.IntersectRect(this, &rect2); return r; }
    CRect operator|(const RECT& rect2) const noexcept { CRect r; r.UnionRect(this, &rect2); return r; }
};

// CFile and CMemFile
class CFile : public CObject {
public:
    enum OpenFlags {
        modeRead =         (int) 0x00000,
        modeWrite =        (int) 0x00001,
        modeReadWrite =    (int) 0x00002,
        shareCompat =      (int) 0x00000,
        shareExclusive =   (int) 0x00010,
        shareDenyWrite =   (int) 0x00020,
        shareDenyRead =    (int) 0x00030,
        shareDenyNone =    (int) 0x00040,
        modeNoInherit =    (int) 0x00080,
        modeCreate =       (int) 0x01000,
        modeNoTruncate =   (int) 0x02000,
        typeText =         (int) 0x04000,
        typeBinary =       (int) 0x08000
    };
    enum SeekPosition { begin = 0x0, current = 0x1, end = 0x2 };

    FILE* m_pStream = nullptr;
    CString m_strFileName;

    CFile() = default;
    CFile(LPCTSTR lpszFileName, UINT nOpenFlags) { Open(lpszFileName, nOpenFlags); }
    ~CFile() override { Close(); }

    virtual BOOL Open(LPCTSTR lpszFileName, UINT nOpenFlags, CFileException* pError = nullptr);
    virtual UINT Read(void* lpBuf, UINT nCount);
    virtual void Write(const void* lpBuf, UINT nCount);
    virtual ULONGLONG Seek(LONGLONG lOff, UINT nFrom);
    virtual void SeekToBegin() { Seek(0, begin); }
    virtual ULONGLONG SeekToEnd() { return Seek(0, end); }
    virtual ULONGLONG GetLength() const;
    virtual ULONGLONG GetPosition() const;
    virtual void SetLength(ULONGLONG dwNewLen);
    virtual void Flush();
    virtual void Close();
    virtual CString GetFileName() const { return m_strFileName; }
    virtual CString GetFilePath() const { return m_strFileName; }
};

class CMemFile : public CFile {
public:
    std::vector<BYTE> m_buffer;
    BYTE* m_lpBuffer = nullptr;
    size_t m_nBufferSize = 0;
    size_t m_nFileSize = 0;
    size_t m_nPosition = 0;
    bool m_bAutoDelete = true;

    CMemFile(UINT nGrowBytes = 1024) { (void)nGrowBytes; }
    CMemFile(BYTE* lpBuffer, UINT nBufferSize, UINT nGrowBytes = 0) {
        Attach(lpBuffer, nBufferSize, nGrowBytes);
    }
    ~CMemFile() override = default;

    void Attach(BYTE* lpBuffer, UINT nBufferSize, UINT nGrowBytes = 0) {
        (void)nGrowBytes;
        m_lpBuffer = lpBuffer;
        m_nBufferSize = nBufferSize;
        m_nFileSize = nBufferSize;
        m_nPosition = 0;
        m_bAutoDelete = false;
    }
    BYTE* Detach() {
        if (m_bAutoDelete) {
            BYTE* p = (BYTE*)malloc(m_buffer.size());
            if (p && !m_buffer.empty()) memcpy(p, m_buffer.data(), m_buffer.size());
            m_buffer.clear();
            m_nFileSize = 0;
            m_nPosition = 0;
            return p;
        }
        BYTE* p = m_lpBuffer;
        m_lpBuffer = nullptr;
        m_nBufferSize = 0;
        m_nFileSize = 0;
        m_nPosition = 0;
        return p;
    }

    UINT Read(void* lpBuf, UINT nCount) override {
        size_t avail = (m_nPosition < m_nFileSize) ? (m_nFileSize - m_nPosition) : 0;
        size_t toRead = std::min((size_t)nCount, avail);
        if (toRead > 0) {
            const BYTE* src = m_bAutoDelete ? m_buffer.data() : m_lpBuffer;
            memcpy(lpBuf, src + m_nPosition, toRead);
            m_nPosition += toRead;
        }
        return (UINT)toRead;
    }
    void Write(const void* lpBuf, UINT nCount) override {
        if (nCount == 0) return;
        if (m_bAutoDelete) {
            if (m_nPosition + nCount > m_buffer.size()) {
                m_buffer.resize(m_nPosition + nCount);
            }
            memcpy(m_buffer.data() + m_nPosition, lpBuf, nCount);
            m_nPosition += nCount;
            if (m_nPosition > m_nFileSize) m_nFileSize = m_nPosition;
        } else if (m_lpBuffer && m_nPosition + nCount <= m_nBufferSize) {
            memcpy(m_lpBuffer + m_nPosition, lpBuf, nCount);
            m_nPosition += nCount;
            if (m_nPosition > m_nFileSize) m_nFileSize = m_nPosition;
        }
    }
    ULONGLONG Seek(LONGLONG lOff, UINT nFrom) override {
        LONGLONG newPos = 0;
        if (nFrom == begin) newPos = lOff;
        else if (nFrom == current) newPos = (LONGLONG)m_nPosition + lOff;
        else if (nFrom == end) newPos = (LONGLONG)m_nFileSize + lOff;
        if (newPos < 0) newPos = 0;
        m_nPosition = (size_t)newPos;
        return m_nPosition;
    }
    ULONGLONG GetLength() const override { return m_nFileSize; }
    ULONGLONG GetPosition() const override { return m_nPosition; }
    void SetLength(ULONGLONG dwNewLen) override {
        if (m_bAutoDelete) m_buffer.resize((size_t)dwNewLen);
        m_nFileSize = (size_t)dwNewLen;
        if (m_nPosition > m_nFileSize) m_nPosition = m_nFileSize;
    }
};

class CArchive {
public:
    enum Mode { store = 0, load = 1, bNoFlushOnDelete = 2, bNoByteSwap = 4 };
    CFile* m_pFile = nullptr;
    UINT m_nMode = 0;

    CArchive(CFile* pFile, UINT nMode, int nBufSize = 4096, void* lpBuf = nullptr)
        : m_pFile(pFile), m_nMode(nMode) { (void)nBufSize; (void)lpBuf; }
    ~CArchive() = default;

    BOOL IsLoading() const { return (m_nMode & load) != 0; }
    BOOL IsStoring() const { return (m_nMode & load) == 0; }
    CFile* GetFile() const { return m_pFile; }
    void Close() {}
    void Flush() { if (m_pFile) m_pFile->Flush(); }
    UINT Read(void* lpBuf, UINT nMax) { return m_pFile ? m_pFile->Read(lpBuf, nMax) : 0; }
    void Write(const void* lpBuf, UINT nMax) { if (m_pFile) m_pFile->Write(lpBuf, nMax); }
};

class CTime {
    time_t m_time{0};
public:
    CTime() noexcept : m_time(0) {}
    CTime(time_t t) noexcept : m_time(t) {}
    // FILETIME counts 100ns ticks since 1601-01-01.
    CTime(const FILETIME& ft) noexcept : m_time((time_t)(((((ULONGLONG)ft.dwHighDateTime) << 32) | ft.dwLowDateTime) / 10000000ULL - 11644473600ULL)) {}
    CTime(int nYear, int nMonth, int nDay, int nHour, int nMin, int nSec, int nDST = -1) {
        struct tm atm{};
        atm.tm_sec = nSec;
        atm.tm_min = nMin;
        atm.tm_hour = nHour;
        atm.tm_mday = nDay;
        atm.tm_mon = nMonth - 1;
        atm.tm_year = nYear - 1900;
        atm.tm_isdst = nDST;
        m_time = mktime(&atm);
    }

    static CTime WINAPI GetCurrentTime() noexcept {
        return CTime(time(nullptr));
    }

    time_t GetTime() const noexcept { return m_time; }

    CString Format(LPCTSTR pszFormat) const {
        if (!pszFormat) return _T("");
        struct tm tmR{};
        localtime_r(&m_time, &tmR);
        TCHAR buf[256];
#if defined(UNICODE) || defined(_UNICODE)
        wcsftime(buf, sizeof(buf)/sizeof(buf[0]), pszFormat, &tmR);
#else
        strftime(buf, sizeof(buf), pszFormat, &tmR);
#endif
        return CString(buf);
    }
};
