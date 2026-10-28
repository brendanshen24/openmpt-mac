#pragma once

#include "afxwin.h"
#include "afxcmn.h"

class CCtrlView : public CView {
    DECLARE_DYNAMIC(CCtrlView)
public:
    CString m_strClass;
    DWORD m_dwDefaultStyle = 0;

    CCtrlView(LPCTSTR lpszClass, DWORD dwStyle) : m_strClass(lpszClass), m_dwDefaultStyle(dwStyle) {}
    ~CCtrlView() override = default;

    void OnDraw(CDC* pDC) override { (void)pDC; }
    BOOL PreCreateWindow(CREATESTRUCT& cs) override {
        cs.lpszClass = m_strClass;
        cs.style |= m_dwDefaultStyle;
        return CView::PreCreateWindow(cs);
    }

    DECLARE_MESSAGE_MAP()
};

class CTreeView : public CCtrlView {
    DECLARE_DYNCREATE(CTreeView)
public:
    CTreeView() : CCtrlView(WC_TREEVIEW, WS_CHILD | WS_VISIBLE | WS_BORDER) {}
    ~CTreeView() override = default;

    CTreeCtrl& GetTreeCtrl() const { return *(CTreeCtrl*)this; }

    DECLARE_MESSAGE_MAP()
};

class CListView : public CCtrlView {
    DECLARE_DYNCREATE(CListView)
public:
    CListView() : CCtrlView(WC_LISTVIEW, WS_CHILD | WS_VISIBLE | WS_BORDER) {}
    ~CListView() override = default;

    CListCtrl& GetListCtrl() const { return *(CListCtrl*)this; }

    DECLARE_MESSAGE_MAP()
};
