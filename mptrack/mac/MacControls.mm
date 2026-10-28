/*
 * MacControls.mm
 * --------------
 * Purpose: The Windows common controls that mptrack's MFC classes sit on, implemented as ordinary
 *          window procedures drawn with the GDI shim so they look like the Windows 10 versions:
 *          image lists, toolbar, status bar, static, edit and up-down controls, plus the MFC
 *          CToolBar / CStatusBar wrappers that drive them (like real MFC does).
 */

#import "MacControls.h"
#import "MacResources.h"
#include "afxext.h"
#include "afxpriv.h"

#include <map>
#include <numeric>
#include <optional>

// ---------------------------------------------------------------------------------------------
// Drawing helpers
// ---------------------------------------------------------------------------------------------

void FillSolid(HDC dc, const RECT &r, COLORREF color)
{
	HBRUSH brush = CreateSolidBrush(color);
	FillRect(dc, &r, brush);
	DeleteObject(brush);
}

void Outline(HDC dc, const RECT &r, COLORREF color)
{
	FillSolid(dc, RECT{r.left, r.top, r.right, r.top + 1}, color);
	FillSolid(dc, RECT{r.left, r.bottom - 1, r.right, r.bottom}, color);
	FillSolid(dc, RECT{r.left, r.top, r.left + 1, r.bottom}, color);
	FillSolid(dc, RECT{r.right - 1, r.top, r.right, r.bottom}, color);
}

HFONT ControlFont(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return (rec && rec->font) ? rec->font : (HFONT)GetStockObject(DEFAULT_GUI_FONT);
}

static std::wstring WindowTextW(HWND hWnd)
{
	const int len = GetWindowTextLengthW(hWnd);
	std::wstring text(len + 1, L'\0');
	GetWindowTextW(hWnd, text.data(), len + 1);
	text.resize(len);
	return text;
}

static void NotifyParentCommand(HWND hWnd, UINT code)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(rec && rec->parent) SendMessageW(rec->parent, WM_COMMAND, MAKEWPARAM((WORD)rec->id, (WORD)code), (LPARAM)hWnd);
}

// Asks the parent for the background brush / text colour (WM_CTLCOLORxxx) and fills the background.
static void PrepareControlDC(HWND hWnd, HDC dc, UINT ctlColorMsg, const RECT &client, COLORREF defaultBk)
{
	SetBkMode(dc, TRANSPARENT);
	SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
	SelectObject(dc, ControlFont(hWnd));
	HBRUSH brush = nullptr;
	if(HWND parent = GetParent(hWnd)) brush = (HBRUSH)SendMessageW(parent, ctlColorMsg, (WPARAM)dc, (LPARAM)hWnd);
	if(brush) FillRect(dc, &client, brush);
	else FillSolid(dc, client, defaultBk);
}

void DrawImageRect(HDC dc, CGImageRef image, int x, int y, int w, int h, CGFloat alpha)
{
	if(!dc || !dc->cgContext || !image) return;
	CGContextRef ctx = dc->cgContext;
	CGContextSaveGState(ctx);
	CGContextSetAlpha(ctx, alpha);
	// Device contexts are y-down; images are drawn bottom-up.
	CGContextTranslateCTM(ctx, x + dc->viewportOrg.x, y + dc->viewportOrg.y + h);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), image);
	CGContextRestoreGState(ctx);
}

// ---------------------------------------------------------------------------------------------
// Image lists
// ---------------------------------------------------------------------------------------------

struct _IMAGELIST
{
	int cx = 16, cy = 16;
	std::vector<CGImageRef> images;
	~_IMAGELIST() { Clear(); }
	void Clear()
	{
		for(CGImageRef image : images) CGImageRelease(image);
		images.clear();
	}
};

// Cuts a strip bitmap into cx-wide images; pixels matching the mask (colour or mask bitmap) become transparent.
static int AddStrip(HIMAGELIST list, MacBitmap *bitmap, std::optional<COLORREF> maskColor, MacBitmap *maskBitmap)
{
	if(!list || !bitmap || bitmap->pixelData.empty() || list->cx <= 0) return -1;
	const int first = (int)list->images.size();
	const int count = bitmap->width / list->cx;
	const int rows = std::min(bitmap->height, list->cy);
	const size_t stride = (size_t)bitmap->width * 4;
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
	for(int i = 0; i < count; i++)
	{
		std::vector<uint8_t> pixels((size_t)list->cx * rows * 4);
		for(int y = 0; y < rows; y++)
		{
			const int srcRow = bitmap->bottomUp ? bitmap->height - 1 - y : y;
			const uint8_t *src = bitmap->pixelData.data() + srcRow * stride + (size_t)i * list->cx * 4;
			uint8_t *dst = pixels.data() + (size_t)y * list->cx * 4;
			for(int x = 0; x < list->cx; x++, src += 4, dst += 4)
			{
				bool transparent = maskColor && RGB(src[0], src[1], src[2]) == *maskColor;
				if(maskBitmap && maskBitmap->width > i * list->cx + x && maskBitmap->height > y)
				{
					const uint8_t *m = maskBitmap->pixelData.data() + (size_t)y * maskBitmap->width * 4 + (size_t)(i * list->cx + x) * 4;
					transparent = m[0] != 0;
				}
				if(transparent)
				{
					dst[0] = dst[1] = dst[2] = dst[3] = 0;
				} else
				{
					// Bitmap data is premultiplied RGBA; keep it as is.
					memcpy(dst, src, 4);
				}
			}
		}
		CFDataRef data = CFDataCreate(nullptr, pixels.data(), (CFIndex)pixels.size());
		CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
		CGImageRef image = CGImageCreate(list->cx, rows, 8, 32, (size_t)list->cx * 4, rgb, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big, provider, nullptr, false, kCGRenderingIntentDefault);
		CGDataProviderRelease(provider);
		CFRelease(data);
		if(image) list->images.push_back(image);
	}
	CGColorSpaceRelease(rgb);
	return list->images.size() > (size_t)first ? first : -1;
}

BOOL CImageList::Create(int cx, int cy, UINT, int, int)
{
	DeleteImageList();
	m_hImageList = new _IMAGELIST();
	m_hImageList->cx = cx;
	m_hImageList->cy = cy;
	return TRUE;
}

BOOL CImageList::Create(UINT nBitmapID, int cx, int nGrow, COLORREF crMask)
{
	return Create(MAKEINTRESOURCE(nBitmapID), cx, nGrow, crMask);
}

BOOL CImageList::Create(LPCTSTR lpszBitmapID, int cx, int nGrow, COLORREF crMask)
{
	CBitmap bitmap;
	if(!bitmap.LoadBitmap(lpszBitmapID)) return FALSE;
	auto *bmp = (MacBitmap *)bitmap.GetSafeHandle();
	if(!Create(cx, bmp->height, ILC_COLOR32 | ILC_MASK, 0, nGrow)) return FALSE;
	return Add(&bitmap, crMask) >= 0;
}

BOOL CImageList::Create(CImageList *pImageList)
{
	if(!pImageList || !pImageList->m_hImageList) return FALSE;
	Create(pImageList->m_hImageList->cx, pImageList->m_hImageList->cy, ILC_COLOR32, 0, 0);
	for(CGImageRef image : pImageList->m_hImageList->images) m_hImageList->images.push_back(CGImageRetain(image));
	return TRUE;
}

BOOL CImageList::DeleteImageList()
{
	delete m_hImageList;
	m_hImageList = nullptr;
	return TRUE;
}

int CImageList::GetImageCount() const { return m_hImageList ? (int)m_hImageList->images.size() : 0; }
COLORREF CImageList::SetBkColor(COLORREF) { return CLR_NONE; }
COLORREF CImageList::GetBkColor() const { return CLR_NONE; }

BOOL CImageList::GetImageInfo(int nImage, IMAGEINFO *pImageInfo) const
{
	if(!m_hImageList || nImage < 0 || nImage >= GetImageCount() || !pImageInfo) return FALSE;
	*pImageInfo = {};
	pImageInfo->rcImage = RECT{0, 0, m_hImageList->cx, m_hImageList->cy};
	return TRUE;
}

int CImageList::Add(CBitmap *pbmImage, CBitmap *pbmMask)
{
	if(!pbmImage) return -1;
	return AddStrip(m_hImageList, (MacBitmap *)pbmImage->GetSafeHandle(), std::nullopt, pbmMask ? (MacBitmap *)pbmMask->GetSafeHandle() : nullptr);
}

int CImageList::Add(CBitmap *pbmImage, COLORREF crMask)
{
	if(!pbmImage) return -1;
	return AddStrip(m_hImageList, (MacBitmap *)pbmImage->GetSafeHandle(), crMask == CLR_NONE ? std::nullopt : std::optional<COLORREF>(crMask), nullptr);
}

int CImageList::Add(HICON hIcon)
{
	return ImageList_ReplaceIcon(m_hImageList, -1, hIcon);
}

BOOL CImageList::Remove(int nImage)
{
	if(!m_hImageList) return FALSE;
	if(nImage < 0)
	{
		m_hImageList->Clear();
		return TRUE;
	}
	if(nImage >= GetImageCount()) return FALSE;
	CGImageRelease(m_hImageList->images[nImage]);
	m_hImageList->images.erase(m_hImageList->images.begin() + nImage);
	return TRUE;
}

BOOL CImageList::Replace(int nImage, CBitmap *pbmImage, CBitmap *pbmMask)
{
	if(!m_hImageList || nImage < 0 || nImage >= GetImageCount()) return FALSE;
	_IMAGELIST temp;
	temp.cx = m_hImageList->cx;
	temp.cy = m_hImageList->cy;
	if(AddStrip(&temp, (MacBitmap *)pbmImage->GetSafeHandle(), std::nullopt, pbmMask ? (MacBitmap *)pbmMask->GetSafeHandle() : nullptr) < 0) return FALSE;
	CGImageRelease(m_hImageList->images[nImage]);
	m_hImageList->images[nImage] = CGImageRetain(temp.images[0]);
	return TRUE;
}

int CImageList::Replace(int nImage, HICON hIcon) { return ImageList_ReplaceIcon(m_hImageList, nImage, hIcon); }
HICON CImageList::ExtractIcon(int) { return nullptr; }

BOOL CImageList::Draw(CDC *pDC, int nImage, POINT pt, UINT nStyle)
{
	return ImageList_Draw(m_hImageList, nImage, pDC ? pDC->GetSafeHdc() : nullptr, pt.x, pt.y, nStyle);
}

BOOL CImageList::DrawEx(CDC *pDC, int nImage, POINT pt, SIZE sz, COLORREF, COLORREF, UINT nStyle)
{
	if(!m_hImageList || nImage < 0 || nImage >= GetImageCount() || !pDC) return FALSE;
	const int w = sz.cx ? sz.cx : m_hImageList->cx, h = sz.cy ? sz.cy : m_hImageList->cy;
	DrawImageRect(pDC->GetSafeHdc(), m_hImageList->images[nImage], pt.x, pt.y, w, h, (nStyle & ILD_BLEND50) ? 0.5 : 1.0);
	return TRUE;
}

BOOL WINAPI ImageList_Draw(HIMAGELIST himl, int i, HDC hdcDst, int x, int y, UINT fStyle)
{
	if(!himl || i < 0 || (size_t)i >= himl->images.size()) return FALSE;
	DrawImageRect(hdcDst, himl->images[i], x, y, himl->cx, himl->cy, (fStyle & ILD_BLEND50) ? 0.5 : 1.0);
	return TRUE;
}

BOOL WINAPI ImageList_RemoveAll(HIMAGELIST himl)
{
	if(himl) himl->Clear();
	return himl != nullptr;
}

BOOL WINAPI ImageList_SetIconSize(HIMAGELIST himl, int cx, int cy)
{
	if(!himl) return FALSE;
	himl->Clear();
	himl->cx = cx;
	himl->cy = cy;
	return TRUE;
}

int WINAPI ImageList_GetImageCount(HIMAGELIST himl) { return himl ? (int)himl->images.size() : 0; }

BOOL WINAPI ImageList_GetIconSize(HIMAGELIST himl, int *cx, int *cy)
{
	if(!himl) return FALSE;
	if(cx) *cx = himl->cx;
	if(cy) *cy = himl->cy;
	return TRUE;
}

int WINAPI ImageList_ReplaceIcon(HIMAGELIST himl, int i, HICON hicon)
{
	if(!himl || !hicon || !hicon->image) return -1;
	NSRect rect = NSMakeRect(0, 0, himl->cx, himl->cy);
	CGImageRef image = [hicon->image CGImageForProposedRect:&rect context:nil hints:nil];
	if(!image) return -1;
	CGImageRetain(image);
	if(i < 0 || (size_t)i >= himl->images.size())
	{
		himl->images.push_back(image);
		return (int)himl->images.size() - 1;
	}
	CGImageRelease(himl->images[i]);
	himl->images[i] = image;
	return i;
}

CImageList *CToolBarCtrl::GetImageList() const { return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, TB_GETIMAGELIST, 0, 0)); }
CImageList *CToolBarCtrl::SetImageList(CImageList *pImageList) { return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, TB_SETIMAGELIST, 0, (LPARAM)pImageList->GetSafeHandle())); }
CImageList *CToolBarCtrl::GetDisabledImageList() const { return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, TB_GETDISABLEDIMAGELIST, 0, 0)); }
CImageList *CToolBarCtrl::SetDisabledImageList(CImageList *pImageList) { return CImageList::FromHandle((HIMAGELIST)::SendMessageW(m_hWnd, TB_SETDISABLEDIMAGELIST, 0, (LPARAM)pImageList->GetSafeHandle())); }

CImageList *CImageList::FromHandle(HIMAGELIST h)
{
	if(!h) return nullptr;
	static std::map<HIMAGELIST, CImageList *> wrappers;
	CImageList *&w = wrappers[h];
	if(!w) w = new CImageList();
	w->m_hImageList = h;
	return w;
}

// ---------------------------------------------------------------------------------------------
// Toolbar control (ToolbarWindow32)
// ---------------------------------------------------------------------------------------------

namespace {

// Windows 10 flat toolbar colours.
constexpr COLORREF kHotFill = RGB(229, 243, 255), kHotBorder = RGB(204, 232, 255);
constexpr COLORREF kDownFill = RGB(204, 232, 255), kDownBorder = RGB(153, 209, 255);
constexpr int kDefaultSeparatorWidth = 8, kDropDownArrowWidth = 13;

struct ToolbarData
{
	std::vector<TBBUTTON> buttons;
	HIMAGELIST images = nullptr, disabledImages = nullptr;
	SIZE buttonSize{23, 22}, bitmapSize{16, 16};
	int indent = 0;
	DWORD exStyle = 0;
	int hot = -1, pressed = -1;
	bool pressedOnArrow = false;
};

std::map<HWND, ToolbarData> g_toolbars;

bool IsSeparator(const TBBUTTON &b) { return b.fsStyle & TBSTYLE_SEP; }

int ButtonWidth(const ToolbarData &tb, const TBBUTTON &b)
{
	if(IsSeparator(b)) return b.iBitmap > 0 ? b.iBitmap : kDefaultSeparatorWidth;
	int width = tb.buttonSize.cx;
	if((b.fsStyle & TBSTYLE_DROPDOWN) && (tb.exStyle & TBSTYLE_EX_DRAWDDARROWS)) width += kDropDownArrowWidth;
	return width;
}

// shortcut: single row unless a button carries TBSTATE_WRAP; add automatic wrapping when the window gets too narrow for the main toolbar.
RECT ButtonRect(const ToolbarData &tb, int index)
{
	int x = tb.indent, y = 0;
	for(int i = 0; i < (int)tb.buttons.size(); i++)
	{
		const TBBUTTON &b = tb.buttons[i];
		if(b.fsState & TBSTATE_HIDDEN)
		{
			if(i == index) return RECT{0, 0, 0, 0};
			continue;
		}
		const int width = ButtonWidth(tb, b);
		if(i == index) return RECT{x, y, x + width, y + tb.buttonSize.cy};
		x += width;
		if(b.fsState & TBSTATE_WRAP)
		{
			x = tb.indent;
			y += tb.buttonSize.cy;
		}
	}
	return RECT{0, 0, 0, 0};
}

SIZE ToolbarExtent(const ToolbarData &tb)
{
	SIZE size{0, tb.buttonSize.cy};
	for(int i = 0; i < (int)tb.buttons.size(); i++)
	{
		const RECT r = ButtonRect(tb, i);
		size.cx = std::max<LONG>(size.cx, r.right);
		size.cy = std::max<LONG>(size.cy, r.bottom);
	}
	return size;
}

int HitTest(const ToolbarData &tb, POINT pt)
{
	for(int i = 0; i < (int)tb.buttons.size(); i++)
	{
		const RECT r = ButtonRect(tb, i);
		if(!IsSeparator(tb.buttons[i]) && PtInRect(&r, pt)) return i;
	}
	return -1;
}

int CommandIndex(const ToolbarData &tb, int id)
{
	for(int i = 0; i < (int)tb.buttons.size(); i++)
		if(tb.buttons[i].idCommand == id) return i;
	return -1;
}

void PaintToolbar(HWND hWnd, ToolbarData &tb)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client;
	GetClientRect(hWnd, &client);
	FillSolid(dc, client, GetSysColor(COLOR_BTNFACE));
	for(int i = 0; i < (int)tb.buttons.size(); i++)
	{
		const TBBUTTON &b = tb.buttons[i];
		if(b.fsState & TBSTATE_HIDDEN) continue;
		const RECT r = ButtonRect(tb, i);
		if(IsSeparator(b))
		{
			// Only short separators are drawn; wide ones are placeholders for embedded controls.
			if(r.right - r.left <= kDefaultSeparatorWidth)
			{
				const int x = (r.left + r.right) / 2;
				FillSolid(dc, RECT{x, r.top + 2, x + 1, r.bottom - 2}, RGB(188, 188, 188));
			}
			continue;
		}
		const bool enabled = b.fsState & TBSTATE_ENABLED;
		const bool checked = b.fsState & TBSTATE_CHECKED;
		const bool down = enabled && (tb.pressed == i || (b.fsState & TBSTATE_PRESSED));
		const bool hot = enabled && tb.hot == i;
		if(down || checked)
		{
			FillSolid(dc, r, kDownFill);
			Outline(dc, r, kDownBorder);
		} else if(hot)
		{
			FillSolid(dc, r, kHotFill);
			Outline(dc, r, kHotBorder);
		}
		const bool hasArrow = (b.fsStyle & TBSTYLE_DROPDOWN) && (tb.exStyle & TBSTYLE_EX_DRAWDDARROWS);
		const int imageAreaRight = hasArrow ? r.right - kDropDownArrowWidth : r.right;
		HIMAGELIST list = (!enabled && tb.disabledImages) ? tb.disabledImages : tb.images;
		if(list && b.iBitmap >= 0)
		{
			const int x = r.left + (imageAreaRight - r.left - tb.bitmapSize.cx) / 2 + (down ? 1 : 0);
			const int y = r.top + (r.bottom - r.top - tb.bitmapSize.cy) / 2 + (down ? 1 : 0);
			ImageList_Draw(list, b.iBitmap, dc, x, y, (!enabled && !tb.disabledImages) ? ILD_BLEND50 : ILD_NORMAL);
		}
		if(hasArrow)
		{
			if(hot || down) FillSolid(dc, RECT{imageAreaRight, r.top + 1, imageAreaRight + 1, r.bottom - 1}, kDownBorder);
			// Small down-pointing triangle.
			const int cx = imageAreaRight + kDropDownArrowWidth / 2, cy = (r.top + r.bottom) / 2;
			const COLORREF arrow = enabled ? RGB(0, 0, 0) : GetSysColor(COLOR_GRAYTEXT);
			for(int row = 0; row < 3; row++)
				FillSolid(dc, RECT{cx - 2 + row, cy - 1 + row, cx + 3 - row, cy + row}, arrow);
		}
	}
	EndPaint(hWnd, &ps);
}

void InsertButtons(ToolbarData &tb, int index, int count, const TBBUTTON *buttons)
{
	if(index < 0 || index > (int)tb.buttons.size()) index = (int)tb.buttons.size();
	tb.buttons.insert(tb.buttons.begin() + index, buttons, buttons + count);
}

LRESULT CALLBACK ToolbarProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	ToolbarData &tb = g_toolbars[hWnd];
	auto byCommand = [&](WPARAM id) -> TBBUTTON * { const int i = CommandIndex(tb, (int)id); return i >= 0 ? &tb.buttons[i] : nullptr; };
	auto setState = [&](WPARAM id, BYTE flag, bool on) -> LRESULT {
		TBBUTTON *b = byCommand(id);
		if(!b) return FALSE;
		const BYTE old = b->fsState;
		b->fsState = on ? (b->fsState | flag) : (b->fsState & ~flag);
		if(old != b->fsState) InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	};
	switch(msg)
	{
	case WM_NCDESTROY:
		g_toolbars.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintToolbar(hWnd, tb);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case TB_BUTTONSTRUCTSIZE:
	case TB_AUTOSIZE:
	case TB_SETMAXTEXTROWS:
		return 0;
	case TB_ADDBUTTONSA:
	case TB_ADDBUTTONSW:
		InsertButtons(tb, -1, (int)wParam, (const TBBUTTON *)lParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case TB_INSERTBUTTONA:
	case TB_INSERTBUTTONW:
		InsertButtons(tb, (int)wParam, 1, (const TBBUTTON *)lParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case TB_DELETEBUTTON:
		if(wParam >= tb.buttons.size()) return FALSE;
		tb.buttons.erase(tb.buttons.begin() + wParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case TB_BUTTONCOUNT:
		return (LRESULT)tb.buttons.size();
	case TB_GETBUTTON:
		if(wParam >= tb.buttons.size() || !lParam) return FALSE;
		*(TBBUTTON *)lParam = tb.buttons[wParam];
		return TRUE;
	case TB_COMMANDTOINDEX:
		return CommandIndex(tb, (int)wParam);
	case TB_GETITEMRECT:
		if(wParam >= tb.buttons.size() || !lParam) return FALSE;
		*(RECT *)lParam = ButtonRect(tb, (int)wParam);
		return TRUE;
	case TB_GETRECT:
	{
		const int i = CommandIndex(tb, (int)wParam);
		if(i < 0 || !lParam) return FALSE;
		*(RECT *)lParam = ButtonRect(tb, i);
		return TRUE;
	}
	case TB_SETBUTTONSIZE:
		tb.buttonSize = SIZE{LOWORD(lParam), HIWORD(lParam)};
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case TB_GETBUTTONSIZE:
		return MAKELONG(tb.buttonSize.cx, tb.buttonSize.cy);
	case TB_SETBITMAPSIZE:
		tb.bitmapSize = SIZE{LOWORD(lParam), HIWORD(lParam)};
		return TRUE;
	case TB_SETIMAGELIST: { HIMAGELIST old = tb.images; tb.images = (HIMAGELIST)lParam; InvalidateRect(hWnd, nullptr, FALSE); return (LRESULT)old; }
	case TB_GETIMAGELIST: return (LRESULT)tb.images;
	case TB_SETDISABLEDIMAGELIST: { HIMAGELIST old = tb.disabledImages; tb.disabledImages = (HIMAGELIST)lParam; InvalidateRect(hWnd, nullptr, FALSE); return (LRESULT)old; }
	case TB_GETDISABLEDIMAGELIST: return (LRESULT)tb.disabledImages;
	case TB_SETINDENT: tb.indent = (int)wParam; InvalidateRect(hWnd, nullptr, FALSE); return TRUE;
	case TB_SETEXTENDEDSTYLE: { const DWORD old = tb.exStyle; tb.exStyle = (DWORD)lParam; return old; }
	case TB_GETEXTENDEDSTYLE: return tb.exStyle;
	case TB_SETSTATE:
		if(TBBUTTON *b = byCommand(wParam))
		{
			b->fsState = (BYTE)LOWORD(lParam);
			InvalidateRect(hWnd, nullptr, FALSE);
			return TRUE;
		}
		return FALSE;
	case TB_GETSTATE:
		if(TBBUTTON *b = byCommand(wParam)) return b->fsState;
		return -1;
	case TB_ENABLEBUTTON: return setState(wParam, TBSTATE_ENABLED, LOWORD(lParam));
	case TB_CHECKBUTTON: return setState(wParam, TBSTATE_CHECKED, LOWORD(lParam));
	case TB_PRESSBUTTON: return setState(wParam, TBSTATE_PRESSED, LOWORD(lParam));
	case TB_HIDEBUTTON: return setState(wParam, TBSTATE_HIDDEN, LOWORD(lParam));
	case TB_INDETERMINATE: return setState(wParam, TBSTATE_INDETERMINATE, LOWORD(lParam));
	case TB_ISBUTTONENABLED: { TBBUTTON *b = byCommand(wParam); return b && (b->fsState & TBSTATE_ENABLED); }
	case TB_ISBUTTONCHECKED: { TBBUTTON *b = byCommand(wParam); return b && (b->fsState & TBSTATE_CHECKED); }
	case TB_ISBUTTONPRESSED: { TBBUTTON *b = byCommand(wParam); return b && (b->fsState & TBSTATE_PRESSED); }
	case TB_ISBUTTONHIDDEN: { TBBUTTON *b = byCommand(wParam); return b && (b->fsState & TBSTATE_HIDDEN); }
	case TB_ISBUTTONINDETERMINATE: { TBBUTTON *b = byCommand(wParam); return b && (b->fsState & TBSTATE_INDETERMINATE); }
	case TB_CHANGEBITMAP:
		if(TBBUTTON *b = byCommand(wParam))
		{
			b->iBitmap = LOWORD(lParam);
			InvalidateRect(hWnd, nullptr, FALSE);
			return TRUE;
		}
		return FALSE;
	case WM_MOUSEMOVE:
	{
		const int hot = HitTest(tb, POINT{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)});
		if(hot != tb.hot)
		{
			tb.hot = hot;
			InvalidateRect(hWnd, nullptr, FALSE);
		}
		return 0;
	}
	case WM_MOUSELEAVE:
		tb.hot = -1;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
	{
		const POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		const int i = HitTest(tb, pt);
		if(i < 0 || !(tb.buttons[i].fsState & TBSTATE_ENABLED)) return 0;
		const TBBUTTON &b = tb.buttons[i];
		const RECT r = ButtonRect(tb, i);
		const bool hasArrow = (b.fsStyle & TBSTYLE_DROPDOWN) && (tb.exStyle & TBSTYLE_EX_DRAWDDARROWS);
		if((b.fsStyle & TBSTYLE_DROPDOWN) && (!hasArrow || pt.x >= r.right - kDropDownArrowWidth))
		{
			// The dropdown part notifies the parent immediately; it shows the menu.
			NMTOOLBARW nm{};
			nm.hdr.hwndFrom = hWnd;
			nm.hdr.idFrom = (UINT_PTR)GetDlgCtrlID(hWnd);
			nm.hdr.code = TBN_DROPDOWN;
			nm.iItem = b.idCommand;
			nm.tbButton = b;
			nm.rcButton = r;
			tb.pressed = i;
			InvalidateRect(hWnd, nullptr, FALSE);
			SendMessageW(GetParent(hWnd), WM_NOTIFY, nm.hdr.idFrom, (LPARAM)&nm);
			tb.pressed = -1;
			InvalidateRect(hWnd, nullptr, FALSE);
			return 0;
		}
		tb.pressed = i;
		SetCapture(hWnd);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	}
	case WM_LBUTTONUP:
	{
		const int i = tb.pressed;
		tb.pressed = -1;
		ReleaseCapture();
		InvalidateRect(hWnd, nullptr, FALSE);
		if(i < 0 || i >= (int)tb.buttons.size() || HitTest(tb, POINT{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)}) != i) return 0;
		TBBUTTON &b = tb.buttons[i];
		if(b.fsStyle & TBSTYLE_CHECK)
		{
			if((b.fsStyle & TBSTYLE_GROUP))
			{
				// Check groups: uncheck the neighbours in the same contiguous group.
				for(int j = i - 1; j >= 0 && (tb.buttons[j].fsStyle & TBSTYLE_CHECKGROUP) == TBSTYLE_CHECKGROUP; j--) tb.buttons[j].fsState &= ~TBSTATE_CHECKED;
				for(int j = i + 1; j < (int)tb.buttons.size() && (tb.buttons[j].fsStyle & TBSTYLE_CHECKGROUP) == TBSTYLE_CHECKGROUP; j++) tb.buttons[j].fsState &= ~TBSTATE_CHECKED;
				b.fsState |= TBSTATE_CHECKED;
			} else
			{
				b.fsState ^= TBSTATE_CHECKED;
			}
		}
		SendMessageW(GetParent(hWnd), WM_COMMAND, MAKEWPARAM(b.idCommand, BN_CLICKED), (LPARAM)hWnd);
		return 0;
	}
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Status bar (msctls_statusbar32)
// ---------------------------------------------------------------------------------------------

struct StatusData
{
	std::vector<int> rightEdges;  // -1 extends to the right border
	std::vector<std::wstring> texts;
	std::vector<UINT> textFlags;
	bool simple = false;
	std::wstring simpleText;
};

std::map<HWND, StatusData> g_statusBars;

constexpr int kStatusGrip = 16;

RECT StatusPartRect(HWND hWnd, const StatusData &sb, int part)
{
	RECT client;
	GetClientRect(hWnd, &client);
	const int left = part > 0 ? sb.rightEdges[part - 1] : 0;
	int right = sb.rightEdges[part];
	if(right < 0 || right > client.right) right = client.right;
	return RECT{left, client.top + 2, right, client.bottom};
}

void PaintStatusBar(HWND hWnd, StatusData &sb)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client;
	GetClientRect(hWnd, &client);
	FillSolid(dc, client, GetSysColor(COLOR_BTNFACE));
	SetBkMode(dc, TRANSPARENT);
	SetTextColor(dc, GetSysColor(COLOR_BTNTEXT));
	SelectObject(dc, ControlFont(hWnd));
	auto drawText = [&](const std::wstring &text, RECT r) {
		r.left += 4;
		r.right -= 2;
		std::wstring t = text;
		UINT format = DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX | DT_END_ELLIPSIS;
		// Tabs split a pane into left / centre / right aligned text.
		const auto tab = t.find(L'\t');
		if(tab == 0) { format |= DT_CENTER; t.erase(0, 1); if(!t.empty() && t[0] == L'\t') { format = (format & ~DT_CENTER) | DT_RIGHT; t.erase(0, 1); } }
		DrawTextW(dc, t.c_str(), (int)t.size(), &r, format);
	};
	if(sb.simple)
	{
		drawText(sb.simpleText, client);
	} else
	{
		for(int i = 0; i < (int)sb.rightEdges.size(); i++)
		{
			const RECT r = StatusPartRect(hWnd, sb, i);
			const bool noBorders = i < (int)sb.textFlags.size() && (sb.textFlags[i] & SBT_NOBORDERS);
			if(!noBorders && i + 1 < (int)sb.rightEdges.size())
				FillSolid(dc, RECT{r.right - 1, r.top + 1, r.right, r.bottom - 2}, RGB(215, 215, 215));
			if(i < (int)sb.texts.size()) drawText(sb.texts[i], r);
		}
	}
	// Size grip: three diagonal rows of dots, as in Windows 10.
	for(int row = 0; row < 3; row++)
		for(int col = 0; col <= row; col++)
		{
			const int x = client.right - 4 - col * 4, y = client.bottom - 4 - (row - col) * 4;
			FillSolid(dc, RECT{x - 2, y - 2, x, y}, RGB(160, 160, 160));
		}
	EndPaint(hWnd, &ps);
}

LRESULT CALLBACK StatusBarProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	StatusData &sb = g_statusBars[hWnd];
	switch(msg)
	{
	case WM_NCDESTROY:
		g_statusBars.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintStatusBar(hWnd, sb);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case SB_SETPARTS:
	{
		const int count = std::clamp<int>((int)wParam, 0, 256);
		const int *edges = (const int *)lParam;
		sb.rightEdges.assign(edges, edges + count);
		sb.texts.resize(count);
		sb.textFlags.resize(count);
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case SB_GETPARTS:
	{
		int *edges = (int *)lParam;
		for(int i = 0; edges && i < (int)wParam && i < (int)sb.rightEdges.size(); i++) edges[i] = sb.rightEdges[i];
		return (LRESULT)sb.rightEdges.size();
	}
	case SB_SETTEXTW:
	case SB_SETTEXTA:
	{
		const int part = LOBYTE(LOWORD(wParam));
		std::wstring text;
		if(msg == SB_SETTEXTW) text = lParam ? (LPCWSTR)lParam : L"";
		else if(lParam) { const char *a = (const char *)lParam; text.assign(a, a + strlen(a)); }
		if(part == 255 || sb.simple)
		{
			sb.simpleText = text;
		} else if(part < (int)sb.texts.size())
		{
			sb.texts[part] = text;
			sb.textFlags[part] = HIWORD(wParam) | (wParam & 0xFF00);
		}
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	}
	case SB_GETRECT:
		if(wParam >= sb.rightEdges.size() || !lParam) return FALSE;
		*(RECT *)lParam = StatusPartRect(hWnd, sb, (int)wParam);
		return TRUE;
	case SB_SIMPLE:
		sb.simple = wParam != 0;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Static control (STATIC)
// ---------------------------------------------------------------------------------------------

LRESULT CALLBACK StaticProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	switch(msg)
	{
	case WM_PAINT:
	{
		WindowRecord *rec = GetWindowRecord(hWnd);
		PAINTSTRUCT ps;
		HDC dc = BeginPaint(hWnd, &ps);
		RECT client;
		GetClientRect(hWnd, &client);
		const DWORD style = rec ? rec->style : 0;
		const DWORD type = style & SS_TYPEMASK;
		PrepareControlDC(hWnd, dc, WM_CTLCOLORSTATIC, client, GetSysColor(COLOR_BTNFACE));
		switch(type)
		{
		case SS_BLACKRECT: FillSolid(dc, client, GetSysColor(COLOR_WINDOWFRAME)); break;
		case SS_GRAYRECT: FillSolid(dc, client, GetSysColor(COLOR_BTNSHADOW)); break;
		case SS_WHITERECT: FillSolid(dc, client, GetSysColor(COLOR_WINDOW)); break;
		case SS_BLACKFRAME: Outline(dc, client, GetSysColor(COLOR_WINDOWFRAME)); break;
		case SS_GRAYFRAME: Outline(dc, client, GetSysColor(COLOR_BTNSHADOW)); break;
		case SS_WHITEFRAME: Outline(dc, client, GetSysColor(COLOR_WINDOW)); break;
		case SS_ETCHEDHORZ:
			FillSolid(dc, RECT{client.left, client.top, client.right, client.top + 1}, GetSysColor(COLOR_BTNSHADOW));
			FillSolid(dc, RECT{client.left, client.top + 1, client.right, client.top + 2}, GetSysColor(COLOR_BTNHIGHLIGHT));
			break;
		case SS_ETCHEDVERT:
			FillSolid(dc, RECT{client.left, client.top, client.left + 1, client.bottom}, GetSysColor(COLOR_BTNSHADOW));
			FillSolid(dc, RECT{client.left + 1, client.top, client.left + 2, client.bottom}, GetSysColor(COLOR_BTNHIGHLIGHT));
			break;
		case SS_ETCHEDFRAME:
			Outline(dc, client, GetSysColor(COLOR_BTNSHADOW));
			Outline(dc, RECT{client.left + 1, client.top + 1, client.right + 1, client.bottom + 1}, GetSysColor(COLOR_BTNHIGHLIGHT));
			break;
		case SS_ICON:
		case SS_BITMAP:
		case SS_OWNERDRAW:
			break;
		default:
		{
			const std::wstring text = WindowTextW(hWnd);
			UINT format = (type == SS_CENTER) ? DT_CENTER : (type == SS_RIGHT ? DT_RIGHT : DT_LEFT);
			if(style & SS_CENTERIMAGE) format |= DT_SINGLELINE | DT_VCENTER;
			else if(type != SS_LEFTNOWORDWRAP && type != SS_SIMPLE) format |= DT_WORDBREAK;
			if(style & SS_NOPREFIX) format |= DT_NOPREFIX;
			if(rec && !rec->isEnabled) SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
			RECT textRect = client;
			DrawTextW(dc, text.c_str(), (int)text.size(), &textRect, format);
			break;
		}
		}
		if(style & WS_BORDER) Outline(dc, client, RGB(100, 100, 100));
		if(style & SS_SUNKEN) Outline(dc, client, GetSysColor(COLOR_BTNSHADOW));
		EndPaint(hWnd, &ps);
		return 0;
	}
	case WM_ERASEBKGND:
		return 1;
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
		if(WindowRecord *rec = GetWindowRecord(hWnd); rec && (rec->style & SS_NOTIFY))
			NotifyParentCommand(hWnd, msg == WM_LBUTTONDOWN ? STN_CLICKED : STN_DBLCLK);
		return 0;
	case WM_SETTEXT:
	{
		const LRESULT r = DefWindowProcW(hWnd, msg, wParam, lParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return r;
	}
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Edit control (EDIT), single line
// ---------------------------------------------------------------------------------------------

struct EditData
{
	int selStart = 0, selEnd = 0;
	int limit = 0x7FFFFFFE;
	int scroll = 0;
	int topLine = 0;  // ES_MULTILINE: first visible line
	bool focused = false;
};

std::map<HWND, EditData> g_edits;

bool EditReadOnly(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec && (rec->style & ES_READONLY);
}

int TextWidth(HDC dc, const std::wstring &text, int count)
{
	SIZE size{};
	GetTextExtentPoint32W(dc, text.c_str(), std::min<int>(count, (int)text.size()), &size);
	return size.cx;
}

void ReplaceSelection(HWND hWnd, EditData &ed, const std::wstring &insert, bool notify)
{
	std::wstring text = WindowTextW(hWnd);
	const int a = std::clamp(std::min(ed.selStart, ed.selEnd), 0, (int)text.size());
	const int b = std::clamp(std::max(ed.selStart, ed.selEnd), 0, (int)text.size());
	std::wstring add = insert;
	const int room = ed.limit - ((int)text.size() - (b - a));
	if((int)add.size() > room) add.resize(std::max(room, 0));
	text.replace(a, b - a, add);
	DefWindowProcW(hWnd, WM_SETTEXT, 0, (LPARAM)text.c_str());
	ed.selStart = ed.selEnd = a + (int)add.size();
	InvalidateRect(hWnd, nullptr, FALSE);
	if(notify)
	{
		NotifyParentCommand(hWnd, EN_UPDATE);
		NotifyParentCommand(hWnd, EN_CHANGE);
	}
}

void PaintEdit(HWND hWnd, EditData &ed)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client;
	GetClientRect(hWnd, &client);
	const bool readOnly = EditReadOnly(hWnd), enabled = rec && rec->isEnabled;
	// Read-only and disabled edits ask for the static colour, like Windows.
	PrepareControlDC(hWnd, dc, (readOnly || !enabled) ? WM_CTLCOLORSTATIC : WM_CTLCOLOREDIT, client, GetSysColor((readOnly || !enabled) ? COLOR_BTNFACE : COLOR_WINDOW));
	if(!enabled) SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
	std::wstring text = WindowTextW(hWnd);
	if(rec && (rec->style & ES_PASSWORD)) text.assign(text.size(), L'●');
	const bool border = rec && ((rec->style & WS_BORDER) || (rec->exStyle & WS_EX_CLIENTEDGE));
	RECT textRect = client;
	InflateRect(&textRect, border ? -3 : -1, border ? -1 : 0);
	if(rec && (rec->style & ES_MULTILINE))
	{
		// shortcut: multi-line edits are view-only (wrapped text, wheel scrolling, no caret/selection); add editing when a dialog needs it.
		text.erase(std::remove(text.begin(), text.end(), L'\r'), text.end());
		SIZE lineSize{};
		GetTextExtentPoint32W(dc, L"Ag", 2, &lineSize);
		RECT r = textRect;
		r.top += 1 - ed.topLine * lineSize.cy;
		const UINT wrap = (rec->style & ES_AUTOHSCROLL) && !(rec->style & WS_HSCROLL) ? 0 : DT_WORDBREAK;
		if(border)
			Outline(dc, client, ed.focused ? RGB(0, 120, 215) : RGB(122, 122, 122));
		IntersectClipRect(dc, textRect.left, textRect.top, textRect.right, textRect.bottom);  // last: the shim cannot unclip
		DrawTextW(dc, text.c_str(), (int)text.size(), &r, DT_NOPREFIX | DT_EXPANDTABS | wrap);
		EndPaint(hWnd, &ps);
		return;
	}
	const int textWidth = TextWidth(dc, text, (int)text.size());
	const DWORD align = rec ? (rec->style & (ES_CENTER | ES_RIGHT)) : 0;
	int x = textRect.left - ed.scroll;
	if(align == ES_CENTER) x = textRect.left + std::max(0, (int)(textRect.right - textRect.left - textWidth) / 2);
	else if(align == ES_RIGHT) x = std::max<int>(textRect.left, textRect.right - textWidth);
	SIZE lineSize{};
	GetTextExtentPoint32W(dc, L"Ag", 2, &lineSize);
	const int y = textRect.top + std::max<int>(0, (textRect.bottom - textRect.top - lineSize.cy) / 2);
	const int a = std::min(ed.selStart, ed.selEnd), b = std::max(ed.selStart, ed.selEnd);
	if(ed.focused && a != b)
	{
		const RECT sel{x + TextWidth(dc, text, a), y, x + TextWidth(dc, text, b), y + lineSize.cy};
		FillSolid(dc, sel, GetSysColor(COLOR_HIGHLIGHT));
	}
	TextOutW(dc, x, y, text.c_str(), (int)text.size());
	if(ed.focused && a != b)
	{
		SetTextColor(dc, GetSysColor(COLOR_HIGHLIGHTTEXT));
		TextOutW(dc, x + TextWidth(dc, text, a), y, text.c_str() + a, b - a);
	}
	if(ed.focused && a == b && !readOnly)
	{
		const int cx = x + TextWidth(dc, text, ed.selEnd);
		FillSolid(dc, RECT{cx, y, cx + 1, y + lineSize.cy}, RGB(0, 0, 0));
	}
	if(border)
		Outline(dc, client, ed.focused ? RGB(0, 120, 215) : RGB(122, 122, 122));
	EndPaint(hWnd, &ps);
}

int EditHitTest(HWND hWnd, int px)
{
	HDC dc = GetDC(hWnd);
	SelectObject(dc, ControlFont(hWnd));
	const std::wstring text = WindowTextW(hWnd);
	const EditData &ed = g_edits[hWnd];
	int pos = 0;
	for(; pos < (int)text.size(); pos++)
	{
		const int mid = (TextWidth(dc, text, pos) + TextWidth(dc, text, pos + 1)) / 2;
		if(px + ed.scroll - 3 < mid) break;
	}
	ReleaseDC(hWnd, dc);
	return pos;
}

LRESULT CALLBACK EditProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	EditData &ed = g_edits[hWnd];
	WindowRecord *rec = GetWindowRecord(hWnd);
	const auto len = [&] { return (int)WindowTextW(hWnd).size(); };
	switch(msg)
	{
	case WM_NCDESTROY:
		g_edits.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintEdit(hWnd, ed);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_GETDLGCODE:
		return DLGC_WANTCHARS | DLGC_WANTARROWS | DLGC_HASSETSEL;
	case WM_SETTEXT:
	{
		const LRESULT r = DefWindowProcW(hWnd, msg, wParam, lParam);
		ed.selStart = ed.selEnd = 0;
		ed.scroll = ed.topLine = 0;
		InvalidateRect(hWnd, nullptr, FALSE);
		NotifyParentCommand(hWnd, EN_CHANGE);  // Windows sends EN_CHANGE for WM_SETTEXT too
		return r;
	}
	case WM_SETFOCUS:
		ed.focused = true;
		ed.selStart = 0;
		ed.selEnd = len();
		InvalidateRect(hWnd, nullptr, FALSE);
		NotifyParentCommand(hWnd, EN_SETFOCUS);
		return 0;
	case WM_KILLFOCUS:
		ed.focused = false;
		InvalidateRect(hWnd, nullptr, FALSE);
		NotifyParentCommand(hWnd, EN_KILLFOCUS);
		return 0;
	case WM_LBUTTONDOWN:
		SetFocus(hWnd);
		ed.selStart = ed.selEnd = EditHitTest(hWnd, GET_X_LPARAM(lParam));
		SetCapture(hWnd);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_MOUSEMOVE:
		if(GetCapture() == hWnd)
		{
			ed.selEnd = EditHitTest(hWnd, GET_X_LPARAM(lParam));
			InvalidateRect(hWnd, nullptr, FALSE);
		}
		return 0;
	case WM_LBUTTONUP:
		if(GetCapture() == hWnd) ReleaseCapture();
		return 0;
	case WM_MOUSEWHEEL:
		if(rec && (rec->style & ES_MULTILINE))
		{
			const int delta = -(short)HIWORD(wParam);
			const int lines = delta * 3 / WHEEL_DELTA;
			ed.topLine = std::max(0, ed.topLine + ((lines == 0 && delta != 0) ? (delta > 0 ? 1 : -1) : lines));
			InvalidateRect(hWnd, nullptr, FALSE);
			return 0;
		}
		break;
	case WM_LBUTTONDBLCLK:
		ed.selStart = 0;
		ed.selEnd = len();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_KEYDOWN:
	{
		const bool shift = GetKeyState(VK_SHIFT) < 0;
		const bool ctrl = GetKeyState(VK_CONTROL) < 0;
		int caret = ed.selEnd;
		switch(wParam)
		{
		case VK_LEFT: caret = std::max(0, caret - 1); break;
		case VK_RIGHT: caret = std::min(len(), caret + 1); break;
		case VK_HOME: caret = 0; break;
		case VK_END: caret = len(); break;
		case VK_DELETE:
			if(EditReadOnly(hWnd)) return 0;
			if(ed.selStart == ed.selEnd) ed.selEnd = std::min(len(), ed.selEnd + 1);
			ReplaceSelection(hWnd, ed, L"", true);
			return 0;
		case 'A':
			if(ctrl) { ed.selStart = 0; ed.selEnd = len(); InvalidateRect(hWnd, nullptr, FALSE); }
			return 0;
		case 'C': if(ctrl) SendMessageW(hWnd, WM_COPY, 0, 0); return 0;
		case 'X': if(ctrl) SendMessageW(hWnd, WM_CUT, 0, 0); return 0;
		case 'V': if(ctrl) SendMessageW(hWnd, WM_PASTE, 0, 0); return 0;
		default: return 0;
		}
		ed.selEnd = caret;
		if(!shift) ed.selStart = caret;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	}
	case WM_CHAR:
	{
		if(EditReadOnly(hWnd) || GetKeyState(VK_CONTROL) < 0) return 0;
		const wchar_t c = (wchar_t)wParam;
		if(c == VK_BACK)
		{
			if(ed.selStart == ed.selEnd) ed.selStart = std::max(0, ed.selStart - 1);
			ReplaceSelection(hWnd, ed, L"", true);
		} else if(c >= 32 && c != 127)
		{
			if(rec && (rec->style & ES_NUMBER) && !iswdigit(c)) { MessageBeep(MB_OK); return 0; }
			ReplaceSelection(hWnd, ed, std::wstring(1, c), true);
		} else if(c == VK_RETURN || c == VK_ESCAPE || c == VK_TAB)
		{
			return 0;
		}
		return 0;
	}
	case WM_COPY:
	case WM_CUT:
	{
		const std::wstring text = WindowTextW(hWnd);
		const int a = std::min(ed.selStart, ed.selEnd), b = std::max(ed.selStart, ed.selEnd);
		if(a == b) return 0;
		NSString *s = [[NSString alloc] initWithBytes:text.data() + a length:(NSUInteger)(b - a) * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
		[[NSPasteboard generalPasteboard] clearContents];
		[[NSPasteboard generalPasteboard] setString:s forType:NSPasteboardTypeString];
		if(msg == WM_CUT && !EditReadOnly(hWnd)) ReplaceSelection(hWnd, ed, L"", true);
		return 0;
	}
	case WM_PASTE:
	{
		if(EditReadOnly(hWnd)) return 0;
		NSString *s = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
		if(!s) return 0;
		NSData *data = [s dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
		std::wstring w((const wchar_t *)data.bytes, data.length / sizeof(wchar_t));
		w.erase(std::remove_if(w.begin(), w.end(), [](wchar_t c) { return c == L'\r' || c == L'\n'; }), w.end());
		ReplaceSelection(hWnd, ed, w, true);
		return 0;
	}
	case EM_SETSEL:
	{
		const int n = len();
		int a = (int)wParam, b = (int)lParam;
		if(a == -1) { ed.selStart = ed.selEnd; }
		else
		{
			if(b == -1 || b > n) b = n;
			ed.selStart = std::clamp(a, 0, n);
			ed.selEnd = std::clamp(b, 0, n);
		}
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	}
	case EM_GETSEL:
	{
		const int a = std::min(ed.selStart, ed.selEnd), b = std::max(ed.selStart, ed.selEnd);
		if(wParam) *(DWORD *)wParam = (DWORD)a;
		if(lParam) *(DWORD *)lParam = (DWORD)b;
		return MAKELRESULT(a, b);
	}
	case EM_REPLACESEL:
		ReplaceSelection(hWnd, ed, lParam ? (LPCWSTR)lParam : L"", false);
		return 0;
	case EM_LIMITTEXT:
		ed.limit = wParam ? (int)wParam : 0x7FFFFFFE;
		return 0;
	case EM_GETLIMITTEXT:
		return ed.limit;
	case EM_SETREADONLY:
		if(rec) wParam ? rec->style |= ES_READONLY : rec->style &= ~ES_READONLY;
		InvalidateRect(hWnd, nullptr, FALSE);
		return TRUE;
	case EM_GETMODIFY:
	case EM_SETMODIFY:
	case EM_SETMARGINS:
	case EM_SETCUEBANNER:
		return 0;
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Up-down control (msctls_updown32)
// ---------------------------------------------------------------------------------------------

struct UpDownData
{
	int lower = 0, upper = 100, pos = 0;
	HWND buddy = nullptr;
	int pressed = 0;  // +1 up, -1 down
};

std::map<HWND, UpDownData> g_upDowns;

void UpDownSync(HWND hWnd, UpDownData &ud)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	if(ud.buddy && rec && (rec->style & UDS_SETBUDDYINT))
	{
		const std::wstring text = std::to_wstring(ud.pos);
		SetWindowTextW(ud.buddy, text.c_str());
	}
}

void UpDownStep(HWND hWnd, UpDownData &ud, int delta)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	// Range may be given reversed (lower > upper), in which case "up" decreases the value.
	if(ud.lower > ud.upper) delta = -delta;
	NMUPDOWN nm{};
	nm.hdr.hwndFrom = hWnd;
	nm.hdr.idFrom = (UINT_PTR)GetDlgCtrlID(hWnd);
	nm.hdr.code = UDN_DELTAPOS;
	nm.iPos = ud.pos;
	nm.iDelta = delta;
	HWND parent = GetParent(hWnd);
	if(SendMessageW(parent, WM_NOTIFY, nm.hdr.idFrom, (LPARAM)&nm)) return;  // nonzero cancels
	const int lo = std::min(ud.lower, ud.upper), hi = std::max(ud.lower, ud.upper);
	int next = ud.pos + nm.iDelta;
	if(rec && (rec->style & UDS_WRAP)) next = next > hi ? lo : (next < lo ? hi : next);
	ud.pos = std::clamp(next, lo, hi);
	UpDownSync(hWnd, ud);
	const UINT scrollMsg = (rec && (rec->style & UDS_HORZ)) ? WM_HSCROLL : WM_VSCROLL;
	SendMessageW(parent, scrollMsg, MAKEWPARAM(SB_THUMBPOSITION, ud.pos), (LPARAM)hWnd);
	SendMessageW(parent, scrollMsg, MAKEWPARAM(SB_ENDSCROLL, ud.pos), (LPARAM)hWnd);
}

void PaintUpDown(HWND hWnd, UpDownData &ud)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client;
	GetClientRect(hWnd, &client);
	const int mid = (client.top + client.bottom) / 2;
	const RECT halves[2] = {{client.left, client.top, client.right, mid}, {client.left, mid, client.right, client.bottom}};
	for(int i = 0; i < 2; i++)
	{
		const bool down = (i == 0 && ud.pressed > 0) || (i == 1 && ud.pressed < 0);
		FillSolid(dc, halves[i], down ? RGB(204, 228, 247) : RGB(225, 225, 225));
		Outline(dc, halves[i], down ? RGB(0, 84, 153) : RGB(173, 173, 173));
		// Arrow
		const int cx = (halves[i].left + halves[i].right) / 2, cy = (halves[i].top + halves[i].bottom) / 2;
		for(int row = 0; row < 3; row++)
		{
			const int y = i == 0 ? cy - 1 + row : cy + 1 - row;
			FillSolid(dc, RECT{cx - row, y, cx + row + 1, y + 1}, RGB(96, 96, 96));
		}
	}
	EndPaint(hWnd, &ps);
}

LRESULT CALLBACK UpDownProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	UpDownData &ud = g_upDowns[hWnd];
	WindowRecord *rec = GetWindowRecord(hWnd);
	switch(msg)
	{
	case WM_CREATE:
		// UDS_AUTOBUDDY: the previously created sibling becomes the buddy.
		if(rec && (rec->style & UDS_AUTOBUDDY)) ud.buddy = GetWindow(hWnd, GW_HWNDPREV);
		return 0;
	case WM_NCDESTROY:
		g_upDowns.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintUpDown(hWnd, ud);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
	{
		RECT client;
		GetClientRect(hWnd, &client);
		ud.pressed = GET_Y_LPARAM(lParam) < (client.top + client.bottom) / 2 ? 1 : -1;
		InvalidateRect(hWnd, nullptr, FALSE);
		UpDownStep(hWnd, ud, ud.pressed);
		SetCapture(hWnd);
		return 0;
	}
	case WM_LBUTTONUP:
		ud.pressed = 0;
		ReleaseCapture();
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case UDM_SETRANGE:
		ud.upper = (short)LOWORD(lParam);
		ud.lower = (short)HIWORD(lParam);
		return 0;
	case UDM_SETRANGE32:
		ud.lower = (int)wParam;
		ud.upper = (int)lParam;
		return 0;
	case UDM_GETRANGE:
		return MAKELONG((short)ud.upper, (short)ud.lower);
	case UDM_GETRANGE32:
		if(wParam) *(int *)wParam = ud.lower;
		if(lParam) *(int *)lParam = ud.upper;
		return 0;
	case UDM_SETPOS:
	case UDM_SETPOS32:
	{
		const int old = ud.pos;
		ud.pos = msg == UDM_SETPOS ? (short)LOWORD(lParam) : (int)lParam;
		UpDownSync(hWnd, ud);
		return old;
	}
	case UDM_GETPOS:
		return MAKELONG((short)ud.pos, 0);
	case UDM_GETPOS32:
		if(lParam) *(BOOL *)lParam = FALSE;
		return ud.pos;
	case UDM_SETBUDDY:
	{
		HWND old = ud.buddy;
		ud.buddy = (HWND)wParam;
		return (LRESULT)old;
	}
	case UDM_GETBUDDY:
		return (LRESULT)ud.buddy;
	case UDM_SETACCEL:
	case UDM_SETBASE:
		return TRUE;
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Button (BUTTON): push buttons, check boxes, radio buttons, group boxes
// ---------------------------------------------------------------------------------------------

struct ButtonData
{
	int check = BST_UNCHECKED;
	bool pushed = false, hot = false, focused = false;
	HANDLE image = nullptr;
	UINT imageType = IMAGE_BITMAP;
};

std::map<HWND, ButtonData> g_buttons;

DWORD ButtonType(HWND hWnd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	return rec ? (rec->style & BS_TYPEMASK) : BS_PUSHBUTTON;
}

bool IsCheckType(DWORD type) { return type == BS_CHECKBOX || type == BS_AUTOCHECKBOX || type == BS_3STATE || type == BS_AUTO3STATE; }
bool IsRadioType(DWORD type) { return type == BS_RADIOBUTTON || type == BS_AUTORADIOBUTTON; }

void DrawCaption(HDC dc, HWND hWnd, RECT r, UINT format)
{
	const std::wstring text = WindowTextW(hWnd);
	DrawTextW(dc, text.c_str(), (int)text.size(), &r, format);
}

void PaintPushButton(HWND hWnd, HDC dc, const RECT &client, const ButtonData &bd, bool isDefault, bool enabled, bool down)
{
	COLORREF fill = RGB(225, 225, 225), border = RGB(173, 173, 173);
	if(!enabled) { fill = RGB(204, 204, 204); border = RGB(191, 191, 191); }
	else if(down) { fill = RGB(204, 228, 247); border = RGB(0, 84, 153); }
	else if(bd.hot) { fill = RGB(229, 241, 251); border = RGB(0, 120, 215); }
	else if(isDefault || bd.focused) { border = RGB(0, 120, 215); }
	FillSolid(dc, client, fill);
	Outline(dc, client, border);
	if(isDefault && enabled && !down) Outline(dc, RECT{client.left + 1, client.top + 1, client.right - 1, client.bottom - 1}, border);
	SetTextColor(dc, GetSysColor(enabled ? COLOR_BTNTEXT : COLOR_GRAYTEXT));
	if(bd.image)
	{
		int w = 0, h = 0;
		CGImageRef image = nullptr;
		if(bd.imageType == IMAGE_ICON && ((HICON)bd.image)->image)
		{
			NSImage *ns = ((HICON)bd.image)->image;
			w = (int)ns.size.width; h = (int)ns.size.height;
			NSRect rect = NSMakeRect(0, 0, w, h);
			image = [ns CGImageForProposedRect:&rect context:nil hints:nil];
		} else if(bd.imageType == IMAGE_BITMAP && ((MacBitmap *)bd.image)->bitmapContext)
		{
			w = ((MacBitmap *)bd.image)->width; h = ((MacBitmap *)bd.image)->height;
			image = CGBitmapContextCreateImage(((MacBitmap *)bd.image)->bitmapContext);
			CFAutorelease(image);
		}
		// Image and caption are centred together, image first (comctl32 v6 behaviour).
		const std::wstring caption = WindowTextW(hWnd);
		SIZE textSize{};
		if(!caption.empty()) GetTextExtentPoint32W(dc, caption.c_str(), (int)caption.size(), &textSize);
		const int left = (client.left + client.right - w - textSize.cx) / 2 + (bd.pushed ? 1 : 0);
		DrawImageRect(dc, image, left, (client.top + client.bottom - h) / 2 + (bd.pushed ? 1 : 0), w, h, enabled ? 1.0 : 0.5);
		if(!caption.empty())
			DrawCaption(dc, hWnd, RECT{left + w, client.top, client.right, client.bottom}, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
		return;
	}
	RECT text = client;
	if(down) OffsetRect(&text, 1, 1);
	WindowRecord *rec = GetWindowRecord(hWnd);
	UINT format = DT_CENTER | DT_VCENTER | DT_SINGLELINE;
	if(rec && (rec->style & BS_MULTILINE)) format = DT_CENTER | DT_WORDBREAK;
	if(rec && (rec->style & BS_LEFT) && !(rec->style & BS_RIGHT)) { format = (format & ~DT_CENTER) | DT_LEFT; text.left += 6; }
	DrawCaption(dc, hWnd, text, format);
}

void PaintCheckOrRadio(HWND hWnd, HDC dc, const RECT &client, const ButtonData &bd, bool radio, bool enabled)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	const bool rightButton = rec && (rec->style & BS_LEFTTEXT);
	const int box = 13;
	const int top = (rec && (rec->style & BS_TOP)) ? client.top + 1 : (client.top + client.bottom - box) / 2;
	const int left = rightButton ? client.right - box : client.left;
	const RECT boxRect{left, top, left + box, top + box};
	const COLORREF border = !enabled ? RGB(204, 204, 204) : (bd.pushed ? RGB(0, 84, 153) : (bd.hot ? RGB(0, 120, 215) : RGB(51, 51, 51)));
	const COLORREF mark = !enabled ? RGB(204, 204, 204) : (bd.pushed ? RGB(0, 84, 153) : (bd.hot ? RGB(0, 120, 215) : RGB(51, 51, 51)));
	if(radio)
	{
		CGContextRef ctx = dc->cgContext;
		if(ctx)
		{
			const CGRect r = CGRectMake(boxRect.left + dc->viewportOrg.x + 0.5, boxRect.top + dc->viewportOrg.y + 0.5, box - 1, box - 1);
			CGContextSetRGBFillColor(ctx, bd.pushed ? 204 / 255.0 : 1, bd.pushed ? 228 / 255.0 : 1, bd.pushed ? 247 / 255.0 : 1, 1);
			CGContextFillEllipseInRect(ctx, r);
			CGContextSetRGBStrokeColor(ctx, GetRValue(border) / 255.0, GetGValue(border) / 255.0, GetBValue(border) / 255.0, 1);
			CGContextSetLineWidth(ctx, 1);
			CGContextStrokeEllipseInRect(ctx, r);
			if(bd.check == BST_CHECKED)
			{
				CGContextSetRGBFillColor(ctx, GetRValue(mark) / 255.0, GetGValue(mark) / 255.0, GetBValue(mark) / 255.0, 1);
				CGContextFillEllipseInRect(ctx, CGRectInset(r, 3, 3));
			}
		}
	} else
	{
		FillSolid(dc, boxRect, bd.pushed ? RGB(204, 228, 247) : RGB(255, 255, 255));
		Outline(dc, boxRect, border);
		if(bd.check == BST_CHECKED && dc->cgContext)
		{
			// The Windows 10 check mark: a short and a long stroke.
			CGContextRef ctx = dc->cgContext;
			const CGFloat ox = boxRect.left + dc->viewportOrg.x, oy = boxRect.top + dc->viewportOrg.y;
			CGContextSetRGBStrokeColor(ctx, GetRValue(mark) / 255.0, GetGValue(mark) / 255.0, GetBValue(mark) / 255.0, 1);
			CGContextSetLineWidth(ctx, 1.5);
			CGContextMoveToPoint(ctx, ox + 3, oy + 6.5);
			CGContextAddLineToPoint(ctx, ox + 5.5, oy + 9);
			CGContextAddLineToPoint(ctx, ox + 10, oy + 3.5);
			CGContextStrokePath(ctx);
		} else if(bd.check == BST_INDETERMINATE)
		{
			FillSolid(dc, RECT{boxRect.left + 3, boxRect.top + 3, boxRect.right - 3, boxRect.bottom - 3}, mark);
		}
	}
	SetTextColor(dc, GetSysColor(enabled ? COLOR_BTNTEXT : COLOR_GRAYTEXT));
	RECT text = client;
	if(rightButton) text.right = boxRect.left - 4;
	else text.left = boxRect.right + 4;
	UINT format = DT_LEFT | ((rec && (rec->style & BS_MULTILINE)) ? DT_WORDBREAK | DT_VCENTER : DT_SINGLELINE | DT_VCENTER);
	if(rec && (rec->style & BS_TOP)) format = (format & ~DT_VCENTER) | DT_TOP;
	DrawCaption(dc, hWnd, text, format);
}

void PaintGroupBox(HWND hWnd, HDC dc, const RECT &client, bool enabled)
{
	SIZE textSize{};
	const std::wstring text = WindowTextW(hWnd);
	GetTextExtentPoint32W(dc, text.empty() ? L"A" : text.c_str(), text.empty() ? 1 : (int)text.size(), &textSize);
	const int lineY = client.top + textSize.cy / 2;
	const COLORREF line = RGB(220, 220, 220);
	FillSolid(dc, RECT{client.left, lineY, client.right, lineY + 1}, line);
	FillSolid(dc, RECT{client.left, client.bottom - 1, client.right, client.bottom}, line);
	FillSolid(dc, RECT{client.left, lineY, client.left + 1, client.bottom}, line);
	FillSolid(dc, RECT{client.right - 1, lineY, client.right, client.bottom}, line);
	if(!text.empty())
	{
		RECT textRect{client.left + 6, client.top, client.left + 6 + textSize.cx + 4, client.top + textSize.cy};
		FillSolid(dc, textRect, GetSysColor(COLOR_BTNFACE));
		SetTextColor(dc, GetSysColor(enabled ? COLOR_BTNTEXT : COLOR_GRAYTEXT));
		textRect.left += 2;
		DrawCaption(dc, hWnd, textRect, DT_LEFT | DT_SINGLELINE);
	}
}

void PaintButton(HWND hWnd, ButtonData &bd)
{
	WindowRecord *rec = GetWindowRecord(hWnd);
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	RECT client;
	GetClientRect(hWnd, &client);
	const DWORD type = ButtonType(hWnd);
	const bool enabled = rec && rec->isEnabled;
	if(type == BS_OWNERDRAW)
	{
		DRAWITEMSTRUCT dis{};
		dis.CtlType = ODT_BUTTON;
		dis.CtlID = (UINT)GetDlgCtrlID(hWnd);
		dis.itemAction = ODA_DRAWENTIRE;
		dis.itemState = (bd.pushed ? ODS_SELECTED : 0) | (enabled ? 0 : ODS_DISABLED) | (bd.focused ? ODS_FOCUS : 0) | (bd.check ? ODS_CHECKED : 0);
		dis.hwndItem = hWnd;
		dis.hDC = dc;
		dis.rcItem = client;
		SendMessageW(GetParent(hWnd), WM_DRAWITEM, dis.CtlID, (LPARAM)&dis);
		EndPaint(hWnd, &ps);
		return;
	}
	if(type == BS_GROUPBOX)
	{
		// Only the frame and caption: the inside shows the controls underneath, as on Windows.
		SetBkMode(dc, TRANSPARENT);
		SelectObject(dc, ControlFont(hWnd));
		PaintGroupBox(hWnd, dc, client, enabled);
		EndPaint(hWnd, &ps);
		return;
	}
	PrepareControlDC(hWnd, dc, WM_CTLCOLORBTN, client, GetSysColor(COLOR_BTNFACE));
	const bool pushLike = rec && (rec->style & BS_PUSHLIKE);
	if((IsCheckType(type) || IsRadioType(type)) && !pushLike)
		PaintCheckOrRadio(hWnd, dc, client, bd, IsRadioType(type), enabled);
	else
		PaintPushButton(hWnd, dc, client, bd, type == BS_DEFPUSHBUTTON, enabled, bd.pushed || (pushLike && bd.check == BST_CHECKED));
	EndPaint(hWnd, &ps);
}

// Auto radio buttons uncheck the other radio buttons of their group (siblings between WS_GROUP markers).
void CheckRadioInGroup(HWND hWnd)
{
	HWND parent = GetParent(hWnd);
	WindowRecord *parentRec = GetWindowRecord(parent);
	if(!parentRec) return;
	const auto &siblings = parentRec->children;
	auto self = std::find(siblings.begin(), siblings.end(), hWnd);
	if(self == siblings.end()) return;
	auto first = self;
	while(first != siblings.begin())
	{
		WindowRecord *r = GetWindowRecord(*first);
		if(r && (r->style & WS_GROUP)) break;
		--first;
	}
	for(auto it = first; it != siblings.end(); ++it)
	{
		WindowRecord *r = GetWindowRecord(*it);
		if(it != first && r && (r->style & WS_GROUP)) break;
		if(*it != hWnd && IsRadioType(ButtonType(*it))) SendMessageW(*it, BM_SETCHECK, BST_UNCHECKED, 0);
	}
}

LRESULT CALLBACK ButtonProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	ButtonData &bd = g_buttons[hWnd];
	WindowRecord *rec = GetWindowRecord(hWnd);
	switch(msg)
	{
	case WM_NCDESTROY:
		g_buttons.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintButton(hWnd, bd);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_GETDLGCODE:
	{
		const DWORD type = ButtonType(hWnd);
		if(type == BS_DEFPUSHBUTTON) return DLGC_DEFPUSHBUTTON | DLGC_BUTTON;
		if(type == BS_PUSHBUTTON) return DLGC_UNDEFPUSHBUTTON | DLGC_BUTTON;
		if(IsRadioType(type)) return DLGC_RADIOBUTTON | DLGC_BUTTON;
		if(type == BS_GROUPBOX) return DLGC_STATIC;
		return DLGC_BUTTON;
	}
	case WM_SETTEXT:
	case WM_ENABLE:
	{
		const LRESULT r = DefWindowProcW(hWnd, msg, wParam, lParam);
		InvalidateRect(hWnd, nullptr, FALSE);
		return r;
	}
	case WM_SETFOCUS:
	case WM_KILLFOCUS:
		bd.focused = msg == WM_SETFOCUS;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_MOUSEMOVE:
		if(!bd.hot) { bd.hot = true; InvalidateRect(hWnd, nullptr, FALSE); }
		if(GetCapture() == hWnd)
		{
			RECT client;
			GetClientRect(hWnd, &client);
			const bool inside = PtInRect(&client, POINT{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)});
			if(inside != bd.pushed) { bd.pushed = inside; InvalidateRect(hWnd, nullptr, FALSE); }
		}
		return 0;
	case WM_MOUSELEAVE:
		bd.hot = false;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
		if(ButtonType(hWnd) == BS_GROUPBOX) return 0;
		bd.pushed = true;
		SetCapture(hWnd);
		if(rec && (rec->style & WS_TABSTOP)) SetFocus(hWnd);
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case WM_LBUTTONUP:
	{
		if(GetCapture() != hWnd) return 0;
		ReleaseCapture();
		const bool clicked = bd.pushed;
		bd.pushed = false;
		InvalidateRect(hWnd, nullptr, FALSE);
		if(clicked) SendMessageW(hWnd, BM_CLICK, 0, 0);
		return 0;
	}
	case BM_CLICK:
	{
		const DWORD type = ButtonType(hWnd);
		if(type == BS_AUTOCHECKBOX) SendMessageW(hWnd, BM_SETCHECK, bd.check == BST_CHECKED ? BST_UNCHECKED : BST_CHECKED, 0);
		else if(type == BS_AUTO3STATE) SendMessageW(hWnd, BM_SETCHECK, (bd.check + 1) % 3, 0);
		else if(type == BS_AUTORADIOBUTTON) { SendMessageW(hWnd, BM_SETCHECK, BST_CHECKED, 0); CheckRadioInGroup(hWnd); }
		NotifyParentCommand(hWnd, BN_CLICKED);
		return 0;
	}
	case BM_GETCHECK:
		return bd.check;
	case BM_SETCHECK:
		if(bd.check != (int)wParam) { bd.check = (int)wParam; InvalidateRect(hWnd, nullptr, FALSE); }
		if(rec) rec->checkState = bd.check;
		return 0;
	case BM_GETSTATE:
		return bd.check | (bd.pushed ? BST_PUSHED : 0) | (bd.focused ? BST_FOCUS : 0);
	case BM_SETSTATE:
		bd.pushed = wParam != 0;
		InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case BM_SETSTYLE:
		if(rec) rec->style = (rec->style & ~0xFFFF) | (DWORD)LOWORD(wParam);
		if(lParam) InvalidateRect(hWnd, nullptr, FALSE);
		return 0;
	case BM_SETIMAGE:
	{
		HANDLE old = bd.image;
		bd.imageType = (UINT)wParam;
		bd.image = (HANDLE)lParam;
		InvalidateRect(hWnd, nullptr, FALSE);
		return (LRESULT)old;
	}
	case BM_GETIMAGE:
		return (bd.imageType == wParam) ? (LRESULT)bd.image : 0;
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// ---------------------------------------------------------------------------------------------
// Dialog (#32770)
// ---------------------------------------------------------------------------------------------

LRESULT CALLBACK DialogProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	switch(msg)
	{
	case WM_ERASEBKGND:
	{
		RECT client;
		GetClientRect(hWnd, &client);
		HDC dc = (HDC)wParam;
		// Windows asks the dialog itself for its background brush.
		HBRUSH brush = (HBRUSH)SendMessageW(hWnd, WM_CTLCOLORDLG, (WPARAM)dc, (LPARAM)hWnd);
		if(brush) FillRect(dc, &client, brush);
		else FillSolid(dc, client, GetSysColor(COLOR_BTNFACE));
		return 1;
	}
	case WM_PAINT:
	{
		PAINTSTRUCT ps;
		BeginPaint(hWnd, &ps);
		EndPaint(hWnd, &ps);
		return 0;
	}
	case WM_CLOSE:
		// Like DefDlgProc: closing a dialog means pressing Cancel.
		SendMessageW(hWnd, WM_COMMAND, MAKEWPARAM(IDCANCEL, BN_CLICKED), 0);
		return 0;
	default:
		return DefWindowProcW(hWnd, msg, wParam, lParam);
	}
}

// MDI client: children are maximized, so they follow the client's size.
LRESULT CALLBACK MDIClientProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	if(msg == WM_SIZE)
	{
		WindowRecord *rec = GetWindowRecord(hWnd);
		const std::vector<HWND> children = rec ? rec->children : std::vector<HWND>();
		for(HWND child : children) MoveWindow(child, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
		return 0;
	}
	return DefWindowProcW(hWnd, msg, wParam, lParam);
}

// ---------------------------------------------------------------------------------------------
// SysTabControl32
// ---------------------------------------------------------------------------------------------

struct TabItemData {
	std::wstring text;
	LPARAM lParam = 0;
	int image = -1;
	DWORD state = 0;
};
struct TabControlData {
	std::vector<TabItemData> items;
	int curSel = 0;
	int curFocus = 0;
	HIMAGELIST imageList = nullptr;
};
static std::unordered_map<HWND, TabControlData> g_tabCtrls;

static int TabHitTest(HWND hWnd, const TabControlData &td, POINT pt)
{
	RECT client;
	GetClientRect(hWnd, &client);
	const int tabH = 26;
	if(pt.y < client.top || pt.y > client.top + tabH) return -1;

	HDC dc = GetDC(hWnd);
	HFONT font = ControlFont(hWnd);
	HGDIOBJ oldFont = SelectObject(dc, font);

	int curX = client.left + 2;
	int hit = -1;
	for(size_t i = 0; i < td.items.size(); ++i)
	{
		const auto &item = td.items[i];
		SIZE textSize{0, 0};
		if(!item.text.empty())
			GetTextExtentPoint32W(dc, item.text.c_str(), (int)item.text.size(), &textSize);
		int tabW = textSize.cx + 18;
		if(item.image >= 0 && td.imageList) tabW += 20;
		if(tabW < 40) tabW = 40;

		if(pt.x >= curX && pt.x < curX + tabW)
		{
			hit = (int)i;
			break;
		}
		curX += tabW + 2;
	}
	SelectObject(dc, oldFont);
	ReleaseDC(hWnd, dc);
	return hit;
}

static void PaintTabCtrl(HWND hWnd, TabControlData &td)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	if(!dc) return;
	RECT client;
	GetClientRect(hWnd, &client);

	const int tabH = 26;
	FillSolid(dc, client, GetSysColor(COLOR_BTNFACE));
	FillSolid(dc, RECT{client.left, client.top + tabH - 1, client.right, client.top + tabH}, RGB(180, 180, 180));

	HFONT font = ControlFont(hWnd);
	HGDIOBJ oldFont = SelectObject(dc, font);
	SetBkMode(dc, TRANSPARENT);

	int curX = client.left + 2;
	for(size_t i = 0; i < td.items.size(); ++i)
	{
		const bool selected = ((int)i == td.curSel);
		const auto &item = td.items[i];
		SIZE textSize{0, 0};
		if(!item.text.empty())
			GetTextExtentPoint32W(dc, item.text.c_str(), (int)item.text.size(), &textSize);
		int tabW = textSize.cx + 18;
		if(item.image >= 0 && td.imageList) tabW += 20;
		if(tabW < 40) tabW = 40;

		RECT tabRect{curX, client.top + (selected ? 0 : 2), curX + tabW, client.top + tabH + (selected ? 1 : 0)};
		FillSolid(dc, tabRect, selected ? RGB(255, 255, 255) : RGB(230, 230, 230));
		FillSolid(dc, RECT{tabRect.left, tabRect.top, tabRect.left + 1, tabRect.bottom}, RGB(180, 180, 180));
		FillSolid(dc, RECT{tabRect.left, tabRect.top, tabRect.right, tabRect.top + 1}, RGB(180, 180, 180));
		FillSolid(dc, RECT{tabRect.right - 1, tabRect.top, tabRect.right, tabRect.bottom}, RGB(180, 180, 180));
		if(!selected)
			FillSolid(dc, RECT{tabRect.left, client.top + tabH - 1, tabRect.right, client.top + tabH}, RGB(180, 180, 180));

		int contentX = tabRect.left + 8;
		if(item.image >= 0 && td.imageList)
		{
			ImageList_Draw(td.imageList, item.image, dc, contentX, tabRect.top + (tabRect.bottom - tabRect.top - 16) / 2, ILD_NORMAL);
			contentX += 20;
		}

		RECT textRect{contentX, tabRect.top, tabRect.right - 4, tabRect.bottom};
		SetTextColor(dc, RGB(0, 0, 0));
		DrawTextW(dc, item.text.c_str(), (int)item.text.size(), &textRect, DT_LEFT | DT_VCENTER | DT_SINGLELINE);

		curX += tabW + 2;
	}

	SelectObject(dc, oldFont);
	EndPaint(hWnd, &ps);
}

static std::wstring ToWStr(LPCSTR s)
{
	if(!s) return L"";
	int len = MultiByteToWideChar(CP_UTF8, 0, s, -1, nullptr, 0);
	if(len <= 1) return L"";
	std::wstring w(len - 1, 0);
	MultiByteToWideChar(CP_UTF8, 0, s, -1, w.data(), len);
	return w;
}

LRESULT CALLBACK TabCtrlProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	TabControlData &td = g_tabCtrls[hWnd];
	switch(msg)
	{
	case WM_NCDESTROY:
		g_tabCtrls.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintTabCtrl(hWnd, td);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_LBUTTONDOWN:
	{
		POINT pt{GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
		int hit = TabHitTest(hWnd, td, pt);
		if(hit >= 0 && hit < (int)td.items.size() && hit != td.curSel)
		{
			td.curSel = hit;
			td.curFocus = hit;
			InvalidateRect(hWnd, nullptr, TRUE);
			NMHDR nmhdr{hWnd, (UINT_PTR)GetWindowLongPtrW(hWnd, GWLP_ID), (UINT)TCN_SELCHANGE};
			SendMessageW(GetParent(hWnd), WM_NOTIFY, (WPARAM)nmhdr.idFrom, (LPARAM)&nmhdr);
		}
		return 0;
	}
	case TCM_INSERTITEMW:
	case TCM_INSERTITEMA:
	{
		int index = (int)wParam;
		const TCITEMW *item = (const TCITEMW *)lParam;
		TabItemData ti;
		if(item)
		{
			if((item->mask & TCIF_TEXT) && item->pszText)
			{
				if(msg == TCM_INSERTITEMW)
					ti.text = item->pszText;
				else
					ti.text = ToWStr((LPCSTR)item->pszText);
			}
			if(item->mask & TCIF_PARAM) ti.lParam = item->lParam;
			if(item->mask & TCIF_IMAGE) ti.image = item->iImage;
			if(item->mask & TCIF_STATE) ti.state = item->dwState;
		}
		if(index < 0 || index >= (int)td.items.size())
		{
			index = (int)td.items.size();
			td.items.push_back(std::move(ti));
		} else
		{
			td.items.insert(td.items.begin() + index, std::move(ti));
		}
		InvalidateRect(hWnd, nullptr, TRUE);
		return index;
	}
	case TCM_GETITEMW:
	case TCM_GETITEMA:
	{
		int index = (int)wParam;
		TCITEMW *item = (TCITEMW *)lParam;
		if(index < 0 || index >= (int)td.items.size() || !item) return FALSE;
		const auto &ti = td.items[index];
		if(item->mask & TCIF_PARAM) item->lParam = ti.lParam;
		if(item->mask & TCIF_IMAGE) item->iImage = ti.image;
		if(item->mask & TCIF_STATE) item->dwState = ti.state;
		if((item->mask & TCIF_TEXT) && item->pszText && item->cchTextMax > 0)
		{
			if(msg == TCM_GETITEMW)
			{
				wcsncpy(item->pszText, ti.text.c_str(), item->cchTextMax);
				item->pszText[item->cchTextMax - 1] = 0;
			} else
			{
				WideCharToMultiByte(CP_UTF8, 0, ti.text.c_str(), -1, (char *)item->pszText, item->cchTextMax, nullptr, nullptr);
				((char *)item->pszText)[item->cchTextMax - 1] = 0;
			}
		}
		return TRUE;
	}
	case TCM_SETITEMW:
	case TCM_SETITEMA:
	{
		int index = (int)wParam;
		const TCITEMW *item = (const TCITEMW *)lParam;
		if(index < 0 || index >= (int)td.items.size() || !item) return FALSE;
		auto &ti = td.items[index];
		if(item->mask & TCIF_PARAM) ti.lParam = item->lParam;
		if(item->mask & TCIF_IMAGE) ti.image = item->iImage;
		if(item->mask & TCIF_STATE) ti.state = item->dwState;
		if((item->mask & TCIF_TEXT) && item->pszText)
		{
			if(msg == TCM_SETITEMW) ti.text = item->pszText;
			else ti.text = ToWStr((LPCSTR)item->pszText);
		}
		InvalidateRect(hWnd, nullptr, TRUE);
		return TRUE;
	}
	case TCM_DELETEITEM:
	{
		int index = (int)wParam;
		if(index >= 0 && index < (int)td.items.size())
		{
			td.items.erase(td.items.begin() + index);
			if(td.curSel >= (int)td.items.size()) td.curSel = (int)td.items.size() - 1;
			InvalidateRect(hWnd, nullptr, TRUE);
			return TRUE;
		}
		return FALSE;
	}
	case TCM_DELETEALLITEMS:
		td.items.clear();
		td.curSel = -1;
		InvalidateRect(hWnd, nullptr, TRUE);
		return TRUE;
	case TCM_GETITEMCOUNT:
		return (LRESULT)td.items.size();
	case TCM_GETCURSEL:
		return td.curSel;
	case TCM_SETCURSEL:
	{
		int old = td.curSel;
		td.curSel = (int)wParam;
		InvalidateRect(hWnd, nullptr, TRUE);
		return old;
	}
	case TCM_GETCURFOCUS:
		return td.curFocus;
	case TCM_SETCURFOCUS:
		td.curFocus = (int)wParam;
		return 0;
	case TCM_ADJUSTRECT:
	{
		BOOL bLarger = (BOOL)wParam;
		LPRECT rc = (LPRECT)lParam;
		if(!rc) return 0;
		const int tabH = 26;
		if(bLarger) rc->top -= tabH;
		else rc->top += tabH;
		return 0;
	}
	case TCM_GETITEMRECT:
	{
		int index = (int)wParam;
		LPRECT rc = (LPRECT)lParam;
		if(!rc || index < 0 || index >= (int)td.items.size()) return FALSE;
		RECT client;
		GetClientRect(hWnd, &client);
		const int tabH = 26;
		HDC dc = GetDC(hWnd);
		HFONT font = ControlFont(hWnd);
		HGDIOBJ oldFont = SelectObject(dc, font);
		int curX = client.left + 2;
		for(int i = 0; i <= index; ++i)
		{
			const auto &item = td.items[i];
			SIZE textSize{0, 0};
			if(!item.text.empty())
				GetTextExtentPoint32W(dc, item.text.c_str(), (int)item.text.size(), &textSize);
			int tabW = textSize.cx + 18;
			if(item.image >= 0 && td.imageList) tabW += 20;
			if(tabW < 40) tabW = 40;
			if(i == index)
			{
				*rc = RECT{curX, client.top, curX + tabW, client.top + tabH};
				break;
			}
			curX += tabW + 2;
		}
		SelectObject(dc, oldFont);
		ReleaseDC(hWnd, dc);
		return TRUE;
	}
	case TCM_HITTEST:
	{
		TCHITTESTINFO *info = (TCHITTESTINFO *)lParam;
		if(!info) return -1;
		int hit = TabHitTest(hWnd, td, info->pt);
		info->flags = (hit >= 0) ? 0x0006 : 0x0001;
		return hit;
	}
	case TCM_SETIMAGELIST:
	{
		HIMAGELIST old = td.imageList;
		td.imageList = (HIMAGELIST)lParam;
		InvalidateRect(hWnd, nullptr, TRUE);
		return (LRESULT)old;
	}
	case TCM_GETIMAGELIST:
		return (LRESULT)td.imageList;
	}
	return DefWindowProcW(hWnd, msg, wParam, lParam);
}

// ---------------------------------------------------------------------------------------------
// msctls_trackbar32
// ---------------------------------------------------------------------------------------------

struct TrackbarControlData {
	int minVal = 0;
	int maxVal = 100;
	int pos = 0;
	int lineSize = 1;
	int pageSize = 10;
	bool dragging = false;
};
static std::unordered_map<HWND, TrackbarControlData> g_trackbars;

static void GetTrackbarMetrics(HWND hWnd, const TrackbarControlData &td, RECT &chanRect, RECT &thumbRect)
{
	RECT client;
	GetClientRect(hWnd, &client);
	WindowRecord *rec = GetWindowRecord(hWnd);
	const bool vertical = rec && (rec->style & TBS_VERT);
	if(vertical)
	{
		const int cx = (client.left + client.right) / 2;
		chanRect = RECT{cx - 2, client.top + 6, cx + 2, client.bottom - 6};
		const int availH = std::max(1, (int)(chanRect.bottom - chanRect.top - 18));
		const int range = std::max(1, td.maxVal - td.minVal);
		const int thumbY = chanRect.top + (td.pos - td.minVal) * availH / range;
		thumbRect = RECT{client.left + 2, thumbY, client.right - 2, thumbY + 18};
	} else
	{
		const int cy = (client.top + client.bottom) / 2;
		chanRect = RECT{client.left + 6, cy - 2, client.right - 6, cy + 2};
		const int availW = std::max(1, (int)(chanRect.right - chanRect.left - 11));
		const int range = std::max(1, td.maxVal - td.minVal);
		const int thumbX = chanRect.left + (td.pos - td.minVal) * availW / range;
		thumbRect = RECT{thumbX, client.top + 2, thumbX + 11, client.bottom - 2};
	}
}

static void PaintTrackbar(HWND hWnd, TrackbarControlData &td)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	if(!dc) return;
	RECT client;
	GetClientRect(hWnd, &client);
	FillSolid(dc, client, GetSysColor(COLOR_BTNFACE));

	RECT chan, thumb;
	GetTrackbarMetrics(hWnd, td, chan, thumb);
	FillSolid(dc, chan, RGB(200, 200, 200));
	Outline(dc, chan, RGB(160, 160, 160));
	FillSolid(dc, thumb, td.dragging ? RGB(204, 228, 247) : RGB(235, 235, 235));
	Outline(dc, thumb, td.dragging ? RGB(0, 84, 153) : RGB(140, 140, 140));

	EndPaint(hWnd, &ps);
}

LRESULT CALLBACK TrackbarProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	TrackbarControlData &td = g_trackbars[hWnd];
	WindowRecord *rec = GetWindowRecord(hWnd);
	const bool vertical = rec && (rec->style & TBS_VERT);
	switch(msg)
	{
	case WM_NCDESTROY:
		g_trackbars.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintTrackbar(hWnd, td);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case WM_LBUTTONDOWN:
	{
		SetCapture(hWnd);
		td.dragging = true;
		RECT chan, thumb;
		GetTrackbarMetrics(hWnd, td, chan, thumb);
		const int range = std::max(1, td.maxVal - td.minVal);
		if(vertical)
		{
			const int availH = std::max(1, (int)(chan.bottom - chan.top - 18));
			const int clickY = std::clamp((int)GET_Y_LPARAM(lParam) - chan.top - 9, 0, availH);
			td.pos = td.minVal + (clickY * range + availH / 2) / availH;
		} else
		{
			const int availW = std::max(1, (int)(chan.right - chan.left - 11));
			const int clickX = std::clamp((int)GET_X_LPARAM(lParam) - chan.left - 5, 0, availW);
			td.pos = td.minVal + (clickX * range + availW / 2) / availW;
		}
		InvalidateRect(hWnd, nullptr, TRUE);
		SendMessageW(GetParent(hWnd), vertical ? WM_VSCROLL : WM_HSCROLL, MAKEWPARAM(TB_THUMBTRACK, td.pos), (LPARAM)hWnd);
		return 0;
	}
	case WM_MOUSEMOVE:
		if(td.dragging)
		{
			RECT chan, thumb;
			GetTrackbarMetrics(hWnd, td, chan, thumb);
			const int range = std::max(1, td.maxVal - td.minVal);
			int newPos = td.pos;
			if(vertical)
			{
				const int availH = std::max(1, (int)(chan.bottom - chan.top - 18));
				const int clickY = std::clamp((int)GET_Y_LPARAM(lParam) - chan.top - 9, 0, availH);
				newPos = td.minVal + (clickY * range + availH / 2) / availH;
			} else
			{
				const int availW = std::max(1, (int)(chan.right - chan.left - 11));
				const int clickX = std::clamp((int)GET_X_LPARAM(lParam) - chan.left - 5, 0, availW);
				newPos = td.minVal + (clickX * range + availW / 2) / availW;
			}
			if(newPos != td.pos)
			{
				td.pos = newPos;
				InvalidateRect(hWnd, nullptr, TRUE);
				SendMessageW(GetParent(hWnd), vertical ? WM_VSCROLL : WM_HSCROLL, MAKEWPARAM(TB_THUMBTRACK, td.pos), (LPARAM)hWnd);
			}
		}
		return 0;
	case WM_LBUTTONUP:
		if(td.dragging)
		{
			td.dragging = false;
			ReleaseCapture();
			SendMessageW(GetParent(hWnd), vertical ? WM_VSCROLL : WM_HSCROLL, MAKEWPARAM(TB_THUMBPOSITION, td.pos), (LPARAM)hWnd);
			SendMessageW(GetParent(hWnd), vertical ? WM_VSCROLL : WM_HSCROLL, MAKEWPARAM(TB_ENDTRACK, td.pos), (LPARAM)hWnd);
		}
		return 0;
	case TBM_GETPOS:
		return td.pos;
	case TBM_SETPOS:
		td.pos = std::clamp((int)lParam, td.minVal, td.maxVal);
		if(wParam) InvalidateRect(hWnd, nullptr, TRUE);
		return 0;
	case TBM_SETRANGE:
		td.minVal = LOWORD(lParam);
		td.maxVal = HIWORD(lParam);
		td.pos = std::clamp(td.pos, td.minVal, td.maxVal);
		if(wParam) InvalidateRect(hWnd, nullptr, TRUE);
		return 0;
	case TBM_SETRANGEMIN:
		td.minVal = (int)lParam;
		td.pos = std::clamp(td.pos, td.minVal, td.maxVal);
		if(wParam) InvalidateRect(hWnd, nullptr, TRUE);
		return 0;
	case TBM_SETRANGEMAX:
		td.maxVal = (int)lParam;
		td.pos = std::clamp(td.pos, td.minVal, td.maxVal);
		if(wParam) InvalidateRect(hWnd, nullptr, TRUE);
		return 0;
	case TBM_GETRANGEMIN:
		return td.minVal;
	case TBM_GETRANGEMAX:
		return td.maxVal;
	case TBM_SETLINESIZE:
		td.lineSize = (int)lParam;
		return td.lineSize;
	case TBM_GETLINESIZE:
		return td.lineSize;
	case TBM_SETPAGESIZE:
		td.pageSize = (int)lParam;
		return td.pageSize;
	case TBM_GETPAGESIZE:
		return td.pageSize;
	case TBM_SETTICFREQ:
		return 0;
	case TBM_GETTHUMBRECT:
	{
		LPRECT r = (LPRECT)lParam;
		if(r) { RECT chan; GetTrackbarMetrics(hWnd, td, chan, *r); }
		return 0;
	}
	case TBM_GETCHANNELRECT:
	{
		LPRECT r = (LPRECT)lParam;
		if(r) { RECT thumb; GetTrackbarMetrics(hWnd, td, *r, thumb); }
		return 0;
	}
	}
	return DefWindowProcW(hWnd, msg, wParam, lParam);
}

// ---------------------------------------------------------------------------------------------
// msctls_progress32
// ---------------------------------------------------------------------------------------------

struct ProgressControlData {
	int minVal = 0;
	int maxVal = 100;
	int pos = 0;
	int step = 10;
};
static std::unordered_map<HWND, ProgressControlData> g_progressBars;

static void PaintProgressBar(HWND hWnd, ProgressControlData &pd)
{
	PAINTSTRUCT ps;
	HDC dc = BeginPaint(hWnd, &ps);
	if(!dc) return;
	RECT client;
	GetClientRect(hWnd, &client);
	FillSolid(dc, client, RGB(230, 230, 230));
	Outline(dc, client, RGB(180, 180, 180));

	const int range = std::max(1, pd.maxVal - pd.minVal);
	const int availW = std::max(0, (int)(client.right - client.left - 2));
	const int fillW = std::clamp((pd.pos - pd.minVal) * availW / range, 0, availW);
	if(fillW > 0)
	{
		RECT barRect{client.left + 1, client.top + 1, client.left + 1 + fillW, client.bottom - 1};
		FillSolid(dc, barRect, RGB(6, 176, 37));
	}
	EndPaint(hWnd, &ps);
}

LRESULT CALLBACK ProgressProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	ProgressControlData &pd = g_progressBars[hWnd];
	switch(msg)
	{
	case WM_NCDESTROY:
		g_progressBars.erase(hWnd);
		return 0;
	case WM_PAINT:
		PaintProgressBar(hWnd, pd);
		return 0;
	case WM_ERASEBKGND:
		return 1;
	case PBM_SETRANGE:
		pd.minVal = LOWORD(lParam);
		pd.maxVal = HIWORD(lParam);
		pd.pos = std::clamp(pd.pos, pd.minVal, pd.maxVal);
		InvalidateRect(hWnd, nullptr, TRUE);
		return MAKELRESULT(pd.minVal, pd.maxVal);
	case PBM_SETPOS:
	{
		int old = pd.pos;
		pd.pos = std::clamp((int)wParam, pd.minVal, pd.maxVal);
		InvalidateRect(hWnd, nullptr, TRUE);
		return old;
	}
	case PBM_GETPOS:
		return pd.pos;
	case PBM_DELTAPOS:
		pd.pos = std::clamp(pd.pos + (int)wParam, pd.minVal, pd.maxVal);
		InvalidateRect(hWnd, nullptr, TRUE);
		return pd.pos;
	case PBM_STEPIT:
		pd.pos = std::clamp(pd.pos + pd.step, pd.minVal, pd.maxVal);
		InvalidateRect(hWnd, nullptr, TRUE);
		return pd.pos;
	case PBM_SETSTEP:
	{
		int old = pd.step;
		pd.step = (int)wParam;
		return old;
	}
	}
	return DefWindowProcW(hWnd, msg, wParam, lParam);
}

}  // namespace

// Registers the built-in classes; done once from main() before the application initialises.
void MacRegisterCommonControls()
{
	const struct { LPCWSTR name; WNDPROC proc; } classes[] = {
		{TOOLBARCLASSNAMEW, ToolbarProc},
		{STATUSCLASSNAMEW, StatusBarProc},
		{L"STATIC", StaticProc},
		{L"EDIT", EditProc},
		{UPDOWN_CLASSW, UpDownProc},
		{L"#32770", DialogProc},
		{L"BUTTON", ButtonProc},
		{L"MDICLIENT", MDIClientProc},
		{WC_TABCONTROLW, TabCtrlProc},
		{TRACKBAR_CLASSW, TrackbarProc},
		{PROGRESS_CLASSW, ProgressProc},
	};
	for(const auto &c : classes)
	{
		WNDCLASSW wc{};
		wc.lpfnWndProc = c.proc;
		wc.lpszClassName = c.name;
		RegisterClassW(&wc);
	}
}

// ---------------------------------------------------------------------------------------------
// MFC: CToolBar on top of ToolbarWindow32
// ---------------------------------------------------------------------------------------------

namespace {

constexpr int kBarBorder = 2;  // MFC's m_cyTopBorder / m_cyBottomBorder

// MFC's toolbar button "style" packs fsStyle in the low word and fsState in the high word,
// with the ENABLED bit inverted so that TBBS_DISABLED is set for disabled buttons.
UINT PackStyle(const TBBUTTON &b) { return MAKELONG(b.fsStyle, b.fsState ^ TBSTATE_ENABLED); }

class CToolCmdUI : public CCmdUI
{
public:
	CToolBar *m_bar = nullptr;
	void Enable(BOOL bOn) override
	{
		m_bEnableChanged = TRUE;
		m_bar->GetToolBarCtrl().EnableButton(m_nID, bOn);
	}
	void SetCheck(int nCheck) override
	{
		m_bar->GetToolBarCtrl().CheckButton(m_nID, nCheck == 1);
		m_bar->GetToolBarCtrl().Indeterminate(m_nID, nCheck == 2);
	}
	void SetText(LPCTSTR) override {}
};

}  // namespace

BOOL CToolBar::Create(CWnd *pParentWnd, DWORD dwStyle, UINT nID)
{
	return CreateEx(pParentWnd, TBSTYLE_FLAT, dwStyle, CRect(0, 0, 0, 0), nID);
}

BOOL CToolBar::CreateEx(CWnd *pParentWnd, DWORD dwCtrlStyle, DWORD dwStyle, CRect, UINT nID)
{
	m_dwStyle = dwStyle & CBRS_ALL;
	if(!CWnd::Create(TOOLBARCLASSNAME, nullptr, (dwStyle & ~CBRS_ALL) | dwCtrlStyle | WS_CHILD, CRect(0, 0, 100, m_sizeButton.cy + 2 * kBarBorder), pParentWnd, nID))
		return FALSE;
	SetSizes(m_sizeButton, m_sizeImage);
	if(auto *frame = dynamic_cast<CFrameWnd *>(pParentWnd)) frame->AddControlBar(this);
	return TRUE;
}

void CToolBar::SetSizes(SIZE sizeButton, SIZE sizeImage)
{
	m_sizeButton = sizeButton;
	m_sizeImage = sizeImage;
	::SendMessageW(m_hWnd, TB_SETBITMAPSIZE, 0, MAKELONG(sizeImage.cx, sizeImage.cy));
	::SendMessageW(m_hWnd, TB_SETBUTTONSIZE, 0, MAKELONG(sizeButton.cx, sizeButton.cy));
	Invalidate();
}

BOOL CToolBar::SetButtons(const UINT *lpIDArray, int nIDCount)
{
	while(::SendMessageW(m_hWnd, TB_BUTTONCOUNT, 0, 0) > 0) ::SendMessageW(m_hWnd, TB_DELETEBUTTON, 0, 0);
	int image = 0;
	for(int i = 0; i < nIDCount; i++)
	{
		TBBUTTON button{};
		button.fsState = TBSTATE_ENABLED;
		if(!lpIDArray || lpIDArray[i] == ID_SEPARATOR)
		{
			button.fsStyle = TBSTYLE_SEP;
		} else
		{
			button.fsStyle = TBSTYLE_BUTTON;
			button.idCommand = (int)lpIDArray[i];
			button.iBitmap = image++;
		}
		::SendMessageW(m_hWnd, TB_ADDBUTTONSW, 1, (LPARAM)&button);
	}
	return TRUE;
}

BOOL CToolBar::LoadToolBar(LPCTSTR) { return FALSE; }  // TOOLBAR resources are not used by mptrack

BOOL CToolBar::SetBitmap(HBITMAP hbmImageWell)
{
	auto *list = new CImageList();
	list->Create(m_sizeImage.cx, m_sizeImage.cy, ILC_COLOR32, 0, 0);
	CBitmap *bitmap = CBitmap::FromHandle(hbmImageWell);
	list->Add(bitmap, RGB(192, 192, 192));
	GetToolBarCtrl().SetImageList(list);
	return TRUE;
}

int CToolBar::CommandToIndex(UINT nIDFind) const { return (int)::SendMessageW(m_hWnd, TB_COMMANDTOINDEX, nIDFind, 0); }

UINT CToolBar::GetItemID(int nIndex) const
{
	TBBUTTON button{};
	::SendMessageW(m_hWnd, TB_GETBUTTON, nIndex, (LPARAM)&button);
	return (button.fsStyle & TBSTYLE_SEP) ? ID_SEPARATOR : (UINT)button.idCommand;
}

void CToolBar::GetItemRect(int nIndex, LPRECT lpRect) const { ::SendMessageW(m_hWnd, TB_GETITEMRECT, nIndex, (LPARAM)lpRect); }

UINT CToolBar::GetButtonStyle(int nIndex) const
{
	TBBUTTON button{};
	::SendMessageW(m_hWnd, TB_GETBUTTON, nIndex, (LPARAM)&button);
	return PackStyle(button);
}

void CToolBar::SetButtonStyle(int nIndex, UINT nStyle)
{
	TBBUTTON button{};
	if(!::SendMessageW(m_hWnd, TB_GETBUTTON, nIndex, (LPARAM)&button)) return;
	button.fsStyle = (BYTE)LOWORD(nStyle);
	button.fsState = (BYTE)(HIWORD(nStyle) ^ TBSTATE_ENABLED);
	::SendMessageW(m_hWnd, TB_DELETEBUTTON, nIndex, 0);
	::SendMessageW(m_hWnd, TB_INSERTBUTTONW, nIndex, (LPARAM)&button);
}

void CToolBar::GetButtonInfo(int nIndex, UINT &nID, UINT &nStyle, int &iImage) const
{
	TBBUTTON button{};
	::SendMessageW(m_hWnd, TB_GETBUTTON, nIndex, (LPARAM)&button);
	nID = (UINT)button.idCommand;
	nStyle = PackStyle(button);
	iImage = button.iBitmap;
}

void CToolBar::SetButtonInfo(int nIndex, UINT nID, UINT nStyle, int iImage)
{
	TBBUTTON button{};
	if(!::SendMessageW(m_hWnd, TB_GETBUTTON, nIndex, (LPARAM)&button)) return;
	button.idCommand = (int)nID;
	button.iBitmap = iImage;  // for separators this is the width
	button.fsStyle = (BYTE)LOWORD(nStyle);
	button.fsState = (BYTE)(HIWORD(nStyle) ^ TBSTATE_ENABLED);
	::SendMessageW(m_hWnd, TB_DELETEBUTTON, nIndex, 0);
	::SendMessageW(m_hWnd, TB_INSERTBUTTONW, nIndex, (LPARAM)&button);
}

BOOL CToolBar::SetButtonText(int, LPCTSTR) { return TRUE; }
CString CToolBar::GetButtonText(int) const { return CString(); }
CToolBarCtrl &CToolBar::GetToolBarCtrl() const { return *(CToolBarCtrl *)this; }

CSize CToolBar::CalcFixedLayout(BOOL bStretch, BOOL bHorz)
{
	const ToolbarData &tb = g_toolbars[m_hWnd];
	const SIZE extent = ToolbarExtent(tb);
	CSize size(extent.cx, extent.cy + 2 * kBarBorder);
	if(bStretch && bHorz) size.cx = 32767;
	return size;
}

CSize CToolBar::CalcDynamicLayout(int nLength, DWORD dwMode)
{
	return CalcFixedLayout((dwMode & LM_HORZDOCK) || (dwMode & LM_STRETCH), (dwMode & LM_HORZ) != 0);
}

void CToolBar::OnUpdateCmdUI(CFrameWnd *pTarget, BOOL bDisableIfNoHndler)
{
	CToolCmdUI state;
	state.m_bar = this;
	const int count = (int)::SendMessageW(m_hWnd, TB_BUTTONCOUNT, 0, 0);
	state.m_nIndexMax = (UINT)count;
	for(int i = 0; i < count; i++)
	{
		TBBUTTON button{};
		::SendMessageW(m_hWnd, TB_GETBUTTON, i, (LPARAM)&button);
		if(button.fsStyle & TBSTYLE_SEP) continue;
		state.m_nIndex = (UINT)i;
		state.m_nID = (UINT)button.idCommand;
		state.DoUpdate(pTarget, bDisableIfNoHndler);
	}
}

// ---------------------------------------------------------------------------------------------
// MFC: CStatusBar on top of msctls_statusbar32
// ---------------------------------------------------------------------------------------------

namespace {

class CStatusCmdUI : public CCmdUI
{
public:
	CStatusBar *m_bar = nullptr;
	void Enable(BOOL bOn) override
	{
		m_bEnableChanged = TRUE;
		UINT style = m_bar->GetPaneStyle((int)m_nIndex) & ~SBPS_DISABLED;
		m_bar->SetPaneStyle((int)m_nIndex, bOn ? style : (style | SBPS_DISABLED));
	}
	void SetCheck(int) override {}
	void SetText(LPCTSTR lpszText) override { m_bar->SetPaneText((int)m_nIndex, lpszText); }
};

constexpr int kStatusHeight = 22, kPaneGap = 2;

}  // namespace

BOOL CStatusBar::Create(CWnd *pParentWnd, DWORD dwStyle, UINT nID)
{
	return CreateEx(pParentWnd, 0, dwStyle, nID);
}

BOOL CStatusBar::CreateEx(CWnd *pParentWnd, DWORD dwCtrlStyle, DWORD dwStyle, UINT nID)
{
	m_dwStyle = dwStyle & CBRS_ALL;
	if(!CWnd::Create(STATUSCLASSNAME, nullptr, (dwStyle & ~CBRS_ALL) | dwCtrlStyle | WS_CHILD, CRect(0, 0, 100, kStatusHeight), pParentWnd, nID))
		return FALSE;
	if(auto *frame = dynamic_cast<CFrameWnd *>(pParentWnd)) frame->AddControlBar(this);
	return TRUE;
}

// Pane widths come from the indicator strings, as in MFC; pane 0 is the stretchy message pane.
BOOL CStatusBar::SetIndicators(const UINT *lpIDArray, int nIDCount)
{
	m_panes.clear();
	HDC dc = ::GetDC(m_hWnd);
	SelectObject(dc, ControlFont(m_hWnd));
	for(int i = 0; i < nIDCount; i++)
	{
		PaneInfo pane;
		pane.nID = lpIDArray[i];
		if(pane.nID == ID_SEPARATOR)
		{
			pane.nStyle = SBPS_STRETCH | SBPS_NOBORDERS;
			pane.cxWidth = 0;
		} else
		{
			pane.strText.LoadString(pane.nID);
			SIZE size{};
			GetTextExtentPoint32W(dc, pane.strText, pane.strText.GetLength(), &size);
			pane.cxWidth = size.cx;
		}
		m_panes.push_back(pane);
	}
	::ReleaseDC(m_hWnd, dc);
	UpdateAllPanes();
	return TRUE;
}

void CStatusBar::UpdateAllPanes()
{
	CRect client;
	GetClientRect(&client);
	const int fixed = std::accumulate(m_panes.begin(), m_panes.end(), 0, [](int sum, const PaneInfo &p) { return sum + ((p.nStyle & SBPS_STRETCH) ? 0 : p.cxWidth + 8 + kPaneGap); });
	const int stretch = std::max(0, client.Width() - fixed - kStatusGrip);
	std::vector<int> edges;
	int x = 0;
	for(const PaneInfo &p : m_panes)
	{
		x += (p.nStyle & SBPS_STRETCH) ? stretch : p.cxWidth + 8 + kPaneGap;
		edges.push_back(x);
	}
	::SendMessageW(m_hWnd, SB_SETPARTS, edges.size(), (LPARAM)edges.data());
	for(int i = 0; i < (int)m_panes.size(); i++)
		::SendMessageW(m_hWnd, SB_SETTEXTW, i | ((m_panes[i].nStyle & SBPS_NOBORDERS) ? SBT_NOBORDERS : 0), (LPARAM)m_panes[i].strText.GetString());
}

int CStatusBar::CommandToIndex(UINT nIDFind) const
{
	for(size_t i = 0; i < m_panes.size(); ++i)
		if(m_panes[i].nID == nIDFind) return (int)i;
	return -1;
}

UINT CStatusBar::GetItemID(int nIndex) const { return (nIndex >= 0 && (size_t)nIndex < m_panes.size()) ? m_panes[nIndex].nID : 0; }
void CStatusBar::GetItemRect(int nIndex, LPRECT lpRect) const { ::SendMessageW(m_hWnd, SB_GETRECT, nIndex, (LPARAM)lpRect); }
CString CStatusBar::GetPaneText(int nIndex) const { return (nIndex >= 0 && (size_t)nIndex < m_panes.size()) ? m_panes[nIndex].strText : CString(); }
void CStatusBar::GetPaneText(int nIndex, CString &rString) const { rString = GetPaneText(nIndex); }

BOOL CStatusBar::SetPaneText(int nIndex, LPCTSTR lpszNewText, BOOL bUpdate)
{
	if(nIndex < 0 || (size_t)nIndex >= m_panes.size()) return FALSE;
	CString text = lpszNewText ? lpszNewText : _T("");
	if(m_panes[nIndex].strText == text) return TRUE;
	m_panes[nIndex].strText = text;
	::SendMessageW(m_hWnd, SB_SETTEXTW, nIndex | ((m_panes[nIndex].nStyle & SBPS_NOBORDERS) ? SBT_NOBORDERS : 0), (LPARAM)text.GetString());
	(void)bUpdate;
	return TRUE;
}

void CStatusBar::GetPaneInfo(int nIndex, UINT &nID, UINT &nStyle, int &cxWidth) const
{
	if(nIndex < 0 || (size_t)nIndex >= m_panes.size()) return;
	nID = m_panes[nIndex].nID;
	nStyle = m_panes[nIndex].nStyle;
	cxWidth = m_panes[nIndex].cxWidth;
}

void CStatusBar::SetPaneInfo(int nIndex, UINT nID, UINT nStyle, int cxWidth)
{
	if(nIndex < 0 || (size_t)nIndex >= m_panes.size()) return;
	m_panes[nIndex].nID = nID;
	m_panes[nIndex].nStyle = nStyle;
	m_panes[nIndex].cxWidth = cxWidth;
	UpdateAllPanes();
}

UINT CStatusBar::GetPaneStyle(int nIndex) const { return (nIndex >= 0 && (size_t)nIndex < m_panes.size()) ? m_panes[nIndex].nStyle : 0; }

void CStatusBar::SetPaneStyle(int nIndex, UINT nStyle)
{
	if(nIndex < 0 || (size_t)nIndex >= m_panes.size() || m_panes[nIndex].nStyle == nStyle) return;
	m_panes[nIndex].nStyle = nStyle;
	UpdateAllPanes();
}

CSize CStatusBar::CalcFixedLayout(BOOL, BOOL)
{
	return CSize(32767, kStatusHeight);
}

void CStatusBar::OnUpdateCmdUI(CFrameWnd *pTarget, BOOL bDisableIfNoHndler)
{
	CStatusCmdUI state;
	state.m_bar = this;
	state.m_nIndexMax = (UINT)m_panes.size();
	for(size_t i = 0; i < m_panes.size(); i++)
	{
		state.m_nIndex = (UINT)i;
		state.m_nID = m_panes[i].nID;
		state.DoUpdate(pTarget, bDisableIfNoHndler);
	}
}

void CStatusBar::OnSize(UINT nType, int cx, int cy)
{
	(void)nType; (void)cx; (void)cy;
	UpdateAllPanes();
}
