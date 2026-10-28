#pragma once

#include "afxwin.h"

#define WM_SIZEPARENT       0x0361
#define WM_SETMESSAGESTRING 0x0362
#define WM_IDLEUPDATECMDUI  0x0363
#define WM_COMMANDHELP      0x0365
#define WM_HELPHITTEST      0x0366
#define WM_EXITHELPMODE     0x0367
#define WM_RECALCPARENT     0x0368
#define WM_SIZECHILD        0x0369
#define WM_KICKIDLE         0x036A
#define WM_INITIALUPDATE    0x036B

struct AFX_SIZEPARENTPARAMS {
    HDWP hDWP;
    RECT rect;
    SIZE sizeTotal;
    BOOL bStretch;
};

class CRecentFileList {
public:
    int m_nSize = 0;
    std::vector<CString> m_arrNames;
    CString m_strSectionName;
    CString m_strEntryFormat;
    UINT m_nStart = 0;
    int m_nMaxDisplayLength = 0;

    CRecentFileList(UINT nStart, LPCTSTR lpszSection, LPCTSTR lpszEntryFormat, int nSize, int nMaxDispLen = 0)
        : m_nSize(nSize), m_arrNames(nSize),
          m_strSectionName(lpszSection ? lpszSection : _T("")),
          m_strEntryFormat(lpszEntryFormat ? lpszEntryFormat : _T("")),
          m_nStart(nStart), m_nMaxDisplayLength(nMaxDispLen) {}
    virtual ~CRecentFileList() = default;

    int GetSize() const { return m_nSize; }
    CString& operator[](int nIndex) { return m_arrNames[nIndex]; }
    const CString& operator[](int nIndex) const { return m_arrNames[nIndex]; }

    virtual void Remove(int nIndex) {
        if (nIndex >= 0 && nIndex < m_nSize) {
            for (int i = nIndex; i < m_nSize - 1; ++i) m_arrNames[i] = m_arrNames[i + 1];
            m_arrNames[m_nSize - 1].Empty();
        }
    }
    virtual void Add(LPCTSTR lpszPathName) {
        if (!lpszPathName || !*lpszPathName || m_nSize <= 0) return;
        for (int i = 0; i < m_nSize; ++i) {
            if (m_arrNames[i].CompareNoCase(lpszPathName) == 0) {
                for (int j = i; j > 0; --j) m_arrNames[j] = m_arrNames[j - 1];
                m_arrNames[0] = lpszPathName;
                return;
            }
        }
        for (int i = m_nSize - 1; i > 0; --i) m_arrNames[i] = m_arrNames[i - 1];
        m_arrNames[0] = lpszPathName;
    }
    virtual BOOL GetDisplayName(CString& strName, int nIndex, LPCTSTR lpszCurDir, int nCurDir, BOOL bAtLeastName = TRUE) const {
        (void)lpszCurDir; (void)nCurDir; (void)bAtLeastName;
        if (nIndex < 0 || nIndex >= m_nSize || m_arrNames[nIndex].IsEmpty()) return FALSE;
        strName = m_arrNames[nIndex];
        return TRUE;
    }
    virtual void UpdateMenu(CCmdUI* pCmdUI);
    virtual void ReadList() {}
    virtual void WriteList() {}
};
