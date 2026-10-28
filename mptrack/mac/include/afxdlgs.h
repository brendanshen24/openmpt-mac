#pragma once

#include "afxwin.h"
#include "afxcmn.h"

class CCommonDialog : public CDialog {
    DECLARE_DYNAMIC(CCommonDialog)
public:
    explicit CCommonDialog(CWnd* pParentWnd = nullptr) : CDialog((UINT)0, pParentWnd) {}
};

class CFileDialog : public CCommonDialog {
    DECLARE_DYNAMIC(CFileDialog)
public:
    OPENFILENAME m_ofn{};
    BOOL m_bOpenFileDialog = TRUE;
    BOOL m_bPickFoldersMode = FALSE;
    BOOL m_bPickNonFileSysFoldersMode = FALSE;
    CString m_strFilter;
    CString m_strFileName;
    CString m_strDefExt;
    std::vector<TCHAR> m_fileBuf;

    explicit CFileDialog(BOOL bOpenFileDialog, LPCTSTR lpszDefExt = nullptr,
                         LPCTSTR lpszFileName = nullptr,
                         DWORD dwFlags = OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT,
                         LPCTSTR lpszFilter = nullptr, CWnd* pParentWnd = nullptr,
                         DWORD dwSize = 0, BOOL bVistaStyle = TRUE);
    ~CFileDialog() override = default;

    INT_PTR DoModal() override;
    OPENFILENAME& GetOFN() { return m_ofn; }
    const OPENFILENAME& GetOFN() const { return m_ofn; }
    CString GetPathName() const;
    CString GetFileName() const;
    CString GetFileExt() const;
    CString GetFileTitle() const;
    POSITION GetStartPosition() const;
    CString GetNextPathName(POSITION& pos) const;

    virtual void OnFileNameChange() {}
    virtual void OnFolderChange() {}
    virtual BOOL OnFileNameOK() { return FALSE; }
};

class CColorDialog : public CCommonDialog {
    DECLARE_DYNAMIC(CColorDialog)
public:
    CHOOSECOLOR m_cc{};
    COLORREF m_custColors[16] = {};

    explicit CColorDialog(COLORREF clrInit = 0, DWORD dwFlags = 0, CWnd* pParentWnd = nullptr);
    ~CColorDialog() override = default;

    INT_PTR DoModal() override;
    COLORREF GetColor() const { return m_cc.rgbResult; }
    static COLORREF* GetSavedCustomColors() {
        static COLORREF saved[16] = {};
        return saved;
    }
};

class CFontDialog : public CCommonDialog {
    DECLARE_DYNAMIC(CFontDialog)
public:
    CHOOSEFONT m_cf{};
    LOGFONT m_lf{};

    explicit CFontDialog(LPLOGFONT lplfInitial = nullptr, DWORD dwFlags = CF_EFFECTS | CF_SCREENFONTS,
                         CDC* pdcPrinter = nullptr, CWnd* pParentWnd = nullptr);
    ~CFontDialog() override = default;

    INT_PTR DoModal() override;
    void GetCurrentFont(LPLOGFONT lplf) const { if (lplf) *lplf = m_lf; }
    CString GetFaceName() const { return CString(m_lf.lfFaceName); }
    int GetSize() const { return m_cf.iPointSize; }
    COLORREF GetColor() const { return m_cf.rgbColors; }
    int GetWeight() const { return (int)m_lf.lfWeight; }
    BOOL IsStrikeOut() const { return m_lf.lfStrikeOut != 0; }
    BOOL IsUnderline() const { return m_lf.lfUnderline != 0; }
    BOOL IsBold() const { return m_lf.lfWeight >= FW_BOLD; }
    BOOL IsItalic() const { return m_lf.lfItalic != 0; }
};

class CPropertySheet;

class CPropertyPage : public CDialog {
    DECLARE_DYNAMIC(CPropertyPage)
public:
    PROPSHEETPAGE m_psp{};
    CString m_strCaption;
    CPropertySheet* m_pSheet = nullptr;

    CPropertyPage();
    explicit CPropertyPage(UINT nIDTemplate, UINT nIDCaption = 0, DWORD dwSize = sizeof(PROPSHEETPAGE));
    explicit CPropertyPage(LPCTSTR lpszTemplateName, UINT nIDCaption = 0, DWORD dwSize = sizeof(PROPSHEETPAGE));
    ~CPropertyPage() override = default;

    void SetModified(BOOL bChanged = TRUE);
    virtual BOOL OnApply() { OnOK(); return TRUE; }
    virtual void OnReset() { OnCancel(); }
    virtual void OnOK() override {}
    virtual void OnCancel() override {}
    virtual BOOL OnSetActive() { return TRUE; }
    virtual BOOL OnKillActive() { return UpdateData(TRUE); }
    virtual BOOL OnQueryCancel() { return TRUE; }
    virtual LRESULT OnWizardBack() { return 0; }
    virtual LRESULT OnWizardNext() { return 0; }
    virtual BOOL OnWizardFinish() { return TRUE; }

    DECLARE_MESSAGE_MAP()
};

class CPropertySheet : public CWnd {
    DECLARE_DYNAMIC(CPropertySheet)
public:
    PROPSHEETHEADER m_psh{};
    CString m_strCaption;
    CWnd* m_pParentWnd = nullptr;
    std::vector<CPropertyPage*> m_pages;
    int m_nActivePage = 0;
    CTabCtrl m_tabCtrl;
    INT_PTR m_nModalResult = IDCANCEL;
    bool m_bModeless = false;

    CPropertySheet();
    explicit CPropertySheet(UINT nIDCaption, CWnd* pParentWnd = nullptr, UINT iSelectPage = 0);
    explicit CPropertySheet(LPCTSTR pszCaption, CWnd* pParentWnd = nullptr, UINT iSelectPage = 0);
    ~CPropertySheet() override = default;

    void Construct(UINT nIDCaption, CWnd* pParentWnd = nullptr, UINT iSelectPage = 0);
    void Construct(LPCTSTR pszCaption, CWnd* pParentWnd = nullptr, UINT iSelectPage = 0);

    virtual BOOL Create(CWnd* pParentWnd = nullptr, DWORD dwStyle = (DWORD)-1, DWORD dwExStyle = 0);
    virtual INT_PTR DoModal();
    virtual BOOL OnInitDialog();

    int GetPageCount() const { return (int)m_pages.size(); }
    CPropertyPage* GetActivePage() const {
        return (m_nActivePage >= 0 && (size_t)m_nActivePage < m_pages.size()) ? m_pages[m_nActivePage] : nullptr;
    }
    int GetActiveIndex() const { return m_nActivePage; }
    CPropertyPage* GetPage(int nPage) const {
        return (nPage >= 0 && (size_t)nPage < m_pages.size()) ? m_pages[nPage] : nullptr;
    }
    int GetPageIndex(CPropertyPage* pPage) const {
        for (size_t i = 0; i < m_pages.size(); ++i) if (m_pages[i] == pPage) return (int)i;
        return -1;
    }
    BOOL SetActivePage(int nPage);
    BOOL SetActivePage(CPropertyPage* pPage) { return SetActivePage(GetPageIndex(pPage)); }
    void SetTitle(LPCTSTR lpszText, UINT nStyle = 0) { (void)nStyle; m_strCaption = lpszText ? lpszText : _T(""); if (m_hWnd) SetWindowText(m_strCaption); }
    CTabCtrl* GetTabControl() { return &m_tabCtrl; }
    void SetWizardMode() { m_psh.dwFlags |= PSH_WIZARD; }
    void SetWizardButtons(DWORD dwFlags) { (void)dwFlags; }
    void EnableStackedTabs(BOOL bStacked) { (void)bStacked; }

    void AddPage(CPropertyPage* pPage);
    void RemovePage(CPropertyPage* pPage);
    void RemovePage(int nPage);
    void EndDialog(int nEndID);
    BOOL PressButton(int nButton);

protected:
    BOOL OnCommand(WPARAM wParam, LPARAM lParam) override;
    afx_msg LRESULT OnSheetClose(WPARAM, LPARAM);
    bool ShowPage(int nPage);
    bool ApplyPages();

    DECLARE_MESSAGE_MAP()
};
