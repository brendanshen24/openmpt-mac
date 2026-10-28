#pragma once

#include "afxwin.h"
#include <map>

#define AFX_RESTART_MANAGER_SUPPORT_RESTART             0x01
#define AFX_RESTART_MANAGER_SUPPORT_RECOVERY            0x02
#define AFX_RESTART_MANAGER_REOPEN_PREVIOUS_DOCUMENTS   0x04
#define AFX_RESTART_MANAGER_REOPEN_PREVIOUS_FILES       0x04
#define AFX_RESTART_MANAGER_RESTORE_AUTOSAVED_DOCUMENTS 0x08
#define AFX_RESTART_MANAGER_SUPPORT_ALL_ASPECTS         0x0F

class CMapStringToString {
    std::map<CString, CString> m_map;
public:
    CMapStringToString() = default;

    POSITION GetStartPosition() const {
        return m_map.empty() ? nullptr : (POSITION)(uintptr_t)1;
    }

    void GetNextAssoc(POSITION& rNextPosition, CString& rKey, CString& rValue) const {
        uintptr_t idx = (uintptr_t)rNextPosition - 1;
        if (idx >= m_map.size()) {
            rNextPosition = nullptr;
            return;
        }
        auto it = m_map.begin();
        std::advance(it, idx);
        rKey = it->first;
        rValue = it->second;
        idx++;
        rNextPosition = (idx < m_map.size()) ? (POSITION)(uintptr_t)(idx + 1) : nullptr;
    }

    CString& operator[](const CString& key) {
        return m_map[key];
    }

    void RemoveAll() { m_map.clear(); }
    INT_PTR GetCount() const { return (INT_PTR)m_map.size(); }
    BOOL IsEmpty() const { return m_map.empty(); }
};

class CDataRecoveryHandler : public CObject {
public:
    DWORD m_dwRestartManagerSupportFlags = 0;
    int m_nAutosaveInterval = 0;
    CMapStringToString m_mapDocNameToAutosaveName;
    CString m_strRestartIdentifier;

    CDataRecoveryHandler(DWORD dwRestartManagerSupportFlags = 0, int nAutosaveInterval = 0)
        : m_dwRestartManagerSupportFlags(dwRestartManagerSupportFlags), m_nAutosaveInterval(nAutosaveInterval) {}
    ~CDataRecoveryHandler() override = default;

    virtual BOOL Initialize() { return TRUE; }
    virtual BOOL SaveOpenDocumentList() { return TRUE; }
    virtual BOOL ReopenPreviousDocuments() { return TRUE; }
    virtual BOOL ReadOpenDocumentList() { return TRUE; }
    virtual CString GetRestartIdentifier() const { return m_strRestartIdentifier.IsEmpty() ? _T("openmpt") : m_strRestartIdentifier; }
    virtual void SetSaveDocumentInfoOnIdle(BOOL bSave) { (void)bSave; }
    virtual void SetRestartIdentifier(const CString& str) { m_strRestartIdentifier = str; }
};
