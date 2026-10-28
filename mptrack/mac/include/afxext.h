#pragma once

#include "afxwin.h"

// Values as in MFC's afxext.h.
#define LM_STRETCH          0x0001
#define LM_HORZ             0x0002
#define LM_MRUWIDTH         0x0004
#define LM_HORZDOCK         0x0008
#define LM_VERTDOCK         0x0010
#define LM_LENGTHY          0x0020
#define LM_COMMIT           0x0040

// As in MFC: style in the low word, button state in the high word (ENABLED inverted to DISABLED).
#define TBBS_BUTTON         MAKELONG(TBSTYLE_BUTTON, 0)
#define TBBS_SEPARATOR      MAKELONG(TBSTYLE_SEP, 0)
#define TBBS_CHECKBOX       MAKELONG(TBSTYLE_CHECK, 0)
#define TBBS_GROUP          MAKELONG(TBSTYLE_GROUP, 0)
#define TBBS_CHECKGROUP     (TBBS_GROUP | TBBS_CHECKBOX)
#define TBBS_DROPDOWN       MAKELONG(TBSTYLE_DROPDOWN, 0)
#define TBBS_CHECKED        MAKELONG(0, TBSTATE_CHECKED)
#define TBBS_PRESSED        MAKELONG(0, TBSTATE_PRESSED)
#define TBBS_DISABLED       MAKELONG(0, TBSTATE_ENABLED)
#define TBBS_INDETERMINATE  MAKELONG(0, TBSTATE_INDETERMINATE)
#define TBBS_HIDDEN         MAKELONG(0, TBSTATE_HIDDEN)
#define TBBS_WRAPPED        MAKELONG(0, TBSTATE_WRAP)

#ifndef AFX_IDC_HSPLITBAR
#define AFX_IDC_HSPLITBAR   30773
#endif
#ifndef AFX_IDC_VSPLITBAR
#define AFX_IDC_VSPLITBAR   30774
#endif

class CToolBarCtrl;

class CControlBar : public CWnd {
    DECLARE_DYNAMIC(CControlBar)
public:
    DWORD m_dwStyle = 0;
    BOOL m_bAutoDelete = FALSE;

    CControlBar() = default;
    ~CControlBar() override = default;

    void SetBarStyle(DWORD dwStyle) { m_dwStyle = dwStyle; }
    DWORD GetBarStyle() const { return m_dwStyle; }
    void EnableDocking(DWORD dwDockStyle) { (void)dwDockStyle; }
    BOOL IsFloating() const { return FALSE; }
    virtual void DelayShow(BOOL show) { (void)show; }
    virtual CSize CalcFixedLayout(BOOL bStretch, BOOL bHorz) {
        (void)bStretch; (void)bHorz;
        return CSize(600, 28);
    }
    virtual CSize CalcDynamicLayout(int nLength, DWORD nMode) {
        (void)nLength; (void)nMode;
        return CalcFixedLayout(FALSE, TRUE);
    }
    virtual void OnUpdateCmdUI(CFrameWnd* pTarget, BOOL bDisableIfNoHndler) {
        (void)pTarget; (void)bDisableIfNoHndler;
    }

    DECLARE_MESSAGE_MAP()
};

class CToolBar : public CControlBar {
    DECLARE_DYNAMIC(CToolBar)
public:
    CSize m_sizeButton{23, 22};
    CSize m_sizeImage{16, 15};

    CToolBar() = default;
    ~CToolBar() override = default;

    virtual BOOL Create(CWnd* pParentWnd, DWORD dwStyle = WS_CHILD | WS_VISIBLE | CBRS_TOP, UINT nID = AFX_IDW_TOOLBAR);
    virtual BOOL CreateEx(CWnd* pParentWnd, DWORD dwCtrlStyle = TBSTYLE_FLAT,
                          DWORD dwStyle = WS_CHILD | WS_VISIBLE | CBRS_ALIGN_TOP,
                          CRect rcBorders = CRect(0, 0, 0, 0), UINT nID = AFX_IDW_TOOLBAR);
    void SetSizes(SIZE sizeButton, SIZE sizeImage);
    BOOL SetButtons(const UINT* lpIDArray, int nIDCount);
    BOOL LoadToolBar(LPCTSTR lpszResourceName);
    BOOL LoadToolBar(UINT nIDResource) { return LoadToolBar(MAKEINTRESOURCE(nIDResource)); }
    BOOL SetBitmap(HBITMAP hbmImageWell);
    int CommandToIndex(UINT nIDFind) const;
    UINT GetItemID(int nIndex) const;
    virtual void GetItemRect(int nIndex, LPRECT lpRect) const;
    UINT GetButtonStyle(int nIndex) const;
    void SetButtonStyle(int nIndex, UINT nStyle);
    void GetButtonInfo(int nIndex, UINT& nID, UINT& nStyle, int& iImage) const;
    void SetButtonInfo(int nIndex, UINT nID, UINT nStyle, int iImage);
    BOOL SetButtonText(int nIndex, LPCTSTR lpszText);
    CString GetButtonText(int nIndex) const;
    CToolBarCtrl& GetToolBarCtrl() const;
    CSize CalcFixedLayout(BOOL bStretch, BOOL bHorz) override;
    CSize CalcDynamicLayout(int nLength, DWORD dwMode) override;
    void OnUpdateCmdUI(CFrameWnd* pTarget, BOOL bDisableIfNoHndler) override;

    DECLARE_MESSAGE_MAP()
};

#define SBPS_NORMAL     0x0000
#define SBPS_NOBORDERS  SBT_NOBORDERS
#define SBPS_POPOUT     SBT_POPOUT
#define SBPS_OWNERDRAW  SBT_OWNERDRAW
#define SBPS_DISABLED   0x04000000
#define SBPS_STRETCH    0x08000000

class CStatusBarCtrl;

class CStatusBar : public CControlBar {
    DECLARE_DYNAMIC(CStatusBar)
public:
    struct PaneInfo {
        UINT nID = 0;
        UINT nStyle = 0;
        int cxWidth = 80;
        CString strText;
    };
    std::vector<PaneInfo> m_panes;

    CStatusBar() = default;
    ~CStatusBar() override = default;

    virtual BOOL Create(CWnd* pParentWnd, DWORD dwStyle = WS_CHILD | WS_VISIBLE | CBRS_BOTTOM, UINT nID = AFX_IDW_STATUS_BAR);
    virtual BOOL CreateEx(CWnd* pParentWnd, DWORD dwCtrlStyle = 0,
                          DWORD dwStyle = WS_CHILD | WS_VISIBLE | CBRS_BOTTOM, UINT nID = AFX_IDW_STATUS_BAR);
    BOOL SetIndicators(const UINT* lpIDArray, int nIDCount);
    int CommandToIndex(UINT nIDFind) const;
    UINT GetItemID(int nIndex) const;
    void GetItemRect(int nIndex, LPRECT lpRect) const;
    CString GetPaneText(int nIndex) const;
    void GetPaneText(int nIndex, CString& rString) const;
    BOOL SetPaneText(int nIndex, LPCTSTR lpszNewText, BOOL bUpdate = TRUE);
    void GetPaneInfo(int nIndex, UINT& nID, UINT& nStyle, int& cxWidth) const;
    void SetPaneInfo(int nIndex, UINT nID, UINT nStyle, int cxWidth);
    UINT GetPaneStyle(int nIndex) const;
    void SetPaneStyle(int nIndex, UINT nStyle);
    CStatusBarCtrl& GetStatusBarCtrl() const { return *(CStatusBarCtrl*)this; }
    CSize CalcFixedLayout(BOOL bStretch, BOOL bHorz) override;
    void OnUpdateCmdUI(CFrameWnd* pTarget, BOOL bDisableIfNoHndler) override;
    void UpdateAllPanes();
    afx_msg void OnSize(UINT nType, int cx, int cy);

    DECLARE_MESSAGE_MAP()
};

class CDialogBar : public CControlBar {
    DECLARE_DYNAMIC(CDialogBar)
public:
    CSize m_sizeDefault{400, 32};

    CDialogBar() = default;
    ~CDialogBar() override = default;

    virtual BOOL Create(CWnd* pParentWnd, LPCTSTR lpszTemplateName, UINT nStyle, UINT nID);
    virtual BOOL Create(CWnd* pParentWnd, UINT nIDTemplate, UINT nStyle, UINT nID) {
        return Create(pParentWnd, MAKEINTRESOURCE(nIDTemplate), nStyle, nID);
    }
    CSize CalcFixedLayout(BOOL bStretch, BOOL bHorz) override {
        (void)bStretch; (void)bHorz;
        return m_sizeDefault;
    }
    virtual LRESULT HandleInitDialog(WPARAM wParam, LPARAM lParam) {
        (void)wParam; (void)lParam;
        return 0;
    }

    DECLARE_MESSAGE_MAP()
};

class CSplitterWnd : public CWnd {
    DECLARE_DYNAMIC(CSplitterWnd)
public:
    int m_nRows = 1;
    int m_nCols = 1;
    int m_nMaxRows = 1;
    int m_nMaxCols = 1;
    CWnd* m_panes[4][4] = {};
    int m_rowHeights[4] = {200, 200, 200, 200};
    int m_colWidths[4] = {200, 200, 200, 200};

    CSplitterWnd() = default;
    ~CSplitterWnd() override = default;

    BOOL CreateStatic(CWnd* pParentWnd, int nRows, int nCols, DWORD dwStyle = WS_CHILD | WS_VISIBLE, UINT nID = AFX_IDW_PANE_FIRST);
    BOOL Create(CWnd* pParentWnd, int nMaxRows, int nMaxCols, SIZE sizeMin, CCreateContext* pContext,
                DWORD dwStyle = WS_CHILD | WS_VISIBLE | WS_HSCROLL | WS_VSCROLL, UINT nID = AFX_IDW_PANE_FIRST);
    virtual BOOL CreateView(int row, int col, CRuntimeClass* pViewClass, SIZE sizeInit, CCreateContext* pContext);
    CWnd* GetPane(int row, int col) const;
    void SetActivePane(int row, int col, CWnd* pWnd = nullptr);
    CWnd* GetActivePane(int* pRow = nullptr, int* pCol = nullptr);
    int IdFromRowCol(int row, int col) const { return AFX_IDW_PANE_FIRST + row * 16 + col; }
    int GetRowCount() const { return m_nRows; }
    int GetColumnCount() const { return m_nCols; }
    void GetRowInfo(int row, int& cyCur, int& cyMin) const;
    void SetRowInfo(int row, int cyIdeal, int cyMin) { (void)cyMin; m_rowHeights[row & 3] = cyIdeal; }
    void GetColumnInfo(int col, int& cxCur, int& cxMin) const;
    void SetColumnInfo(int col, int cxIdeal, int cxMin) { (void)cxMin; m_colWidths[col & 3] = cxIdeal; }
    virtual void DeleteView(int row, int col) {
        if (row >= 0 && row < 4 && col >= 0 && col < 4) {
            if (m_panes[row][col]) {
                m_panes[row][col]->DestroyWindow();
                m_panes[row][col] = nullptr;
            }
        }
    }
    virtual void DeleteRow(int rowDelete) { (void)rowDelete; }
    virtual void DeleteColumn(int colDelete) { (void)colDelete; }
    virtual void RecalcLayout();
    int HitTestBar(CPoint pt) const;
    int m_trackingBar = -1;
    afx_msg void OnSize(UINT nType, int cx, int cy);
    afx_msg void OnPaint();
    afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
    afx_msg void OnMouseMove(UINT nFlags, CPoint point);
    afx_msg void OnLButtonUp(UINT nFlags, CPoint point);

    DECLARE_MESSAGE_MAP()
};

class CFormView : public CScrollView {
    DECLARE_DYNAMIC(CFormView)
public:
    LPCTSTR m_lpszTemplateName = nullptr;

    explicit CFormView(LPCTSTR lpszTemplateName) : m_lpszTemplateName(lpszTemplateName) {}
    explicit CFormView(UINT nIDTemplate) : m_lpszTemplateName(MAKEINTRESOURCE(nIDTemplate)) {}
    ~CFormView() override = default;

    BOOL Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle,
                const RECT& rect, CWnd* pParentWnd, UINT nID, CCreateContext* pContext = nullptr) override;
    void OnInitialUpdate() override;
    void OnDraw(CDC* pDC) override { (void)pDC; }

    DECLARE_MESSAGE_MAP()
};
