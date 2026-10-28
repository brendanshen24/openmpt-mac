#pragma once

#include "afxwin.h"

class CImageList : public CObject {
public:
    HIMAGELIST m_hImageList = nullptr;

    CImageList() = default;
    ~CImageList() override { DeleteImageList(); }

    operator HIMAGELIST() const noexcept { return m_hImageList; }
    HIMAGELIST GetSafeHandle() const noexcept { return this ? m_hImageList : nullptr; }
    static CImageList* FromHandle(HIMAGELIST h);

    BOOL Create(int cx, int cy, UINT nFlags, int nInitial, int nGrow);
    BOOL Create(UINT nBitmapID, int cx, int nGrow, COLORREF crMask);
    BOOL Create(LPCTSTR lpszBitmapID, int cx, int nGrow, COLORREF crMask);
    BOOL Create(CImageList* pImageList);
    BOOL Attach(HIMAGELIST hImageList) { m_hImageList = hImageList; return hImageList != nullptr; }
    HIMAGELIST Detach() { HIMAGELIST h = m_hImageList; m_hImageList = nullptr; return h; }
    BOOL DeleteImageList();

    int GetImageCount() const;
    BOOL SetImageCount(UINT uNewCount) { (void)uNewCount; return TRUE; }
    COLORREF SetBkColor(COLORREF cr);
    COLORREF GetBkColor() const;
    BOOL GetImageInfo(int nImage, IMAGEINFO* pImageInfo) const;
    int Add(CBitmap* pbmImage, CBitmap* pbmMask);
    int Add(CBitmap* pbmImage, COLORREF crMask);
    int Add(HICON hIcon);
    BOOL Remove(int nImage);
    BOOL Replace(int nImage, CBitmap* pbmImage, CBitmap* pbmMask);
    int Replace(int nImage, HICON hIcon);
    HICON ExtractIcon(int nImage);
    BOOL Draw(CDC* pDC, int nImage, POINT pt, UINT nStyle);
    BOOL DrawEx(CDC* pDC, int nImage, POINT pt, SIZE sz, COLORREF clrBk, COLORREF clrFg, UINT nStyle);
    BOOL SetOverlayImage(int nImage, int nOverlay) { (void)nImage; (void)nOverlay; return TRUE; }

    static BOOL BeginDrag(int nImage, CPoint ptHotSpot) { (void)nImage; (void)ptHotSpot; return TRUE; }
    static void EndDrag() {}
    static BOOL DragMove(CPoint pt) { (void)pt; return TRUE; }
    static BOOL DragEnter(CWnd* pWndLock, CPoint point) { (void)pWndLock; (void)point; return TRUE; }
    static BOOL DragLeave(CWnd* pWndLock) { (void)pWndLock; return TRUE; }
    static BOOL DragShowNolock(BOOL bShow) { (void)bShow; return TRUE; }
};

class CHeaderCtrl : public CWnd {
    DECLARE_DYNAMIC(CHeaderCtrl)
public:
    int GetItemCount() const { return (int)::SendMessage(m_hWnd, HDM_GETITEMCOUNT, 0, 0L); }
    int InsertItem(int nPos, HDITEM* phdi) { return (int)::SendMessage(m_hWnd, HDM_INSERTITEM, nPos, (LPARAM)phdi); }
    BOOL DeleteItem(int nPos) { return (BOOL)::SendMessage(m_hWnd, HDM_DELETEITEM, nPos, 0L); }
    BOOL GetItem(int nPos, HDITEM* pHeaderItem) const { return (BOOL)::SendMessage(m_hWnd, HDM_GETITEM, nPos, (LPARAM)pHeaderItem); }
    BOOL SetItem(int nPos, HDITEM* pHeaderItem) { return (BOOL)::SendMessage(m_hWnd, HDM_SETITEM, nPos, (LPARAM)pHeaderItem); }
    BOOL GetItemRect(int nIndex, LPRECT lpRect) const { return (BOOL)::SendMessage(m_hWnd, HDM_GETITEMRECT, nIndex, (LPARAM)lpRect); }
};

class CListCtrl : public CWnd {
    DECLARE_DYNAMIC(CListCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(WC_LISTVIEW, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    CEdit* GetEditControl() const { return (CEdit*)CWnd::FromHandle((HWND)::SendMessage(m_hWnd, LVM_GETEDITCONTROL, 0, 0L)); }
    DWORD SetExtendedStyle(DWORD dwNewStyle) { return (DWORD)::SendMessage(m_hWnd, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, (LPARAM)dwNewStyle); }
    DWORD GetExtendedStyle() const { return (DWORD)::SendMessage(m_hWnd, LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0); }
    CHeaderCtrl* GetHeaderCtrl() const;
    CImageList* SetImageList(CImageList* pImageList, int nImageListType);
    CImageList* GetImageList(int nImageList) const;

    COLORREF GetBkColor() const { return (COLORREF)::SendMessage(m_hWnd, LVM_GETBKCOLOR, 0, 0); }
    BOOL SetBkColor(COLORREF cr) { return (BOOL)::SendMessage(m_hWnd, LVM_SETBKCOLOR, 0, (LPARAM)cr); }
    COLORREF GetTextColor() const { return (COLORREF)::SendMessage(m_hWnd, LVM_GETTEXTCOLOR, 0, 0); }
    BOOL SetTextColor(COLORREF cr) { return (BOOL)::SendMessage(m_hWnd, LVM_SETTEXTCOLOR, 0, (LPARAM)cr); }
    COLORREF GetTextBkColor() const { return (COLORREF)::SendMessage(m_hWnd, LVM_GETTEXTBKCOLOR, 0, 0); }
    BOOL SetTextBkColor(COLORREF cr) { return (BOOL)::SendMessage(m_hWnd, LVM_SETTEXTBKCOLOR, 0, (LPARAM)cr); }

    int GetItemCount() const { return (int)::SendMessage(m_hWnd, LVM_GETITEMCOUNT, 0, 0L); }
    BOOL SetItemCount(int nItems) { return (BOOL)::SendMessage(m_hWnd, LVM_SETITEMCOUNT, nItems, 0); }
    BOOL SetItemCountEx(int iCount, DWORD dwFlags = LVSICF_NOINVALIDATEALL) { return (BOOL)::SendMessage(m_hWnd, LVM_SETITEMCOUNT, iCount, (LPARAM)dwFlags); }

    BOOL GetItem(LVITEM* pItem) const { return (BOOL)::SendMessage(m_hWnd, LVM_GETITEM, 0, (LPARAM)pItem); }
    BOOL SetItem(const LVITEM* pItem) { return (BOOL)::SendMessage(m_hWnd, LVM_SETITEM, 0, (LPARAM)pItem); }
    BOOL SetItem(int nItem, int nSubItem, UINT nMask, LPCTSTR lpszItem, int nImage, UINT nState, UINT nStateMask, LPARAM lParam);
    int InsertItem(const LVITEM* pItem) { return (int)::SendMessage(m_hWnd, LVM_INSERTITEM, 0, (LPARAM)pItem); }
    int InsertItem(int nItem, LPCTSTR lpszItem);
    int InsertItem(int nItem, LPCSTR lpszItem) {
        CString s(lpszItem);
        return InsertItem(nItem, (LPCTSTR)s);
    }
    int InsertItem(int nItem, LPCTSTR lpszItem, int nImage);
    int InsertItem(UINT nMask, int nItem, LPCTSTR lpszItem, UINT nState, UINT nStateMask, int nImage, LPARAM lParam);
    BOOL DeleteItem(int nItem) { return (BOOL)::SendMessage(m_hWnd, LVM_DELETEITEM, nItem, 0L); }
    BOOL DeleteAllItems() { return (BOOL)::SendMessage(m_hWnd, LVM_DELETEALLITEMS, 0, 0L); }

    UINT GetCallbackMask() const { return (UINT)::SendMessage(m_hWnd, LVM_GETCALLBACKMASK, 0, 0); }
    BOOL SetCallbackMask(UINT nMask) { return (BOOL)::SendMessage(m_hWnd, LVM_SETCALLBACKMASK, nMask, 0); }
    int GetNextItem(int nItem, int nFlags) const { return (int)::SendMessage(m_hWnd, LVM_GETNEXTITEM, nItem, MAKELPARAM(nFlags, 0)); }
    POSITION GetFirstSelectedItemPosition() const {
        return (POSITION)(intptr_t)(1 + GetNextItem(-1, LVNI_SELECTED));
    }
    int GetNextSelectedItem(POSITION& pos) const {
        int nOldPos = (int)(intptr_t)pos - 1;
        pos = (POSITION)(intptr_t)(1 + GetNextItem(nOldPos, LVNI_SELECTED));
        return nOldPos;
    }
    BOOL GetItemRect(int nItem, LPRECT lpRect, UINT nCode) const {
        if (lpRect) lpRect->left = nCode;
        return (BOOL)::SendMessage(m_hWnd, LVM_GETITEMRECT, nItem, (LPARAM)lpRect);
    }
    BOOL GetSubItemRect(int iItem, int iSubItem, int nArea, CRect& ref) const {
        ref.top = iSubItem; ref.left = nArea;
        return (BOOL)::SendMessage(m_hWnd, LVM_GETSUBITEMRECT, iItem, (LPARAM)&ref);
    }
    BOOL GetViewRect(LPRECT lpRect) const {
        return (BOOL)::SendMessage(m_hWnd, LVM_GETVIEWRECT, 0, (LPARAM)lpRect);
    }
    int GetSelectionMark() const { return (int)::SendMessage(m_hWnd, LVM_GETSELECTIONMARK, 0, 0); }
    int SetSelectionMark(int iIndex) { return (int)::SendMessage(m_hWnd, LVM_SETSELECTIONMARK, 0, iIndex); }
    UINT GetSelectedCount() const { return (UINT)::SendMessage(m_hWnd, LVM_GETSELECTEDCOUNT, 0, 0L); }

    BOOL SetItemState(int nItem, LVITEM* pItem) { return (BOOL)::SendMessage(m_hWnd, LVM_SETITEMSTATE, nItem, (LPARAM)pItem); }
    BOOL SetItemState(int nItem, UINT nState, UINT nMask) {
        LVITEM lvi{}; lvi.stateMask = nMask; lvi.state = nState;
        return (BOOL)::SendMessage(m_hWnd, LVM_SETITEMSTATE, nItem, (LPARAM)&lvi);
    }
    UINT GetItemState(int nItem, UINT nMask) const { return (UINT)::SendMessage(m_hWnd, LVM_GETITEMSTATE, nItem, nMask); }
    CString GetItemText(int nItem, int nSubItem) const;
    int GetItemText(int nItem, int nSubItem, LPTSTR lpszText, int nLen) const;
    BOOL SetItemText(int nItem, int nSubItem, LPCTSTR lpszText);
    BOOL SetItemText(int nItem, int nSubItem, LPCSTR lpszText) {
        CString s(lpszText);
        return SetItemText(nItem, nSubItem, (LPCTSTR)s);
    }
    BOOL SetItemData(int nItem, DWORD_PTR dwData);
    DWORD_PTR GetItemData(int nItem) const;

    int InsertColumn(int nCol, const LVCOLUMN* pColumn) { return (int)::SendMessage(m_hWnd, LVM_INSERTCOLUMN, nCol, (LPARAM)pColumn); }
    int InsertColumn(int nCol, LPCTSTR lpszColumnHeading, int nFormat = LVCFMT_LEFT, int nWidth = -1, int nSubItem = -1);
    BOOL DeleteColumn(int nCol) { return (BOOL)::SendMessage(m_hWnd, LVM_DELETECOLUMN, nCol, 0); }
    BOOL GetColumn(int nCol, LVCOLUMN* pColumn) const { return (BOOL)::SendMessage(m_hWnd, LVM_GETCOLUMN, nCol, (LPARAM)pColumn); }
    BOOL SetColumn(int nCol, const LVCOLUMN* pColumn) { return (BOOL)::SendMessage(m_hWnd, LVM_SETCOLUMN, nCol, (LPARAM)pColumn); }
    int GetColumnWidth(int nCol) const { return (int)::SendMessage(m_hWnd, LVM_GETCOLUMNWIDTH, nCol, 0); }
    BOOL SetColumnWidth(int nCol, int cx) { return (BOOL)::SendMessage(m_hWnd, LVM_SETCOLUMNWIDTH, nCol, MAKELPARAM(cx, 0)); }
    BOOL GetColumnOrderArray(LPINT piArray, int iCount = -1) const { return (BOOL)::SendMessage(m_hWnd, LVM_GETCOLUMNORDERARRAY, iCount, (LPARAM)piArray); }
    BOOL SetColumnOrderArray(int iCount, LPINT piArray) { return (BOOL)::SendMessage(m_hWnd, LVM_SETCOLUMNORDERARRAY, iCount, (LPARAM)piArray); }

    BOOL GetCheck(int nItem) const { return (GetItemState(nItem, LVIS_STATEIMAGEMASK) >> 12) - 1 > 0; }
    BOOL SetCheck(int nItem, BOOL fCheck = TRUE) { return SetItemState(nItem, INDEXTOSTATEIMAGEMASK((fCheck ? 2 : 1)), LVIS_STATEIMAGEMASK); }
    BOOL EnsureVisible(int nItem, BOOL bPartialOK) { return (BOOL)::SendMessage(m_hWnd, LVM_ENSUREVISIBLE, nItem, MAKELPARAM(bPartialOK, 0)); }
    BOOL Scroll(CSize size) { return (BOOL)::SendMessage(m_hWnd, LVM_SCROLL, size.cx, size.cy); }
    BOOL RedrawItems(int nFirst, int nLast) { return (BOOL)::SendMessage(m_hWnd, LVM_REDRAWITEMS, nFirst, nLast); }
    BOOL Arrange(UINT nCode) { return (BOOL)::SendMessage(m_hWnd, LVM_ARRANGE, nCode, 0L); }
    CEdit* EditLabel(int nItem) { (void)nItem; return nullptr; }
    int HitTest(LVHITTESTINFO* pHitTestInfo) const { return (int)::SendMessage(m_hWnd, LVM_HITTEST, 0, (LPARAM)pHitTestInfo); }
    int HitTest(CPoint pt, UINT* pFlags = nullptr) const {
        LVHITTESTINFO hti{}; hti.pt = pt;
        int res = (int)::SendMessage(m_hWnd, LVM_HITTEST, 0, (LPARAM)&hti);
        if (pFlags) *pFlags = hti.flags;
        return res;
    }
    int SubItemHitTest(LPLVHITTESTINFO pInfo) { return (int)::SendMessage(m_hWnd, LVM_SUBITEMHITTEST, 0, (LPARAM)pInfo); }
    BOOL SortItems(PFNLVCOMPARE pfnCompare, DWORD_PTR dwData) { return (BOOL)::SendMessage(m_hWnd, LVM_SORTITEMS, dwData, (LPARAM)pfnCompare); }
    BOOL SortItemsEx(PFNLVCOMPARE pfnCompare, DWORD_PTR dwData) { return (BOOL)::SendMessage(m_hWnd, LVM_SORTITEMSEX, dwData, (LPARAM)pfnCompare); }

    int InsertGroup(int index, PLVGROUP pgrp) { return (int)::SendMessage(m_hWnd, LVM_INSERTGROUP, index, (LPARAM)pgrp); }
    int RemoveGroup(int iGroupId) { return (int)::SendMessage(m_hWnd, LVM_REMOVEGROUP, iGroupId, 0); }
    void RemoveAllGroups() { ::SendMessage(m_hWnd, LVM_REMOVEALLGROUPS, 0, 0); }
    int EnableGroupView(BOOL fEnable) { return (int)::SendMessage(m_hWnd, LVM_ENABLEGROUPVIEW, fEnable, 0); }
    BOOL IsGroupViewEnabled() const { return (BOOL)::SendMessage(m_hWnd, LVM_ISGROUPVIEWENABLED, 0, 0); }

    virtual void DrawItem(LPDRAWITEMSTRUCT lpDrawItemStruct) { (void)lpDrawItemStruct; }
};

class CTreeCtrl : public CWnd {
    DECLARE_DYNAMIC(CTreeCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(WC_TREEVIEW, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    CImageList* SetImageList(CImageList* pImageList, int nImageListType);
    CImageList* GetImageList(UINT nImageList) const;
    UINT GetCount() const { return (UINT)::SendMessage(m_hWnd, TVM_GETCOUNT, 0, 0); }
    UINT GetIndent() const { return (UINT)::SendMessage(m_hWnd, TVM_GETINDENT, 0, 0); }
    void SetIndent(UINT nIndent) { ::SendMessage(m_hWnd, TVM_SETINDENT, nIndent, 0); }

    HTREEITEM GetNextItem(HTREEITEM hItem, UINT nCode) const { return (HTREEITEM)::SendMessage(m_hWnd, TVM_GETNEXTITEM, nCode, (LPARAM)hItem); }
    HTREEITEM GetChildItem(HTREEITEM hItem) const { return GetNextItem(hItem, TVGN_CHILD); }
    HTREEITEM GetNextSiblingItem(HTREEITEM hItem) const { return GetNextItem(hItem, TVGN_NEXT); }
    HTREEITEM GetPrevSiblingItem(HTREEITEM hItem) const { return GetNextItem(hItem, TVGN_PREVIOUS); }
    HTREEITEM GetParentItem(HTREEITEM hItem) const { return GetNextItem(hItem, TVGN_PARENT); }
    HTREEITEM GetFirstVisibleItem() const { return GetNextItem(nullptr, TVGN_FIRSTVISIBLE); }
    HTREEITEM GetNextVisibleItem(HTREEITEM hItem) const { return GetNextItem(hItem, TVGN_NEXTVISIBLE); }
    HTREEITEM GetPrevVisibleItem(HTREEITEM hItem) const { return GetNextItem(hItem, TVGN_PREVIOUSVISIBLE); }
    HTREEITEM GetSelectedItem() const { return GetNextItem(nullptr, TVGN_CARET); }
    HTREEITEM GetDropHilightItem() const { return GetNextItem(nullptr, TVGN_DROPHILITE); }
    HTREEITEM GetRootItem() const { return GetNextItem(nullptr, TVGN_ROOT); }

    BOOL GetItem(TVITEM* pItem) const { return (BOOL)::SendMessage(m_hWnd, TVM_GETITEM, 0, (LPARAM)pItem); }
    BOOL SetItem(const TVITEM* pItem) { return (BOOL)::SendMessage(m_hWnd, TVM_SETITEM, 0, (LPARAM)pItem); }
    BOOL SetItem(HTREEITEM hItem, UINT nMask, LPCTSTR lpszItem, int nImage, int nSelectedImage, UINT nState, UINT nStateMask, LPARAM lParam);
    CString GetItemText(HTREEITEM hItem) const;
    BOOL SetItemText(HTREEITEM hItem, LPCTSTR lpszItem);
    BOOL GetItemImage(HTREEITEM hItem, int& nImage, int& nSelectedImage) const;
    BOOL SetItemImage(HTREEITEM hItem, int nImage, int nSelectedImage);
    UINT GetItemState(HTREEITEM hItem, UINT nStateMask) const;
    BOOL SetItemState(HTREEITEM hItem, UINT nState, UINT nStateMask);
    DWORD_PTR GetItemData(HTREEITEM hItem) const;
    BOOL SetItemData(HTREEITEM hItem, DWORD_PTR dwData);
    BOOL ItemHasChildren(HTREEITEM hItem) const { return GetChildItem(hItem) != nullptr; }
    BOOL GetItemRect(HTREEITEM hItem, LPRECT lpRect, BOOL bTextOnly) const {
        if (lpRect) *(HTREEITEM*)lpRect = hItem;
        return (BOOL)::SendMessage(m_hWnd, TVM_GETITEMRECT, bTextOnly, (LPARAM)lpRect);
    }
    CEdit* GetEditControl() const { return (CEdit*)CWnd::FromHandle((HWND)::SendMessage(m_hWnd, TVM_GETEDITCONTROL, 0, 0)); }

    HTREEITEM InsertItem(LPTVINSERTSTRUCT lpInsertStruct) { return (HTREEITEM)::SendMessage(m_hWnd, TVM_INSERTITEM, 0, (LPARAM)lpInsertStruct); }
    HTREEITEM InsertItem(UINT nMask, LPCTSTR lpszItem, int nImage, int nSelectedImage, UINT nState, UINT nStateMask, LPARAM lParam, HTREEITEM hParent, HTREEITEM hInsertAfter);
    HTREEITEM InsertItem(LPCTSTR lpszItem, HTREEITEM hParent = TVI_ROOT, HTREEITEM hInsertAfter = TVI_LAST);
    HTREEITEM InsertItem(LPCTSTR lpszItem, int nImage, int nSelectedImage, HTREEITEM hParent = TVI_ROOT, HTREEITEM hInsertAfter = TVI_LAST);
    BOOL DeleteItem(HTREEITEM hItem) { return (BOOL)::SendMessage(m_hWnd, TVM_DELETEITEM, 0, (LPARAM)hItem); }
    BOOL DeleteAllItems() { return DeleteItem(TVI_ROOT); }
    BOOL Expand(HTREEITEM hItem, UINT nCode) { return (BOOL)::SendMessage(m_hWnd, TVM_EXPAND, nCode, (LPARAM)hItem); }
    BOOL Select(HTREEITEM hItem, UINT nCode) { return (BOOL)::SendMessage(m_hWnd, TVM_SELECTITEM, nCode, (LPARAM)hItem); }
    BOOL SelectItem(HTREEITEM hItem) { return Select(hItem, TVGN_CARET); }
    BOOL SelectDropTarget(HTREEITEM hItem) { return Select(hItem, TVGN_DROPHILITE); }
    BOOL SelectSetFirstVisible(HTREEITEM hItem) { return Select(hItem, TVGN_FIRSTVISIBLE); }
    BOOL EndEditLabelNow(BOOL fCancelWithoutSave) { return (BOOL)::SendMessage(m_hWnd, TVM_ENDEDITLABELNOW, fCancelWithoutSave, 0); }
    CEdit* EditLabel(HTREEITEM hItem) { return (CEdit*)CWnd::FromHandle((HWND)::SendMessage(m_hWnd, TVM_EDITLABEL, 0, (LPARAM)hItem)); }
    HTREEITEM HitTest(CPoint pt, UINT* pFlags = nullptr) const {
        TVHITTESTINFO hti{}; hti.pt = pt;
        HTREEITEM h = (HTREEITEM)::SendMessage(m_hWnd, TVM_HITTEST, 0, (LPARAM)&hti);
        if (pFlags) *pFlags = hti.flags;
        return h;
    }
    HTREEITEM HitTest(TVHITTESTINFO* pHitTestInfo) const { return (HTREEITEM)::SendMessage(m_hWnd, TVM_HITTEST, 0, (LPARAM)pHitTestInfo); }
    CImageList* CreateDragImage(HTREEITEM hItem) { (void)hItem; return nullptr; }
    BOOL SortChildren(HTREEITEM hItem) { return (BOOL)::SendMessage(m_hWnd, TVM_SORTCHILDREN, 0, (LPARAM)hItem); }
    BOOL EnsureVisible(HTREEITEM hItem) { return (BOOL)::SendMessage(m_hWnd, TVM_ENSUREVISIBLE, 0, (LPARAM)hItem); }
    BOOL SortChildrenCB(LPTVSORTCB pSort) { return (BOOL)::SendMessage(m_hWnd, TVM_SORTCHILDRENCB, 0, (LPARAM)pSort); }
    BOOL GetCheck(HTREEITEM hItem) const { return (GetItemState(hItem, TVIS_STATEIMAGEMASK) >> 12) - 1 > 0; }
    BOOL SetCheck(HTREEITEM hItem, BOOL fCheck = TRUE) { return SetItemState(hItem, INDEXTOSTATEIMAGEMASK((fCheck ? 2 : 1)), TVIS_STATEIMAGEMASK); }
};

class CTabCtrl : public CWnd {
    DECLARE_DYNAMIC(CTabCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(WC_TABCONTROL, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    CImageList* SetImageList(CImageList* pImageList) {
        return (CImageList*)nullptr + ::SendMessage(m_hWnd, TCM_SETIMAGELIST, 0, (LPARAM)(pImageList ? pImageList->GetSafeHandle() : nullptr)) * 0;
    }
    int GetItemCount() const { return (int)::SendMessage(m_hWnd, TCM_GETITEMCOUNT, 0, 0L); }
    BOOL GetItem(int nItem, TCITEM* pTabCtrlItem) const { return (BOOL)::SendMessage(m_hWnd, TCM_GETITEM, nItem, (LPARAM)pTabCtrlItem); }
    BOOL SetItem(int nItem, TCITEM* pTabCtrlItem) { return (BOOL)::SendMessage(m_hWnd, TCM_SETITEM, nItem, (LPARAM)pTabCtrlItem); }
    BOOL GetItemRect(int nItem, LPRECT lpRect) const { return (BOOL)::SendMessage(m_hWnd, TCM_GETITEMRECT, nItem, (LPARAM)lpRect); }
    int GetCurSel() const { return (int)::SendMessage(m_hWnd, TCM_GETCURSEL, 0, 0L); }
    int SetCurSel(int nItem) { return (int)::SendMessage(m_hWnd, TCM_SETCURSEL, nItem, 0L); }
    int GetCurFocus() const { return (int)::SendMessage(m_hWnd, TCM_GETCURFOCUS, 0, 0L); }
    void SetCurFocus(int nItem) { ::SendMessage(m_hWnd, TCM_SETCURFOCUS, nItem, 0L); }
    CSize SetItemSize(CSize size) {
        DWORD dw = (DWORD)::SendMessage(m_hWnd, TCM_SETITEMSIZE, 0, MAKELPARAM(size.cx, size.cy));
        return CSize(LOWORD(dw), HIWORD(dw));
    }
    void SetPadding(CSize size) { ::SendMessage(m_hWnd, TCM_SETPADDING, 0, MAKELPARAM(size.cx, size.cy)); }
    int GetRowCount() const { return (int)::SendMessage(m_hWnd, TCM_GETROWCOUNT, 0, 0L); }
    LONG InsertItem(int nItem, TCITEM* pTabCtrlItem) { return (LONG)::SendMessage(m_hWnd, TCM_INSERTITEM, nItem, (LPARAM)pTabCtrlItem); }
    LONG InsertItem(int nItem, LPCTSTR lpszItem);
    LONG InsertItem(int nItem, LPCTSTR lpszItem, int nImage);
    LONG InsertItem(UINT nMask, int nItem, LPCTSTR lpszItem, int nImage, LPARAM lParam);
    LONG InsertItem(UINT nMask, int nItem, LPCTSTR lpszItem, int nImage, LPARAM lParam, DWORD dwState, DWORD dwStateMask);
    BOOL DeleteItem(int nItem) { return (BOOL)::SendMessage(m_hWnd, TCM_DELETEITEM, nItem, 0L); }
    BOOL DeleteAllItems() { return (BOOL)::SendMessage(m_hWnd, TCM_DELETEALLITEMS, 0, 0L); }
    void AdjustRect(BOOL bLarger, LPRECT lpRect) { ::SendMessage(m_hWnd, TCM_ADJUSTRECT, bLarger, (LPARAM)lpRect); }
    int HitTest(TCHITTESTINFO* pHitTestInfo) const { return (int)::SendMessage(m_hWnd, TCM_HITTEST, 0, (LPARAM)pHitTestInfo); }
};

class CSliderCtrl : public CWnd {
    DECLARE_DYNAMIC(CSliderCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(TRACKBAR_CLASS, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    int GetLineSize() const { return (int)::SendMessage(m_hWnd, TBM_GETLINESIZE, 0, 0l); }
    int SetLineSize(int nSize) { return (int)::SendMessage(m_hWnd, TBM_SETLINESIZE, 0, nSize); }
    int GetPageSize() const { return (int)::SendMessage(m_hWnd, TBM_GETPAGESIZE, 0, 0l); }
    int SetPageSize(int nSize) { return (int)::SendMessage(m_hWnd, TBM_SETPAGESIZE, 0, nSize); }
    int GetRangeMax() const { return (int)::SendMessage(m_hWnd, TBM_GETRANGEMAX, 0, 0l); }
    int GetRangeMin() const { return (int)::SendMessage(m_hWnd, TBM_GETRANGEMIN, 0, 0l); }
    void GetRange(int& nMin, int& nMax) const { nMin = GetRangeMin(); nMax = GetRangeMax(); }
    void SetRangeMin(int nMin, BOOL bRedraw = FALSE) { ::SendMessage(m_hWnd, TBM_SETRANGEMIN, bRedraw, nMin); }
    void SetRangeMax(int nMax, BOOL bRedraw = FALSE) { ::SendMessage(m_hWnd, TBM_SETRANGEMAX, bRedraw, nMax); }
    void SetRange(int nMin, int nMax, BOOL bRedraw = FALSE) {
        SetRangeMin(nMin, FALSE);
        SetRangeMax(nMax, bRedraw);
    }
    void GetSelection(int& nMin, int& nMax) const {
        nMin = (int)::SendMessage(m_hWnd, TBM_GETSELSTART, 0, 0L);
        nMax = (int)::SendMessage(m_hWnd, TBM_GETSELEND, 0, 0L);
    }
    void SetSelection(int nMin, int nMax) {
        ::SendMessage(m_hWnd, TBM_SETSELSTART, 0, (LPARAM)nMin);
        ::SendMessage(m_hWnd, TBM_SETSELEND, 0, (LPARAM)nMax);
    }
    void ClearSel(BOOL bRedraw = FALSE) { ::SendMessage(m_hWnd, TBM_CLEARSEL, bRedraw, 0l); }
    void ClearTics(BOOL bRedraw = FALSE) { ::SendMessage(m_hWnd, TBM_CLEARTICS, bRedraw, 0l); }
    BOOL SetTic(int nTic) { return (BOOL)::SendMessage(m_hWnd, TBM_SETTIC, 0, nTic); }
    void SetTicFreq(int nFreq) { ::SendMessage(m_hWnd, TBM_SETTICFREQ, nFreq, 0L); }
    int GetPos() const { return (int)::SendMessage(m_hWnd, TBM_GETPOS, 0, 0l); }
    void SetPos(int nPos) { ::SendMessage(m_hWnd, TBM_SETPOS, TRUE, nPos); }
};

class CSpinButtonCtrl : public CWnd {
    DECLARE_DYNAMIC(CSpinButtonCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(UPDOWN_CLASS, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    BOOL SetAccel(int nAccel, UDACCEL* pAccel) { return (BOOL)::SendMessage(m_hWnd, UDM_SETACCEL, nAccel, (LPARAM)pAccel); }
    UINT GetAccel(int nAccel, UDACCEL* pAccel) const { return (UINT)::SendMessage(m_hWnd, UDM_GETACCEL, nAccel, (LPARAM)pAccel); }
    int SetBase(int nBase) { return (int)::SendMessage(m_hWnd, UDM_SETBASE, nBase, 0L); }
    UINT GetBase() const { return (UINT)::SendMessage(m_hWnd, UDM_GETBASE, 0, 0l); }
    CWnd* SetBuddy(CWnd* pWndBuddy) { return CWnd::FromHandle((HWND)::SendMessage(m_hWnd, UDM_SETBUDDY, (WPARAM)(pWndBuddy ? pWndBuddy->GetSafeHwnd() : nullptr), 0L)); }
    CWnd* GetBuddy() const { return CWnd::FromHandle((HWND)::SendMessage(m_hWnd, UDM_GETBUDDY, 0, 0l)); }
    int SetPos(int nPos) { return (int)(short)LOWORD(::SendMessage(m_hWnd, UDM_SETPOS, 0, MAKELPARAM(nPos, 0))); }
    int GetPos() const { return (int)(LOWORD(::SendMessage(m_hWnd, UDM_GETPOS, 0, 0l))); }
    int SetPos32(int nPos) { return (int)::SendMessage(m_hWnd, UDM_SETPOS32, 0, (LPARAM)nPos); }
    int GetPos32(LPBOOL lpbError = nullptr) const { return (int)::SendMessage(m_hWnd, UDM_GETPOS32, 0, (LPARAM)lpbError); }
    void SetRange(int nLower, int nUpper) { ::SendMessage(m_hWnd, UDM_SETRANGE, 0, MAKELPARAM(nUpper, nLower)); }
    void SetRange32(int nLower, int nUpper) { ::SendMessage(m_hWnd, UDM_SETRANGE32, (WPARAM)nLower, (LPARAM)nUpper); }
    DWORD GetRange() const { return (DWORD)::SendMessage(m_hWnd, UDM_GETRANGE, 0, 0l); }
    void GetRange(int& lower, int& upper) const {
        DWORD dw = (DWORD)::SendMessage(m_hWnd, UDM_GETRANGE, 0, 0l);
        lower = (int)(short)HIWORD(dw); upper = (int)(short)LOWORD(dw);
    }
    void GetRange32(int& lower, int& upper) const { ::SendMessage(m_hWnd, UDM_GETRANGE32, (WPARAM)&lower, (LPARAM)&upper); }
};

class CProgressCtrl : public CWnd {
    DECLARE_DYNAMIC(CProgressCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(PROGRESS_CLASS, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    void SetRange(short nLower, short nUpper) { ::SendMessage(m_hWnd, PBM_SETRANGE, 0, MAKELPARAM(nLower, nUpper)); }
    void SetRange32(int nLower, int nUpper) { ::SendMessage(m_hWnd, PBM_SETRANGE32, (WPARAM)nLower, (LPARAM)nUpper); }
    void GetRange(int& nLower, int& nUpper) const {
        PBRANGE range{};
        ::SendMessage(m_hWnd, PBM_GETRANGE, TRUE, (LPARAM)&range);
        nLower = range.iLow; nUpper = range.iHigh;
    }
    int GetPos() const { return (int)::SendMessage(m_hWnd, PBM_GETPOS, 0, 0); }
    int SetPos(int nPos) { return (int)::SendMessage(m_hWnd, PBM_SETPOS, nPos, 0L); }
    int OffsetPos(int nPos) { return (int)::SendMessage(m_hWnd, PBM_DELTAPOS, nPos, 0L); }
    int SetStep(int nStep) { return (int)::SendMessage(m_hWnd, PBM_SETSTEP, nStep, 0L); }
    int StepIt() { return (int)::SendMessage(m_hWnd, PBM_STEPIT, 0, 0L); }
};

class CComboBoxEx : public CComboBox {
    DECLARE_DYNAMIC(CComboBoxEx)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(WC_COMBOBOXEX, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    int InsertItem(const COMBOBOXEXITEM* pCBItem) { return (int)::SendMessage(m_hWnd, CBEM_INSERTITEM, 0, (LPARAM)pCBItem); }
    BOOL GetItem(COMBOBOXEXITEM* pCBItem) { return (BOOL)::SendMessage(m_hWnd, CBEM_GETITEM, 0, (LPARAM)pCBItem); }
    BOOL SetItem(const COMBOBOXEXITEM* pCBItem) { return (BOOL)::SendMessage(m_hWnd, CBEM_SETITEM, 0, (LPARAM)pCBItem); }
    int DeleteItem(int iIndex) { return (int)::SendMessage(m_hWnd, CBEM_DELETEITEM, iIndex, 0); }
    CComboBox* GetComboBoxCtrl() { return this; }
    CEdit* GetEditCtrl() { return (CEdit*)CWnd::FromHandle((HWND)::SendMessage(m_hWnd, CBEM_GETEDITCONTROL, 0, 0)); }
    CImageList* SetImageList(CImageList* pImageList);
    CImageList* GetImageList() const;
};

class CToolBarCtrl : public CWnd {
    DECLARE_DYNAMIC(CToolBarCtrl)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(TOOLBARCLASSNAME, nullptr, dwStyle, rect, pParentWnd, nID);
    }
    BOOL SetIndent(int iIndent) { return (BOOL)::SendMessage(m_hWnd, TB_SETINDENT, iIndent, 0L); }
    BOOL ChangeBitmap(int idButton, int iBitmap) { return (BOOL)::SendMessage(m_hWnd, TB_CHANGEBITMAP, idButton, MAKELPARAM(iBitmap, 0)); }
    BOOL EnableButton(int nID, BOOL bEnable = TRUE) { return (BOOL)::SendMessage(m_hWnd, TB_ENABLEBUTTON, nID, MAKELPARAM(bEnable, 0)); }
    BOOL CheckButton(int nID, BOOL bCheck = TRUE) { return (BOOL)::SendMessage(m_hWnd, TB_CHECKBUTTON, nID, MAKELPARAM(bCheck, 0)); }
    BOOL PressButton(int nID, BOOL bPress = TRUE) { return (BOOL)::SendMessage(m_hWnd, TB_PRESSBUTTON, nID, MAKELPARAM(bPress, 0)); }
    BOOL HideButton(int nID, BOOL bHide = TRUE) { return (BOOL)::SendMessage(m_hWnd, TB_HIDEBUTTON, nID, MAKELPARAM(bHide, 0)); }
    BOOL Indeterminate(int nID, BOOL bIndeterminate = TRUE) { return (BOOL)::SendMessage(m_hWnd, TB_INDETERMINATE, nID, MAKELPARAM(bIndeterminate, 0)); }
    BOOL IsButtonEnabled(int nID) const { return (BOOL)::SendMessage(m_hWnd, TB_ISBUTTONENABLED, nID, 0); }
    BOOL IsButtonChecked(int nID) const { return (BOOL)::SendMessage(m_hWnd, TB_ISBUTTONCHECKED, nID, 0); }
    BOOL IsButtonPressed(int nID) const { return (BOOL)::SendMessage(m_hWnd, TB_ISBUTTONPRESSED, nID, 0); }
    BOOL IsButtonHidden(int nID) const { return (BOOL)::SendMessage(m_hWnd, TB_ISBUTTONHIDDEN, nID, 0); }
    BOOL IsButtonIndeterminate(int nID) const { return (BOOL)::SendMessage(m_hWnd, TB_ISBUTTONINDETERMINATE, nID, 0); }
    int SetState(int nID, UINT nState) { return (int)::SendMessage(m_hWnd, TB_SETSTATE, nID, MAKELPARAM(nState, 0)); }
    int GetState(int nID) const { return (int)::SendMessage(m_hWnd, TB_GETSTATE, nID, 0L); }
    BOOL GetButton(int nIndex, LPTBBUTTON lpButton) const { return (BOOL)::SendMessage(m_hWnd, TB_GETBUTTON, nIndex, (LPARAM)lpButton); }
    int GetButtonCount() const { return (int)::SendMessage(m_hWnd, TB_BUTTONCOUNT, 0, 0L); }
    BOOL GetItemRect(int nIndex, LPRECT lpRect) const { return (BOOL)::SendMessage(m_hWnd, TB_GETITEMRECT, nIndex, (LPARAM)lpRect); }
    BOOL GetRect(int nID, LPRECT lpRect) const {
        int idx = (int)::SendMessage(m_hWnd, TB_COMMANDTOINDEX, nID, 0L);
        if (idx >= 0) return GetItemRect(idx, lpRect);
        if (lpRect) *lpRect = RECT{0, 0, 0, 0};
        return FALSE;
    }
    void SetButtonStructSize(int nSize) { ::SendMessage(m_hWnd, TB_BUTTONSTRUCTSIZE, nSize, 0L); }
    DWORD GetButtonSize() const { return (DWORD)::SendMessage(m_hWnd, TB_GETBUTTONSIZE, 0, 0L); }
    BOOL SetButtonSize(CSize size) { return (BOOL)::SendMessage(m_hWnd, TB_SETBUTTONSIZE, 0, MAKELPARAM(size.cx, size.cy)); }
    BOOL SetBitmapSize(CSize size) { return (BOOL)::SendMessage(m_hWnd, TB_SETBITMAPSIZE, 0, MAKELPARAM(size.cx, size.cy)); }
    void AutoSize() { ::SendMessage(m_hWnd, TB_AUTOSIZE, 0, 0L); }
    CImageList* GetImageList() const;
    CImageList* SetImageList(CImageList* pImageList);
    CImageList* GetDisabledImageList() const;
    CImageList* SetDisabledImageList(CImageList* pImageList);
    BOOL AddButtons(int nNumButtons, LPTBBUTTON lpButtons) { return (BOOL)::SendMessage(m_hWnd, TB_ADDBUTTONS, nNumButtons, (LPARAM)lpButtons); }
    BOOL InsertButton(int nIndex, LPTBBUTTON lpButton) { return (BOOL)::SendMessage(m_hWnd, TB_INSERTBUTTON, nIndex, (LPARAM)lpButton); }
    BOOL DeleteButton(int nIndex) { return (BOOL)::SendMessage(m_hWnd, TB_DELETEBUTTON, nIndex, 0); }
    UINT CommandToIndex(UINT nID) const { return (UINT)::SendMessage(m_hWnd, TB_COMMANDTOINDEX, nID, 0L); }
    DWORD SetExtendedStyle(DWORD dwExStyle) { return (DWORD)::SendMessage(m_hWnd, TB_SETEXTENDEDSTYLE, 0, (LPARAM)dwExStyle); }
    DWORD GetExtendedStyle() const { return (DWORD)::SendMessage(m_hWnd, TB_GETEXTENDEDSTYLE, 0, 0L); }
    int SetBitmap(HBITMAP hbmImageWell) { (void)hbmImageWell; return 0; }
};

class CStatusBarCtrl : public CWnd {
    DECLARE_DYNAMIC(CStatusBarCtrl)
public:
    BOOL SetText(LPCTSTR lpszText, int nPane, int nType) { return (BOOL)::SendMessage(m_hWnd, SB_SETTEXT, (nPane | nType), (LPARAM)lpszText); }
    BOOL SetParts(int nParts, int* pWidths) { return (BOOL)::SendMessage(m_hWnd, SB_SETPARTS, nParts, (LPARAM)pWidths); }
    int GetParts(int nParts, int* pParts) const { return (int)::SendMessage(m_hWnd, SB_GETPARTS, nParts, (LPARAM)pParts); }
    BOOL GetRect(int nPane, LPRECT lpRect) const { return (BOOL)::SendMessage(m_hWnd, SB_GETRECT, nPane, (LPARAM)lpRect); }
    BOOL SetIcon(int nPane, HICON hIcon) { return (BOOL)::SendMessage(m_hWnd, SB_SETICON, nPane, (LPARAM)hIcon); }
};

class CToolTipCtrl : public CWnd {
    DECLARE_DYNAMIC(CToolTipCtrl)
public:
    BOOL Create(CWnd* pParentWnd, DWORD dwStyle = 0) {
        return CWnd::Create(TOOLTIPS_CLASS, nullptr, dwStyle, CRect(0, 0, 0, 0), pParentWnd, 0);
    }
    void Activate(BOOL bActivate) { ::SendMessage(m_hWnd, TTM_ACTIVATE, bActivate, 0L); }
    BOOL AddTool(CWnd* pWnd, UINT nIDText, LPCRECT lpRectTool = nullptr, UINT_PTR nIDTool = 0) {
        CString str; str.LoadString(nIDText);
        return AddTool(pWnd, str, lpRectTool, nIDTool);
    }
    BOOL AddTool(CWnd* pWnd, LPCTSTR lpszText = LPSTR_TEXTCALLBACK, LPCRECT lpRectTool = nullptr, UINT_PTR nIDTool = 0) {
        TOOLINFO ti{}; ti.cbSize = sizeof(ti);
        ti.hwnd = pWnd ? pWnd->GetSafeHwnd() : nullptr;
        ti.uId = nIDTool ? nIDTool : (UINT_PTR)ti.hwnd;
        ti.lpszText = const_cast<LPTSTR>(lpszText);
        if (lpRectTool) ti.rect = *lpRectTool;
        return (BOOL)::SendMessage(m_hWnd, TTM_ADDTOOL, 0, (LPARAM)&ti);
    }
    void DelTool(CWnd* pWnd, UINT_PTR nIDTool = 0) {
        TOOLINFO ti{}; ti.cbSize = sizeof(ti);
        ti.hwnd = pWnd ? pWnd->GetSafeHwnd() : nullptr;
        ti.uId = nIDTool ? nIDTool : (UINT_PTR)ti.hwnd;
        ::SendMessage(m_hWnd, TTM_DELTOOL, 0, (LPARAM)&ti);
    }
    void RelayEvent(LPMSG lpMsg) { ::SendMessage(m_hWnd, TTM_RELAYEVENT, 0, (LPARAM)lpMsg); }
    void SetDelayTime(UINT nDelay) { ::SendMessage(m_hWnd, TTM_SETDELAYTIME, TTDT_INITIAL, MAKELPARAM(nDelay, 0)); }
    void SetDelayTime(DWORD dwDuration, int iTime) { ::SendMessage(m_hWnd, TTM_SETDELAYTIME, dwDuration, MAKELPARAM(iTime, 0)); }
    int GetDelayTime(DWORD dwDuration) const { return (int)::SendMessage(m_hWnd, TTM_GETDELAYTIME, dwDuration, 0L); }
    int SetMaxTipWidth(int iWidth) { return (int)::SendMessage(m_hWnd, TTM_SETMAXTIPWIDTH, 0, iWidth); }
    void UpdateTipText(LPCTSTR lpszText, CWnd* pWnd, UINT_PTR nIDTool = 0) {
        TOOLINFO ti{}; ti.cbSize = sizeof(ti);
        ti.hwnd = pWnd ? pWnd->GetSafeHwnd() : nullptr;
        ti.uId = nIDTool ? nIDTool : (UINT_PTR)ti.hwnd;
        ti.lpszText = const_cast<LPTSTR>(lpszText);
        ::SendMessage(m_hWnd, TTM_UPDATETIPTEXT, 0, (LPARAM)&ti);
    }
    void Pop() { ::SendMessage(m_hWnd, TTM_POP, 0, 0L); }
    void Update() { ::SendMessage(m_hWnd, TTM_UPDATE, 0, 0L); }
    BOOL SetTitle(UINT uIcon, LPCTSTR lpstrTitle) { return (BOOL)::SendMessage(m_hWnd, TTM_SETTITLE, (WPARAM)uIcon, (LPARAM)lpstrTitle); }
};

class CHotKeyCtrl : public CWnd {
    DECLARE_DYNAMIC(CHotKeyCtrl)
public:
    CHotKeyCtrl() = default;
    ~CHotKeyCtrl() override = default;
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(_T("msctls_hotkey32"), nullptr, dwStyle, rect, pParentWnd, nID);
    }
    void SetHotKey(WORD wVirtualKeyCode, WORD wModifiers) { (void)wVirtualKeyCode; (void)wModifiers; }
    DWORD GetHotKey() const { return 0; }
    void GetHotKey(WORD &wVirtualKeyCode, WORD &wModifiers) const { wVirtualKeyCode = 0; wModifiers = 0; }
    void SetRules(WORD wInvalidComb, WORD wModifiers) { (void)wInvalidComb; (void)wModifiers; }

    static CString GetKeyName(UINT vk, BOOL fExtended) {
        UINT scanCode = (UINT)::MapVirtualKey(vk, MAPVK_VK_TO_VSC);
        LONG lParam = (LONG)(scanCode << 16);
        if (fExtended) lParam |= (1 << 24);
        TCHAR buf[128] = {0};
        if (::GetKeyNameText(lParam, buf, 128) > 0) {
            return CString(buf);
        }
        if (vk >= 'A' && vk <= 'Z') return CString((TCHAR)vk);
        if (vk >= '0' && vk <= '9') return CString((TCHAR)vk);
        if (vk >= VK_NUMPAD0 && vk <= VK_NUMPAD9) {
            CString s; s.Format(_T("Num %d"), (int)(vk - VK_NUMPAD0)); return s;
        }
        if (vk >= VK_F1 && vk <= VK_F24) {
            CString s; s.Format(_T("F%d"), (int)(vk - VK_F1 + 1)); return s;
        }
        switch (vk) {
            case VK_SPACE: return _T("Space");
            case VK_RETURN: return _T("Enter");
            case VK_ESCAPE: return _T("Esc");
            case VK_TAB: return _T("Tab");
            case VK_BACK: return _T("Backspace");
            case VK_INSERT: return _T("Insert");
            case VK_DELETE: return _T("Delete");
            case VK_HOME: return _T("Home");
            case VK_END: return _T("End");
            case VK_PRIOR: return _T("Page Up");
            case VK_NEXT: return _T("Page Down");
            case VK_LEFT: return _T("Left");
            case VK_UP: return _T("Up");
            case VK_RIGHT: return _T("Right");
            case VK_DOWN: return _T("Down");
            case VK_CONTROL: return _T("Ctrl");
            case VK_SHIFT: return _T("Shift");
            case VK_MENU: return _T("Alt");
            default: break;
        }
        CString s;
        s.Format(_T("0x%02X"), (unsigned int)vk);
        return s;
    }
};
