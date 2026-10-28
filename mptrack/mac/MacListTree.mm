/*
 * MacListTree.mm
 * --------------
 * Purpose: The tree view (SysTreeView32) and list view (SysListView32) common controls, drawn in
 *          the classic Windows 10 style, plus the in-client scroll bars they use (Windows draws
 *          scroll bars in the non-client area, which this port does not have).
 */

#import "MacControls.h"
#import <Carbon/Carbon.h>

#include <algorithm>
#include <map>
#include <cmath>
#include <functional>
#include <set>

#ifndef I_IMAGECALLBACK
#define I_IMAGECALLBACK (-1)
#endif
#ifndef I_CHILDRENCALLBACK
#define I_CHILDRENCALLBACK (-1)
#endif
#ifndef I_GROUPIDNONE
#define I_GROUPIDNONE (-2)
#endif
#ifndef TVC_UNKNOWN
#define TVC_UNKNOWN 0x0000
#define TVC_BYMOUSE 0x0001
#define TVC_BYKEYBOARD 0x0002
#endif

namespace {

// ---------------------------------------------------------------------------------------------
// Scroll bar drawn inside the client area
// ---------------------------------------------------------------------------------------------

constexpr int kScrollSize = 17;

struct ScrollBar
{
	int pos = 0;    // first visible unit
	int total = 0;  // content size in units
	int page = 0;   // visible size in units
	bool Needed() const { return total > page && page > 0; }
	int MaxPos() const { return std::max(0, total - page); }
	void Clamp() { pos = std::clamp(pos, 0, MaxPos()); }
};

struct ScrollDrag
{
	bool active = false;
	bool vertical = true;
	int grabOffset = 0;
};

// Track and thumb geometry along the bar; bar is the full scroll bar rectangle.
void ThumbExtent(const ScrollBar &sb, int barLength, int &thumbStart, int &thumbLength)
{
	const int track = std::max(0, barLength - 2 * kScrollSize);
	thumbLength = sb.total > 0 ? std::max(kScrollSize, track * sb.page / sb.total) : track;
	thumbLength = std::min(thumbLength, track);
	const int range = track - thumbLength;
	thumbStart = kScrollSize + (sb.MaxPos() > 0 ? range * sb.pos / sb.MaxPos() : 0);
}

void DrawArrow(HDC dc, int cx, int cy, int direction, COLORREF color)  // 0 up, 1 down, 2 left, 3 right
{
	for(int i = 0; i < 4; i++)
	{
		switch(direction)
		{
		case 0: FillSolid(dc, RECT{cx - i, cy - 2 + i, cx + i + 1, cy - 1 + i}, color); break;
		case 1: FillSolid(dc, RECT{cx - i, cy + 1 - i, cx + i + 1, cy + 2 - i}, color); break;
		case 2: FillSolid(dc, RECT{cx - 2 + i, cy - i, cx - 1 + i, cy + i + 1}, color); break;
		case 3: FillSolid(dc, RECT{cx + 1 - i, cy - i, cx + 2 - i, cy + i + 1}, color); break;
		}
	}
}

void DrawScrollBar(HDC dc, const RECT &bar, const ScrollBar &sb, bool vertical)
{
	FillSolid(dc, bar, RGB(240, 240, 240));
	const COLORREF arrow = sb.Needed() ? RGB(96, 96, 96) : RGB(191, 191, 191);
	const int length = vertical ? bar.bottom - bar.top : bar.right - bar.left;
	if(vertical)
	{
		DrawArrow(dc, (bar.left + bar.right) / 2, bar.top + kScrollSize / 2, 0, arrow);
		DrawArrow(dc, (bar.left + bar.right) / 2, bar.bottom - kScrollSize / 2, 1, arrow);
	} else
	{
		DrawArrow(dc, bar.left + kScrollSize / 2, (bar.top + bar.bottom) / 2, 2, arrow);
		DrawArrow(dc, bar.right - kScrollSize / 2, (bar.top + bar.bottom) / 2, 3, arrow);
	}
	if(!sb.Needed()) return;
	int start, thumb;
	ThumbExtent(sb, length, start, thumb);
	const RECT thumbRect = vertical ? RECT{bar.left + 2, bar.top + start, bar.right - 2, bar.top + start + thumb}
	                                : RECT{bar.left + start, bar.top + 2, bar.left + start + thumb, bar.bottom - 2};
	FillSolid(dc, thumbRect, RGB(205, 205, 205));
}

// Handles a click on a scroll bar; returns true if the scroll position changed.
bool ScrollBarClick(ScrollBar &sb, ScrollDrag &drag, const RECT &bar, POINT pt, bool vertical, int lineUnits)
{
	const int length = vertical ? bar.bottom - bar.top : bar.right - bar.left;
	const int at = vertical ? pt.y - bar.top : pt.x - bar.left;
	const int old = sb.pos;
	int start, thumb;
	ThumbExtent(sb, length, start, thumb);
	if(at < kScrollSize) sb.pos -= lineUnits;
	else if(at >= length - kScrollSize) sb.pos += lineUnits;
	else if(at < start) sb.pos -= sb.page;
	else if(at >= start + thumb) sb.pos += sb.page;
	else
	{
		drag.active = true;
		drag.vertical = vertical;
		drag.grabOffset = at - start;
	}
	sb.Clamp();
	return sb.pos != old;
}

bool ScrollBarDrag(ScrollBar &sb, const ScrollDrag &drag, const RECT &bar, POINT pt)
{
	const int length = drag.vertical ? bar.bottom - bar.top : bar.right - bar.left;
	const int at = drag.vertical ? pt.y - bar.top : pt.x - bar.left;
	int start, thumb;
	ThumbExtent(sb, length, start, thumb);
	const int range = std::max(1, length - 2 * kScrollSize - thumb);
	const int old = sb.pos;
	sb.pos = (at - drag.grabOffset - kScrollSize) * sb.MaxPos() / range;
	sb.Clamp();
	return sb.pos != old;
}

int WheelLines(WPARAM wParam)
{
	const int delta = -(short)HIWORD(wParam);
	const int lines = delta * 3 / WHEEL_DELTA;
	return (lines == 0 && delta != 0) ? (delta > 0 ? 1 : -1) : lines;  // small trackpad steps still move
}

int LineHeight(HDC dc)
{
	SIZE size{};
	GetTextExtentPoint32W(dc, L"Ag", 2, &size);
	return size.cy;
}

LRESULT SendNotify(HWND hWnd, NMHDR &hdr, UINT code)
{
	hdr.hwndFrom = hWnd;
	hdr.idFrom = (UINT_PTR)GetDlgCtrlID(hWnd);
	hdr.code = code;
	return SendMessageW(GetParent(hWnd), WM_NOTIFY, hdr.idFrom, (LPARAM)&hdr);
}

bool HasStyle(HWND hWnd, DWORD style)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec && (rec->style & style);
}

bool IsFocused(HWND hWnd) { return GetFocus() == hWnd; }

HFONT BoldVariant(HFONT font)
{
	static std::map<HFONT, HFONT> cache;
	HFONT &bold = cache[font];
	if(!bold)
	{
		LOGFONTW lf{};
		GetObjectW(font, sizeof(lf), &lf);
		lf.lfWeight = FW_BOLD;
		bold = CreateFontIndirectW(&lf);
	}
	return bold;
}

// Label editing shared by both controls: an EDIT child whose Enter / Escape / focus loss ends the edit.
struct LabelEdit
{
	HWND edit = nullptr;
	WNDPROC editProc = nullptr;
	std::function<void(bool cancel)> finish;
};

std::map<HWND, LabelEdit> g_labelEdits;  // keyed by the edit window

LRESULT CALLBACK LabelEditProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	auto it = g_labelEdits.find(hWnd);
	if(it == g_labelEdits.end()) return DefWindowProcW(hWnd, msg, wParam, lParam);
	WNDPROC original = it->second.editProc;
	auto finish = it->second.finish;
	if((msg == WM_KEYDOWN && (wParam == VK_RETURN || wParam == VK_ESCAPE)) || msg == WM_KILLFOCUS)
	{
		g_labelEdits.erase(it);
		if(finish) finish(msg == WM_KEYDOWN && wParam == VK_ESCAPE);
		return 0;
	}
	if(msg == WM_GETDLGCODE) return DLGC_WANTALLKEYS;
	return original(hWnd, msg, wParam, lParam);
}

HWND BeginLabelEdit(HWND owner, const RECT &rect, const std::wstring &text, std::function<void(bool cancel)> finish)
{
	HWND edit = CreateWindowExW(0, L"EDIT", text.c_str(), WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
		rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, owner, nullptr, nullptr, nullptr);
	if(!edit) return nullptr;
	SendMessageW(edit, WM_SETFONT, (WPARAM)ControlFont(owner), FALSE);
	LabelEdit &le = g_labelEdits[edit];
	le.edit = edit;
	le.editProc = (WNDPROC)GetWindowLongPtrW(edit, GWLP_WNDPROC);
	le.finish = std::move(finish);
	SetWindowLongPtrW(edit, GWLP_WNDPROC, (LONG_PTR)LabelEditProc);
	SetFocus(edit);
	SendMessageW(edit, EM_SETSEL, 0, -1);
	return edit;
}

std::wstring EditText(HWND edit)
{
	const int len = GetWindowTextLengthW(edit);
	std::wstring text(len + 1, L'\0');
	GetWindowTextW(edit, text.data(), len + 1);
	text.resize(len);
	return text;
}

// ---------------------------------------------------------------------------------------------
// Tree view
// ---------------------------------------------------------------------------------------------

struct TreeItem
{
	TreeItem *parent = nullptr;
	std::vector<TreeItem *> children;
	std::wstring text;
	bool textCallback = false;
	int image = 0, selectedImage = 0;
	UINT state = 0;
	LPARAM lParam = 0;
	int cChildren = 0;
};

struct TreeRow
{
	TreeItem *item;
	int depth;
};

struct TreeData
{
	TreeItem root;
	std::set<TreeItem *> live;
	TreeItem *caret = nullptr, *dropHilite = nullptr;
	HIMAGELIST images = nullptr, stateImages = nullptr;
	int indent = 19;
	ScrollBar vscroll, hscroll;
	ScrollDrag drag;
	COLORREF bk = CLR_NONE, text = CLR_NONE;
	POINT pressPoint{};
	TreeItem *pressItem = nullptr;
	bool dragStarted = false;
	HWND edit = nullptr;
	TreeItem *editItem = nullptr;
};

std::map<HWND, TreeData> g_trees;

TreeItem *ToItem(TreeData &td, HTREEITEM h)
{
	if(h == TVI_ROOT || !h) return nullptr;
	TreeItem *item = reinterpret_cast<TreeItem *>(h);
	return td.live.count(item) ? item : nullptr;
}

HTREEITEM ToHandle(TreeItem *item) { return reinterpret_cast<HTREEITEM>(item); }

bool HasChildren(HWND hWnd, TreeItem *item)
{
	if(item->cChildren == I_CHILDRENCALLBACK)
	{
		NMTVDISPINFOW di{};
		di.item.mask = TVIF_CHILDREN;
		di.item.hItem = ToHandle(item);
		di.item.lParam = item->lParam;
		SendNotify(hWnd, di.hdr, TVN_GETDISPINFOW);
		return di.item.cChildren != 0;
	}
	return !item->children.empty() || item->cChildren > 0;
}

std::wstring ItemText(HWND hWnd, TreeItem *item)
{
	if(!item->textCallback) return item->text;
	wchar_t buffer[512] = {};
	NMTVDISPINFOW di{};
	di.item.mask = TVIF_TEXT;
	di.item.hItem = ToHandle(item);
	di.item.lParam = item->lParam;
	di.item.pszText = buffer;
	di.item.cchTextMax = 512;
	SendNotify(hWnd, di.hdr, TVN_GETDISPINFOW);
	return di.item.pszText ? std::wstring(di.item.pszText) : std::wstring();
}

void CollectRows(TreeItem *parent, int depth, std::vector<TreeRow> &rows)
{
	for(TreeItem *child : parent->children)
	{
		rows.push_back({child, depth});
		if(child->state & TVIS_EXPANDED) CollectRows(child, depth + 1, rows);
	}
}

std::vector<TreeRow> VisibleRows(TreeData &td)
{
	std::vector<TreeRow> rows;
	CollectRows(&td.root, 0, rows);
	return rows;
}

int TreeItemHeight(HWND hWnd, TreeData &td)
{
	HDC dc = GetDC(hWnd);
	SelectObject(dc, ControlFont(hWnd));
	const int text = LineHeight(dc);
	ReleaseDC(hWnd, dc);
	int cx = 0, cy = 0;
	if(td.images) ImageList_GetIconSize(td.images, &cx, &cy);
	return std::max(text + 3, cy + 2);
}

// Layout of the client area: rows on the left/top, scroll bars at the right/bottom when needed.
void TreeLayout(HWND hWnd, TreeData &td, RECT &rowsArea, RECT &vbar, int &itemHeight, std::vector<TreeRow> &rows)
{
	GetClientRect(hWnd, &rowsArea);
	const bool border = HasStyle(hWnd, WS_BORDER);
	if(border) InflateRect(&rowsArea, -1, -1);
	itemHeight = TreeItemHeight(hWnd, td);
	rows = VisibleRows(td);
	td.vscroll.total = (int)rows.size();
	td.vscroll.page = std::max(1, (int)(rowsArea.bottom - rowsArea.top) / itemHeight);
	vbar = RECT{0, 0, 0, 0};
	if(td.vscroll.Needed())
	{
		vbar = RECT{rowsArea.right - kScrollSize, rowsArea.top, rowsArea.right, rowsArea.bottom};
		rowsArea.right -= kScrollSize;
	}
	td.vscroll.Clamp();
}

int ItemBaseX(HWND hWnd, TreeData &td, int depth, const RECT &rowsArea)
{
	const bool rootLines = HasStyle(hWnd, TVS_LINESATROOT) || HasStyle(hWnd, TVS_HASBUTTONS);
	return rowsArea.left + (depth + (rootLines ? 1 : 0)) * td.indent;
}

void DrawDottedV(HDC dc, int x, int y1, int y2, COLORREF color)
{
	for(int y = y1 + ((y1 & 1) ? 1 : 0); y < y2; y += 2) FillSolid(dc, RECT{x, y, x + 1, y + 1}, color);
}

void DrawDottedH(HDC dc, int x1, int x2, int y, COLORREF color)
{
	for(int x = x1 + ((x1 & 1) ? 1 : 0); x < x2; x += 2) FillSolid(dc, RECT{x, y, x + 1, y + 1}, color);
}

void PaintTree(HWND hWnd, TreeData &td)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client, rowsArea, vbar;
	GetClientRect(hWnd, &client);
	int itemHeight;
	std::vector<TreeRow> rows;
	TreeLayout(hWnd, td, rowsArea, vbar, itemHeight, rows);
	const COLORREF bk = td.bk != CLR_NONE ? td.bk : GetSysColor(COLOR_WINDOW);
	FillSolid(dc, client, bk);
	SetBkMode(dc, TRANSPARENT);
	HFONT font = ControlFont(hWnd);
	const bool lines = HasStyle(hWnd, TVS_HASLINES), buttons = HasStyle(hWnd, TVS_HASBUTTONS);
	const bool rootLines = HasStyle(hWnd, TVS_LINESATROOT) || buttons;
	const bool focused = IsFocused(hWnd) || (td.edit && IsFocused(td.edit));
	const bool showSelAlways = HasStyle(hWnd, TVS_SHOWSELALWAYS);
	const COLORREF lineColor = RGB(160, 160, 160);
	int imageW = 0, imageH = 0;
	if(td.images) ImageList_GetIconSize(td.images, &imageW, &imageH);
	CGContextRef ctx = dc->cgContext;
	if(ctx)
	{
		CGContextSaveGState(ctx);
		CGContextClipToRect(ctx, CGRectMake(rowsArea.left + dc->viewportOrg.x, rowsArea.top + dc->viewportOrg.y, rowsArea.right - rowsArea.left, rowsArea.bottom - rowsArea.top));
	}
	for(int r = td.vscroll.pos; r < (int)rows.size(); r++)
	{
		const int y = rowsArea.top + (r - td.vscroll.pos) * itemHeight;
		if(y >= rowsArea.bottom) break;
		TreeItem *item = rows[r].item;
		const int depth = rows[r].depth;
		const int base = ItemBaseX(hWnd, td, depth, rowsArea);
		const int midY = y + itemHeight / 2;
		if(lines && (depth > 0 || rootLines))
		{
			// Connector from the parent's vertical line to this item, and that line down to the next sibling.
			const int lineX = base - td.indent / 2;
			DrawDottedH(dc, lineX, base, midY, lineColor);
			const auto &siblings = item->parent->children;
			const bool last = siblings.back() == item;
			const bool first = siblings.front() == item && item->parent == &td.root;
			DrawDottedV(dc, lineX, first ? midY : y, last ? midY + 1 : y + itemHeight, lineColor);
			// Ancestors that have further siblings below keep their vertical lines going through this row.
			int ancestorX = lineX;
			for(TreeItem *a = item->parent; a && a != &td.root; a = a->parent)
			{
				ancestorX -= td.indent;
				if(a->parent->children.back() != a) DrawDottedV(dc, ancestorX, y, y + itemHeight, lineColor);
			}
		}
		if(buttons && HasChildren(hWnd, item) && (depth > 0 || rootLines))
		{
			const int bx = base - td.indent / 2;
			const RECT box{bx - 4, midY - 4, bx + 5, midY + 5};
			FillSolid(dc, box, RGB(255, 255, 255));
			Outline(dc, box, RGB(145, 145, 145));
			FillSolid(dc, RECT{bx - 2, midY, bx + 3, midY + 1}, RGB(0, 0, 0));
			if(!(item->state & TVIS_EXPANDED)) FillSolid(dc, RECT{bx, midY - 2, bx + 1, midY + 3}, RGB(0, 0, 0));
		}
		int x = base;
		if(td.images)
		{
			const bool selected = item == td.caret;
			int image = selected ? item->selectedImage : item->image;
			if(image == I_IMAGECALLBACK)
			{
				NMTVDISPINFOW di{};
				di.item.mask = selected ? TVIF_SELECTEDIMAGE : TVIF_IMAGE;
				di.item.hItem = ToHandle(item);
				di.item.lParam = item->lParam;
				SendNotify(hWnd, di.hdr, TVN_GETDISPINFOW);
				image = selected ? di.item.iSelectedImage : di.item.iImage;
			}
			ImageList_Draw(td.images, image, dc, x, y + (itemHeight - imageH) / 2, (item->state & TVIS_CUT) ? ILD_BLEND50 : ILD_NORMAL);
			x += imageW + 3;
		}
		SelectObject(dc, (item->state & TVIS_BOLD) ? BoldVariant(font) : font);
		const std::wstring text = ItemText(hWnd, item);
		SIZE textSize{};
		GetTextExtentPoint32W(dc, text.c_str(), (int)text.size(), &textSize);
		const RECT labelRect{x, y, x + textSize.cx + 4, y + itemHeight};
		const bool highlighted = (item == td.caret && (focused || showSelAlways)) || item == td.dropHilite || (item->state & TVIS_DROPHILITED);
		if(highlighted)
		{
			const bool active = focused || item == td.dropHilite;
			FillSolid(dc, labelRect, active ? GetSysColor(COLOR_HIGHLIGHT) : GetSysColor(COLOR_BTNFACE));
			SetTextColor(dc, active ? GetSysColor(COLOR_HIGHLIGHTTEXT) : GetSysColor(COLOR_WINDOWTEXT));
		} else
		{
			SetTextColor(dc, td.text != CLR_NONE ? td.text : GetSysColor(COLOR_WINDOWTEXT));
		}
		TextOutW(dc, x + 2, y + (itemHeight - textSize.cy) / 2, text.c_str(), (int)text.size());
	}
	if(ctx) CGContextRestoreGState(ctx);
	if(td.vscroll.Needed()) DrawScrollBar(dc, vbar, td.vscroll, true);
	if(HasStyle(hWnd, WS_BORDER)) Outline(dc, client, RGB(130, 135, 144));
	EndPaint(hWnd, &ps);
}

// Fills a TVITEMW from an item, honouring the mask.
void FillTvItem(TreeItem *item, TVITEMW &tvi)
{
	tvi.hItem = ToHandle(item);
	if(tvi.mask & TVIF_TEXT)
	{
		if(item->textCallback) tvi.pszText = LPSTR_TEXTCALLBACKW;
		else if(tvi.pszText && tvi.cchTextMax > 0)
		{
			const size_t n = std::min<size_t>(item->text.size(), tvi.cchTextMax - 1);
			std::copy_n(item->text.data(), n, tvi.pszText);
			tvi.pszText[n] = 0;
		}
	}
	if(tvi.mask & TVIF_IMAGE) tvi.iImage = item->image;
	if(tvi.mask & TVIF_SELECTEDIMAGE) tvi.iSelectedImage = item->selectedImage;
	if(tvi.mask & TVIF_STATE) tvi.state = item->state & (tvi.stateMask ? tvi.stateMask : ~0u);
	if(tvi.mask & TVIF_PARAM) tvi.lParam = item->lParam;
	if(tvi.mask & TVIF_CHILDREN) tvi.cChildren = item->cChildren == I_CHILDRENCALLBACK ? I_CHILDRENCALLBACK : (item->children.empty() ? item->cChildren : 1);
}

void ApplyTvItem(TreeItem *item, const TVITEMW &tvi)
{
	if(tvi.mask & TVIF_TEXT)
	{
		item->textCallback = tvi.pszText == LPSTR_TEXTCALLBACKW;
		item->text = (!item->textCallback && tvi.pszText) ? tvi.pszText : L"";
	}
	if(tvi.mask & TVIF_IMAGE) item->image = tvi.iImage;
	if(tvi.mask & TVIF_SELECTEDIMAGE) item->selectedImage = tvi.iSelectedImage;
	if(tvi.mask & TVIF_STATE) item->state = (item->state & ~tvi.stateMask) | (tvi.state & tvi.stateMask);
	if(tvi.mask & TVIF_PARAM) item->lParam = tvi.lParam;
	if(tvi.mask & TVIF_CHILDREN) item->cChildren = tvi.cChildren;
}

void NotifyTree(HWND hWnd, UINT code, UINT action, TreeItem *oldItem, TreeItem *newItem, LRESULT *result = nullptr)
{
	NMTREEVIEWW nm{};
	nm.action = action;
	if(oldItem)
	{
		nm.itemOld.mask = TVIF_HANDLE | TVIF_PARAM | TVIF_STATE;
		nm.itemOld.hItem = ToHandle(oldItem);
		nm.itemOld.lParam = oldItem->lParam;
		nm.itemOld.state = oldItem->state;
	}
	if(newItem)
	{
		nm.itemNew.mask = TVIF_HANDLE | TVIF_PARAM | TVIF_STATE;
		nm.itemNew.hItem = ToHandle(newItem);
		nm.itemNew.lParam = newItem->lParam;
		nm.itemNew.state = newItem->state;
	}
	GetCursorPos(&nm.ptDrag);
	ScreenToClient(hWnd, &nm.ptDrag);
	const LRESULT r = SendNotify(hWnd, nm.hdr, code);
	if(result) *result = r;
}

void DeleteTreeItem(HWND hWnd, TreeData &td, TreeItem *item)
{
	while(!item->children.empty()) DeleteTreeItem(hWnd, td, item->children.back());
	NotifyTree(hWnd, TVN_DELETEITEMW, 0, item, nullptr);
	if(item->parent) std::erase(item->parent->children, item);
	if(td.caret == item) td.caret = nullptr;
	if(td.dropHilite == item) td.dropHilite = nullptr;
	td.live.erase(item);
	delete item;
}

bool ExpandItem(HWND hWnd, TreeData &td, TreeItem *item, UINT code)
{
	if(!item) return false;
	const bool expanded = item->state & TVIS_EXPANDED;
	bool expand = expanded;
	switch(code & 3)
	{
	case TVE_EXPAND: expand = true; break;
	case TVE_COLLAPSE: expand = false; break;
	case TVE_TOGGLE: expand = !expanded; break;
	}
	if(expand == expanded) return true;
	LRESULT cancel = 0;
	NotifyTree(hWnd, TVN_ITEMEXPANDINGW, expand ? TVE_EXPAND : TVE_COLLAPSE, nullptr, item, &cancel);
	if(cancel) return false;
	item->state = expand ? (item->state | TVIS_EXPANDED | TVIS_EXPANDEDONCE) : (item->state & ~TVIS_EXPANDED);
	if(!expand && (code & TVE_COLLAPSERESET))
		while(!item->children.empty()) DeleteTreeItem(hWnd, td, item->children.back());
	// Collapsing hides descendants; the caret moves up to the collapsed item, as on Windows.
	for(TreeItem *c = td.caret; !expand && c; c = c->parent)
		if(c->parent == item) { td.caret = item; break; }
	NotifyTree(hWnd, TVN_ITEMEXPANDEDW, expand ? TVE_EXPAND : TVE_COLLAPSE, nullptr, item);
	InvalidateRect(hWnd, nullptr, FALSE);
	return true;
}

void EnsureTreeVisible(HWND hWnd, TreeData &td, TreeItem *item)
{
	for(TreeItem *p = item ? item->parent : nullptr; p && p != &td.root; p = p->parent)
		if(!(p->state & TVIS_EXPANDED)) ExpandItem(hWnd, td, p, TVE_EXPAND);
	RECT rowsArea, vbar;
	int itemHeight;
	std::vector<TreeRow> rows;
	TreeLayout(hWnd, td, rowsArea, vbar, itemHeight, rows);
	for(int r = 0; r < (int)rows.size(); r++)
	{
		if(rows[r].item != item) continue;
		if(r < td.vscroll.pos) td.vscroll.pos = r;
		else if(r >= td.vscroll.pos + td.vscroll.page) td.vscroll.pos = r - td.vscroll.page + 1;
		td.vscroll.Clamp();
		break;
	}
}

bool SelectTreeItem(HWND hWnd, TreeData &td, TreeItem *item, UINT action)
{
	if(item == td.caret) return true;
	LRESULT cancel = 0;
	NotifyTree(hWnd, TVN_SELCHANGINGW, action, td.caret, item, &cancel);
	if(cancel) return false;
	TreeItem *old = td.caret;
	if(old) old->state &= ~TVIS_SELECTED;
	td.caret = item;
	if(item) item->state |= TVIS_SELECTED;
	if(item) EnsureTreeVisible(hWnd, td, item);
	NotifyTree(hWnd, TVN_SELCHANGEDW, action, old, item);
	if(item && HasStyle(hWnd, TVS_SINGLEEXPAND) && action == TVC_BYMOUSE) ExpandItem(hWnd, td, item, TVE_TOGGLE);
	InvalidateRect(hWnd, nullptr, FALSE);
	return true;
}

RECT TreeItemRect(HWND hWnd, TreeData &td, TreeItem *item, bool textOnly, bool &found)
{
	RECT rowsArea, vbar;
	int itemHeight;
	std::vector<TreeRow> rows;
	TreeLayout(hWnd, td, rowsArea, vbar, itemHeight, rows);
	found = false;
	for(int r = 0; r < (int)rows.size(); r++)
	{
		if(rows[r].item != item) continue;
		found = true;
		const int y = rowsArea.top + (r - td.vscroll.pos) * itemHeight;
		if(!textOnly) return RECT{rowsArea.left, y, rowsArea.right, y + itemHeight};
		int x = ItemBaseX(hWnd, td, rows[r].depth, rowsArea);
		int imageW = 0, imageH = 0;
		if(td.images && ImageList_GetIconSize(td.images, &imageW, &imageH)) x += imageW + 3;
		HDC dc = GetDC(hWnd);
		SelectObject(dc, (item->state & TVIS_BOLD) ? BoldVariant(ControlFont(hWnd)) : ControlFont(hWnd));
		const std::wstring text = ItemText(hWnd, item);
		SIZE size{};
		GetTextExtentPoint32W(dc, text.c_str(), (int)text.size(), &size);
		ReleaseDC(hWnd, dc);
		return RECT{x, y, x + size.cx + 4, y + itemHeight};
	}
	return RECT{0, 0, 0, 0};
}

TreeItem *TreeHitTest(HWND hWnd, TreeData &td, POINT pt, UINT &flags)
{
	RECT rowsArea, vbar;
	int itemHeight;
	std::vector<TreeRow> rows;
	TreeLayout(hWnd, td, rowsArea, vbar, itemHeight, rows);
	flags = TVHT_NOWHERE;
	if(!PtInRect(&rowsArea, pt)) return nullptr;
	const int r = td.vscroll.pos + (pt.y - rowsArea.top) / itemHeight;
	if(r < 0 || r >= (int)rows.size()) return nullptr;
	TreeItem *item = rows[r].item;
	const int base = ItemBaseX(hWnd, td, rows[r].depth, rowsArea);
	int imageW = 0, imageH = 0;
	if(td.images) ImageList_GetIconSize(td.images, &imageW, &imageH);
	bool found = false;
	const RECT label = TreeItemRect(hWnd, td, item, true, found);
	if(pt.x < base - td.indent) flags = TVHT_ONITEMINDENT;
	else if(pt.x < base) flags = HasStyle(hWnd, TVS_HASBUTTONS) && HasChildren(hWnd, item) ? TVHT_ONITEMBUTTON : TVHT_ONITEMINDENT;
	else if(pt.x < base + imageW) flags = TVHT_ONITEMICON;
	else if(pt.x < label.right) flags = TVHT_ONITEMLABEL;
	else flags = TVHT_ONITEMRIGHT;
	return item;
}

void BeginTreeLabelEdit(HWND hWnd, TreeData &td, TreeItem *item)
{
	if(!item || td.edit) return;
	NMTVDISPINFOW di{};
	di.item.mask = TVIF_HANDLE | TVIF_PARAM | TVIF_TEXT;
	di.item.hItem = ToHandle(item);
	di.item.lParam = item->lParam;
	std::wstring text = ItemText(hWnd, item);
	di.item.pszText = text.data();
	if(SendNotify(hWnd, di.hdr, TVN_BEGINLABELEDITW)) return;
	EnsureTreeVisible(hWnd, td, item);
	bool found = false;
	RECT r = TreeItemRect(hWnd, td, item, true, found);
	r.right = std::max<LONG>(r.right + 40, r.left + 80);
	td.editItem = item;
	td.edit = BeginLabelEdit(hWnd, r, text, [hWnd](bool cancel) {
		auto it = g_trees.find(hWnd);
		if(it == g_trees.end()) return;
		TreeData &t = it->second;
		HWND edit = t.edit;
		TreeItem *editItem = t.editItem;
		t.edit = nullptr;
		t.editItem = nullptr;
		std::wstring newText = EditText(edit);
		NMTVDISPINFOW end{};
		end.item.mask = TVIF_HANDLE | TVIF_PARAM | TVIF_TEXT;
		end.item.hItem = ToHandle(editItem);
		end.item.lParam = editItem && t.live.count(editItem) ? editItem->lParam : 0;
		end.item.pszText = cancel ? nullptr : newText.data();
		if(SendNotify(hWnd, end.hdr, TVN_ENDLABELEDITW) && !cancel && editItem && t.live.count(editItem))
		{
			editItem->text = newText;
			editItem->textCallback = false;
		}
		DestroyWindow(edit);
		SetFocus(hWnd);
		InvalidateRect(hWnd, nullptr, FALSE);
	});
}

LRESULT CALLBACK TreeProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	TreeData &td = g_trees[hWnd];
	switch(msg)
	{
	case WM_NCDESTROY:
		while(!td.root.children.empty()) DeleteTreeItem(hWnd, td, td.root.children.back());
		g_trees.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintTree(hWnd, td);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS | DLGC_WANTCHARS;
	case WM_SETFOCUS:
	case WM_KILLFOCUS:
		InvalidateRect(hWnd, nullptr, FALSE);
		{
			NMHDR hdr{};
			SendNotify(hWnd, hdr, msg == WM_SETFOCUS ? NM_SETFOCUS : NM_KILLFOCUS);
		}
		return 0;
	case WM_SIZE:
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;

	case TVM_INSERTITEMW:
	case TVM_INSERTITEMA:
	{
		const auto *tis = (const TVINSERTSTRUCTW *)lParam;
		if(!tis) return 0;
		TreeItem *parent = ToItem(td, tis->hParent);
		if(!parent) parent = &td.root;
		auto *item = new TreeItem();
		item->parent = parent;
		ApplyTvItem(item, tis->item);
		if((tis->item.mask & TVIF_TEXT) && msg == TVM_INSERTITEMA && tis->item.pszText && tis->item.pszText != LPSTR_TEXTCALLBACKW)
		{
			const char *a = (const char *)tis->item.pszText;
			item->text.assign(a, a + strlen(a));
		}
		auto &siblings = parent->children;
		auto pos = siblings.end();
		if(tis->hInsertAfter == TVI_FIRST) pos = siblings.begin();
		else if(tis->hInsertAfter == TVI_SORT)
			pos = std::find_if(siblings.begin(), siblings.end(), [&](TreeItem *s) { return lstrcmpiW(s->text.c_str(), item->text.c_str()) > 0; });
		else if(TreeItem *after = ToItem(td, tis->hInsertAfter))
		{
			auto it = std::find(siblings.begin(), siblings.end(), after);
			if(it != siblings.end()) pos = it + 1;
		}
		siblings.insert(pos, item);
		td.live.insert(item);
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)ToHandle(item);
	}
	case TVM_DELETEITEM:
	{
		if((HTREEITEM)lParam == TVI_ROOT || !lParam)
		{
			while(!td.root.children.empty()) DeleteTreeItem(hWnd, td, td.root.children.back());
			td.vscroll.pos = 0;
		} else if(TreeItem *item = ToItem(td, (HTREEITEM)lParam))
		{
			DeleteTreeItem(hWnd, td, item);
		} else return FALSE;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case TVM_GETNEXTITEM:
	{
		TreeItem *item = ToItem(td, (HTREEITEM)lParam);
		switch(wParam)
		{
		case TVGN_ROOT: return td.root.children.empty() ? 0 : (LRESULT)ToHandle(td.root.children.front());
		case TVGN_CARET: return (LRESULT)ToHandle(td.caret);
		case TVGN_DROPHILITE: return (LRESULT)ToHandle(td.dropHilite);
		case TVGN_CHILD:
		{
			TreeItem *parent = item ? item : &td.root;
			return parent->children.empty() ? 0 : (LRESULT)ToHandle(parent->children.front());
		}
		case TVGN_PARENT: return (item && item->parent != &td.root) ? (LRESULT)ToHandle(item->parent) : 0;
		case TVGN_NEXT:
		case TVGN_PREVIOUS:
		{
			if(!item) return 0;
			auto &siblings = item->parent->children;
			auto it = std::find(siblings.begin(), siblings.end(), item);
			if(wParam == TVGN_NEXT) return (it + 1 != siblings.end()) ? (LRESULT)ToHandle(*(it + 1)) : 0;
			return (it != siblings.begin()) ? (LRESULT)ToHandle(*(it - 1)) : 0;
		}
		case TVGN_FIRSTVISIBLE:
		case TVGN_NEXTVISIBLE:
		case TVGN_PREVIOUSVISIBLE:
		case TVGN_LASTVISIBLE:
		{
			const auto rows = VisibleRows(td);
			if(rows.empty()) return 0;
			if(wParam == TVGN_FIRSTVISIBLE) return (LRESULT)ToHandle(rows[std::min<size_t>(td.vscroll.pos, rows.size() - 1)].item);
			if(wParam == TVGN_LASTVISIBLE) return (LRESULT)ToHandle(rows.back().item);
			auto it = std::find_if(rows.begin(), rows.end(), [&](const TreeRow &r) { return r.item == item; });
			if(it == rows.end()) return 0;
			if(wParam == TVGN_NEXTVISIBLE) return (it + 1 != rows.end()) ? (LRESULT)ToHandle((it + 1)->item) : 0;
			return (it != rows.begin()) ? (LRESULT)ToHandle((it - 1)->item) : 0;
		}
		default: return 0;
		}
	}
	case TVM_GETITEMW:
	case TVM_GETITEMA:
	{
		auto *tvi = (TVITEMW *)lParam;
		TreeItem *item = tvi ? ToItem(td, tvi->hItem) : nullptr;
		if(!item) return FALSE;
		FillTvItem(item, *tvi);
		return TRUE;
	}
	case TVM_SETITEMW:
	case TVM_SETITEMA:
	{
		const auto *tvi = (const TVITEMW *)lParam;
		TreeItem *item = tvi ? ToItem(td, tvi->hItem) : nullptr;
		if(!item) return FALSE;
		ApplyTvItem(item, *tvi);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case TVM_GETITEMSTATE:
	{
		TreeItem *item = ToItem(td, (HTREEITEM)wParam);
		return item ? (item->state & (UINT)lParam) : 0;
	}
	case TVM_EXPAND:
		return ExpandItem(hWnd, td, ToItem(td, (HTREEITEM)lParam), (UINT)wParam);
	case TVM_SELECTITEM:
	{
		TreeItem *item = ToItem(td, (HTREEITEM)lParam);
		switch(wParam & 0xFF)
		{
		case TVGN_CARET: return SelectTreeItem(hWnd, td, item, TVC_UNKNOWN);
		case TVGN_DROPHILITE: td.dropHilite = item; InvalidateRect(hWnd, nullptr, FALSE); return TRUE;
		case TVGN_FIRSTVISIBLE:
		{
			const auto rows = VisibleRows(td);
			for(int r = 0; r < (int)rows.size(); r++)
				if(rows[r].item == item) { td.vscroll.pos = r; td.vscroll.Clamp(); }
			InvalidateRect(hWnd, nullptr, FALSE);
			return TRUE;
		}
		default: return FALSE;
		}
	}
	case TVM_ENSUREVISIBLE:
		EnsureTreeVisible(hWnd, td, ToItem(td, (HTREEITEM)lParam));
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case TVM_GETITEMRECT:
	{
		auto *rect = (RECT *)lParam;
		if(!rect) return FALSE;
		TreeItem *item = ToItem(td, *(HTREEITEM *)rect);
		if(!item) return FALSE;
		bool found = false;
		*rect = TreeItemRect(hWnd, td, item, wParam != 0, found);
		return found;
	}
	case TVM_HITTEST:
	{
		auto *hti = (TVHITTESTINFO *)lParam;
		if(!hti) return 0;
		hti->hItem = ToHandle(TreeHitTest(hWnd, td, hti->pt, hti->flags));
		return (LRESULT)hti->hItem;
	}
	case TVM_GETCOUNT:
		return (LRESULT)td.live.size();
	case TVM_GETVISIBLECOUNT:
		return td.vscroll.page;
	case TVM_SETIMAGELIST:
	{
		HIMAGELIST &slot = wParam == TVSIL_STATE ? td.stateImages : td.images;
		HIMAGELIST old = slot;
		slot = (HIMAGELIST)lParam;
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)old;
	}
	case TVM_GETIMAGELIST:
		return (LRESULT)(wParam == TVSIL_STATE ? td.stateImages : td.images);
	case TVM_SETINDENT:
		td.indent = std::max<int>(5, (int)wParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case TVM_GETINDENT:
		return td.indent;
	case TVM_SETBKCOLOR: { const COLORREF old = td.bk; td.bk = (COLORREF)lParam; InvalidateRect(hWnd, nullptr, FALSE); return old == CLR_NONE ? (LRESULT)-1 : old; }
	case TVM_SETTEXTCOLOR: { const COLORREF old = td.text; td.text = (COLORREF)lParam; InvalidateRect(hWnd, nullptr, FALSE); return old == CLR_NONE ? (LRESULT)-1 : old; }
	case TVM_GETBKCOLOR: return td.bk == CLR_NONE ? (LRESULT)-1 : td.bk;
	case TVM_GETTEXTCOLOR: return td.text == CLR_NONE ? (LRESULT)-1 : td.text;
	case TVM_SORTCHILDREN:
	case TVM_SORTCHILDRENCB:
	{
		TreeItem *parent;
		PFNTVCOMPARE compare = nullptr;
		LPARAM sortParam = 0;
		if(msg == TVM_SORTCHILDRENCB)
		{
			const auto *cb = (const TVSORTCB *)lParam;
			parent = ToItem(td, cb->hParent);
			compare = cb->lpfnCompare;
			sortParam = cb->lParam;
		} else parent = ToItem(td, (HTREEITEM)lParam);
		if(!parent) parent = &td.root;
		std::stable_sort(parent->children.begin(), parent->children.end(), [&](TreeItem *a, TreeItem *b) {
			if(compare) return compare(a->lParam, b->lParam, sortParam) < 0;
			return lstrcmpiW(a->text.c_str(), b->text.c_str()) < 0;
		});
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case TVM_EDITLABELW:
	case TVM_EDITLABELA:
		BeginTreeLabelEdit(hWnd, td, ToItem(td, (HTREEITEM)lParam));
		return (LRESULT)td.edit;
	case TVM_GETEDITCONTROL:
		return (LRESULT)td.edit;
	case TVM_ENDEDITLABELNOW:
		if(td.edit) SendMessageW(td.edit, WM_KEYDOWN, wParam ? VK_ESCAPE : VK_RETURN, 0);
		return TRUE;
	case TVM_SETINSERTMARK:
	case TVM_SETEXTENDEDSTYLE:
	case TVM_SETTOOLTIPS:
	case TVM_SETSCROLLTIME:
		return 0;

	case WM_MOUSEWHEEL:
		td.vscroll.pos += WheelLines(wParam);
		td.vscroll.Clamp();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONDOWN:
	case WM_RBUTTONDOWN:
	{
		SetFocus(hWnd);
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		RECT rowsArea, vbar;
		int itemHeight;
		std::vector<TreeRow> rows;
		TreeLayout(hWnd, td, rowsArea, vbar, itemHeight, rows);
		if(td.vscroll.Needed() && PtInRect(&vbar, pt))
		{
			if(msg == WM_LBUTTONDOWN && ScrollBarClick(td.vscroll, td.drag, vbar, pt, true, 1)) InvalidateRect(hWnd, nullptr, FALSE);
			if(td.drag.active) SetCapture(hWnd);
			return 0;
		}
		UINT flags = 0;
		TreeItem *item = TreeHitTest(hWnd, td, pt, flags);
		if(msg == WM_RBUTTONDOWN)
		{
			NMHDR hdr{};
			// Like Windows: right-click highlights the item while NM_RCLICK is handled.
			TreeItem *oldDrop = td.dropHilite;
			td.dropHilite = item;
			InvalidateRect(hWnd, nullptr, FALSE);
			if(!SendNotify(hWnd, hdr, NM_RCLICK))
			{
				POINT screen = pt;
				ClientToScreen(hWnd, &screen);
				SendMessageW(hWnd, WM_CONTEXTMENU, (WPARAM)hWnd, MAKELPARAM(screen.x, screen.y));
			}
			if(g_trees.count(hWnd)) { g_trees[hWnd].dropHilite = oldDrop; InvalidateRect(hWnd, nullptr, FALSE); }
			return 0;
		}
		if(item && flags == TVHT_ONITEMBUTTON)
		{
			ExpandItem(hWnd, td, item, TVE_TOGGLE);
			return 0;
		}
		if(item)
		{
			const bool wasSelected = item == td.caret;
			SelectTreeItem(hWnd, td, item, TVC_BYMOUSE);
			td.pressItem = item;
			td.pressPoint = pt;
			td.dragStarted = false;
			SetCapture(hWnd);
			(void)wasSelected;
		}
		NMHDR hdr{};
		SendNotify(hWnd, hdr, NM_CLICK);
		return 0;
	}
	case WM_MOUSEMOVE:
	{
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		if(td.drag.active)
		{
			RECT rowsArea, vbar;
			int itemHeight;
			std::vector<TreeRow> rows;
			TreeLayout(hWnd, td, rowsArea, vbar, itemHeight, rows);
			if(ScrollBarDrag(td.vscroll, td.drag, vbar, pt)) InvalidateRect(hWnd, nullptr, FALSE);
			return 0;
		}
		if(td.pressItem && !td.dragStarted && (wParam & MK_LBUTTON) && (std::abs(pt.x - td.pressPoint.x) > 4 || std::abs(pt.y - td.pressPoint.y) > 4))
		{
			td.dragStarted = true;
			ReleaseCapture();
			if(!HasStyle(hWnd, TVS_DISABLEDRAGDROP)) NotifyTree(hWnd, TVN_BEGINDRAGW, 0, nullptr, td.pressItem);
			if(g_trees.count(hWnd)) g_trees[hWnd].pressItem = nullptr;
		}
		return 0;
	}
	case WM_LBUTTONUP:
		td.drag.active = false;
		td.pressItem = nullptr;
		if(GetCapture() == hWnd) ReleaseCapture();
		return 0;
	case WM_LBUTTONDBLCLK:
	{
		NMHDR hdr{};
		if(!SendNotify(hWnd, hdr, NM_DBLCLK))
		{
			UINT flags = 0;
			if(TreeItem *item = TreeHitTest(hWnd, td, POINT{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)}, flags); item && (flags & (TVHT_ONITEMICON | TVHT_ONITEMLABEL)))
				ExpandItem(hWnd, td, item, TVE_TOGGLE);
		}
		return 0;
	}
	case WM_KEYDOWN:
	{
		NMTVKEYDOWN kd{};
		kd.wVKey = (WORD)wParam;
		SendNotify(hWnd, kd.hdr, TVN_KEYDOWN);
		if(!g_trees.count(hWnd)) return 0;
		const auto rows = VisibleRows(td);
		auto index = std::find_if(rows.begin(), rows.end(), [&](const TreeRow &r) { return r.item == td.caret; }) - rows.begin();
		TreeItem *target = nullptr;
		switch(wParam)
		{
		case VK_UP: if(index > 0 && index <= (int)rows.size()) target = rows[index - 1].item; break;
		case VK_DOWN: if(index + 1 < (int)rows.size()) target = rows[index + 1].item; else if(index == (int)rows.size() && !rows.empty()) target = rows[0].item; break;
		case VK_HOME: if(!rows.empty()) target = rows.front().item; break;
		case VK_END: if(!rows.empty()) target = rows.back().item; break;
		case VK_PRIOR: if(!rows.empty()) target = rows[std::max<ptrdiff_t>(0, index - td.vscroll.page)].item; break;
		case VK_NEXT: if(!rows.empty()) target = rows[std::min<ptrdiff_t>(rows.size() - 1, index + td.vscroll.page)].item; break;
		case VK_LEFT:
			if(td.caret && (td.caret->state & TVIS_EXPANDED)) ExpandItem(hWnd, td, td.caret, TVE_COLLAPSE);
			else if(td.caret && td.caret->parent != &td.root) target = td.caret->parent;
			break;
		case VK_RIGHT:
			if(td.caret && HasChildren(hWnd, td.caret))
			{
				if(!(td.caret->state & TVIS_EXPANDED)) ExpandItem(hWnd, td, td.caret, TVE_EXPAND);
				else if(!td.caret->children.empty()) target = td.caret->children.front();
			}
			break;
		case VK_ADD: if(td.caret) ExpandItem(hWnd, td, td.caret, TVE_EXPAND); break;
		case VK_SUBTRACT: if(td.caret) ExpandItem(hWnd, td, td.caret, TVE_COLLAPSE); break;
		case VK_RETURN:
		{
			NMHDR hdr{};
			SendNotify(hWnd, hdr, NM_RETURN);
			break;
		}
		case VK_F2:
			if(HasStyle(hWnd, TVS_EDITLABELS)) BeginTreeLabelEdit(hWnd, td, td.caret);
			break;
		}
		if(target) SelectTreeItem(hWnd, td, target, TVC_BYKEYBOARD);
		return 0;
	}
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// List view (report mode)
// ---------------------------------------------------------------------------------------------

struct ListColumn
{
	std::wstring text;
	int width = 60;
	int fmt = LVCFMT_LEFT;
};

struct ListItem
{
	std::vector<std::wstring> texts;  // per sub-item
	std::vector<bool> textCallback;
	int image = 0;
	UINT state = 0;
	LPARAM lParam = 0;
	int groupId = I_GROUPIDNONE;
};

struct ListGroup
{
	int id = 0;
	std::wstring header;
	UINT state = 0;
};

struct ListRow
{
	int item = -1;   // -1 for a group header row
	int group = -1;  // index into groups for header rows
};

struct ListData
{
	std::vector<ListColumn> columns;
	std::vector<ListItem> items;
	int ownerDataCount = 0;
	std::map<int, UINT> ownerDataState;
	DWORD exStyle = 0;
	HIMAGELIST smallImages = nullptr, stateImages = nullptr;
	std::vector<ListGroup> groups;
	bool groupView = false;
	ScrollBar vscroll, hscroll;
	ScrollDrag drag;
	int selectionMark = -1;
	COLORREF bk = CLR_NONE, text = CLR_NONE, textBk = CLR_NONE;
	HWND edit = nullptr;
	int editItem = -1;
	int pressItem = -1;
	POINT pressPoint{};
};

std::map<HWND, ListData> g_lists;

bool OwnerData(HWND hWnd) { return HasStyle(hWnd, LVS_OWNERDATA); }

int ListCount(HWND hWnd, ListData &ld) { return OwnerData(hWnd) ? ld.ownerDataCount : (int)ld.items.size(); }

UINT ListItemState(HWND hWnd, ListData &ld, int i)
{
	if(OwnerData(hWnd)) return ld.ownerDataState.count(i) ? ld.ownerDataState[i] : 0;
	return (i >= 0 && i < (int)ld.items.size()) ? ld.items[i].state : 0;
}

void SetListItemStateRaw(HWND hWnd, ListData &ld, int i, UINT state)
{
	if(OwnerData(hWnd))
	{
		if(state) ld.ownerDataState[i] = state;
		else ld.ownerDataState.erase(i);
	} else if(i >= 0 && i < (int)ld.items.size())
	{
		ld.items[i].state = state;
	}
}

std::wstring ListText(HWND hWnd, ListData &ld, int item, int sub)
{
	const bool owner = OwnerData(hWnd);
	if(!owner)
	{
		if(item < 0 || item >= (int)ld.items.size()) return {};
		const ListItem &li = ld.items[item];
		const bool callback = sub < (int)li.textCallback.size() && li.textCallback[sub];
		if(!callback) return sub < (int)li.texts.size() ? li.texts[sub] : std::wstring();
	}
	wchar_t buffer[512] = {};
	NMLVDISPINFOW di{};
	di.item.mask = LVIF_TEXT;
	di.item.iItem = item;
	di.item.iSubItem = sub;
	di.item.pszText = buffer;
	di.item.cchTextMax = 512;
	if(!owner) di.item.lParam = ld.items[item].lParam;
	SendNotify(hWnd, di.hdr, LVN_GETDISPINFOW);
	return di.item.pszText ? std::wstring(di.item.pszText) : std::wstring();
}

int ListImage(HWND hWnd, ListData &ld, int item)
{
	if(!OwnerData(hWnd) && item >= 0 && item < (int)ld.items.size() && ld.items[item].image != I_IMAGECALLBACK) return ld.items[item].image;
	NMLVDISPINFOW di{};
	di.item.mask = LVIF_IMAGE;
	di.item.iItem = item;
	SendNotify(hWnd, di.hdr, LVN_GETDISPINFOW);
	return di.item.iImage;
}

std::vector<ListRow> ListRows(HWND hWnd, ListData &ld)
{
	std::vector<ListRow> rows;
	const int count = ListCount(hWnd, ld);
	if(ld.groupView && !OwnerData(hWnd) && !ld.groups.empty())
	{
		for(int g = 0; g < (int)ld.groups.size(); g++)
		{
			bool any = false;
			for(int i = 0; i < count; i++)
			{
				if(ld.items[i].groupId != ld.groups[g].id) continue;
				if(!any) rows.push_back({-1, g});
				any = true;
				if(!(ld.groups[g].state & LVGS_COLLAPSED)) rows.push_back({i, g});
			}
		}
	} else
	{
		for(int i = 0; i < count; i++) rows.push_back({i, -1});
	}
	return rows;
}

int ListLineHeight(HWND hWnd)
{
	HDC dc = GetDC(hWnd);
	SelectObject(dc, ControlFont(hWnd));
	const int h = LineHeight(dc);
	ReleaseDC(hWnd, dc);
	return h;
}

int ListRowHeight(HWND hWnd, ListData &ld)
{
	int cx = 0, cy = 0;
	if(ld.smallImages) ImageList_GetIconSize(ld.smallImages, &cx, &cy);
	return std::max(ListLineHeight(hWnd) + 4, cy + 1);
}

int HeaderHeight(HWND hWnd)
{
	return HasStyle(hWnd, LVS_NOCOLUMNHEADER) ? 0 : ListLineHeight(hWnd) + 10;
}

int TotalColumnWidth(const ListData &ld)
{
	int w = 0;
	for(const auto &c : ld.columns) w += c.width;
	return w;
}

void ListLayout(HWND hWnd, ListData &ld, RECT &header, RECT &rowsArea, RECT &vbar, RECT &hbar, int &rowHeight, std::vector<ListRow> &rows)
{
	RECT client;
	GetClientRect(hWnd, &client);
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(rec && ((rec->style & WS_BORDER) || (rec->exStyle & WS_EX_CLIENTEDGE))) InflateRect(&client, -1, -1);
	rowHeight = ListRowHeight(hWnd, ld);
	rows = ListRows(hWnd, ld);
	const int headerHeight = HeaderHeight(hWnd);
	rowsArea = client;
	rowsArea.top += headerHeight;
	const int totalWidth = TotalColumnWidth(ld);
	const bool needH = totalWidth > client.right - client.left - kScrollSize;
	if(needH) rowsArea.bottom -= kScrollSize;
	ld.vscroll.total = (int)rows.size();
	ld.vscroll.page = std::max(1, (int)(rowsArea.bottom - rowsArea.top) / rowHeight);
	vbar = hbar = RECT{0, 0, 0, 0};
	if(ld.vscroll.Needed())
	{
		vbar = RECT{client.right - kScrollSize, client.top, client.right, rowsArea.bottom};
		rowsArea.right -= kScrollSize;
	}
	ld.hscroll.total = totalWidth;
	ld.hscroll.page = rowsArea.right - rowsArea.left;
	if(ld.hscroll.Needed()) hbar = RECT{client.left, rowsArea.bottom, rowsArea.right, rowsArea.bottom + kScrollSize};
	else ld.hscroll.pos = 0;
	ld.vscroll.Clamp();
	ld.hscroll.Clamp();
	header = RECT{client.left, client.top, rowsArea.right, client.top + headerHeight};
}

RECT ColumnRect(ListData &ld, int col, const RECT &rowsArea, int top, int bottom)
{
	int x = rowsArea.left - ld.hscroll.pos;
	for(int c = 0; c < col && c < (int)ld.columns.size(); c++) x += ld.columns[c].width;
	const int w = col < (int)ld.columns.size() ? ld.columns[col].width : 0;
	return RECT{x, top, x + w, bottom};
}

LRESULT ListCustomDraw(HWND hWnd, DWORD stage, HDC dc, const RECT &rc, int item, int sub, UINT itemState, LPARAM lParam, COLORREF &text, COLORREF &textBk)
{
	NMLVCUSTOMDRAW cd{};
	cd.nmcd.dwDrawStage = stage;
	cd.nmcd.hdc = dc;
	cd.nmcd.rc = rc;
	cd.nmcd.dwItemSpec = (DWORD_PTR)item;
	cd.nmcd.uItemState = itemState;
	cd.nmcd.lItemlParam = lParam;
	cd.iSubItem = sub;
	cd.clrText = text;
	cd.clrTextBk = textBk;
	const LRESULT r = SendNotify(hWnd, cd.nmcd.hdr, NM_CUSTOMDRAW);
	text = cd.clrText;
	textBk = cd.clrTextBk;
	return r;
}

void PaintList(HWND hWnd, ListData &ld)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client, header, rowsArea, vbar, hbar;
	GetClientRect(hWnd, &client);
	int rowHeight;
	std::vector<ListRow> rows;
	ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
	const COLORREF bk = ld.bk != CLR_NONE ? ld.bk : GetSysColor(COLOR_WINDOW);
	FillSolid(dc, client, bk);
	SetBkMode(dc, TRANSPARENT);
	HFONT font = ControlFont(hWnd);
	SelectObject(dc, font);
	const bool focused = IsFocused(hWnd) || (ld.edit && IsFocused(ld.edit));
	const bool fullRow = ld.exStyle & LVS_EX_FULLROWSELECT;
	const bool showSelAlways = HasStyle(hWnd, LVS_SHOWSELALWAYS);
	const bool checkboxes = ld.exStyle & LVS_EX_CHECKBOXES;
	int imageW = 0, imageH = 0;
	if(ld.smallImages) ImageList_GetIconSize(ld.smallImages, &imageW, &imageH);
	CGContextRef ctx = dc->cgContext;
	const int lineHeight = LineHeight(dc);

	// Whole-control custom draw prologue.
	COLORREF dummyText = 0, dummyBk = 0;
	const LRESULT prepaint = ListCustomDraw(hWnd, CDDS_PREPAINT, dc, client, 0, 0, 0, 0, dummyText, dummyBk);
	if(ctx)
	{
		CGContextSaveGState(ctx);
		CGContextClipToRect(ctx, CGRectMake(rowsArea.left + dc->viewportOrg.x, rowsArea.top + dc->viewportOrg.y, rowsArea.right - rowsArea.left, rowsArea.bottom - rowsArea.top));
	}
	for(int r = ld.vscroll.pos; r < (int)rows.size(); r++)
	{
		const int y = rowsArea.top + (r - ld.vscroll.pos) * rowHeight;
		if(y >= rowsArea.bottom) break;
		const ListRow &row = rows[r];
		if(row.item < 0)
		{
			// Group header: blue caption followed by a separator line, collapse chevron at the right.
			const ListGroup &g = ld.groups[row.group];
			SetTextColor(dc, RGB(30, 57, 145));
			SIZE size{};
			GetTextExtentPoint32W(dc, g.header.c_str(), (int)g.header.size(), &size);
			TextOutW(dc, rowsArea.left + 6 - ld.hscroll.pos, y + (rowHeight - size.cy) / 2, g.header.c_str(), (int)g.header.size());
			const int lineY = y + rowHeight / 2;
			FillSolid(dc, RECT{rowsArea.left + 14 + size.cx - ld.hscroll.pos, lineY, rowsArea.right - 20, lineY + 1}, RGB(226, 226, 226));
			if(g.state & LVGS_COLLAPSIBLE)
			{
				const int cx = rowsArea.right - 12;
				for(int i = 0; i < 3; i++)
				{
					if(g.state & LVGS_COLLAPSED) FillSolid(dc, RECT{cx - 2 + i, lineY - i, cx - 1 + i, lineY + i + 1}, RGB(96, 96, 96));
					else FillSolid(dc, RECT{cx - i, lineY - 1 + i, cx + i + 1, lineY + i}, RGB(96, 96, 96));
				}
			}
			continue;
		}
		const int i = row.item;
		const UINT state = ListItemState(hWnd, ld, i);
		const bool selected = state & LVIS_SELECTED;
		const bool highlighted = selected && (focused || showSelAlways);
		COLORREF textColor = ld.text != CLR_NONE ? ld.text : GetSysColor(COLOR_WINDOWTEXT);
		COLORREF textBk = ld.textBk != CLR_NONE ? ld.textBk : CLR_NONE;
		if(highlighted)
		{
			textColor = focused ? GetSysColor(COLOR_HIGHLIGHTTEXT) : GetSysColor(COLOR_WINDOWTEXT);
			textBk = focused ? GetSysColor(COLOR_HIGHLIGHT) : GetSysColor(COLOR_BTNFACE);
		}
		const LPARAM itemParam = OwnerData(hWnd) ? 0 : ld.items[i].lParam;
		const RECT rowRect{rowsArea.left - ld.hscroll.pos, y, rowsArea.left - ld.hscroll.pos + std::max<int>(TotalColumnWidth(ld), rowsArea.right - rowsArea.left), y + rowHeight};
		LRESULT itemDraw = CDRF_DODEFAULT;
		if(prepaint & CDRF_NOTIFYITEMDRAW)
			itemDraw = ListCustomDraw(hWnd, CDDS_ITEMPREPAINT, dc, rowRect, i, 0, highlighted ? CDIS_SELECTED : 0, itemParam, textColor, textBk);
		if(itemDraw & CDRF_SKIPDEFAULT) continue;
		const int cols = std::max<int>(1, (int)ld.columns.size());
		for(int c = 0; c < cols; c++)
		{
			RECT cell = ld.columns.empty() ? RECT{rowRect.left, y, rowsArea.right, y + rowHeight} : ColumnRect(ld, c, rowsArea, y, y + rowHeight);
			COLORREF cellText = textColor, cellBk = textBk;
			if(itemDraw & CDRF_NOTIFYSUBITEMDRAW)
				ListCustomDraw(hWnd, CDDS_ITEMPREPAINT | CDDS_SUBITEM, dc, cell, i, c, highlighted ? CDIS_SELECTED : 0, itemParam, cellText, cellBk);
			int x = cell.left + 2;
			if(c == 0 && checkboxes)
			{
				const int checkState = (state & LVIS_STATEIMAGEMASK) >> 12;
				const RECT box{x + 2, y + (rowHeight - 13) / 2, x + 15, y + (rowHeight - 13) / 2 + 13};
				FillSolid(dc, box, RGB(255, 255, 255));
				Outline(dc, box, RGB(51, 51, 51));
				if(checkState == 2 && ctx)
				{
					CGContextSetRGBStrokeColor(ctx, 0.2, 0.2, 0.2, 1);
					CGContextSetLineWidth(ctx, 1.5);
					CGContextMoveToPoint(ctx, box.left + 3 + dc->viewportOrg.x, box.top + 6.5 + dc->viewportOrg.y);
					CGContextAddLineToPoint(ctx, box.left + 5.5 + dc->viewportOrg.x, box.top + 9 + dc->viewportOrg.y);
					CGContextAddLineToPoint(ctx, box.left + 10 + dc->viewportOrg.x, box.top + 3.5 + dc->viewportOrg.y);
					CGContextStrokePath(ctx);
				}
				x += 18;
			}
			if(c == 0 && ld.smallImages)
			{
				ImageList_Draw(ld.smallImages, ListImage(hWnd, ld, i), dc, x, y + (rowHeight - imageH) / 2, ILD_NORMAL);
				x += imageW + 2;
			}
			const std::wstring text = ListText(hWnd, ld, i, c);
			SIZE textSize{};
			GetTextExtentPoint32W(dc, text.c_str(), (int)text.size(), &textSize);
			const bool paintBk = cellBk != CLR_NONE && (fullRow || c == 0);
			if(paintBk)
			{
				RECT bkRect = cell;
				if(!fullRow) bkRect = RECT{x, y, std::min<LONG>(x + textSize.cx + 6, cell.right), y + rowHeight};
				else if(c == cols - 1) bkRect.right = std::max<LONG>(bkRect.right, rowsArea.right);
				FillSolid(dc, bkRect, cellBk);
			}
			SetTextColor(dc, (fullRow || c == 0) ? cellText : (ld.text != CLR_NONE ? ld.text : GetSysColor(COLOR_WINDOWTEXT)));
			RECT textRect{x + 4, y, cell.right - 4, y + rowHeight};
			const int fmt = c < (int)ld.columns.size() ? (ld.columns[c].fmt & LVCFMT_JUSTIFYMASK) : LVCFMT_LEFT;
			const UINT align = fmt == LVCFMT_RIGHT ? DT_RIGHT : (fmt == LVCFMT_CENTER ? DT_CENTER : DT_LEFT);
			DrawTextW(dc, text.c_str(), (int)text.size(), &textRect, align | DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX | DT_END_ELLIPSIS);
			(void)lineHeight;
		}
		if(ld.exStyle & LVS_EX_GRIDLINES)
			FillSolid(dc, RECT{rowRect.left, y + rowHeight - 1, rowRect.right, y + rowHeight}, RGB(240, 240, 240));
	}
	if(ld.exStyle & LVS_EX_GRIDLINES)
		for(int c = 0; c < (int)ld.columns.size(); c++)
		{
			const RECT col = ColumnRect(ld, c, rowsArea, rowsArea.top, rowsArea.bottom);
			FillSolid(dc, RECT{col.right - 1, rowsArea.top, col.right, rowsArea.bottom}, RGB(240, 240, 240));
		}
	if(ctx) CGContextRestoreGState(ctx);

	// Column header.
	if(header.bottom > header.top)
	{
		FillSolid(dc, header, RGB(255, 255, 255));
		FillSolid(dc, RECT{header.left, header.bottom - 1, header.right, header.bottom}, RGB(229, 229, 229));
		SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
		for(int c = 0; c < (int)ld.columns.size(); c++)
		{
			const RECT col = ColumnRect(ld, c, rowsArea, header.top, header.bottom);
			if(col.left >= header.right) break;
			FillSolid(dc, RECT{col.right - 1, header.top, col.right, header.bottom - 1}, RGB(229, 229, 229));
			RECT textRect{col.left + 6, header.top, col.right - 6, header.bottom};
			const int fmt = ld.columns[c].fmt & LVCFMT_JUSTIFYMASK;
			const UINT align = fmt == LVCFMT_RIGHT ? DT_RIGHT : (fmt == LVCFMT_CENTER ? DT_CENTER : DT_LEFT);
			DrawTextW(dc, ld.columns[c].text.c_str(), (int)ld.columns[c].text.size(), &textRect, align | DT_SINGLELINE | DT_VCENTER | DT_END_ELLIPSIS);
		}
	}
	if(ld.vscroll.Needed()) DrawScrollBar(dc, vbar, ld.vscroll, true);
	if(ld.hscroll.Needed()) DrawScrollBar(dc, hbar, ld.hscroll, false);
	if(ld.vscroll.Needed() && ld.hscroll.Needed()) FillSolid(dc, RECT{vbar.left, hbar.top, vbar.right, hbar.bottom}, RGB(240, 240, 240));
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(rec && ((rec->style & WS_BORDER) || (rec->exStyle & WS_EX_CLIENTEDGE))) Outline(dc, client, RGB(130, 135, 144));
	EndPaint(hWnd, &ps);
}

// Changes an item's state and sends LVN_ITEMCHANGING / LVN_ITEMCHANGED like comctl32.
bool ChangeListItemState(HWND hWnd, ListData &ld, int i, UINT state, UINT mask)
{
	const UINT old = ListItemState(hWnd, ld, i);
	const UINT next = (old & ~mask) | (state & mask);
	if(next == old) return true;
	NMLISTVIEW nm{};
	nm.iItem = i;
	nm.uOldState = old;
	nm.uNewState = next;
	nm.uChanged = LVIF_STATE;
	nm.lParam = OwnerData(hWnd) ? 0 : ld.items[i].lParam;
	if(SendNotify(hWnd, nm.hdr, LVN_ITEMCHANGING)) return false;
	if(!g_lists.count(hWnd)) return false;
	SetListItemStateRaw(hWnd, ld, i, next);
	SendNotify(hWnd, nm.hdr, LVN_ITEMCHANGED);
	InvalidateRect(hWnd, nullptr, FALSE);
	return true;
}

void SelectOnly(HWND hWnd, ListData &ld, int item)
{
	const int count = ListCount(hWnd, ld);
	for(int i = 0; i < count; i++)
	{
		const UINT st = ListItemState(hWnd, ld, i);
		if(i != item && (st & (LVIS_SELECTED | LVIS_FOCUSED))) ChangeListItemState(hWnd, ld, i, 0, LVIS_SELECTED | LVIS_FOCUSED);
	}
	if(item >= 0) ChangeListItemState(hWnd, ld, item, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
	ld.selectionMark = item;
}

void EnsureListVisible(HWND hWnd, ListData &ld, int item)
{
	RECT header, rowsArea, vbar, hbar;
	int rowHeight;
	std::vector<ListRow> rows;
	ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
	for(int r = 0; r < (int)rows.size(); r++)
	{
		if(rows[r].item != item) continue;
		if(r < ld.vscroll.pos) ld.vscroll.pos = r;
		else if(r >= ld.vscroll.pos + ld.vscroll.page) ld.vscroll.pos = r - ld.vscroll.page + 1;
		ld.vscroll.Clamp();
		InvalidateRect(hWnd, nullptr, FALSE);
		return;
	}
}

// Returns the row index under pt, or -1; sets item / sub-item / group for that row.
int ListHitTest(HWND hWnd, ListData &ld, POINT pt, int &item, int &sub, int &group, UINT &flags)
{
	RECT header, rowsArea, vbar, hbar;
	int rowHeight;
	std::vector<ListRow> rows;
	ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
	item = sub = group = -1;
	flags = LVHT_NOWHERE;
	if(!PtInRect(&rowsArea, pt)) return -1;
	const int r = ld.vscroll.pos + (pt.y - rowsArea.top) / rowHeight;
	if(r < 0 || r >= (int)rows.size()) return -1;
	item = rows[r].item;
	group = rows[r].group;
	if(item < 0) return r;
	for(int c = 0; c < std::max<int>(1, (int)ld.columns.size()); c++)
	{
		const RECT cell = ColumnRect(ld, c, rowsArea, 0, 1);
		if(ld.columns.empty() || (pt.x >= cell.left && pt.x < cell.right)) { sub = c; break; }
	}
	const RECT first = ColumnRect(ld, 0, rowsArea, 0, 1);
	if((ld.exStyle & LVS_EX_CHECKBOXES) && pt.x >= first.left && pt.x < first.left + 20) flags = LVHT_ONITEMSTATEICON;
	else if(sub >= 0 || (ld.exStyle & LVS_EX_FULLROWSELECT)) flags = LVHT_ONITEMLABEL;
	return r;
}

void NotifyItemActivate(HWND hWnd, UINT code, int item, int sub, POINT pt)
{
	NMITEMACTIVATE nm{};
	nm.iItem = item;
	nm.iSubItem = sub;
	nm.ptAction = pt;
	SendNotify(hWnd, nm.hdr, code);
}

int AutoColumnWidth(HWND hWnd, ListData &ld, int col, bool useHeader)
{
	HDC dc = GetDC(hWnd);
	SelectObject(dc, ControlFont(hWnd));
	int width = 0;
	auto measure = [&](const std::wstring &t) {
		SIZE s{};
		GetTextExtentPoint32W(dc, t.c_str(), (int)t.size(), &s);
		width = std::max<int>(width, s.cx);
	};
	const int count = ListCount(hWnd, ld);
	for(int i = 0; i < count; i++) measure(ListText(hWnd, ld, i, col));
	if(useHeader && col < (int)ld.columns.size()) measure(ld.columns[col].text);
	ReleaseDC(hWnd, dc);
	int extra = 12;
	if(col == 0 && ld.smallImages) { int cx = 0, cy = 0; ImageList_GetIconSize(ld.smallImages, &cx, &cy); extra += cx + 2; }
	if(col == 0 && (ld.exStyle & LVS_EX_CHECKBOXES)) extra += 18;
	return width + extra;
}

void BeginListLabelEdit(HWND hWnd, ListData &ld, int item)
{
	if(ld.edit || item < 0 || item >= ListCount(hWnd, ld)) return;
	std::wstring text = ListText(hWnd, ld, item, 0);
	NMLVDISPINFOW di{};
	di.item.mask = LVIF_TEXT;
	di.item.iItem = item;
	di.item.pszText = text.data();
	if(SendNotify(hWnd, di.hdr, LVN_BEGINLABELEDITW)) return;
	EnsureListVisible(hWnd, ld, item);
	RECT header, rowsArea, vbar, hbar;
	int rowHeight;
	std::vector<ListRow> rows;
	ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
	int r = 0;
	for(; r < (int)rows.size() && rows[r].item != item; r++) {}
	const int y = rowsArea.top + (r - ld.vscroll.pos) * rowHeight;
	RECT cell = ColumnRect(ld, 0, rowsArea, y, y + rowHeight);
	if(ld.smallImages) { int cx = 0, cy = 0; ImageList_GetIconSize(ld.smallImages, &cx, &cy); cell.left += cx + 2; }
	ld.editItem = item;
	ld.edit = BeginLabelEdit(hWnd, cell, text, [hWnd](bool cancel) {
		auto it = g_lists.find(hWnd);
		if(it == g_lists.end()) return;
		ListData &l = it->second;
		HWND edit = l.edit;
		const int editItem = l.editItem;
		l.edit = nullptr;
		l.editItem = -1;
		std::wstring newText = EditText(edit);
		NMLVDISPINFOW end{};
		end.item.mask = LVIF_TEXT;
		end.item.iItem = editItem;
		end.item.pszText = cancel ? nullptr : newText.data();
		if(SendNotify(hWnd, end.hdr, LVN_ENDLABELEDITW) && !cancel && !OwnerData(hWnd) && editItem >= 0 && editItem < (int)l.items.size())
		{
			auto &li = l.items[editItem];
			if(li.texts.empty()) li.texts.resize(1);
			li.texts[0] = newText;
		}
		DestroyWindow(edit);
		SetFocus(hWnd);
		InvalidateRect(hWnd, nullptr, FALSE);
	});
}

void SetSubItemText(ListItem &li, int sub, LPCWSTR text)
{
	if((int)li.texts.size() <= sub) { li.texts.resize(sub + 1); li.textCallback.resize(sub + 1); }
	if((int)li.textCallback.size() <= sub) li.textCallback.resize(sub + 1);
	li.textCallback[sub] = text == LPSTR_TEXTCALLBACKW;
	li.texts[sub] = (text && text != LPSTR_TEXTCALLBACKW) ? text : L"";
}

LRESULT CALLBACK ListProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	ListData &ld = g_lists[hWnd];
	switch(msg)
	{
	case WM_NCDESTROY:
		g_lists.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintList(hWnd, ld);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS | DLGC_WANTCHARS;
	case WM_SETFOCUS:
	case WM_KILLFOCUS:
	{
		InvalidateRect(hWnd, nullptr, FALSE);
		NMHDR hdr{};
		SendNotify(hWnd, hdr, msg == WM_SETFOCUS ? NM_SETFOCUS : NM_KILLFOCUS);
		return 0;
	}
	case WM_SIZE:
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;

	case LVM_GETITEMCOUNT:
		return ListCount(hWnd, ld);
	case LVM_SETITEMCOUNT:
		if(OwnerData(hWnd)) ld.ownerDataCount = (int)wParam;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case LVM_INSERTITEMW:
	case LVM_INSERTITEMA:
	{
		const auto *lvi = (const LVITEMW *)lParam;
		if(!lvi || OwnerData(hWnd)) return -1;
		ListItem li;
		if(lvi->mask & LVIF_TEXT)
		{
			if(msg == LVM_INSERTITEMA && lvi->pszText && lvi->pszText != LPSTR_TEXTCALLBACKW)
			{
				const char *a = (const char *)lvi->pszText;
				std::wstring w(a, a + strlen(a));
				SetSubItemText(li, 0, w.c_str());
			} else SetSubItemText(li, 0, lvi->pszText);
		}
		if(lvi->mask & LVIF_IMAGE) li.image = lvi->iImage;
		if(lvi->mask & LVIF_PARAM) li.lParam = lvi->lParam;
		if(lvi->mask & LVIF_STATE) li.state = lvi->state & lvi->stateMask;
		if(lvi->mask & LVIF_GROUPID) li.groupId = lvi->iGroupId;
		if((ld.exStyle & LVS_EX_CHECKBOXES) && !(li.state & LVIS_STATEIMAGEMASK)) li.state |= INDEXTOSTATEIMAGEMASK(1);
		int index = std::clamp(lvi->iItem, 0, (int)ld.items.size());
		if(HasStyle(hWnd, LVS_SORTASCENDING | LVS_SORTDESCENDING) && !li.texts.empty())
		{
			const bool desc = HasStyle(hWnd, LVS_SORTDESCENDING);
			index = 0;
			while(index < (int)ld.items.size() && !ld.items[index].texts.empty() && (lstrcmpiW(ld.items[index].texts[0].c_str(), li.texts[0].c_str()) < 0) != desc) index++;
		}
		ld.items.insert(ld.items.begin() + index, li);
		InvalidateRect(hWnd, nullptr, FALSE);
		return index;
	}
	case LVM_DELETEITEM:
	{
		if(OwnerData(hWnd) || wParam >= ld.items.size()) return FALSE;
		NMLISTVIEW nm{};
		nm.iItem = (int)wParam;
		nm.lParam = ld.items[wParam].lParam;
		SendNotify(hWnd, nm.hdr, LVN_DELETEITEM);
		if(!g_lists.count(hWnd)) return FALSE;
		ld.items.erase(ld.items.begin() + wParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_DELETEALLITEMS:
	{
		NMLISTVIEW nm{};
		nm.iItem = -1;
		// Nonzero from LVN_DELETEALLITEMS suppresses the per-item notifications.
		const bool quiet = SendNotify(hWnd, nm.hdr, LVN_DELETEALLITEMS) != 0;
		if(!g_lists.count(hWnd)) return FALSE;
		for(int i = 0; !quiet && i < (int)ld.items.size(); i++)
		{
			NMLISTVIEW del{};
			del.iItem = i;
			del.lParam = ld.items[i].lParam;
			SendNotify(hWnd, del.hdr, LVN_DELETEITEM);
		}
		ld.items.clear();
		ld.ownerDataState.clear();
		ld.vscroll.pos = 0;
		ld.selectionMark = -1;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_SETITEMW:
	case LVM_SETITEMA:
	{
		const auto *lvi = (const LVITEMW *)lParam;
		if(!lvi || lvi->iItem < 0) return FALSE;
		if(lvi->mask & LVIF_STATE) ChangeListItemState(hWnd, ld, lvi->iItem, lvi->state, lvi->stateMask);
		if(OwnerData(hWnd) || lvi->iItem >= (int)ld.items.size()) return TRUE;
		ListItem &li = ld.items[lvi->iItem];
		if(lvi->mask & LVIF_TEXT) SetSubItemText(li, lvi->iSubItem, lvi->pszText);
		if((lvi->mask & LVIF_IMAGE) && lvi->iSubItem == 0) li.image = lvi->iImage;
		if(lvi->mask & LVIF_PARAM) li.lParam = lvi->lParam;
		if(lvi->mask & LVIF_GROUPID) li.groupId = lvi->iGroupId;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_GETITEMW:
	case LVM_GETITEMA:
	{
		auto *lvi = (LVITEMW *)lParam;
		if(!lvi || lvi->iItem < 0 || lvi->iItem >= ListCount(hWnd, ld)) return FALSE;
		if(lvi->mask & LVIF_TEXT && lvi->pszText && lvi->cchTextMax > 0)
		{
			const std::wstring t = ListText(hWnd, ld, lvi->iItem, lvi->iSubItem);
			const size_t n = std::min<size_t>(t.size(), lvi->cchTextMax - 1);
			std::copy_n(t.data(), n, lvi->pszText);
			lvi->pszText[n] = 0;
		}
		if(lvi->mask & LVIF_STATE) lvi->state = ListItemState(hWnd, ld, lvi->iItem) & lvi->stateMask;
		if(OwnerData(hWnd)) return TRUE;
		const ListItem &li = ld.items[lvi->iItem];
		if(lvi->mask & LVIF_IMAGE) lvi->iImage = li.image;
		if(lvi->mask & LVIF_PARAM) lvi->lParam = li.lParam;
		if(lvi->mask & LVIF_GROUPID) lvi->iGroupId = li.groupId;
		return TRUE;
	}
	case LVM_SETITEMTEXTW:
	case LVM_SETITEMTEXTA:
	{
		const auto *lvi = (const LVITEMW *)lParam;
		if(!lvi || OwnerData(hWnd) || wParam >= ld.items.size()) return FALSE;
		SetSubItemText(ld.items[wParam], lvi->iSubItem, lvi->pszText);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_GETITEMTEXTW:
	case LVM_GETITEMTEXTA:
	{
		auto *lvi = (LVITEMW *)lParam;
		if(!lvi || !lvi->pszText || lvi->cchTextMax <= 0 || (int)wParam >= ListCount(hWnd, ld)) return 0;
		const std::wstring t = ListText(hWnd, ld, (int)wParam, lvi->iSubItem);
		const size_t n = std::min<size_t>(t.size(), lvi->cchTextMax - 1);
		std::copy_n(t.data(), n, lvi->pszText);
		lvi->pszText[n] = 0;
		return (LRESULT)n;
	}
	case LVM_SETITEMSTATE:
	{
		const auto *lvi = (const LVITEMW *)lParam;
		if(!lvi) return FALSE;
		if((int)wParam == -1)
		{
			for(int i = 0; i < ListCount(hWnd, ld); i++) ChangeListItemState(hWnd, ld, i, lvi->state, lvi->stateMask);
			return TRUE;
		}
		if((int)wParam >= ListCount(hWnd, ld)) return FALSE;
		if((lvi->stateMask & LVIS_SELECTED) && (lvi->state & LVIS_SELECTED) && HasStyle(hWnd, LVS_SINGLESEL))
			for(int i = 0; i < ListCount(hWnd, ld); i++)
				if(i != (int)wParam) ChangeListItemState(hWnd, ld, i, 0, LVIS_SELECTED);
		return ChangeListItemState(hWnd, ld, (int)wParam, lvi->state, lvi->stateMask);
	}
	case LVM_GETITEMSTATE:
		return ListItemState(hWnd, ld, (int)wParam) & (UINT)lParam;
	case LVM_GETNEXTITEM:
	{
		const UINT flags = LOWORD(lParam) & 0xFF;
		const int count = ListCount(hWnd, ld);
		for(int i = (int)wParam + 1; i < count; i++)
		{
			const UINT st = ListItemState(hWnd, ld, i);
			if(flags == LVNI_ALL || ((flags & LVNI_SELECTED) && (st & LVIS_SELECTED)) || ((flags & LVNI_FOCUSED) && (st & LVIS_FOCUSED))) return i;
		}
		return -1;
	}
	case LVM_GETSELECTEDCOUNT:
	{
		int n = 0;
		for(int i = 0; i < ListCount(hWnd, ld); i++) if(ListItemState(hWnd, ld, i) & LVIS_SELECTED) n++;
		return n;
	}
	case LVM_GETSELECTIONMARK: return ld.selectionMark;
	case LVM_SETSELECTIONMARK: { const int old = ld.selectionMark; ld.selectionMark = (int)lParam; return old; }
	case LVM_INSERTCOLUMNW:
	case LVM_INSERTCOLUMNA:
	{
		const auto *col = (const LVCOLUMNW *)lParam;
		if(!col) return -1;
		ListColumn c;
		if(col->mask & LVCF_TEXT && col->pszText)
		{
			if(msg == LVM_INSERTCOLUMNA) { const char *a = (const char *)col->pszText; c.text.assign(a, a + strlen(a)); }
			else c.text = col->pszText;
		}
		if(col->mask & LVCF_WIDTH) c.width = col->cx;
		if(col->mask & LVCF_FMT) c.fmt = col->fmt;
		const int index = std::clamp<int>((int)wParam, 0, (int)ld.columns.size());
		ld.columns.insert(ld.columns.begin() + index, c);
		for(auto &li : ld.items)
			if(index < (int)li.texts.size()) { li.texts.insert(li.texts.begin() + index, L""); li.textCallback.insert(li.textCallback.begin() + index, false); }
		InvalidateRect(hWnd, nullptr, FALSE);
		return index;
	}
	case LVM_DELETECOLUMN:
		if(wParam >= ld.columns.size()) return FALSE;
		ld.columns.erase(ld.columns.begin() + wParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case LVM_GETCOLUMNW:
	case LVM_GETCOLUMNA:
	{
		auto *col = (LVCOLUMNW *)lParam;
		if(!col || wParam >= ld.columns.size()) return FALSE;
		const ListColumn &c = ld.columns[wParam];
		if(col->mask & LVCF_WIDTH) col->cx = c.width;
		if(col->mask & LVCF_FMT) col->fmt = c.fmt;
		if((col->mask & LVCF_TEXT) && col->pszText && col->cchTextMax > 0)
		{
			const size_t n = std::min<size_t>(c.text.size(), col->cchTextMax - 1);
			std::copy_n(c.text.data(), n, col->pszText);
			col->pszText[n] = 0;
		}
		return TRUE;
	}
	case LVM_SETCOLUMNW:
	case LVM_SETCOLUMNA:
	{
		const auto *col = (const LVCOLUMNW *)lParam;
		if(!col || wParam >= ld.columns.size()) return FALSE;
		ListColumn &c = ld.columns[wParam];
		if(col->mask & LVCF_WIDTH) c.width = col->cx;
		if(col->mask & LVCF_FMT) c.fmt = col->fmt;
		if((col->mask & LVCF_TEXT) && col->pszText) c.text = col->pszText;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_GETCOLUMNWIDTH:
		return wParam < ld.columns.size() ? ld.columns[wParam].width : 0;
	case LVM_SETCOLUMNWIDTH:
	{
		if(wParam >= ld.columns.size()) return FALSE;
		const int cx = (short)LOWORD(lParam);
		if(cx == LVSCW_AUTOSIZE) ld.columns[wParam].width = AutoColumnWidth(hWnd, ld, (int)wParam, false);
		else if(cx == LVSCW_AUTOSIZE_USEHEADER)
		{
			// The last column fills the remaining width, as on Windows.
			if(wParam + 1 == ld.columns.size())
			{
				RECT header, rowsArea, vbar, hbar;
				int rowHeight;
				std::vector<ListRow> rows;
				ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
				const int others = TotalColumnWidth(ld) - ld.columns[wParam].width;
				ld.columns[wParam].width = std::max(AutoColumnWidth(hWnd, ld, (int)wParam, true), (int)(rowsArea.right - rowsArea.left) - others);
			} else ld.columns[wParam].width = AutoColumnWidth(hWnd, ld, (int)wParam, true);
		} else ld.columns[wParam].width = cx;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_GETITEMRECT:
	case LVM_GETSUBITEMRECT:
	{
		auto *rect = (RECT *)lParam;
		if(!rect) return FALSE;
		RECT header, rowsArea, vbar, hbar;
		int rowHeight;
		std::vector<ListRow> rows;
		ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
		int r = 0;
		for(; r < (int)rows.size() && rows[r].item != (int)wParam; r++) {}
		if(r == (int)rows.size()) return FALSE;
		const int y = rowsArea.top + (r - ld.vscroll.pos) * rowHeight;
		if(msg == LVM_GETSUBITEMRECT && rect->top > 0) *rect = ColumnRect(ld, rect->top, rowsArea, y, y + rowHeight);
		else
		{
			const RECT first = ColumnRect(ld, 0, rowsArea, y, y + rowHeight);
			*rect = RECT{first.left, y, rowsArea.left - ld.hscroll.pos + std::max(TotalColumnWidth(ld), (int)(rowsArea.right - rowsArea.left)), y + rowHeight};
			if(msg == LVM_GETITEMRECT && (rect->left == LVIR_LABEL || rect->left == LVIR_ICON)) rect->right = first.right;
		}
		return TRUE;
	}
	case LVM_GETVIEWRECT:
	{
		auto *rect = (RECT *)lParam;
		if(!rect) return FALSE;
		const int rowHeight = ListRowHeight(hWnd, ld);
		*rect = RECT{0, 0, TotalColumnWidth(ld), (int)ListRows(hWnd, ld).size() * rowHeight + HeaderHeight(hWnd)};
		return TRUE;
	}
	case LVM_HITTEST:
	case LVM_SUBITEMHITTEST:
	{
		auto *hti = (LVHITTESTINFO *)lParam;
		if(!hti) return -1;
		int item, sub, group;
		ListHitTest(hWnd, ld, hti->pt, item, sub, group, hti->flags);
		hti->iItem = item;
		hti->iSubItem = std::max(sub, 0);
		hti->iGroup = group;
		return item;
	}
	case LVM_ENSUREVISIBLE:
		EnsureListVisible(hWnd, ld, (int)wParam);
		return TRUE;
	case LVM_SCROLL:
		ld.hscroll.pos += (int)wParam;
		ld.vscroll.pos += (int)lParam / std::max(1, ListRowHeight(hWnd, ld));
		ld.hscroll.Clamp();
		ld.vscroll.Clamp();
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case LVM_GETTOPINDEX:
		return ld.vscroll.pos;
	case LVM_GETCOUNTPERPAGE:
		return ld.vscroll.page;
	case LVM_REDRAWITEMS:
	case LVM_UPDATE:
	case LVM_ARRANGE:
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case LVM_SETEXTENDEDLISTVIEWSTYLE:
	{
		const DWORD old = ld.exStyle;
		const DWORD mask = wParam ? (DWORD)wParam : ~0u;
		ld.exStyle = (ld.exStyle & ~mask) | ((DWORD)lParam & mask);
		if((ld.exStyle & LVS_EX_CHECKBOXES) && !(old & LVS_EX_CHECKBOXES))
			for(auto &li : ld.items) if(!(li.state & LVIS_STATEIMAGEMASK)) li.state |= INDEXTOSTATEIMAGEMASK(1);
		InvalidateRect(hWnd, nullptr, FALSE);
		return old;
	}
	case LVM_GETEXTENDEDLISTVIEWSTYLE:
		return ld.exStyle;
	case LVM_SETIMAGELIST:
	{
		HIMAGELIST &slot = wParam == LVSIL_STATE ? ld.stateImages : ld.smallImages;
		HIMAGELIST old = slot;
		slot = (HIMAGELIST)lParam;
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)old;
	}
	case LVM_GETIMAGELIST:
		return (LRESULT)(wParam == LVSIL_STATE ? ld.stateImages : ld.smallImages);
	case LVM_SETBKCOLOR: ld.bk = (COLORREF)lParam; InvalidateRect(hWnd, nullptr, FALSE); return TRUE;
	case LVM_GETBKCOLOR: return ld.bk == CLR_NONE ? GetSysColor(COLOR_WINDOW) : ld.bk;
	case LVM_SETTEXTCOLOR: ld.text = (COLORREF)lParam; InvalidateRect(hWnd, nullptr, FALSE); return TRUE;
	case LVM_GETTEXTCOLOR: return ld.text == CLR_NONE ? GetSysColor(COLOR_WINDOWTEXT) : ld.text;
	case LVM_SETTEXTBKCOLOR: ld.textBk = (COLORREF)lParam; InvalidateRect(hWnd, nullptr, FALSE); return TRUE;
	case LVM_GETTEXTBKCOLOR: return ld.textBk;
	case LVM_SORTITEMS:
	case LVM_SORTITEMSEX:
	{
		auto compare = (PFNLVCOMPARE)lParam;
		if(!compare || OwnerData(hWnd)) return FALSE;
		std::vector<int> order(ld.items.size());
		for(size_t i = 0; i < order.size(); i++) order[i] = (int)i;
		// LVM_SORTITEMSEX passes item indices, LVM_SORTITEMS the items' lParams.
		std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
			return msg == LVM_SORTITEMSEX ? compare(a, b, (LPARAM)wParam) < 0 : compare(ld.items[a].lParam, ld.items[b].lParam, (LPARAM)wParam) < 0;
		});
		std::vector<ListItem> sorted;
		for(int i : order) sorted.push_back(ld.items[i]);
		ld.items = std::move(sorted);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case LVM_ENABLEGROUPVIEW:
	{
		const bool old = ld.groupView;
		ld.groupView = wParam != 0;
		InvalidateRect(hWnd, nullptr, FALSE);
		return old == ld.groupView ? 0 : 1;
	}
	case LVM_ISGROUPVIEWENABLED:
		return ld.groupView;
	case LVM_INSERTGROUP:
	{
		const auto *g = (const LVGROUP *)lParam;
		if(!g) return -1;
		ListGroup group;
		group.id = g->iGroupId;
		if((g->mask & LVGF_HEADER) && g->pszHeader) group.header = g->pszHeader;
		if(g->mask & LVGF_STATE) group.state = g->state & g->stateMask;
		const int index = ((int)wParam < 0 || (int)wParam > (int)ld.groups.size()) ? (int)ld.groups.size() : (int)wParam;
		ld.groups.insert(ld.groups.begin() + index, group);
		InvalidateRect(hWnd, nullptr, FALSE);
		return index;
	}
	case LVM_SETGROUPINFO:
	{
		const auto *g = (const LVGROUP *)lParam;
		for(auto &group : ld.groups)
		{
			if(group.id != (int)wParam || !g) continue;
			if((g->mask & LVGF_HEADER) && g->pszHeader) group.header = g->pszHeader;
			if(g->mask & LVGF_STATE) group.state = (group.state & ~g->stateMask) | (g->state & g->stateMask);
			InvalidateRect(hWnd, nullptr, FALSE);
			return group.id;
		}
		return -1;
	}
	case LVM_GETGROUPINFO:
	{
		auto *g = (LVGROUP *)lParam;
		for(const auto &group : ld.groups)
		{
			if(group.id != (int)wParam || !g) continue;
			if(g->mask & LVGF_STATE) g->state = group.state & g->stateMask;
			g->iGroupId = group.id;
			return group.id;
		}
		return -1;
	}
	case LVM_GETGROUPSTATE:
		for(const auto &group : ld.groups) if(group.id == (int)wParam) return group.state & (UINT)lParam;
		return 0;
	case LVM_REMOVEGROUP:
		std::erase_if(ld.groups, [&](const ListGroup &g) { return g.id == (int)wParam; });
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)ld.groups.size();
	case LVM_REMOVEALLGROUPS:
		ld.groups.clear();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case LVM_GETSTRINGWIDTHW:
	{
		HDC dc = GetDC(hWnd);
		SelectObject(dc, ControlFont(hWnd));
		SIZE s{};
		if(lParam) GetTextExtentPoint32W(dc, (LPCWSTR)lParam, (int)wcslen((LPCWSTR)lParam), &s);
		ReleaseDC(hWnd, dc);
		return s.cx;
	}
	case LVM_EDITLABELW:
	case LVM_EDITLABELA:
		BeginListLabelEdit(hWnd, ld, (int)wParam);
		return (LRESULT)ld.edit;
	case LVM_GETEDITCONTROL:
		return (LRESULT)ld.edit;
	case LVM_SETCOLUMNORDERARRAY:
	case LVM_SETHOTITEM:
	case LVM_SETTOOLTIPS:
	case LVM_SETCALLBACKMASK:
		return TRUE;
	case LVM_GETCALLBACKMASK:
		return 0;

	case WM_MOUSEWHEEL:
		ld.vscroll.pos += WheelLines(wParam);
		ld.vscroll.Clamp();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONDOWN:
	case WM_RBUTTONDOWN:
	{
		SetFocus(hWnd);
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		RECT header, rowsArea, vbar, hbar;
		int rowHeight;
		std::vector<ListRow> rows;
		ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
		if(msg == WM_LBUTTONDOWN && ld.vscroll.Needed() && PtInRect(&vbar, pt))
		{
			if(ScrollBarClick(ld.vscroll, ld.drag, vbar, pt, true, 1)) InvalidateRect(hWnd, nullptr, FALSE);
			if(ld.drag.active) SetCapture(hWnd);
			return 0;
		}
		if(msg == WM_LBUTTONDOWN && ld.hscroll.Needed() && PtInRect(&hbar, pt))
		{
			if(ScrollBarClick(ld.hscroll, ld.drag, hbar, pt, false, 20)) InvalidateRect(hWnd, nullptr, FALSE);
			if(ld.drag.active) SetCapture(hWnd);
			return 0;
		}
		if(PtInRect(&header, pt))
		{
			if(msg == WM_LBUTTONDOWN && !HasStyle(hWnd, LVS_NOSORTHEADER))
				for(int c = 0; c < (int)ld.columns.size(); c++)
				{
					const RECT col = ColumnRect(ld, c, rowsArea, header.top, header.bottom);
					if(pt.x < col.left || pt.x >= col.right) continue;
					NMLISTVIEW nm{};
					nm.iItem = -1;
					nm.iSubItem = c;
					SendNotify(hWnd, nm.hdr, LVN_COLUMNCLICK);
					break;
				}
			return 0;
		}
		int item, sub, group;
		UINT flags;
		ListHitTest(hWnd, ld, pt, item, sub, group, flags);
		if(item < 0 && group >= 0 && msg == WM_LBUTTONDOWN)
		{
			ListGroup &g = ld.groups[group];
			if(g.state & LVGS_COLLAPSIBLE) g.state ^= LVGS_COLLAPSED;
			InvalidateRect(hWnd, nullptr, FALSE);
			return 0;
		}
		if(item >= 0 && flags == LVHT_ONITEMSTATEICON && msg == WM_LBUTTONDOWN)
		{
			const UINT st = ListItemState(hWnd, ld, item);
			const UINT next = ((st & LVIS_STATEIMAGEMASK) >> 12) == 2 ? INDEXTOSTATEIMAGEMASK(1) : INDEXTOSTATEIMAGEMASK(2);
			ChangeListItemState(hWnd, ld, item, next, LVIS_STATEIMAGEMASK);
		} else if(item >= 0)
		{
			const bool ctrl = GetKeyState(VK_CONTROL) < 0, shift = GetKeyState(VK_SHIFT) < 0;
			const bool multi = !HasStyle(hWnd, LVS_SINGLESEL);
			if(multi && ctrl && msg == WM_LBUTTONDOWN)
			{
				const UINT st = ListItemState(hWnd, ld, item);
				ChangeListItemState(hWnd, ld, item, (st & LVIS_SELECTED) ? 0 : LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
				ld.selectionMark = item;
			} else if(multi && shift && ld.selectionMark >= 0 && msg == WM_LBUTTONDOWN)
			{
				const int a = std::min(ld.selectionMark, item), b = std::max(ld.selectionMark, item);
				for(int i = 0; i < ListCount(hWnd, ld); i++) ChangeListItemState(hWnd, ld, i, (i >= a && i <= b) ? LVIS_SELECTED : 0, LVIS_SELECTED);
			} else if(!(msg == WM_RBUTTONDOWN && (ListItemState(hWnd, ld, item) & LVIS_SELECTED)))
			{
				SelectOnly(hWnd, ld, item);
			}
			ld.pressItem = item;
			ld.pressPoint = pt;
		} else if(msg == WM_LBUTTONDOWN && !HasStyle(hWnd, LVS_SINGLESEL))
		{
			SelectOnly(hWnd, ld, -1);
		}
		if(!g_lists.count(hWnd)) return 0;
		NotifyItemActivate(hWnd, msg == WM_LBUTTONDOWN ? NM_CLICK : NM_RCLICK, item, std::max(sub, 0), pt);
		if(msg == WM_RBUTTONDOWN && g_lists.count(hWnd))
		{
			POINT screen = pt;
			ClientToScreen(hWnd, &screen);
			SendMessageW(GetParent(hWnd), WM_CONTEXTMENU, (WPARAM)hWnd, MAKELPARAM(screen.x, screen.y));
		}
		if(msg == WM_LBUTTONDOWN) SetCapture(hWnd);
		return 0;
	}
	case WM_MOUSEMOVE:
	{
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		if(ld.drag.active)
		{
			RECT header, rowsArea, vbar, hbar;
			int rowHeight;
			std::vector<ListRow> rows;
			ListLayout(hWnd, ld, header, rowsArea, vbar, hbar, rowHeight, rows);
			if(ScrollBarDrag(ld.drag.vertical ? ld.vscroll : ld.hscroll, ld.drag, ld.drag.vertical ? vbar : hbar, pt)) InvalidateRect(hWnd, nullptr, FALSE);
			return 0;
		}
		if(ld.pressItem >= 0 && (wParam & MK_LBUTTON) && (std::abs(pt.x - ld.pressPoint.x) > 4 || std::abs(pt.y - ld.pressPoint.y) > 4))
		{
			NMLISTVIEW nm{};
			nm.iItem = ld.pressItem;
			nm.ptAction = pt;
			ld.pressItem = -1;
			ReleaseCapture();
			SendNotify(hWnd, nm.hdr, LVN_BEGINDRAG);
		}
		return 0;
	}
	case WM_LBUTTONUP:
		ld.drag.active = false;
		ld.pressItem = -1;
		if(GetCapture() == hWnd) ReleaseCapture();
		return 0;
	case WM_LBUTTONDBLCLK:
	{
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		int item, sub, group;
		UINT flags;
		ListHitTest(hWnd, ld, pt, item, sub, group, flags);
		NotifyItemActivate(hWnd, NM_DBLCLK, item, std::max(sub, 0), pt);
		if(item >= 0 && g_lists.count(hWnd)) NotifyItemActivate(hWnd, LVN_ITEMACTIVATE, item, std::max(sub, 0), pt);
		return 0;
	}
	case WM_KEYDOWN:
	{
		NMLVKEYDOWN kd{};
		kd.wVKey = (WORD)wParam;
		SendNotify(hWnd, kd.hdr, LVN_KEYDOWN);
		if(!g_lists.count(hWnd)) return 0;
		const auto rows = ListRows(hWnd, ld);
		int focus = -1;
		for(int i = 0; i < ListCount(hWnd, ld); i++) if(ListItemState(hWnd, ld, i) & LVIS_FOCUSED) { focus = i; break; }
		int r = 0;
		for(; r < (int)rows.size() && rows[r].item != focus; r++) {}
		auto findItemRow = [&](int start, int step) {
			for(int k = start; k >= 0 && k < (int)rows.size(); k += step) if(rows[k].item >= 0) return rows[k].item;
			return -1;
		};
		int target = -1;
		switch(wParam)
		{
		case VK_UP: target = findItemRow(focus < 0 ? 0 : r - 1, focus < 0 ? 1 : -1); break;
		case VK_DOWN: target = findItemRow(focus < 0 ? 0 : r + 1, 1); break;
		case VK_HOME: target = findItemRow(0, 1); break;
		case VK_END: target = findItemRow((int)rows.size() - 1, -1); break;
		case VK_PRIOR: target = findItemRow(std::max(0, r - ld.vscroll.page), 1); break;
		case VK_NEXT: target = findItemRow(std::min<int>((int)rows.size() - 1, r + ld.vscroll.page), -1); break;
		case VK_SPACE:
			if((ld.exStyle & LVS_EX_CHECKBOXES) && focus >= 0)
			{
				const UINT st = ListItemState(hWnd, ld, focus);
				ChangeListItemState(hWnd, ld, focus, ((st & LVIS_STATEIMAGEMASK) >> 12) == 2 ? INDEXTOSTATEIMAGEMASK(1) : INDEXTOSTATEIMAGEMASK(2), LVIS_STATEIMAGEMASK);
			}
			break;
		case 'A':
			if(GetKeyState(VK_CONTROL) < 0 && !HasStyle(hWnd, LVS_SINGLESEL))
				for(int i = 0; i < ListCount(hWnd, ld); i++) ChangeListItemState(hWnd, ld, i, LVIS_SELECTED, LVIS_SELECTED);
			break;
		case VK_RETURN:
			if(focus >= 0) NotifyItemActivate(hWnd, LVN_ITEMACTIVATE, focus, 0, POINT{0, 0});
			{
				NMHDR hdr{};
				if(g_lists.count(hWnd)) SendNotify(hWnd, hdr, NM_RETURN);
			}
			break;
		case VK_F2:
			if(HasStyle(hWnd, LVS_EDITLABELS) && focus >= 0) BeginListLabelEdit(hWnd, ld, focus);
			break;
		}
		if(target >= 0 && g_lists.count(hWnd))
		{
			SelectOnly(hWnd, ld, target);
			EnsureListVisible(hWnd, ld, target);
		}
		return 0;
	}
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// List box (LISTBOX); also the drop-down list of combo boxes (ComboLBox)
// ---------------------------------------------------------------------------------------------

struct ListBoxItem
{
	std::wstring text;
	DWORD_PTR data = 0;
	bool selected = false;
};

struct ListBoxData
{
	std::vector<ListBoxItem> items;
	int curSel = -1;   // single selection / caret
	int anchor = -1;
	int itemHeight = 0;
	ScrollBar vscroll;
	ScrollDrag drag;
	HWND comboOwner = nullptr;  // set for a combo box's drop-down list
	bool tracking = false;
};

std::map<HWND, ListBoxData> g_listBoxes;

DWORD ListBoxStyle(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? rec->style : 0;
}

bool MultiSelect(HWND hWnd) { return ListBoxStyle(hWnd) & (LBS_MULTIPLESEL | LBS_EXTENDEDSEL); }
bool OwnerDrawList(HWND hWnd) { return ListBoxStyle(hWnd) & (LBS_OWNERDRAWFIXED | LBS_OWNERDRAWVARIABLE); }

int ListBoxItemHeight(HWND hWnd, ListBoxData &lb)
{
	if(lb.itemHeight > 0) return lb.itemHeight;
	if(OwnerDrawList(hWnd))
	{
		// Owner-drawn lists ask their parent once, like Windows does at creation.
		MEASUREITEMSTRUCT mis{};
		mis.CtlType = ODT_LISTBOX;
		mis.CtlID = (UINT)GetDlgCtrlID(hWnd);
		mis.itemHeight = (UINT)(ListLineHeight(hWnd) + 2);
		SendMessageW(GetParent(hWnd), WM_MEASUREITEM, mis.CtlID, (LPARAM)&mis);
		lb.itemHeight = std::max<int>(1, (int)mis.itemHeight);
		return lb.itemHeight;
	}
	return ListLineHeight(hWnd) + 2;
}

void ListBoxLayout(HWND hWnd, ListBoxData &lb, RECT &rowsArea, RECT &vbar, int &itemHeight)
{
	GetClientRect(hWnd, &rowsArea);
	if(ListBoxStyle(hWnd) & WS_BORDER) InflateRect(&rowsArea, -1, -1);
	itemHeight = ListBoxItemHeight(hWnd, lb);
	lb.vscroll.total = (int)lb.items.size();
	lb.vscroll.page = std::max(1, (int)(rowsArea.bottom - rowsArea.top) / itemHeight);
	vbar = RECT{0, 0, 0, 0};
	if(lb.vscroll.Needed() || (ListBoxStyle(hWnd) & LBS_DISABLENOSCROLL))
	{
		vbar = RECT{rowsArea.right - kScrollSize, rowsArea.top, rowsArea.right, rowsArea.bottom};
		rowsArea.right -= kScrollSize;
	}
	lb.vscroll.Clamp();
}

void NotifyListBox(HWND hWnd, UINT code)
{
	ListBoxData &lb = g_listBoxes[hWnd];
	if(lb.comboOwner)
	{
		SendMessageW(lb.comboOwner, WM_USER + 0x7000, code, (LPARAM)hWnd);  // internal: drop-down list event
		return;
	}
	if(ListBoxStyle(hWnd) & LBS_NOTIFY)
	{
		WindowRecord *rec = GetWindowRecord(hWnd);
		if(rec && rec->parent) SendMessageW(rec->parent, WM_COMMAND, MAKEWPARAM((WORD)rec->id, (WORD)code), (LPARAM)hWnd);
	}
}

void PaintListBox(HWND hWnd, ListBoxData &lb)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client, rowsArea, vbar;
	GetClientRect(hWnd, &client);
	int itemHeight;
	ListBoxLayout(hWnd, lb, rowsArea, vbar, itemHeight);
	WindowRecord *rec = GetWindowRecord(hWnd);
	const bool enabled = !rec || rec->isEnabled;
	// Like Windows, the parent picks the background through WM_CTLCOLORLISTBOX.
	SetBkMode(dc, TRANSPARENT);
	SetTextColor(dc, GetSysColor(enabled ? COLOR_WINDOWTEXT : COLOR_GRAYTEXT));
	SelectObject(dc, ControlFont(hWnd));
	HBRUSH brush = lb.comboOwner ? nullptr : (HBRUSH)SendMessageW(GetParent(hWnd), WM_CTLCOLORLISTBOX, (WPARAM)dc, (LPARAM)hWnd);
	if(brush) FillRect(dc, &client, brush);
	else FillSolid(dc, client, GetSysColor(COLOR_WINDOW));
	const COLORREF textColor = GetTextColor(dc);
	const bool focused = IsFocused(hWnd) || lb.comboOwner;
	CGContextRef ctx = dc->cgContext;
	if(ctx)
	{
		CGContextSaveGState(ctx);
		CGContextClipToRect(ctx, CGRectMake(rowsArea.left + dc->viewportOrg.x, rowsArea.top + dc->viewportOrg.y, rowsArea.right - rowsArea.left, rowsArea.bottom - rowsArea.top));
	}
	for(int i = lb.vscroll.pos; i < (int)lb.items.size(); i++)
	{
		const int y = rowsArea.top + (i - lb.vscroll.pos) * itemHeight;
		if(y >= rowsArea.bottom) break;
		const RECT row{rowsArea.left, y, rowsArea.right, y + itemHeight};
		const bool selected = MultiSelect(hWnd) ? lb.items[i].selected : i == lb.curSel;
		if(OwnerDrawList(hWnd))
		{
			DRAWITEMSTRUCT dis{};
			dis.CtlType = ODT_LISTBOX;
			dis.CtlID = (UINT)GetDlgCtrlID(hWnd);
			dis.itemID = (UINT)i;
			dis.itemAction = ODA_DRAWENTIRE;
			dis.itemState = (selected ? ODS_SELECTED : 0) | (enabled ? 0 : ODS_DISABLED) | (focused && i == lb.curSel ? ODS_FOCUS : 0);
			dis.hwndItem = hWnd;
			dis.hDC = dc;
			dis.rcItem = row;
			dis.itemData = lb.items[i].data;
			SendMessageW(GetParent(hWnd), WM_DRAWITEM, dis.CtlID, (LPARAM)&dis);
			continue;
		}
		if(selected)
		{
			FillSolid(dc, row, focused ? GetSysColor(COLOR_HIGHLIGHT) : GetSysColor(COLOR_BTNFACE));
			SetTextColor(dc, focused ? GetSysColor(COLOR_HIGHLIGHTTEXT) : textColor);
		} else
		{
			SetTextColor(dc, textColor);
		}
		RECT textRect{row.left + 3, row.top, row.right - 2, row.bottom};
		DrawTextW(dc, lb.items[i].text.c_str(), (int)lb.items[i].text.size(), &textRect, DT_LEFT | DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX | DT_EXPANDTABS);
	}
	if(ctx) CGContextRestoreGState(ctx);
	if(vbar.right > vbar.left) DrawScrollBar(dc, vbar, lb.vscroll, true);
	if(ListBoxStyle(hWnd) & WS_BORDER) Outline(dc, client, lb.comboOwner ? RGB(100, 100, 100) : RGB(130, 135, 144));
	EndPaint(hWnd, &ps);
}

int ListBoxIndexAt(HWND hWnd, ListBoxData &lb, POINT pt, bool clampToItems)
{
	RECT rowsArea, vbar;
	int itemHeight;
	ListBoxLayout(hWnd, lb, rowsArea, vbar, itemHeight);
	if(!clampToItems && !PtInRect(&rowsArea, pt)) return -1;
	int i = lb.vscroll.pos + (int)std::floor((pt.y - rowsArea.top) / (double)itemHeight);
	if(clampToItems) i = std::clamp(i, 0, (int)lb.items.size() - 1);
	return (i >= 0 && i < (int)lb.items.size()) ? i : -1;
}

void EnsureListBoxVisible(HWND hWnd, ListBoxData &lb, int i)
{
	RECT rowsArea, vbar;
	int itemHeight;
	ListBoxLayout(hWnd, lb, rowsArea, vbar, itemHeight);
	if(i < 0) return;
	if(i < lb.vscroll.pos) lb.vscroll.pos = i;
	else if(i >= lb.vscroll.pos + lb.vscroll.page) lb.vscroll.pos = i - lb.vscroll.page + 1;
	lb.vscroll.Clamp();
}

int FindListString(const std::vector<std::wstring> &texts, int start, LPCWSTR text, bool exact)
{
	if(!text) return -1;
	const size_t n = texts.size();
	const size_t prefix = wcslen(text);
	for(size_t k = 1; k <= n; k++)
	{
		const size_t i = (size_t)(start + (int)k) % n;
		const std::wstring &t = texts[i];
		if(exact ? lstrcmpiW(t.c_str(), text) == 0 : (t.size() >= prefix && CompareStringW(0, NORM_IGNORECASE, t.c_str(), (int)prefix, text, (int)prefix) == 2)) return (int)i;
	}
	return -1;
}

std::vector<std::wstring> ListBoxTexts(const ListBoxData &lb)
{
	std::vector<std::wstring> texts;
	for(const auto &item : lb.items) texts.push_back(item.text);
	return texts;
}

int InsertListBoxString(HWND hWnd, ListBoxData &lb, int index, LPCWSTR text, bool sorted)
{
	ListBoxItem item;
	const bool hasStrings = !OwnerDrawList(hWnd) || (ListBoxStyle(hWnd) & LBS_HASSTRINGS);
	if(hasStrings) item.text = text ? text : L"";
	else item.data = (DWORD_PTR)text;
	if(sorted && hasStrings)
	{
		index = 0;
		while(index < (int)lb.items.size() && lstrcmpiW(lb.items[index].text.c_str(), item.text.c_str()) <= 0) index++;
	} else if(index < 0 || index > (int)lb.items.size())
	{
		index = (int)lb.items.size();
	}
	lb.items.insert(lb.items.begin() + index, item);
	if(lb.curSel >= index) lb.curSel++;
	InvalidateRect(hWnd, nullptr, FALSE);
	return index;
}

LRESULT CALLBACK ListBoxProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	ListBoxData &lb = g_listBoxes[hWnd];
	const bool sorted = ListBoxStyle(hWnd) & LBS_SORT;
	switch(msg)
	{
	case WM_NCDESTROY:
		g_listBoxes.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintListBox(hWnd, lb);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS | DLGC_WANTCHARS;
	case WM_SETFOCUS:
	case WM_KILLFOCUS:
		InvalidateRect(hWnd, nullptr, FALSE);
		NotifyListBox(hWnd, msg == WM_SETFOCUS ? LBN_SETFOCUS : LBN_KILLFOCUS);
		return 0;
	case WM_SETFONT:
		lb.itemHeight = 0;
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	case LB_ADDSTRING:
		return InsertListBoxString(hWnd, lb, -1, (LPCWSTR)lParam, sorted);
	case LB_INSERTSTRING:
		return InsertListBoxString(hWnd, lb, (int)wParam, (LPCWSTR)lParam, false);
	case LB_DELETESTRING:
		if(wParam >= lb.items.size()) return LB_ERR;
		lb.items.erase(lb.items.begin() + wParam);
		if(lb.curSel == (int)wParam) lb.curSel = -1;
		else if(lb.curSel > (int)wParam) lb.curSel--;
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)lb.items.size();
	case LB_RESETCONTENT:
		lb.items.clear();
		lb.curSel = lb.anchor = -1;
		lb.vscroll.pos = 0;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case LB_GETCOUNT:
		return (LRESULT)lb.items.size();
	case LB_GETCURSEL:
		if(MultiSelect(hWnd)) return lb.curSel;  // caret, as on Windows
		return lb.curSel;
	case LB_SETCURSEL:
		if(MultiSelect(hWnd)) return LB_ERR;
		lb.curSel = ((int)wParam >= 0 && wParam < lb.items.size()) ? (int)wParam : -1;
		EnsureListBoxVisible(hWnd, lb, lb.curSel);
		InvalidateRect(hWnd, nullptr, FALSE);
		return lb.curSel < 0 && (int)wParam != -1 ? LB_ERR : lb.curSel;
	case LB_GETSEL:
		if(wParam >= lb.items.size()) return LB_ERR;
		return MultiSelect(hWnd) ? lb.items[wParam].selected : (int)wParam == lb.curSel;
	case LB_SETSEL:
		if(!MultiSelect(hWnd)) return LB_ERR;
		if((int)lParam == -1) for(auto &item : lb.items) item.selected = wParam != 0;
		else if((size_t)lParam < lb.items.size()) lb.items[lParam].selected = wParam != 0;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case LB_GETSELCOUNT:
		if(!MultiSelect(hWnd)) return LB_ERR;
		return std::count_if(lb.items.begin(), lb.items.end(), [](const ListBoxItem &i) { return i.selected; });
	case LB_GETSELITEMS:
	{
		if(!MultiSelect(hWnd)) return LB_ERR;
		int *out = (int *)lParam;
		int n = 0;
		for(int i = 0; i < (int)lb.items.size() && n < (int)wParam; i++)
			if(lb.items[i].selected) out[n++] = i;
		return n;
	}
	case LB_SELITEMRANGE:
	case LB_SELITEMRANGEEX:
	{
		int a = LOWORD(lParam), b = HIWORD(lParam);
		bool select = wParam != 0;
		if(msg == LB_SELITEMRANGEEX) { a = (int)wParam; b = (int)lParam; select = b >= a; if(!select) std::swap(a, b); }
		for(int i = std::max(0, std::min(a, b)); i <= std::max(a, b) && i < (int)lb.items.size(); i++) lb.items[i].selected = select;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	}
	case LB_GETTEXT:
		if(wParam >= lb.items.size()) return LB_ERR;
		if(OwnerDrawList(hWnd) && !(ListBoxStyle(hWnd) & LBS_HASSTRINGS)) { *(DWORD_PTR *)lParam = lb.items[wParam].data; return sizeof(DWORD_PTR); }
		std::copy(lb.items[wParam].text.begin(), lb.items[wParam].text.end(), (wchar_t *)lParam);
		((wchar_t *)lParam)[lb.items[wParam].text.size()] = 0;
		return (LRESULT)lb.items[wParam].text.size();
	case LB_GETTEXTLEN:
		return wParam < lb.items.size() ? (LRESULT)lb.items[wParam].text.size() : LB_ERR;
	case LB_GETITEMDATA:
		return wParam < lb.items.size() ? (LRESULT)lb.items[wParam].data : LB_ERR;
	case LB_SETITEMDATA:
		if(wParam >= lb.items.size()) return LB_ERR;
		lb.items[wParam].data = (DWORD_PTR)lParam;
		return TRUE;
	case LB_FINDSTRING:
	case LB_FINDSTRINGEXACT:
		return FindListString(ListBoxTexts(lb), (int)wParam, (LPCWSTR)lParam, msg == LB_FINDSTRINGEXACT);
	case LB_SELECTSTRING:
	{
		const int i = FindListString(ListBoxTexts(lb), (int)wParam, (LPCWSTR)lParam, false);
		if(i >= 0) SendMessageW(hWnd, LB_SETCURSEL, i, 0);
		return i;
	}
	case LB_GETTOPINDEX:
		return lb.vscroll.pos;
	case LB_SETTOPINDEX:
		lb.vscroll.pos = (int)wParam;
		lb.vscroll.Clamp();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case LB_GETITEMHEIGHT:
		return ListBoxItemHeight(hWnd, lb);
	case LB_SETITEMHEIGHT:
		lb.itemHeight = std::max<int>(1, LOWORD(lParam));
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case LB_GETITEMRECT:
	{
		RECT rowsArea, vbar;
		int itemHeight;
		ListBoxLayout(hWnd, lb, rowsArea, vbar, itemHeight);
		if(wParam >= lb.items.size() || !lParam) return LB_ERR;
		const int y = rowsArea.top + ((int)wParam - lb.vscroll.pos) * itemHeight;
		*(RECT *)lParam = RECT{rowsArea.left, y, rowsArea.right, y + itemHeight};
		return 1;
	}
	case LB_ITEMFROMPOINT:
	{
		const int i = ListBoxIndexAt(hWnd, lb, POINT{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)}, false);
		return i >= 0 ? MAKELONG(i, 0) : MAKELONG(0xFFFF, 1);
	}
	case LB_SETCARETINDEX:
		lb.curSel = (int)wParam;
		EnsureListBoxVisible(hWnd, lb, lb.curSel);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case LB_GETCARETINDEX:
		return lb.curSel;
	case LB_SETHORIZONTALEXTENT:
	case LB_INITSTORAGE:
	case LB_SETTABSTOPS:
	case LB_SETCOLUMNWIDTH:
		return 0;
	case WM_MOUSEWHEEL:
		lb.vscroll.pos += WheelLines(wParam);
		lb.vscroll.Clamp();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
	{
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		RECT rowsArea, vbar;
		int itemHeight;
		ListBoxLayout(hWnd, lb, rowsArea, vbar, itemHeight);
		if(vbar.right > vbar.left && PtInRect(&vbar, pt))
		{
			if(ScrollBarClick(lb.vscroll, lb.drag, vbar, pt, true, 1)) InvalidateRect(hWnd, nullptr, FALSE);
			if(lb.drag.active) SetCapture(hWnd);
			return 0;
		}
		if(!lb.comboOwner) SetFocus(hWnd);
		const int i = ListBoxIndexAt(hWnd, lb, pt, false);
		if(i < 0) return 0;
		if(msg == WM_LBUTTONDBLCLK && !lb.comboOwner)
		{
			NotifyListBox(hWnd, LBN_DBLCLK);
			return 0;
		}
		const DWORD style = ListBoxStyle(hWnd);
		if(style & LBS_MULTIPLESEL) lb.items[i].selected = !lb.items[i].selected;
		else if(style & LBS_EXTENDEDSEL)
		{
			if(GetKeyState(VK_SHIFT) < 0 && lb.anchor >= 0)
				for(int k = 0; k < (int)lb.items.size(); k++) lb.items[k].selected = k >= std::min(lb.anchor, i) && k <= std::max(lb.anchor, i);
			else if(GetKeyState(VK_CONTROL) < 0) { lb.items[i].selected = !lb.items[i].selected; lb.anchor = i; }
			else { for(auto &item : lb.items) item.selected = false; lb.items[i].selected = true; lb.anchor = i; }
		}
		lb.curSel = i;
		lb.tracking = true;
		SetCapture(hWnd);
		InvalidateRect(hWnd, nullptr, FALSE);
		if(!lb.comboOwner) NotifyListBox(hWnd, LBN_SELCHANGE);
		return 0;
	}
	case WM_MOUSEMOVE:
	{
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		if(lb.drag.active)
		{
			RECT rowsArea, vbar;
			int itemHeight;
			ListBoxLayout(hWnd, lb, rowsArea, vbar, itemHeight);
			if(ScrollBarDrag(lb.vscroll, lb.drag, vbar, pt)) InvalidateRect(hWnd, nullptr, FALSE);
			return 0;
		}
		// Drop-down lists highlight the item under the mouse; normal lists drag the selection.
		if((lb.comboOwner || (lb.tracking && !MultiSelect(hWnd))) && !lb.items.empty())
		{
			const int i = ListBoxIndexAt(hWnd, lb, pt, lb.tracking);
			if(i >= 0 && i != lb.curSel)
			{
				lb.curSel = i;
				InvalidateRect(hWnd, nullptr, FALSE);
				if(!lb.comboOwner) NotifyListBox(hWnd, LBN_SELCHANGE);
			}
		}
		return 0;
	}
	case WM_LBUTTONUP:
	{
		const bool wasTracking = lb.tracking;
		lb.tracking = false;
		lb.drag.active = false;
		if(GetCapture() == hWnd) ReleaseCapture();
		if(lb.comboOwner && wasTracking) NotifyListBox(hWnd, CBN_SELENDOK);
		return 0;
	}
	case WM_KEYDOWN:
	{
		if(lb.items.empty()) return 0;
		int i = lb.curSel;
		switch(wParam)
		{
		case VK_UP: i = std::max(0, i - 1); break;
		case VK_DOWN: i = std::min((int)lb.items.size() - 1, i + 1); break;
		case VK_HOME: i = 0; break;
		case VK_END: i = (int)lb.items.size() - 1; break;
		case VK_PRIOR: i = std::max(0, i - lb.vscroll.page); break;
		case VK_NEXT: i = std::min((int)lb.items.size() - 1, i + lb.vscroll.page); break;
		case VK_SPACE:
			if(MultiSelect(hWnd) && i >= 0) { lb.items[i].selected = !lb.items[i].selected; InvalidateRect(hWnd, nullptr, FALSE); NotifyListBox(hWnd, LBN_SELCHANGE); }
			return 0;
		case VK_RETURN:
			if(lb.comboOwner) NotifyListBox(hWnd, CBN_SELENDOK);
			return 0;
		case VK_ESCAPE:
			if(lb.comboOwner) NotifyListBox(hWnd, CBN_SELENDCANCEL);
			return 0;
		default:
			return 0;
		}
		if(i == lb.curSel) return 0;
		lb.curSel = i;
		if(ListBoxStyle(hWnd) & LBS_EXTENDEDSEL) { for(auto &item : lb.items) item.selected = false; lb.items[i].selected = true; lb.anchor = i; }
		EnsureListBoxVisible(hWnd, lb, i);
		InvalidateRect(hWnd, nullptr, FALSE);
		if(!lb.comboOwner) NotifyListBox(hWnd, LBN_SELCHANGE);
		return 0;
	}
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Combo box (COMBOBOX, ComboBoxEx32)
// ---------------------------------------------------------------------------------------------

constexpr UINT WM_COMBO_LIST_EVENT = WM_USER + 0x7000;
constexpr int kComboButton = 17;

struct ComboItem
{
	std::wstring text;
	DWORD_PTR data = 0;
	int image = -1;
};

struct ComboData
{
	std::vector<ComboItem> items;
	int curSel = -1;
	int droppedHeight = 100;
	int droppedWidth = 0;
	int minVisible = 30;
	HWND edit = nullptr;
	HWND popup = nullptr;
	id monitor = nil;
	bool hot = false;
	bool extended = false;  // ComboBoxEx32
	HIMAGELIST images = nullptr;
};

std::map<HWND, ComboData> g_combos;

DWORD ComboType(HWND hWnd) { return ListBoxStyle(hWnd) & 3; }  // CBS_SIMPLE / CBS_DROPDOWN / CBS_DROPDOWNLIST

void NotifyCombo(HWND hWnd, UINT code)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(rec && rec->parent) SendMessageW(rec->parent, WM_COMMAND, MAKEWPARAM((WORD)rec->id, (WORD)code), (LPARAM)hWnd);
}

std::wstring ComboText(ComboData &cd)
{
	if(cd.edit) return EditText(cd.edit);
	return (cd.curSel >= 0 && cd.curSel < (int)cd.items.size()) ? cd.items[cd.curSel].text : std::wstring();
}

void CloseDropDown(HWND hWnd, ComboData &cd, bool accept)
{
	if(!cd.popup) return;
	if(cd.monitor) { [NSEvent removeMonitor:cd.monitor]; cd.monitor = nil; }
	const int selected = g_listBoxes.count(cd.popup) ? g_listBoxes[cd.popup].curSel : -1;
	HWND popup = cd.popup;
	cd.popup = nullptr;
	DestroyWindow(popup);
	const int old = cd.curSel;
	if(accept && selected >= 0)
	{
		cd.curSel = selected;
		if(cd.edit) SetWindowTextW(cd.edit, cd.items[selected].text.c_str());
	}
	InvalidateRect(hWnd, nullptr, FALSE);
	NotifyCombo(hWnd, CBN_CLOSEUP);
	if(accept && cd.curSel != old) NotifyCombo(hWnd, CBN_SELCHANGE);
	NotifyCombo(hWnd, accept ? CBN_SELENDOK : CBN_SELENDCANCEL);
}

// The drop-down is an owned popup list box below the combo, like the Windows ComboLBox.
void ShowDropDown(HWND hWnd, ComboData &cd)
{
	if(cd.popup || cd.items.empty()) return;
	NotifyCombo(hWnd, CBN_DROPDOWN);
	RECT window;
	GetWindowRect(hWnd, &window);
	const int itemHeight = ListLineHeight(hWnd) + 2;
	const int visible = std::min<int>((int)cd.items.size(), std::max(cd.minVisible, std::max(1, cd.droppedHeight / itemHeight)));
	const int width = std::max<int>(window.right - window.left, cd.droppedWidth);
	HWND owner = hWnd;
	while(HWND parent = GetParent(owner)) owner = parent;
	cd.popup = CreateWindowExW(WS_EX_TOOLWINDOW, L"ComboLBox", L"", WS_POPUP | WS_BORDER | WS_VISIBLE | LBS_NOTIFY,
		window.left, window.bottom, width, visible * itemHeight + 2, owner, nullptr, nullptr, nullptr);
	ListBoxData &lb = g_listBoxes[cd.popup];
	lb.comboOwner = hWnd;
	lb.itemHeight = itemHeight;
	SendMessageW(cd.popup, WM_SETFONT, (WPARAM)ControlFont(hWnd), FALSE);
	for(const auto &item : cd.items) InsertListBoxString(cd.popup, lb, -1, item.text.c_str(), false);
	lb.curSel = cd.curSel;
	EnsureListBoxVisible(cd.popup, lb, cd.curSel);
	// Close on clicks outside the list and steer it with the keyboard (Windows does this with capture).
	WindowRecord *popupRec = GetWindowRecord(cd.popup);
	NSWindow *popupWindow = popupRec ? (NSWindow *)popupRec->nsWindow : nil;
	cd.monitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown | NSEventMaskKeyDown)
		handler:^NSEvent *(NSEvent *event) {
			auto it = g_combos.find(hWnd);
			if(it == g_combos.end() || !it->second.popup) return event;
			if(event.type == NSEventTypeKeyDown)
			{
				const unsigned short key = event.keyCode;
				const WPARAM vk = key == kVK_UpArrow ? VK_UP : key == kVK_DownArrow ? VK_DOWN : key == kVK_Return ? VK_RETURN : key == kVK_Escape ? VK_ESCAPE : key == kVK_PageUp ? VK_PRIOR : key == kVK_PageDown ? VK_NEXT : 0;
				if(vk) { SendMessageW(it->second.popup, WM_KEYDOWN, vk, 0); return nil; }
				return event;
			}
			if(event.window != popupWindow) CloseDropDown(hWnd, it->second, false);
			return event;
		}];
	InvalidateRect(hWnd, nullptr, FALSE);
}

void PaintCombo(HWND hWnd, ComboData &cd)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client;
	GetClientRect(hWnd, &client);
	WindowRecord *rec = GetWindowRecord(hWnd);
	const bool enabled = !rec || rec->isEnabled;
	const bool open = cd.popup != nullptr;
	SelectObject(dc, ControlFont(hWnd));
	SetBkMode(dc, TRANSPARENT);
	if(ComboType(hWnd) == CBS_DROPDOWNLIST)
	{
		// Windows 10 drop-down lists look like push buttons.
		COLORREF fill = RGB(225, 225, 225), border = RGB(173, 173, 173);
		if(!enabled) { fill = RGB(204, 204, 204); border = RGB(191, 191, 191); }
		else if(open) { fill = RGB(204, 228, 247); border = RGB(0, 84, 153); }
		else if(cd.hot || IsFocused(hWnd)) { fill = RGB(229, 241, 251); border = RGB(0, 120, 215); }
		FillSolid(dc, client, fill);
		Outline(dc, client, border);
		int textLeft = client.left + 4;
		if(cd.extended && cd.images && cd.curSel >= 0 && cd.items[cd.curSel].image >= 0)
		{
			int w = 0, h = 0;
			ImageList_GetIconSize(cd.images, &w, &h);
			ImageList_Draw(cd.images, cd.items[cd.curSel].image, dc, textLeft, (client.top + client.bottom - h) / 2, ILD_NORMAL);
			textLeft += w + 3;
		}
		const std::wstring text = ComboText(cd);
		SetTextColor(dc, GetSysColor(enabled ? COLOR_BTNTEXT : COLOR_GRAYTEXT));
		RECT textRect{textLeft, client.top, client.right - kComboButton, client.bottom};
		DrawTextW(dc, text.c_str(), (int)text.size(), &textRect, DT_LEFT | DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX | DT_END_ELLIPSIS);
	} else
	{
		HBRUSH brush = (HBRUSH)SendMessageW(GetParent(hWnd), WM_CTLCOLOREDIT, (WPARAM)dc, (LPARAM)hWnd);
		if(brush) FillRect(dc, &client, brush);
		else FillSolid(dc, client, GetSysColor(enabled ? COLOR_WINDOW : COLOR_BTNFACE));
		Outline(dc, client, cd.hot || open ? RGB(0, 120, 215) : RGB(122, 122, 122));
		if(cd.hot || open) FillSolid(dc, RECT{client.right - kComboButton, client.top + 1, client.right - 1, client.bottom - 1}, open ? RGB(204, 228, 247) : RGB(229, 241, 251));
	}
	const int ax = client.right - kComboButton / 2 - 1, ay = (client.top + client.bottom) / 2;
	const COLORREF arrow = enabled ? RGB(96, 96, 96) : RGB(160, 160, 160);
	for(int i = 0; i < 4; i++) FillSolid(dc, RECT{ax - 3 + i, ay - 1 + i, ax + 4 - i, ay + i}, arrow);
	EndPaint(hWnd, &ps);
}

int InsertComboString(HWND hWnd, ComboData &cd, int index, LPCWSTR text, bool sorted)
{
	ComboItem item;
	item.text = text ? text : L"";
	if(sorted)
	{
		index = 0;
		while(index < (int)cd.items.size() && lstrcmpiW(cd.items[index].text.c_str(), item.text.c_str()) <= 0) index++;
	} else if(index < 0 || index > (int)cd.items.size())
	{
		index = (int)cd.items.size();
	}
	cd.items.insert(cd.items.begin() + index, item);
	if(cd.curSel >= index) cd.curSel++;
	InvalidateRect(hWnd, nullptr, FALSE);
	return index;
}

std::vector<std::wstring> ComboTexts(const ComboData &cd)
{
	std::vector<std::wstring> texts;
	for(const auto &item : cd.items) texts.push_back(item.text);
	return texts;
}

int ComboHeight(HWND hWnd) { return ListLineHeight(hWnd) + 8; }

void CopyText(const std::wstring &text, WPARAM size, LPARAM buffer)
{
	if(!buffer || size == 0) return;
	const size_t n = std::min<size_t>(text.size(), size - 1);
	std::copy_n(text.data(), n, (wchar_t *)buffer);
	((wchar_t *)buffer)[n] = 0;
}

LRESULT CALLBACK ComboProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	ComboData &cd = g_combos[hWnd];
	WindowRecord *rec = GetWindowRecord(hWnd);
	switch(msg)
	{
	case WM_CREATE:
	{
		// The height given at creation is the drop-down list height; the control itself is one line tall.
		if(rec) cd.droppedHeight = std::max<int>(rec->rect.bottom - rec->rect.top - ComboHeight(hWnd), 40);
		cd.extended = rec && rec->className == "ComboBoxEx32";
		if(ComboType(hWnd) != CBS_DROPDOWNLIST)
		{
			RECT r;
			GetClientRect(hWnd, &r);
			cd.edit = CreateWindowExW(0, L"EDIT", L"", WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 3, 2, std::max<int>(1, r.right - kComboButton - 4), ComboHeight(hWnd) - 4, hWnd, (HMENU)1001, nullptr, nullptr);
		}
		if(rec) MoveWindow(hWnd, rec->rect.left, rec->rect.top, rec->rect.right - rec->rect.left, ComboHeight(hWnd), FALSE);
		return 0;
	}
	case WM_NCDESTROY:
		if(cd.monitor) [NSEvent removeMonitor:cd.monitor];
		if(cd.popup) DestroyWindow(cd.popup);
		g_combos.erase(hWnd);
		return 0;
	case WM_SIZE:
		if(cd.edit) MoveWindow(cd.edit, 3, 2, std::max<int>(1, LOWORD(lParam) - kComboButton - 4), std::max<int>(1, HIWORD(lParam) - 4), TRUE);
		return 0;
	case WM_SETFONT:
		if(cd.edit) SendMessageW(cd.edit, WM_SETFONT, wParam, lParam);
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	case WM_PAINT:
		PaintCombo(hWnd, cd);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS | DLGC_WANTCHARS;
	case WM_COMMAND:
		// The edit field's notifications become the combo's CBN_ codes.
		if((HWND)lParam == cd.edit)
		{
			switch(HIWORD(wParam))
			{
			case EN_CHANGE: NotifyCombo(hWnd, CBN_EDITCHANGE); break;
			case EN_UPDATE: NotifyCombo(hWnd, CBN_EDITUPDATE); break;
			case EN_SETFOCUS: NotifyCombo(hWnd, CBN_SETFOCUS); break;
			case EN_KILLFOCUS: NotifyCombo(hWnd, CBN_KILLFOCUS); break;
			}
		}
		return 0;
	case WM_CTLCOLOREDIT:
	case WM_CTLCOLORSTATIC:
		return SendMessageW(GetParent(hWnd), msg, wParam, (LPARAM)hWnd);
	case WM_COMBO_LIST_EVENT:
		if(wParam == CBN_SELENDOK) CloseDropDown(hWnd, cd, true);
		else if(wParam == CBN_SELENDCANCEL) CloseDropDown(hWnd, cd, false);
		return 0;
	case WM_MOUSEMOVE:
		if(!cd.hot) { cd.hot = true; InvalidateRect(hWnd, nullptr, FALSE); }
		return 0;
	case WM_MOUSELEAVE:
		cd.hot = false;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
		if(rec && !rec->isEnabled) return 0;
		if(cd.popup) CloseDropDown(hWnd, cd, false);
		else
		{
			if(!cd.edit) SetFocus(hWnd);
			ShowDropDown(hWnd, cd);
		}
		return 0;
	case WM_SETFOCUS:
		if(cd.edit) SetFocus(cd.edit);
		else NotifyCombo(hWnd, CBN_SETFOCUS);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_KILLFOCUS:
		if(!cd.edit) NotifyCombo(hWnd, CBN_KILLFOCUS);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_KEYDOWN:
	{
		if(wParam == VK_F4 || ((wParam == VK_DOWN || wParam == VK_UP) && GetKeyState(VK_MENU) < 0)) { ShowDropDown(hWnd, cd); return 0; }
		int i = cd.curSel;
		if(wParam == VK_UP) i = std::max(0, i - 1);
		else if(wParam == VK_DOWN) i = std::min((int)cd.items.size() - 1, i + 1);
		else if(wParam == VK_HOME) i = 0;
		else if(wParam == VK_END) i = (int)cd.items.size() - 1;
		else return 0;
		if(i != cd.curSel && i >= 0)
		{
			cd.curSel = i;
			if(cd.edit) SetWindowTextW(cd.edit, cd.items[i].text.c_str());
			InvalidateRect(hWnd, nullptr, FALSE);
			NotifyCombo(hWnd, CBN_SELCHANGE);
		}
		return 0;
	}
	case WM_SETTEXT:
		if(cd.edit) return SetWindowTextW(cd.edit, (LPCWSTR)lParam);
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	case WM_GETTEXT:
	{
		const std::wstring text = ComboText(cd);
		CopyText(text, wParam, lParam);
		return (LRESULT)std::min<size_t>(text.size(), wParam ? wParam - 1 : 0);
	}
	case WM_GETTEXTLENGTH:
		return (LRESULT)ComboText(cd).size();
	case CB_ADDSTRING:
		return InsertComboString(hWnd, cd, -1, (LPCWSTR)lParam, ListBoxStyle(hWnd) & CBS_SORT);
	case CB_INSERTSTRING:
		return InsertComboString(hWnd, cd, (int)wParam, (LPCWSTR)lParam, false);
	case CB_DELETESTRING:
		if(wParam >= cd.items.size()) return CB_ERR;
		cd.items.erase(cd.items.begin() + wParam);
		if(cd.curSel == (int)wParam) cd.curSel = -1;
		else if(cd.curSel > (int)wParam) cd.curSel--;
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)cd.items.size();
	case CB_RESETCONTENT:
		cd.items.clear();
		cd.curSel = -1;
		if(cd.edit) SetWindowTextW(cd.edit, L"");
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case CB_GETCOUNT:
		return (LRESULT)cd.items.size();
	case CB_GETCURSEL:
		return cd.curSel;
	case CB_SETCURSEL:
		cd.curSel = ((int)wParam >= 0 && wParam < cd.items.size()) ? (int)wParam : -1;
		if(cd.edit) SetWindowTextW(cd.edit, cd.curSel >= 0 ? cd.items[cd.curSel].text.c_str() : L"");
		InvalidateRect(hWnd, nullptr, FALSE);
		return cd.curSel < 0 && (int)wParam != -1 ? CB_ERR : cd.curSel;
	case CB_GETLBTEXT:
		if(wParam >= cd.items.size() || !lParam) return CB_ERR;
		CopyText(cd.items[wParam].text, cd.items[wParam].text.size() + 1, lParam);
		return (LRESULT)cd.items[wParam].text.size();
	case CB_GETLBTEXTLEN:
		return wParam < cd.items.size() ? (LRESULT)cd.items[wParam].text.size() : CB_ERR;
	case CB_GETITEMDATA:
		return wParam < cd.items.size() ? (LRESULT)cd.items[wParam].data : CB_ERR;
	case CB_SETITEMDATA:
		if(wParam >= cd.items.size()) return CB_ERR;
		cd.items[wParam].data = (DWORD_PTR)lParam;
		return TRUE;
	case CB_FINDSTRING:
	case CB_FINDSTRINGEXACT:
		return FindListString(ComboTexts(cd), (int)wParam, (LPCWSTR)lParam, msg == CB_FINDSTRINGEXACT);
	case CB_SELECTSTRING:
	{
		const int i = FindListString(ComboTexts(cd), (int)wParam, (LPCWSTR)lParam, false);
		if(i >= 0) SendMessageW(hWnd, CB_SETCURSEL, i, 0);
		return i;
	}
	case CB_SHOWDROPDOWN:
		if(wParam) ShowDropDown(hWnd, cd);
		else CloseDropDown(hWnd, cd, false);
		return TRUE;
	case CB_GETDROPPEDSTATE:
		return cd.popup != nullptr;
	case CB_SETDROPPEDWIDTH:
		cd.droppedWidth = (int)wParam;
		return cd.droppedWidth;
	case CB_GETDROPPEDWIDTH:
		return cd.droppedWidth;
	case CB_GETITEMHEIGHT:
		return ListLineHeight(hWnd) + 2;
	case CB_GETDROPPEDCONTROLRECT:
	{
		RECT window;
		GetWindowRect(hWnd, &window);
		window.bottom += cd.droppedHeight;
		if(lParam) *(RECT *)lParam = window;
		return TRUE;
	}
	case CB_LIMITTEXT:
		if(cd.edit) SendMessageW(cd.edit, EM_LIMITTEXT, wParam, 0);
		return TRUE;
	case CB_SETEDITSEL:
		if(cd.edit) SendMessageW(cd.edit, EM_SETSEL, (short)LOWORD(lParam), (short)HIWORD(lParam));
		return TRUE;
	case CB_GETEDITSEL:
		return cd.edit ? SendMessageW(cd.edit, EM_GETSEL, wParam, lParam) : CB_ERR;
	case CB_GETCOMBOBOXINFO:
	{
		auto *info = (COMBOBOXINFO *)lParam;
		if(!info) return FALSE;
		info->hwndCombo = hWnd;
		info->hwndItem = cd.edit ? cd.edit : hWnd;
		info->hwndList = cd.popup;
		GetClientRect(hWnd, &info->rcItem);
		info->rcButton = info->rcItem;
		info->rcButton.left = info->rcItem.right - kComboButton;
		info->rcItem.right -= kComboButton;
		return TRUE;
	}
	case CB_SETITEMHEIGHT:
	case CB_INITSTORAGE:
	case CB_SETEXTENDEDUI:
	case CB_SETCUEBANNER:
		return 0;
	// ComboBoxEx32
	case CBEM_SETIMAGELIST: { HIMAGELIST old = cd.images; cd.images = (HIMAGELIST)lParam; InvalidateRect(hWnd, nullptr, FALSE); return (LRESULT)old; }
	case CBEM_GETIMAGELIST: return (LRESULT)cd.images;
	case CBEM_INSERTITEMW:
	{
		const auto *item = (const COMBOBOXEXITEMW *)lParam;
		if(!item) return -1;
		const int i = InsertComboString(hWnd, cd, (int)item->iItem, (item->mask & CBEIF_TEXT) ? item->pszText : L"", false);
		if(item->mask & CBEIF_IMAGE) cd.items[i].image = item->iImage;
		if(item->mask & CBEIF_LPARAM) cd.items[i].data = (DWORD_PTR)item->lParam;
		return i;
	}
	case CBEM_GETITEMW:
	{
		auto *item = (COMBOBOXEXITEMW *)lParam;
		const int i = item ? (item->iItem < 0 ? cd.curSel : (int)item->iItem) : -1;
		if(i < 0 || i >= (int)cd.items.size()) return FALSE;
		if(item->mask & CBEIF_TEXT) CopyText(cd.items[i].text, item->cchTextMax, (LPARAM)item->pszText);
		if(item->mask & CBEIF_IMAGE) item->iImage = cd.items[i].image;
		if(item->mask & CBEIF_LPARAM) item->lParam = (LPARAM)cd.items[i].data;
		return TRUE;
	}
	case CBEM_GETEDITCONTROL:
		return (LRESULT)cd.edit;
	case CBEM_GETCOMBOCONTROL:
		return (LRESULT)hWnd;
	case CBEM_SETEXTENDEDSTYLE:
		return 0;
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

}  // namespace

void MacRegisterListTreeControls()
{
	WNDCLASSW tree{};
	tree.lpfnWndProc = TreeProc;
	tree.lpszClassName = WC_TREEVIEWW;
	RegisterClassW(&tree);
	WNDCLASSW list{};
	list.lpfnWndProc = ListProc;
	list.lpszClassName = WC_LISTVIEWW;
	RegisterClassW(&list);
	const struct { LPCWSTR name; WNDPROC proc; } more[] = {
		{L"LISTBOX", ListBoxProc},
		{L"ComboLBox", ListBoxProc},
		{L"COMBOBOX", ComboProc},
		{L"ComboBoxEx32", ComboProc},
	};
	for(const auto &c : more)
	{
		WNDCLASSW wc{};
		wc.lpfnWndProc = c.proc;
		wc.lpszClassName = c.name;
		RegisterClassW(&wc);
	}
}

// ---------------------------------------------------------------------------------------------
// MFC wrappers that were stubs: route them through the controls' messages, as MFC does.
// ---------------------------------------------------------------------------------------------

CImageList *CTreeCtrl::SetImageList(CImageList *pImageList, int nImageListType)
{
	return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, TVM_SETIMAGELIST, nImageListType, (LPARAM)pImageList->GetSafeHandle()));
}

CImageList *CTreeCtrl::GetImageList(UINT nImageList) const
{
	return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, TVM_GETIMAGELIST, nImageList, 0));
}

CString CTreeCtrl::GetItemText(HTREEITEM hItem) const
{
	wchar_t buffer[1024] = {};
	TVITEMW tvi{};
	tvi.mask = TVIF_TEXT | TVIF_HANDLE;
	tvi.hItem = hItem;
	tvi.pszText = buffer;
	tvi.cchTextMax = 1024;
	::SendMessageW(m_hWnd, TVM_GETITEMW, 0, (LPARAM)&tvi);
	return CString(tvi.pszText == LPSTR_TEXTCALLBACKW ? L"" : buffer);
}

BOOL CTreeCtrl::SetItemText(HTREEITEM hItem, LPCTSTR lpszItem)
{
	return SetItem(hItem, TVIF_TEXT, lpszItem, 0, 0, 0, 0, 0);
}

BOOL CTreeCtrl::GetItemImage(HTREEITEM hItem, int &nImage, int &nSelectedImage) const
{
	TVITEMW tvi{};
	tvi.mask = TVIF_IMAGE | TVIF_SELECTEDIMAGE | TVIF_HANDLE;
	tvi.hItem = hItem;
	const BOOL ok = (BOOL)::SendMessageW(m_hWnd, TVM_GETITEMW, 0, (LPARAM)&tvi);
	nImage = tvi.iImage;
	nSelectedImage = tvi.iSelectedImage;
	return ok;
}

BOOL CTreeCtrl::SetItemImage(HTREEITEM hItem, int nImage, int nSelectedImage)
{
	return SetItem(hItem, TVIF_IMAGE | TVIF_SELECTEDIMAGE, nullptr, nImage, nSelectedImage, 0, 0, 0);
}

UINT CTreeCtrl::GetItemState(HTREEITEM hItem, UINT nStateMask) const
{
	return (UINT)::SendMessageW(m_hWnd, TVM_GETITEMSTATE, (WPARAM)hItem, nStateMask);
}

BOOL CTreeCtrl::SetItemState(HTREEITEM hItem, UINT nState, UINT nStateMask)
{
	return SetItem(hItem, TVIF_STATE, nullptr, 0, 0, nState, nStateMask, 0);
}

DWORD_PTR CTreeCtrl::GetItemData(HTREEITEM hItem) const
{
	TVITEMW tvi{};
	tvi.mask = TVIF_PARAM | TVIF_HANDLE;
	tvi.hItem = hItem;
	::SendMessageW(m_hWnd, TVM_GETITEMW, 0, (LPARAM)&tvi);
	return (DWORD_PTR)tvi.lParam;
}

BOOL CTreeCtrl::SetItemData(HTREEITEM hItem, DWORD_PTR dwData)
{
	return SetItem(hItem, TVIF_PARAM, nullptr, 0, 0, 0, 0, (LPARAM)dwData);
}

BOOL CTreeCtrl::SetItem(HTREEITEM hItem, UINT nMask, LPCTSTR lpszItem, int nImage, int nSelectedImage, UINT nState, UINT nStateMask, LPARAM lParam)
{
	TVITEMW tvi{};
	tvi.mask = nMask | TVIF_HANDLE;
	tvi.hItem = hItem;
	tvi.pszText = const_cast<LPWSTR>(lpszItem);
	tvi.iImage = nImage;
	tvi.iSelectedImage = nSelectedImage;
	tvi.state = nState;
	tvi.stateMask = nStateMask;
	tvi.lParam = lParam;
	return (BOOL)::SendMessageW(m_hWnd, TVM_SETITEMW, 0, (LPARAM)&tvi);
}

HTREEITEM CTreeCtrl::InsertItem(UINT nMask, LPCTSTR lpszItem, int nImage, int nSelectedImage, UINT nState, UINT nStateMask, LPARAM lParam, HTREEITEM hParent, HTREEITEM hInsertAfter)
{
	TVINSERTSTRUCTW tis{};
	tis.hParent = hParent;
	tis.hInsertAfter = hInsertAfter;
	tis.item.mask = nMask;
	tis.item.pszText = const_cast<LPWSTR>(lpszItem);
	tis.item.iImage = nImage;
	tis.item.iSelectedImage = nSelectedImage;
	tis.item.state = nState;
	tis.item.stateMask = nStateMask;
	tis.item.lParam = lParam;
	return (HTREEITEM)::SendMessageW(m_hWnd, TVM_INSERTITEMW, 0, (LPARAM)&tis);
}

HTREEITEM CTreeCtrl::InsertItem(LPCTSTR lpszItem, HTREEITEM hParent, HTREEITEM hInsertAfter)
{
	return InsertItem(TVIF_TEXT, lpszItem, 0, 0, 0, 0, 0, hParent, hInsertAfter);
}

HTREEITEM CTreeCtrl::InsertItem(LPCTSTR lpszItem, int nImage, int nSelectedImage, HTREEITEM hParent, HTREEITEM hInsertAfter)
{
	return InsertItem(TVIF_TEXT | TVIF_IMAGE | TVIF_SELECTEDIMAGE, lpszItem, nImage, nSelectedImage, 0, 0, 0, hParent, hInsertAfter);
}

CImageList *CListCtrl::SetImageList(CImageList *pImageList, int nImageListType)
{
	return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, LVM_SETIMAGELIST, nImageListType, (LPARAM)pImageList->GetSafeHandle()));
}

CImageList *CListCtrl::GetImageList(int nImageList) const
{
	return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, LVM_GETIMAGELIST, nImageList, 0));
}

CHeaderCtrl *CListCtrl::GetHeaderCtrl() const { return nullptr; }  // the list view draws its own header

int CListCtrl::InsertItem(int nItem, LPCTSTR lpszItem)
{
	return InsertItem(LVIF_TEXT, nItem, lpszItem, 0, 0, 0, 0);
}

int CListCtrl::InsertItem(int nItem, LPCTSTR lpszItem, int nImage)
{
	return InsertItem(LVIF_TEXT | LVIF_IMAGE, nItem, lpszItem, 0, 0, nImage, 0);
}

int CListCtrl::InsertItem(UINT nMask, int nItem, LPCTSTR lpszItem, UINT nState, UINT nStateMask, int nImage, LPARAM lParam)
{
	LVITEMW lvi{};
	lvi.mask = nMask;
	lvi.iItem = nItem;
	lvi.pszText = const_cast<LPWSTR>(lpszItem);
	lvi.state = nState;
	lvi.stateMask = nStateMask;
	lvi.iImage = nImage;
	lvi.lParam = lParam;
	return (int)::SendMessageW(m_hWnd, LVM_INSERTITEMW, 0, (LPARAM)&lvi);
}

BOOL CListCtrl::SetItem(int nItem, int nSubItem, UINT nMask, LPCTSTR lpszItem, int nImage, UINT nState, UINT nStateMask, LPARAM lParam)
{
	LVITEMW lvi{};
	lvi.mask = nMask;
	lvi.iItem = nItem;
	lvi.iSubItem = nSubItem;
	lvi.pszText = const_cast<LPWSTR>(lpszItem);
	lvi.iImage = nImage;
	lvi.state = nState;
	lvi.stateMask = nStateMask;
	lvi.lParam = lParam;
	return (BOOL)::SendMessageW(m_hWnd, LVM_SETITEMW, 0, (LPARAM)&lvi);
}

CString CListCtrl::GetItemText(int nItem, int nSubItem) const
{
	wchar_t buffer[1024] = {};
	GetItemText(nItem, nSubItem, buffer, 1024);
	return CString(buffer);
}

int CListCtrl::GetItemText(int nItem, int nSubItem, LPTSTR lpszText, int nLen) const
{
	LVITEMW lvi{};
	lvi.iSubItem = nSubItem;
	lvi.pszText = lpszText;
	lvi.cchTextMax = nLen;
	return (int)::SendMessageW(m_hWnd, LVM_GETITEMTEXTW, nItem, (LPARAM)&lvi);
}

BOOL CListCtrl::SetItemText(int nItem, int nSubItem, LPCTSTR lpszText)
{
	LVITEMW lvi{};
	lvi.iSubItem = nSubItem;
	lvi.pszText = const_cast<LPWSTR>(lpszText);
	return (BOOL)::SendMessageW(m_hWnd, LVM_SETITEMTEXTW, nItem, (LPARAM)&lvi);
}

BOOL CListCtrl::SetItemData(int nItem, DWORD_PTR dwData)
{
	return SetItem(nItem, 0, LVIF_PARAM, nullptr, 0, 0, 0, (LPARAM)dwData);
}

DWORD_PTR CListCtrl::GetItemData(int nItem) const
{
	LVITEMW lvi{};
	lvi.mask = LVIF_PARAM;
	lvi.iItem = nItem;
	::SendMessageW(m_hWnd, LVM_GETITEMW, 0, (LPARAM)&lvi);
	return (DWORD_PTR)lvi.lParam;
}

int CListCtrl::InsertColumn(int nCol, LPCTSTR lpszColumnHeading, int nFormat, int nWidth, int nSubItem)
{
	LVCOLUMNW col{};
	col.mask = LVCF_TEXT | LVCF_FMT;
	col.pszText = const_cast<LPWSTR>(lpszColumnHeading);
	col.fmt = nFormat;
	if(nWidth >= 0)
	{
		col.mask |= LVCF_WIDTH;
		col.cx = nWidth;
	}
	if(nSubItem >= 0)
	{
		col.mask |= LVCF_SUBITEM;
		col.iSubItem = nSubItem;
	}
	return (int)::SendMessageW(m_hWnd, LVM_INSERTCOLUMNW, nCol, (LPARAM)&col);
}
