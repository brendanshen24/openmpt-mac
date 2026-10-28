#pragma once

#include "afxcmn.h"

class CMFCHeaderCtrl : public CHeaderCtrl {
    DECLARE_DYNAMIC(CMFCHeaderCtrl)
public:
    int m_nSortColumn = -1;
    BOOL m_bAscending = TRUE;
    BOOL m_bMultipleSort = FALSE;

    void SetSortColumn(int iColumn, BOOL bAscending = TRUE, BOOL bAdd = FALSE) {
        (void)bAdd;
        m_nSortColumn = iColumn;
        m_bAscending = bAscending;
    }
    void RemoveSortColumn(int iColumn) {
        if (m_nSortColumn == iColumn) m_nSortColumn = -1;
    }
    int GetSortColumn() const { return m_nSortColumn; }
    BOOL IsAscending() const { return m_bAscending; }
    int GetColumnState(int iColumn) const {
        if (m_nSortColumn == iColumn) return m_bAscending ? 1 : -1;
        return 0;
    }
    BOOL IsMultipleSort() const { return m_bMultipleSort; }
    void EnableMultipleSort(BOOL bEnable = TRUE) { m_bMultipleSort = bEnable; }
};

class CMFCListCtrl : public CListCtrl {
    DECLARE_DYNAMIC(CMFCListCtrl)
public:
    CMFCHeaderCtrl m_headerCtrl;

    CMFCHeaderCtrl& GetHeaderCtrl() { return m_headerCtrl; }
    virtual COLORREF OnGetCellTextColor(int nRow, int nCol) { (void)nRow; (void)nCol; return ::GetSysColor(COLOR_WINDOWTEXT); }
    virtual COLORREF OnGetCellBkColor(int nRow, int nCol) { (void)nRow; (void)nCol; return ::GetSysColor(COLOR_WINDOW); }
    virtual HFONT OnGetCellFont(int nRow, int nCol, DWORD dwData = 0) { (void)nRow; (void)nCol; (void)dwData; return nullptr; }
    virtual int OnCompareItems(LPARAM lParam1, LPARAM lParam2, int iColumn) { (void)lParam1; (void)lParam2; (void)iColumn; return 0; }
    virtual void Sort(int iColumn, BOOL bAscending = TRUE, BOOL bAdd = FALSE) {
        m_headerCtrl.SetSortColumn(iColumn, bAscending, bAdd);
    }
    void SetSortColumn(int iColumn, BOOL bAscending = TRUE, BOOL bAdd = FALSE) {
        m_headerCtrl.SetSortColumn(iColumn, bAscending, bAdd);
    }
    void RemoveSortColumn(int iColumn) { m_headerCtrl.RemoveSortColumn(iColumn); }
    void EnableMultipleSort(BOOL bEnable = TRUE) { m_headerCtrl.EnableMultipleSort(bEnable); }
    BOOL IsMultipleSort() const { return m_headerCtrl.IsMultipleSort(); }

    DECLARE_MESSAGE_MAP()
};
