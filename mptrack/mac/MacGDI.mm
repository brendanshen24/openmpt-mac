#include <sstream>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import <ImageIO/ImageIO.h>
#include <cmath>
#include <algorithm>
#include <map>

#import "MacGDI.h"
#import "MacResources.h"

static inline CGFloat Clamp01(CGFloat f) {
    return (f < 0.0f) ? 0.0f : ((f > 1.0f) ? 1.0f : f);
}

static inline void SetCGColorFromCOLORREF(CGContextRef ctx, COLORREF cr, bool stroke) {
    CGFloat r = GetRValue(cr) / 255.0f;
    CGFloat g = GetGValue(cr) / 255.0f;
    CGFloat b = GetBValue(cr) / 255.0f;
    if (stroke) {
        CGContextSetRGBStrokeColor(ctx, r, g, b, 1.0f);
    } else {
        CGContextSetRGBFillColor(ctx, r, g, b, 1.0f);
    }
}

HDC WINAPI CreateCompatibleDC(HDC hdc) {
    MacHDC* newDC = new MacHDC();
    newDC->ownsContext = false;
    newDC->isWindowDC = false;
    if (hdc) {
        newDC->textColor = hdc->textColor;
        newDC->bkColor = hdc->bkColor;
        newDC->bkMode = hdc->bkMode;
        newDC->currentFont = hdc->currentFont;
    }
    return newDC;
}

BOOL WINAPI DeleteDC(HDC hdc) {
    if (!hdc) return FALSE;
    if (hdc->ownsContext && hdc->cgContext) {
        CGContextRelease(hdc->cgContext);
    }
    delete hdc;
    return TRUE;
}

int WINAPI SaveDC(HDC hdc) {
    if (!hdc) return 0;
    MacGraphicsState state;
    state.viewportOrg = hdc->viewportOrg;
    state.windowOrg = hdc->windowOrg;
    state.textColor = hdc->textColor;
    state.bkColor = hdc->bkColor;
    state.bkMode = hdc->bkMode;
    state.rop2 = hdc->rop2;
    state.bitmap = hdc->currentBitmap;
    state.pen = hdc->currentPen;
    state.brush = hdc->currentBrush;
    state.font = hdc->currentFont;
    hdc->stateStack.push_back(state);
    if (hdc->cgContext) CGContextSaveGState(hdc->cgContext);
    return (int)hdc->stateStack.size();
}

BOOL WINAPI RestoreDC(HDC hdc, int nSavedDC) {
    if (!hdc || hdc->stateStack.empty()) return FALSE;
    size_t target = (nSavedDC < 0) ? (hdc->stateStack.size() + nSavedDC) : (size_t)(nSavedDC - 1);
    if (target >= hdc->stateStack.size()) return FALSE;

    while (hdc->stateStack.size() > target) {
        if (hdc->cgContext) CGContextRestoreGState(hdc->cgContext);
        const auto& state = hdc->stateStack.back();
        hdc->viewportOrg = state.viewportOrg;
        hdc->windowOrg = state.windowOrg;
        hdc->textColor = state.textColor;
        hdc->bkColor = state.bkColor;
        hdc->bkMode = state.bkMode;
        hdc->rop2 = state.rop2;
        hdc->currentBitmap = state.bitmap;
        hdc->currentPen = state.pen;
        hdc->currentBrush = state.brush;
        hdc->currentFont = state.font;
        hdc->stateStack.pop_back();
    }
    return TRUE;
}

int WINAPI GetDeviceCaps(HDC hdc, int nIndex) {
    (void)hdc;
    switch (nIndex) {
        case HORZRES: return 1920;
        case VERTRES: return 1080;
        case LOGPIXELSX: return 96;
        case LOGPIXELSY: return 96;
        case BITSPIXEL: return 32;
        case PLANES: return 1;
        case NUMCOLORS: return -1;
        case RASTERCAPS: return RC_BITBLT | RC_STRETCHBLT | RC_DI_BITMAP;
        default: return 0;
    }
}

// GDI coordinates grow downwards; make bitmap contexts match the flipped NSViews so the same drawing code works on both.
void MacFlipBitmapContext(MacBitmap* bmp) {
    if (!bmp || !bmp->bitmapContext) return;
    CGContextTranslateCTM(bmp->bitmapContext, 0, bmp->height);
    CGContextScaleCTM(bmp->bitmapContext, 1, -1);
}

HBITMAP WINAPI CreateBitmap(int nWidth, int nHeight, UINT nPlanes, UINT nBitCount, const void* lpBits) {
    MacBitmap* bmp = new MacBitmap();
    bmp->width = nWidth > 0 ? nWidth : 1;
    bmp->height = nHeight > 0 ? nHeight : 1;
    bmp->bpp = nBitCount ? nBitCount : 32;
    size_t stride = (size_t)((bmp->width * 4 + 3) & ~3);
    bmp->pixelData.resize(stride * (size_t)bmp->height, 0);

    if (lpBits) {
        memcpy(bmp->pixelData.data(), lpBits, std::min(bmp->pixelData.size(), (size_t)(nWidth * nHeight * (nBitCount / 8))));
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    bmp->bitmapContext = CGBitmapContextCreate(bmp->pixelData.data(),
                                              bmp->width, bmp->height, 8, stride,
                                              colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    MacFlipBitmapContext(bmp);
    return bmp;
}

HBITMAP WINAPI CreateCompatibleBitmap(HDC hdc, int nWidth, int nHeight) {
    (void)hdc;
    return CreateBitmap(nWidth, nHeight, 1, 32, nullptr);
}

HBITMAP WINAPI CreateDIBSection(HDC hdc, const BITMAPINFO* pbmi, UINT usage, void** ppvBits, HANDLE hSection, DWORD offset) {
    (void)hdc; (void)usage; (void)hSection; (void)offset;
    if (!pbmi) return nullptr;
    int w = pbmi->bmiHeader.biWidth;
    int h = std::abs(pbmi->bmiHeader.biHeight);
    int bpp = pbmi->bmiHeader.biBitCount;

    MacBitmap* bmp = new MacBitmap();
    bmp->width = w > 0 ? w : 1;
    bmp->height = h > 0 ? h : 1;
    bmp->bpp = bpp;
    bmp->isDIBSection = true;

    size_t stride = (size_t)(((bmp->width * bpp + 31) / 32) * 4);
    bmp->pixelData.resize(stride * (size_t)bmp->height, 0);

    if (ppvBits) *ppvBits = bmp->pixelData.data();

    if (bpp == 32) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        bmp->bitmapContext = CGBitmapContextCreate(bmp->pixelData.data(),
                                                  bmp->width, bmp->height, 8, stride,
                                                  colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
    }
    // shortcut: bottom-up DIB sections keep CG's native orientation, so GDI drawing into them is mirrored; flip them too if a view draws into one.
    bmp->bottomUp = pbmi->bmiHeader.biHeight > 0;
    if (!bmp->bottomUp) MacFlipBitmapContext(bmp);
    return bmp;
}

HGDIOBJ WINAPI SelectObject(HDC hdc, HGDIOBJ h) {
    if (!hdc || !h) return nullptr;
    MacGdiObject* obj = static_cast<MacGdiObject*>(h);
    if (auto* bmp = dynamic_cast<MacBitmap*>(obj)) {
        HBITMAP old = hdc->currentBitmap;
        hdc->currentBitmap = bmp;
        if (bmp->bitmapContext) {
            hdc->cgContext = bmp->bitmapContext;
            hdc->ownsContext = false;
        }
        return old;
    }
    if (auto* pen = dynamic_cast<MacPen*>(obj)) {
        HPEN old = hdc->currentPen;
        hdc->currentPen = pen;
        return old;
    }
    if (auto* brush = dynamic_cast<MacBrush*>(obj)) {
        HBRUSH old = hdc->currentBrush;
        hdc->currentBrush = brush;
        return old;
    }
    if (auto* font = dynamic_cast<MacFont*>(obj)) {
        HFONT old = hdc->currentFont;
        hdc->currentFont = font;
        return old;
    }
    if (auto* rgn = dynamic_cast<MacRgn*>(obj)) {
        return (HGDIOBJ)(intptr_t)SelectClipRgn(hdc, rgn);
    }
    return nullptr;
}

BOOL WINAPI DeleteObject(HGDIOBJ ho) {
    if (!ho) return FALSE;
    MacGdiObject* obj = static_cast<MacGdiObject*>(ho);
    if (!obj->isStock) delete obj;
    return TRUE;
}

int WINAPI GetObjectA(HGDIOBJ hgdiobj, int cbBuffer, LPVOID lpvObject) {
    if (!hgdiobj) return 0;
    MacGdiObject* obj = static_cast<MacGdiObject*>(hgdiobj);
    if (auto* font = dynamic_cast<MacFont*>(obj)) {
        if (!lpvObject) return sizeof(LOGFONTA);
        memcpy(lpvObject, &font->logFont, std::min<size_t>((size_t)cbBuffer, sizeof(LOGFONTA)));
        return std::min<int>(cbBuffer, sizeof(LOGFONTA));
    }
    if (auto* brush = dynamic_cast<MacBrush*>(obj)) {
        if (!lpvObject) return sizeof(LOGBRUSH);
        LOGBRUSH lb{(UINT)brush->style, brush->color, 0};
        memcpy(lpvObject, &lb, std::min<size_t>((size_t)cbBuffer, sizeof(lb)));
        return std::min<int>(cbBuffer, sizeof(lb));
    }
    if (auto* pen = dynamic_cast<MacPen*>(obj)) {
        if (!lpvObject) return sizeof(LOGPEN);
        LOGPEN lp{(UINT)pen->style, POINT{pen->width, 0}, pen->color};
        memcpy(lpvObject, &lp, std::min<size_t>((size_t)cbBuffer, sizeof(lp)));
        return std::min<int>(cbBuffer, sizeof(lp));
    }
    MacBitmap* bmp = dynamic_cast<MacBitmap*>(obj);
    if (!bmp || !lpvObject) return bmp ? sizeof(BITMAP) : 0;
    if (cbBuffer == sizeof(BITMAP)) {
        BITMAP* bm = (BITMAP*)lpvObject;
        bm->bmType = 0;
        bm->bmWidth = bmp->width;
        bm->bmHeight = bmp->height;
        bm->bmWidthBytes = (LONG)(((bmp->width * bmp->bpp + 31) / 32) * 4);
        bm->bmPlanes = 1;
        bm->bmBitsPixel = bmp->bpp;
        bm->bmBits = bmp->pixelData.data();
        return sizeof(BITMAP);
    }
    if (cbBuffer == sizeof(DIBSECTION)) {
        DIBSECTION* ds = (DIBSECTION*)lpvObject;
        ds->dsBm.bmType = 0;
        ds->dsBm.bmWidth = bmp->width;
        ds->dsBm.bmHeight = bmp->height;
        ds->dsBm.bmWidthBytes = (LONG)(((bmp->width * bmp->bpp + 31) / 32) * 4);
        ds->dsBm.bmPlanes = 1;
        ds->dsBm.bmBitsPixel = bmp->bpp;
        ds->dsBm.bmBits = bmp->pixelData.data();
        ds->dsBmih.biSize = sizeof(BITMAPINFOHEADER);
        ds->dsBmih.biWidth = bmp->width;
        ds->dsBmih.biHeight = bmp->height;
        ds->dsBmih.biPlanes = 1;
        ds->dsBmih.biBitCount = bmp->bpp;
        ds->dsBmih.biCompression = BI_RGB;
        return sizeof(DIBSECTION);
    }
    return 0;
}

int WINAPI GetObjectW(HGDIOBJ hgdiobj, int cbBuffer, LPVOID lpvObject) {
    // Fonts differ between A and W (face name width); everything else is shared.
    if (auto* font = dynamic_cast<MacFont*>(static_cast<MacGdiObject*>(hgdiobj))) {
        if (!lpvObject) return sizeof(LOGFONTW);
        LOGFONTW lfw{};
        const LOGFONTA& lfa = font->logFont;
        lfw.lfHeight = lfa.lfHeight; lfw.lfWidth = lfa.lfWidth; lfw.lfEscapement = lfa.lfEscapement;
        lfw.lfOrientation = lfa.lfOrientation; lfw.lfWeight = lfa.lfWeight; lfw.lfItalic = lfa.lfItalic;
        lfw.lfUnderline = lfa.lfUnderline; lfw.lfStrikeOut = lfa.lfStrikeOut; lfw.lfCharSet = lfa.lfCharSet;
        lfw.lfQuality = lfa.lfQuality; lfw.lfPitchAndFamily = lfa.lfPitchAndFamily;
        MultiByteToWideChar(CP_UTF8, 0, lfa.lfFaceName, -1, lfw.lfFaceName, LF_FACESIZE);
        memcpy(lpvObject, &lfw, std::min<size_t>((size_t)cbBuffer, sizeof(lfw)));
        return std::min<int>(cbBuffer, sizeof(lfw));
    }
    return GetObjectA(hgdiobj, cbBuffer, lpvObject);
}

HBRUSH WINAPI CreateSolidBrush(COLORREF crColor) {
    MacBrush* br = new MacBrush();
    br->style = BS_SOLID;
    br->color = crColor;
    return (HBRUSH)br;
}

// System brushes are shared and never deleted by callers, as on Windows.
HBRUSH WINAPI GetSysColorBrush(int nIndex) {
    static std::map<int, MacBrush*> brushes;
    MacBrush*& brush = brushes[nIndex];
    if (!brush) {
        brush = (MacBrush*)CreateSolidBrush(GetSysColor(nIndex));
        brush->isStock = true;
    }
    return (HBRUSH)brush;
}

HPEN WINAPI CreatePen(int iStyle, int cWidth, COLORREF color) {
    MacPen* pen = new MacPen();
    pen->style = iStyle;
    pen->width = cWidth > 0 ? cWidth : 1;
    pen->color = color;
    return (HPEN)pen;
}

HFONT WINAPI CreateFontIndirectA(const LOGFONTA* lplf) {
    MacFont* f = new MacFont();
    if (lplf) f->logFont = *lplf;
    f->height = lplf ? std::abs(lplf->lfHeight) : 12;
    if (f->height == 0) f->height = 12;

    NSString* face = (lplf && lplf->lfFaceName[0]) ? [NSString stringWithUTF8String:lplf->lfFaceName] : @"Microsoft Sans Serif";
    // Windows' logical UI font names resolve to fonts macOS also ships (Tahoma, Microsoft Sans Serif).
    static NSDictionary<NSString*, NSString*>* const substitutes = @{
        @"MS Shell Dlg": @"Microsoft Sans Serif",
        @"MS Sans Serif": @"Microsoft Sans Serif",
        @"MS Shell Dlg 2": @"Tahoma",
        @"Segoe UI": @"Tahoma",
        @"System": @"Microsoft Sans Serif",
        @"Lucida Console": @"Courier New",
        @"Consolas": @"Courier New",
    };
    if (NSString* substitute = substitutes[face]) face = substitute;
    f->ctFont = CTFontCreateWithName((__bridge CFStringRef)face, (CGFloat)f->height, nullptr);
    if (!f->ctFont) f->ctFont = CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, (CGFloat)f->height, nullptr);
    CTFontSymbolicTraits traits = 0;
    if (lplf && lplf->lfWeight >= FW_SEMIBOLD) traits |= kCTFontBoldTrait;
    if (lplf && lplf->lfItalic) traits |= kCTFontItalicTrait;
    if (traits) {
        if (CTFontRef styled = CTFontCreateCopyWithSymbolicTraits(f->ctFont, 0, nullptr, traits, traits)) {
            CFRelease(f->ctFont);
            f->ctFont = styled;
        }
    }

    f->ascent = (int)std::ceil(CTFontGetAscent(f->ctFont));
    f->descent = (int)std::ceil(CTFontGetDescent(f->ctFont));
    f->aveCharWidth = (int)std::ceil(f->height * 0.6f);
    return (HFONT)f;
}

HFONT WINAPI CreateFontIndirectW(const LOGFONTW* lplf) {
    LOGFONTA lfa{};
    if (lplf) {
        lfa.lfHeight = lplf->lfHeight;
        lfa.lfWidth = lplf->lfWidth;
        lfa.lfWeight = lplf->lfWeight;
        lfa.lfItalic = lplf->lfItalic;
        lfa.lfUnderline = lplf->lfUnderline;
        lfa.lfStrikeOut = lplf->lfStrikeOut;
        lfa.lfCharSet = lplf->lfCharSet;
        lfa.lfQuality = lplf->lfQuality;
        lfa.lfPitchAndFamily = lplf->lfPitchAndFamily;
        WideCharToMultiByte(CP_UTF8, 0, lplf->lfFaceName, -1, lfa.lfFaceName, sizeof(lfa.lfFaceName), nullptr, nullptr);
    }
    return CreateFontIndirectA(&lfa);
}

HFONT WINAPI CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight,
                         DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut, DWORD iCharSet,
                         DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality,
                         DWORD iPitchAndFamily, LPCSTR pszFaceName) {
    LOGFONTA lf{};
    lf.lfHeight = cHeight;
    lf.lfWidth = cWidth;
    lf.lfEscapement = cEscapement;
    lf.lfOrientation = cOrientation;
    lf.lfWeight = cWeight;
    lf.lfItalic = (BYTE)bItalic;
    lf.lfUnderline = (BYTE)bUnderline;
    lf.lfStrikeOut = (BYTE)bStrikeOut;
    lf.lfCharSet = (BYTE)iCharSet;
    if (pszFaceName) strncpy(lf.lfFaceName, pszFaceName, sizeof(lf.lfFaceName) - 1);
    return CreateFontIndirectA(&lf);
}

HFONT WINAPI CreateFontW(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight,
                         DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut, DWORD iCharSet,
                         DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality,
                         DWORD iPitchAndFamily, LPCWSTR pszFaceName) {
    LOGFONTW lfw{};
    lfw.lfHeight = cHeight;
    lfw.lfWidth = cWidth;
    lfw.lfEscapement = cEscapement;
    lfw.lfOrientation = cOrientation;
    lfw.lfWeight = cWeight;
    lfw.lfItalic = (BYTE)bItalic;
    lfw.lfUnderline = (BYTE)bUnderline;
    lfw.lfStrikeOut = (BYTE)bStrikeOut;
    lfw.lfCharSet = (BYTE)iCharSet;
    if (pszFaceName) wcsncpy(lfw.lfFaceName, pszFaceName, sizeof(lfw.lfFaceName) / sizeof(WCHAR) - 1);
    return CreateFontIndirectW(&lfw);
}

COLORREF WINAPI SetTextColor(HDC hdc, COLORREF color) {
    if (!hdc) return 0;
    COLORREF old = hdc->textColor;
    hdc->textColor = color;
    return old;
}

COLORREF WINAPI GetTextColor(HDC hdc) {
    return hdc ? hdc->textColor : RGB(0, 0, 0);
}

COLORREF WINAPI SetBkColor(HDC hdc, COLORREF color) {
    if (!hdc) return 0;
    COLORREF old = hdc->bkColor;
    hdc->bkColor = color;
    return old;
}

COLORREF WINAPI GetBkColor(HDC hdc) {
    return hdc ? hdc->bkColor : RGB(255, 255, 255);
}

int WINAPI SetBkMode(HDC hdc, int mode) {
    if (!hdc) return 0;
    int old = hdc->bkMode;
    hdc->bkMode = mode;
    return old;
}

int WINAPI GetBkMode(HDC hdc) {
    return hdc ? hdc->bkMode : OPAQUE;
}

COLORREF WINAPI SetDCBrushColor(HDC hdc, COLORREF color) {
    if (!hdc) return 0;
    COLORREF old = hdc->dcBrushColor;
    hdc->dcBrushColor = color;
    return old;
}

COLORREF WINAPI SetDCPenColor(HDC hdc, COLORREF color) {
    if (!hdc) return 0;
    COLORREF old = hdc->dcPenColor;
    hdc->dcPenColor = color;
    return old;
}

UINT WINAPI SetTextAlign(HDC hdc, UINT align) {
    if (!hdc) return 0;
    UINT old = hdc->textAlign;
    hdc->textAlign = align;
    return old;
}

BOOL WINAPI SetViewportOrgEx(HDC hdc, int x, int y, LPPOINT lppt) {
    if (!hdc) return FALSE;
    if (lppt) *lppt = hdc->viewportOrg;
    hdc->viewportOrg.x = x;
    hdc->viewportOrg.y = y;
    return TRUE;
}

BOOL WINAPI GetViewportOrgEx(HDC hdc, LPPOINT lppt) {
    if (!hdc || !lppt) return FALSE;
    *lppt = hdc->viewportOrg;
    return TRUE;
}

BOOL WINAPI OffsetViewportOrgEx(HDC hdc, int x, int y, LPPOINT lppt) {
    if (!hdc) return FALSE;
    if (lppt) *lppt = hdc->viewportOrg;
    hdc->viewportOrg.x += x;
    hdc->viewportOrg.y += y;
    return TRUE;
}

BOOL WINAPI SetWindowOrgEx(HDC hdc, int x, int y, LPPOINT lppt) {
    if (!hdc) return FALSE;
    if (lppt) *lppt = hdc->windowOrg;
    hdc->windowOrg.x = x;
    hdc->windowOrg.y = y;
    return TRUE;
}

BOOL WINAPI GetWindowOrgEx(HDC hdc, LPPOINT lppt) {
    if (!hdc || !lppt) return FALSE;
    *lppt = hdc->windowOrg;
    return TRUE;
}

// SetDCPenColor / SetDCBrushColor recolour the stock DC_PEN / DC_BRUSH while they are selected or passed in.
static COLORREF PenColor(HDC hdc, const MacPen* pen) {
    return (!pen || pen == (MacPen*)GetStockObject(DC_PEN)) ? hdc->dcPenColor : pen->color;
}
static COLORREF BrushColor(HDC hdc, const MacBrush* brush) {
    return (!brush || brush == (MacBrush*)GetStockObject(DC_BRUSH)) ? hdc->dcBrushColor : brush->color;
}

BOOL WINAPI MoveToEx(HDC hdc, int x, int y, LPPOINT lppt) {
    if (!hdc || !hdc->cgContext) return FALSE;
    if (lppt) {
        CGPoint pt = CGContextGetPathCurrentPoint(hdc->cgContext);
        lppt->x = (LONG)pt.x - hdc->viewportOrg.x;
        lppt->y = (LONG)pt.y - hdc->viewportOrg.y;
    }
    CGContextMoveToPoint(hdc->cgContext, x + hdc->viewportOrg.x + 0.5, y + hdc->viewportOrg.y + 0.5);
    return TRUE;
}

// GDI lines cover whole pixels: stroke through pixel centres, unantialiased, with width 0 meaning one pixel.
static void StrokeGdiPath(HDC hdc) {
    MacPen* pen = (MacPen*)hdc->currentPen;
    SetCGColorFromCOLORREF(hdc->cgContext, PenColor(hdc, pen), true);
    CGContextSetLineWidth(hdc->cgContext, (CGFloat)std::max(1, pen ? pen->width : 1));
    CGContextSaveGState(hdc->cgContext);
    CGContextSetShouldAntialias(hdc->cgContext, false);
    CGContextStrokePath(hdc->cgContext);
    CGContextRestoreGState(hdc->cgContext);
}

BOOL WINAPI LineTo(HDC hdc, int x, int y) {
    if (!hdc || !hdc->cgContext) return FALSE;
    const CGFloat px = x + hdc->viewportOrg.x + 0.5, py = y + hdc->viewportOrg.y + 0.5;
    CGContextAddLineToPoint(hdc->cgContext, px, py);
    StrokeGdiPath(hdc);
    CGContextMoveToPoint(hdc->cgContext, px, py);
    return TRUE;
}

BOOL WINAPI Polyline(HDC hdc, const POINT* apt, int cpt) {
    if (!hdc || !hdc->cgContext || !apt || cpt < 2) return FALSE;
    CGContextMoveToPoint(hdc->cgContext, apt[0].x + hdc->viewportOrg.x + 0.5, apt[0].y + hdc->viewportOrg.y + 0.5);
    for (int i = 1; i < cpt; ++i) {
        CGContextAddLineToPoint(hdc->cgContext, apt[i].x + hdc->viewportOrg.x + 0.5, apt[i].y + hdc->viewportOrg.y + 0.5);
    }
    StrokeGdiPath(hdc);
    return TRUE;
}

BOOL WINAPI Polygon(HDC hdc, const POINT* apt, int cpt) {
    if (!hdc || !hdc->cgContext || !apt || cpt < 3) return FALSE;
    MacBrush* brush = (MacBrush*)hdc->currentBrush;
    COLORREF brushClr = BrushColor(hdc, brush);
    SetCGColorFromCOLORREF(hdc->cgContext, brushClr, false);

    CGContextMoveToPoint(hdc->cgContext, (CGFloat)(apt[0].x + hdc->viewportOrg.x), (CGFloat)(apt[0].y + hdc->viewportOrg.y));
    for (int i = 1; i < cpt; ++i) {
        CGContextAddLineToPoint(hdc->cgContext, (CGFloat)(apt[i].x + hdc->viewportOrg.x), (CGFloat)(apt[i].y + hdc->viewportOrg.y));
    }
    CGContextClosePath(hdc->cgContext);
    CGContextFillPath(hdc->cgContext);
    return TRUE;
}

BOOL WINAPI Rectangle(HDC hdc, int left, int top, int right, int bottom) {
    if (!hdc || !hdc->cgContext) return FALSE;
    CGRect r = CGRectMake((CGFloat)(left + hdc->viewportOrg.x), (CGFloat)(top + hdc->viewportOrg.y),
                          (CGFloat)(right - left), (CGFloat)(bottom - top));

    MacBrush* brush = (MacBrush*)hdc->currentBrush;
    if (brush && brush->style != BS_NULL) {
        SetCGColorFromCOLORREF(hdc->cgContext, BrushColor(hdc, brush), false);
        CGContextFillRect(hdc->cgContext, r);
    }
    MacPen* pen = (MacPen*)hdc->currentPen;
    if (pen && pen->style != PS_NULL) {
        SetCGColorFromCOLORREF(hdc->cgContext, PenColor(hdc, pen), true);
        CGContextSetLineWidth(hdc->cgContext, (CGFloat)pen->width);
        CGContextStrokeRect(hdc->cgContext, r);
    }
    return TRUE;
}

BOOL WINAPI RoundRect(HDC hdc, int left, int top, int right, int bottom, int width, int height) {
    if (!hdc || !hdc->cgContext) return FALSE;
    CGRect r = CGRectMake((CGFloat)(left + hdc->viewportOrg.x), (CGFloat)(top + hdc->viewportOrg.y),
                          (CGFloat)(right - left), (CGFloat)(bottom - top));
    CGFloat radius = std::min((CGFloat)width, (CGFloat)height) / 2.0f;
    CGPathRef path = CGPathCreateWithRoundedRect(r, radius, radius, nullptr);

    MacBrush* brush = (MacBrush*)hdc->currentBrush;
    if (brush && brush->style != BS_NULL) {
        SetCGColorFromCOLORREF(hdc->cgContext, BrushColor(hdc, brush), false);
        CGContextAddPath(hdc->cgContext, path);
        CGContextFillPath(hdc->cgContext);
    }
    MacPen* pen = (MacPen*)hdc->currentPen;
    if (pen && pen->style != PS_NULL) {
        SetCGColorFromCOLORREF(hdc->cgContext, PenColor(hdc, pen), true);
        CGContextSetLineWidth(hdc->cgContext, (CGFloat)pen->width);
        CGContextAddPath(hdc->cgContext, path);
        CGContextStrokePath(hdc->cgContext);
    }
    CGPathRelease(path);
    return TRUE;
}

BOOL WINAPI Ellipse(HDC hdc, int left, int top, int right, int bottom) {
    if (!hdc || !hdc->cgContext) return FALSE;
    CGRect r = CGRectMake((CGFloat)(left + hdc->viewportOrg.x), (CGFloat)(top + hdc->viewportOrg.y),
                          (CGFloat)(right - left), (CGFloat)(bottom - top));

    MacBrush* brush = (MacBrush*)hdc->currentBrush;
    if (brush && brush->style != BS_NULL) {
        SetCGColorFromCOLORREF(hdc->cgContext, BrushColor(hdc, brush), false);
        CGContextFillEllipseInRect(hdc->cgContext, r);
    }
    MacPen* pen = (MacPen*)hdc->currentPen;
    if (pen && pen->style != PS_NULL) {
        SetCGColorFromCOLORREF(hdc->cgContext, PenColor(hdc, pen), true);
        CGContextSetLineWidth(hdc->cgContext, (CGFloat)pen->width);
        CGContextStrokeEllipseInRect(hdc->cgContext, r);
    }
    return TRUE;
}

BOOL WINAPI Arc(HDC hdc, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    (void)x3; (void)y3; (void)x4; (void)y4;
    return Ellipse(hdc, x1, y1, x2, y2);
}

BOOL WINAPI Pie(HDC hdc, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    (void)x3; (void)y3; (void)x4; (void)y4;
    return Ellipse(hdc, x1, y1, x2, y2);
}

int WINAPI FillRect(HDC hdc, const RECT* lprc, HBRUSH hbr) {
    if (!hdc || !hdc->cgContext || !lprc) return 0;
    CGRect r = CGRectMake((CGFloat)(lprc->left + hdc->viewportOrg.x), (CGFloat)(lprc->top + hdc->viewportOrg.y),
                          (CGFloat)(lprc->right - lprc->left), (CGFloat)(lprc->bottom - lprc->top));
    MacBrush* brush = (MacBrush*)hbr;
    COLORREF clr = BrushColor(hdc, brush);
    SetCGColorFromCOLORREF(hdc->cgContext, clr, false);
    CGContextFillRect(hdc->cgContext, r);
    return 1;
}

int WINAPI FrameRect(HDC hdc, const RECT* lprc, HBRUSH hbr) {
    if (!hdc || !hdc->cgContext || !lprc) return 0;
    CGRect r = CGRectMake((CGFloat)(lprc->left + hdc->viewportOrg.x), (CGFloat)(lprc->top + hdc->viewportOrg.y),
                          (CGFloat)(lprc->right - lprc->left), (CGFloat)(lprc->bottom - lprc->top));
    MacBrush* brush = (MacBrush*)hbr;
    COLORREF clr = BrushColor(hdc, brush);
    SetCGColorFromCOLORREF(hdc->cgContext, clr, true);
    CGContextSetLineWidth(hdc->cgContext, 1.0f);
    CGContextStrokeRect(hdc->cgContext, r);
    return 1;
}

BOOL WINAPI InvertRect(HDC hdc, const RECT* lprc) {
    if (!hdc || !hdc->cgContext || !lprc) return FALSE;
    CGRect r = CGRectMake((CGFloat)(lprc->left + hdc->viewportOrg.x), (CGFloat)(lprc->top + hdc->viewportOrg.y),
                          (CGFloat)(lprc->right - lprc->left), (CGFloat)(lprc->bottom - lprc->top));
    CGContextSetBlendMode(hdc->cgContext, kCGBlendModeDifference);
    CGContextSetRGBFillColor(hdc->cgContext, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextFillRect(hdc->cgContext, r);
    CGContextSetBlendMode(hdc->cgContext, kCGBlendModeNormal);
    return TRUE;
}

BOOL WINAPI DrawFocusRect(HDC hdc, const RECT* lprc) {
    if (!hdc || !hdc->cgContext || !lprc) return FALSE;
    CGFloat lengths[] = {1.0f, 1.0f};
    CGContextSetLineDash(hdc->cgContext, 0, lengths, 2);
    CGContextSetRGBStrokeColor(hdc->cgContext, 0.3f, 0.3f, 0.3f, 1.0f);
    CGRect r = CGRectMake((CGFloat)(lprc->left + hdc->viewportOrg.x), (CGFloat)(lprc->top + hdc->viewportOrg.y),
                          (CGFloat)(lprc->right - lprc->left), (CGFloat)(lprc->bottom - lprc->top));
    CGContextStrokeRect(hdc->cgContext, r);
    CGContextSetLineDash(hdc->cgContext, 0, nullptr, 0);
    return TRUE;
}

BOOL WINAPI DrawEdge(HDC hdc, LPRECT qrc, UINT edge, UINT grfFlags) {
    (void)grfFlags;
    if (!hdc || !qrc) return FALSE;
    COLORREF cHigh = GetSysColor(COLOR_3DHIGHLIGHT);
    COLORREF cShadow = GetSysColor(COLOR_3DSHADOW);
    if ((edge & BDR_SUNKENOUTER) || (edge & BDR_SUNKENINNER)) {
        std::swap(cHigh, cShadow);
    }
    RECT r = *qrc;
    HBRUSH hHigh = CreateSolidBrush(cHigh);
    HBRUSH hShadow = CreateSolidBrush(cShadow);
    RECT top = {r.left, r.top, r.right, r.top + 1};
    RECT left = {r.left, r.top, r.left + 1, r.bottom};
    RECT bottom = {r.left, r.bottom - 1, r.right, r.bottom};
    RECT right = {r.right - 1, r.top, r.right, r.bottom};
    FillRect(hdc, &top, hHigh);
    FillRect(hdc, &left, hHigh);
    FillRect(hdc, &bottom, hShadow);
    FillRect(hdc, &right, hShadow);
    DeleteObject(hHigh);
    DeleteObject(hShadow);
    return TRUE;
}

BOOL WINAPI DrawFrameControl(HDC hdc, LPRECT lprc, UINT uType, UINT uState) {
    (void)uType; (void)uState;
    if (!hdc || !lprc) return FALSE;
    HBRUSH br = CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
    FillRect(hdc, lprc, br);
    DeleteObject(br);
    DrawEdge(hdc, lprc, EDGE_RAISED, BF_RECT);
    return TRUE;
}

BOOL WINAPI BitBlt(HDC hdc, int x, int y, int cx, int cy, HDC hdcSrc, int x1, int y1, DWORD rop) {
    if (!hdc || !hdc->cgContext || !hdcSrc || !hdcSrc->currentBitmap) return FALSE;
    MacBitmap* srcBmp = hdcSrc->currentBitmap;
    if (!srcBmp->bitmapContext) return FALSE;

    CGImageRef img = CGBitmapContextCreateImage(srcBmp->bitmapContext);
    if (!img) return FALSE;

    CGRect destRect = CGRectMake((CGFloat)(x + hdc->viewportOrg.x), (CGFloat)(y + hdc->viewportOrg.y), (CGFloat)cx, (CGFloat)cy);
    CGRect srcCrop = CGRectMake((CGFloat)x1, (CGFloat)(srcBmp->bottomUp ? srcBmp->height - (y1 + cy) : y1), (CGFloat)cx, (CGFloat)cy);

    CGImageRef subImg = CGImageCreateWithImageInRect(img, srcCrop);
    CGImageRelease(img);
    if (!subImg) return FALSE;

    CGContextSaveGState(hdc->cgContext);
    // Draw flipped because CG coordinate system is bottom-up
    CGContextTranslateCTM(hdc->cgContext, destRect.origin.x, destRect.origin.y + destRect.size.height);
    CGContextScaleCTM(hdc->cgContext, 1.0f, -1.0f);
    CGContextDrawImage(hdc->cgContext, CGRectMake(0, 0, destRect.size.width, destRect.size.height), subImg);
    CGContextRestoreGState(hdc->cgContext);
    CGImageRelease(subImg);
    return TRUE;
}

BOOL WINAPI StretchBlt(HDC hdcDest, int xDest, int yDest, int wDest, int hDest,
                       HDC hdcSrc, int xSrc, int ySrc, int wSrc, int hSrc, DWORD rop) {
    if (!hdcDest || !hdcDest->cgContext || !hdcSrc || !hdcSrc->currentBitmap) return FALSE;
    MacBitmap* srcBmp = hdcSrc->currentBitmap;
    if (!srcBmp->bitmapContext) return FALSE;

    CGImageRef img = CGBitmapContextCreateImage(srcBmp->bitmapContext);
    if (!img) return FALSE;

    CGRect destRect = CGRectMake((CGFloat)(xDest + hdcDest->viewportOrg.x), (CGFloat)(yDest + hdcDest->viewportOrg.y), (CGFloat)wDest, (CGFloat)hDest);
    CGRect srcCrop = CGRectMake((CGFloat)xSrc, (CGFloat)(srcBmp->bottomUp ? srcBmp->height - (ySrc + hSrc) : ySrc), (CGFloat)wSrc, (CGFloat)hSrc);

    CGImageRef subImg = CGImageCreateWithImageInRect(img, srcCrop);
    CGImageRelease(img);
    if (!subImg) return FALSE;

    CGContextSaveGState(hdcDest->cgContext);
    CGContextTranslateCTM(hdcDest->cgContext, destRect.origin.x, destRect.origin.y + destRect.size.height);
    CGContextScaleCTM(hdcDest->cgContext, 1.0f, -1.0f);
    CGContextDrawImage(hdcDest->cgContext, CGRectMake(0, 0, destRect.size.width, destRect.size.height), subImg);
    CGContextRestoreGState(hdcDest->cgContext);
    CGImageRelease(subImg);
    return TRUE;
}

BOOL WINAPI PatBlt(HDC hdc, int x, int y, int w, int h, DWORD rop) {
    if (!hdc || !hdc->cgContext) return FALSE;
    RECT r = {x, y, x + w, y + h};
    if (rop == BLACKNESS) {
        HBRUSH br = CreateSolidBrush(RGB(0, 0, 0));
        FillRect(hdc, &r, br);
        DeleteObject(br);
    } else if (rop == WHITENESS) {
        HBRUSH br = CreateSolidBrush(RGB(255, 255, 255));
        FillRect(hdc, &r, br);
        DeleteObject(br);
    } else {
        FillRect(hdc, &r, (HBRUSH)hdc->currentBrush);
    }
    return TRUE;
}

int WINAPI SetDIBitsToDevice(HDC hdc, int xDest, int yDest, DWORD w, DWORD h,
                             int xSrc, int ySrc, UINT StartScan, UINT cLines,
                             const VOID* lpvBits, const BITMAPINFO* lpbmi, UINT ColorUse) {
    if (!hdc || !hdc->cgContext || !lpvBits || !lpbmi) return 0;
    int srcW = lpbmi->bmiHeader.biWidth;
    int srcH = std::abs(lpbmi->bmiHeader.biHeight);
    int bpp = lpbmi->bmiHeader.biBitCount;

    CGColorSpaceRef colorSpace = nullptr;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

    std::vector<uint32_t> rgbaBuf;
    const void* drawBits = lpvBits;
    size_t stride = (size_t)(((srcW * bpp + 31) / 32) * 4);

    if (bpp == 8) {
        // 8-bit indexed fast bitmap (CFastBitmap / pattern view)
        rgbaBuf.resize((size_t)srcW * (size_t)srcH);
        const uint8_t* pSrc = (const uint8_t*)lpvBits;
        const RGBQUAD* pal = lpbmi->bmiColors;
        for (int row = 0; row < srcH; ++row) {
            const uint8_t* rowSrc = pSrc + (size_t)(srcH - 1 - row) * stride;
            uint32_t* rowDst = rgbaBuf.data() + (size_t)row * (size_t)srcW;
            for (int col = 0; col < srcW; ++col) {
                uint8_t idx = rowSrc[col];
                RGBQUAD q = pal[idx];
                rowDst[col] = (0xFF << 24) | ((uint32_t)q.rgbBlue << 16) | ((uint32_t)q.rgbGreen << 8) | (uint32_t)q.rgbRed;
            }
        }
        colorSpace = CGColorSpaceCreateDeviceRGB();
        drawBits = rgbaBuf.data();
        stride = (size_t)srcW * 4;
        bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;  // bytes are R,G,B,X
    } else if (bpp == 32) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    // Copy the pixels: window contexts may rasterize the image after this call returns, when drawBits is gone or reused.
    CFDataRef pixels = CFDataCreate(nullptr, (const UInt8*)drawBits, (CFIndex)(stride * (size_t)srcH));
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(pixels);
    CFRelease(pixels);
    CGImageRef img = CGImageCreate(srcW, srcH, 8, (bpp == 8 ? 32 : bpp), stride, colorSpace, bitmapInfo, provider, nullptr, false, kCGRenderingIntentDefault);

    if (img) {
        CGRect destRect = CGRectMake((CGFloat)(xDest + hdc->viewportOrg.x), (CGFloat)(yDest + hdc->viewportOrg.y), (CGFloat)w, (CGFloat)h);
        // ySrc counts from the bottom of a bottom-up DIB; the 8-bit buffer above is already converted to top-down rows.
        const bool bottomUp = lpbmi->bmiHeader.biHeight > 0;
        CGRect cropRect = CGRectMake((CGFloat)xSrc, (CGFloat)(bpp == 8 && bottomUp ? srcH - (ySrc + (int)h) : ySrc), (CGFloat)w, (CGFloat)h);
        CGImageRef subImg = CGImageCreateWithImageInRect(img, cropRect);

        CGContextSaveGState(hdc->cgContext);
        CGContextTranslateCTM(hdc->cgContext, destRect.origin.x, destRect.origin.y + destRect.size.height);
        CGContextScaleCTM(hdc->cgContext, 1.0f, -1.0f);
        CGContextDrawImage(hdc->cgContext, CGRectMake(0, 0, destRect.size.width, destRect.size.height), subImg ? subImg : img);
        CGContextRestoreGState(hdc->cgContext);

        if (subImg) CGImageRelease(subImg);
        CGImageRelease(img);
    }

    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return (int)cLines;
}

int WINAPI StretchDIBits(HDC hdc, int xDest, int yDest, int DestWidth, int DestHeight,
                         int xSrc, int ySrc, int SrcWidth, int SrcHeight,
                         const VOID* lpBits, const BITMAPINFO* lpBitsInfo, UINT iUsage, DWORD rop) {
    return SetDIBitsToDevice(hdc, xDest, yDest, DestWidth, DestHeight, xSrc, ySrc, 0, SrcHeight, lpBits, lpBitsInfo, iUsage);
}

COLORREF WINAPI GetPixel(HDC hdc, int x, int y) {
    if (!hdc || !hdc->currentBitmap) return 0;
    MacBitmap* bmp = hdc->currentBitmap;
    if (x < 0 || x >= bmp->width || y < 0 || y >= bmp->height) return 0;
    size_t stride = (size_t)(((bmp->width * bmp->bpp + 31) / 32) * 4);
    const uint8_t* p = bmp->pixelData.data() + (size_t)y * stride + (size_t)x * 4;
    return RGB(p[0], p[1], p[2]);
}

COLORREF WINAPI SetPixel(HDC hdc, int x, int y, COLORREF color) {
    if (!hdc || !hdc->currentBitmap) return 0;
    MacBitmap* bmp = hdc->currentBitmap;
    if (x < 0 || x >= bmp->width || y < 0 || y >= bmp->height) return 0;
    size_t stride = (size_t)(((bmp->width * bmp->bpp + 31) / 32) * 4);
    uint8_t* p = bmp->pixelData.data() + (size_t)y * stride + (size_t)x * 4;
    p[0] = GetRValue(color);
    p[1] = GetGValue(color);
    p[2] = GetBValue(color);
    p[3] = 0xFF;
    return color;
}

BOOL WINAPI SetPixelV(HDC hdc, int x, int y, COLORREF color) {
    SetPixel(hdc, x, y, color);
    return TRUE;
}

BOOL WINAPI TextOutA(HDC hdc, int x, int y, LPCSTR lpString, int c) {
    if (!hdc || !hdc->cgContext || !lpString || c <= 0) return FALSE;
    NSString* str = [[NSString alloc] initWithBytes:lpString length:(NSUInteger)c encoding:NSUTF8StringEncoding];
    if (!str) str = [[NSString alloc] initWithBytes:lpString length:(NSUInteger)c encoding:NSISOLatin1StringEncoding];
    if (!str) return FALSE;

    MacFont* font = (MacFont*)hdc->currentFont;
    CTFontRef ctFont = font ? font->ctFont : nullptr;
    if (!ctFont) ctFont = CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, 12.0f, nullptr);

    CGFloat r = GetRValue(hdc->textColor) / 255.0f;
    CGFloat g = GetGValue(hdc->textColor) / 255.0f;
    CGFloat b = GetBValue(hdc->textColor) / 255.0f;
    CGColorRef clr = CGColorCreateGenericRGB(r, g, b, 1.0f);

    NSDictionary* attrs = @{
        (__bridge id)kCTFontAttributeName: (__bridge id)ctFont,
        (__bridge id)kCTForegroundColorAttributeName: (__bridge id)clr
    };
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:str attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrStr);

    CGFloat ascent = 0, descent = 0, leading = 0;
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

    if (hdc->bkMode == OPAQUE) {
        CGFloat width = CTLineGetTypographicBounds(line, nullptr, nullptr, nullptr);
        RECT rcBk = {x, y, (int)(x + width), (int)(y + ascent + descent)};
        HBRUSH brBk = CreateSolidBrush(hdc->bkColor);
        FillRect(hdc, &rcBk, brBk);
        DeleteObject(brBk);
    }

    CGContextSaveGState(hdc->cgContext);
    // Draw CoreText line flipped
    CGContextSetTextMatrix(hdc->cgContext, CGAffineTransformIdentity);
    CGContextTranslateCTM(hdc->cgContext, (CGFloat)(x + hdc->viewportOrg.x), (CGFloat)(y + hdc->viewportOrg.y) + ascent);
    CGContextScaleCTM(hdc->cgContext, 1.0f, -1.0f);
    CGContextSetTextPosition(hdc->cgContext, 0, 0);
    CTLineDraw(line, hdc->cgContext);
    CGContextRestoreGState(hdc->cgContext);

    CFRelease(line);
    CGColorRelease(clr);
    if (!font) CFRelease(ctFont);
    return TRUE;
}

BOOL WINAPI TextOutW(HDC hdc, int x, int y, LPCWSTR lpString, int c) {
    if (!lpString || c <= 0) return FALSE;
    char buf[1024] = {};
    int len = WideCharToMultiByte(CP_UTF8, 0, lpString, c, buf, sizeof(buf) - 1, nullptr, nullptr);
    return TextOutA(hdc, x, y, buf, len);
}

BOOL WINAPI ExtTextOutA(HDC hdc, int x, int y, UINT options, const RECT* lprect, LPCSTR lpString, UINT c, const INT* lpDx) {
    (void)lpDx;
    if (lprect && (options & ETO_OPAQUE)) {
        HBRUSH br = CreateSolidBrush(hdc ? hdc->bkColor : RGB(255, 255, 255));
        FillRect(hdc, lprect, br);
        DeleteObject(br);
    }
    if (lpString && c > 0) {
        return TextOutA(hdc, x, y, lpString, (int)c);
    }
    return TRUE;
}

BOOL WINAPI ExtTextOutW(HDC hdc, int x, int y, UINT options, const RECT* lprect, LPCWSTR lpString, UINT c, const INT* lpDx) {
    if (lprect && (options & ETO_OPAQUE)) {
        HBRUSH br = CreateSolidBrush(hdc ? hdc->bkColor : RGB(255, 255, 255));
        FillRect(hdc, lprect, br);
        DeleteObject(br);
    }
    if (lpString && c > 0) {
        return TextOutW(hdc, x, y, lpString, (int)c);
    }
    return TRUE;
}

// DrawText with the Windows layout rules mptrack relies on: '&' prefixes, line breaks, word
// wrapping, ellipses, single-line vertical alignment, DT_CALCRECT and clipping.
int WINAPI DrawTextA(HDC hdc, LPCSTR lpchText, int cchText, LPRECT lprc, UINT format) {
    if (!hdc || !lpchText || !lprc) return 0;
    std::string text(lpchText, (cchText < 0) ? strlen(lpchText) : (size_t)cchText);
    if (!(format & DT_NOPREFIX)) {
        // Windows 10 hides mnemonic underlines until Alt is pressed: drop '&', keep "&&" as '&'.
        std::string stripped;
        for (size_t i = 0; i < text.size(); ++i) {
            if (text[i] == '&' && i + 1 < text.size()) ++i;
            else if (text[i] == '&') continue;
            stripped += text[i];
        }
        text = std::move(stripped);
    }
    auto width = [&](const std::string& t) {
        SIZE sz{};
        GetTextExtentPoint32A(hdc, t.c_str(), (int)t.size(), &sz);
        return (int)sz.cx;
    };
    SIZE lineSize{};
    GetTextExtentPoint32A(hdc, "Ag", 2, &lineSize);
    const int lineHeight = lineSize.cy;
    const int maxWidth = lprc->right - lprc->left;

    std::vector<std::string> lines;
    if (format & DT_SINGLELINE) {
        std::replace(text.begin(), text.end(), '\n', ' ');
        text.erase(std::remove(text.begin(), text.end(), '\r'), text.end());
        lines.push_back(text);
    } else {
        std::istringstream paragraphs(text);
        std::string paragraph;
        while (std::getline(paragraphs, paragraph)) {
            if (!paragraph.empty() && paragraph.back() == '\r') paragraph.pop_back();
            if (!(format & DT_WORDBREAK) || width(paragraph) <= maxWidth) {
                lines.push_back(paragraph);
                continue;
            }
            std::string current;
            std::istringstream words(paragraph);
            std::string word;
            while (words >> word) {
                const std::string candidate = current.empty() ? word : current + " " + word;
                if (!current.empty() && width(candidate) > maxWidth) {
                    lines.push_back(current);
                    current = word;
                } else {
                    current = candidate;
                }
            }
            lines.push_back(current);
        }
        if (lines.empty()) lines.push_back("");
    }
    if (format & (DT_END_ELLIPSIS | DT_PATH_ELLIPSIS | DT_WORD_ELLIPSIS)) {
        for (std::string& line : lines) {
            if (width(line) <= maxWidth) continue;
            while (!line.empty() && width(line + "...") > maxWidth) {
                // Drop a whole UTF-8 sequence at a time.
                do line.pop_back(); while (!line.empty() && (line.back() & 0xC0) == 0x80);
            }
            line += "...";
        }
    }

    int textWidth = 0;
    for (const std::string& line : lines) textWidth = std::max(textWidth, width(line));
    const int textHeight = lineHeight * (int)lines.size();
    if (format & DT_CALCRECT) {
        lprc->right = lprc->left + textWidth;
        lprc->bottom = lprc->top + textHeight;
        return textHeight;
    }

    int y = lprc->top;
    if (format & DT_SINGLELINE) {
        if (format & DT_VCENTER) y = lprc->top + (lprc->bottom - lprc->top - lineHeight) / 2;
        else if (format & DT_BOTTOM) y = lprc->bottom - lineHeight;
    }
    const bool clip = !(format & DT_NOCLIP) && hdc->cgContext;
    if (clip) {
        CGContextSaveGState(hdc->cgContext);
        CGContextClipToRect(hdc->cgContext, CGRectMake(lprc->left + hdc->viewportOrg.x, lprc->top + hdc->viewportOrg.y, maxWidth, lprc->bottom - lprc->top));
    }
    for (const std::string& line : lines) {
        const int w = width(line);
        int x = lprc->left;
        if (format & DT_CENTER) x = lprc->left + (maxWidth - w) / 2;
        else if (format & DT_RIGHT) x = lprc->right - w;
        TextOutA(hdc, x, y, line.c_str(), (int)line.size());
        y += lineHeight;
    }
    if (clip) CGContextRestoreGState(hdc->cgContext);
    return textHeight;
}

int WINAPI DrawTextW(HDC hdc, LPCWSTR lpchText, int cchText, LPRECT lprc, UINT format) {
    if (!lpchText || !lprc) return 0;
    const int wlen = (cchText < 0) ? (int)wcslen(lpchText) : cchText;
    std::string utf8(wlen * 4 + 1, '\0');
    const int len = WideCharToMultiByte(CP_UTF8, 0, lpchText, wlen, utf8.data(), (int)utf8.size(), nullptr, nullptr);
    return DrawTextA(hdc, utf8.c_str(), len, lprc, format);
}

BOOL WINAPI GetTextExtentPoint32A(HDC hdc, LPCSTR lpString, int c, LPSIZE psizl) {
    if (!psizl) return FALSE;
    if (!lpString || c <= 0) {
        psizl->cx = 0; psizl->cy = 0;
        return TRUE;
    }
    MacFont* font = hdc ? (MacFont*)hdc->currentFont : nullptr;
    CTFontRef ctFont = font ? font->ctFont : nullptr;
    if (!ctFont) ctFont = CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, 12.0f, nullptr);

    NSString* str = [[NSString alloc] initWithBytes:lpString length:(NSUInteger)c encoding:NSUTF8StringEncoding];
    if (!str) str = [[NSString alloc] initWithBytes:lpString length:(NSUInteger)c encoding:NSISOLatin1StringEncoding];

    NSDictionary* attrs = @{ (__bridge id)kCTFontAttributeName: (__bridge id)ctFont };
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:(str ? str : @"") attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrStr);

    CGFloat ascent = 0, descent = 0, leading = 0;
    CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    psizl->cx = (LONG)std::ceil(width);
    psizl->cy = (LONG)std::ceil(ascent + descent);

    CFRelease(line);
    if (!font) CFRelease(ctFont);
    return TRUE;
}

BOOL WINAPI GetTextExtentPoint32W(HDC hdc, LPCWSTR lpString, int c, LPSIZE psizl) {
    if (!lpString || c <= 0) {
        if (psizl) { psizl->cx = 0; psizl->cy = 0; }
        return TRUE;
    }
    char buf[1024] = {};
    int len = WideCharToMultiByte(CP_UTF8, 0, lpString, c, buf, sizeof(buf) - 1, nullptr, nullptr);
    return GetTextExtentPoint32A(hdc, buf, len, psizl);
}

BOOL WINAPI GetTextMetricsA(HDC hdc, LPTEXTMETRICA lptm) {
    if (!lptm) return FALSE;
    MacFont* font = hdc ? (MacFont*)hdc->currentFont : nullptr;
    lptm->tmHeight = font ? font->height : 12;
    lptm->tmAscent = font ? font->ascent : 10;
    lptm->tmDescent = font ? font->descent : 2;
    lptm->tmAveCharWidth = font ? font->aveCharWidth : 7;
    lptm->tmMaxCharWidth = lptm->tmAveCharWidth * 2;
    lptm->tmWeight = font ? font->logFont.lfWeight : FW_NORMAL;
    lptm->tmItalic = font ? font->logFont.lfItalic : 0;
    lptm->tmUnderlined = font ? font->logFont.lfUnderline : 0;
    lptm->tmStruckOut = font ? font->logFont.lfStrikeOut : 0;
    lptm->tmInternalLeading = 0;
    lptm->tmExternalLeading = 0;
    return TRUE;
}

BOOL WINAPI GetTextMetricsW(HDC hdc, LPTEXTMETRICW lptm) {
    TEXTMETRICA tma{};
    if (!GetTextMetricsA(hdc, &tma)) return FALSE;
    lptm->tmHeight = tma.tmHeight;
    lptm->tmAscent = tma.tmAscent;
    lptm->tmDescent = tma.tmDescent;
    lptm->tmAveCharWidth = tma.tmAveCharWidth;
    lptm->tmMaxCharWidth = tma.tmMaxCharWidth;
    lptm->tmWeight = tma.tmWeight;
    lptm->tmItalic = tma.tmItalic;
    lptm->tmUnderlined = tma.tmUnderlined;
    lptm->tmStruckOut = tma.tmStruckOut;
    return TRUE;
}

// Region functions
HRGN WINAPI CreateRectRgn(int x1, int y1, int x2, int y2) {
    MacRgn* rgn = new MacRgn();
    rgn->path = CGPathCreateMutable();
    CGPathAddRect(rgn->path, nullptr, CGRectMake((CGFloat)x1, (CGFloat)y1, (CGFloat)(x2 - x1), (CGFloat)(y2 - y1)));
    return (HRGN)rgn;
}

HRGN WINAPI CreateRectRgnIndirect(const RECT* lprc) {
    if (!lprc) return nullptr;
    return CreateRectRgn(lprc->left, lprc->top, lprc->right, lprc->bottom);
}

HRGN WINAPI CreatePolygonRgn(const POINT* pptl, int cPoints, int iMode) {
    (void)iMode;
    if (!pptl || cPoints < 3) return nullptr;
    MacRgn* rgn = new MacRgn();
    rgn->path = CGPathCreateMutable();
    CGPathMoveToPoint(rgn->path, nullptr, (CGFloat)pptl[0].x, (CGFloat)pptl[0].y);
    for (int i = 1; i < cPoints; ++i) {
        CGPathAddLineToPoint(rgn->path, nullptr, (CGFloat)pptl[i].x, (CGFloat)pptl[i].y);
    }
    CGPathCloseSubpath(rgn->path);
    return (HRGN)rgn;
}

int WINAPI CombineRgn(HRGN hrgnDst, HRGN hrgnSrc1, HRGN hrgnSrc2, int iMode) {
    (void)hrgnDst; (void)hrgnSrc1; (void)hrgnSrc2; (void)iMode;
    return SIMPLEREGION;
}

BOOL WINAPI PtInRegion(HRGN hrgn, int x, int y) {
    if (!hrgn) return FALSE;
    MacRgn* rgn = (MacRgn*)hrgn;
    return CGPathContainsPoint(rgn->path, nullptr, CGPointMake((CGFloat)x, (CGFloat)y), false);
}

int WINAPI SelectClipRgn(HDC hdc, HRGN hrgn) {
    if (!hdc || !hdc->cgContext) return ERROR;
    if (hrgn) {
        MacRgn* rgn = (MacRgn*)hrgn;
        CGContextAddPath(hdc->cgContext, rgn->path);
        CGContextClip(hdc->cgContext);
    }
    return SIMPLEREGION;
}

int WINAPI ExtSelectClipRgn(HDC hdc, HRGN hrgn, int mode) {
    (void)mode;
    return SelectClipRgn(hdc, hrgn);
}

int WINAPI IntersectClipRect(HDC hdc, int left, int top, int right, int bottom) {
    if (!hdc || !hdc->cgContext) return ERROR;
    CGRect r = CGRectMake((CGFloat)(left + hdc->viewportOrg.x), (CGFloat)(top + hdc->viewportOrg.y),
                          (CGFloat)(right - left), (CGFloat)(bottom - top));
    CGContextClipToRect(hdc->cgContext, r);
    return SIMPLEREGION;
}

int WINAPI ExcludeClipRect(HDC hdc, int left, int top, int right, int bottom) {
    (void)hdc; (void)left; (void)top; (void)right; (void)bottom;
    return SIMPLEREGION;
}

int WINAPI GetClipBox(HDC hdc, LPRECT lprect) {
    if (!hdc || !hdc->cgContext || !lprect) return ERROR;
    CGRect r = CGContextGetClipBoundingBox(hdc->cgContext);
    lprect->left = (LONG)r.origin.x - hdc->viewportOrg.x;
    lprect->top = (LONG)r.origin.y - hdc->viewportOrg.y;
    lprect->right = (LONG)(r.origin.x + r.size.width) - hdc->viewportOrg.x;
    lprect->bottom = (LONG)(r.origin.y + r.size.height) - hdc->viewportOrg.y;
    return SIMPLEREGION;
}

BOOL WINAPI RectVisible(HDC hdc, const RECT* lprect) {
    if (!hdc || !hdc->cgContext || !lprect) return FALSE;
    CGRect r = CGRectMake((CGFloat)(lprect->left + hdc->viewportOrg.x), (CGFloat)(lprect->top + hdc->viewportOrg.y),
                          (CGFloat)(lprect->right - lprect->left), (CGFloat)(lprect->bottom - lprect->top));
    CGRect clip = CGContextGetClipBoundingBox(hdc->cgContext);
    return CGRectIntersectsRect(clip, r);
}

BOOL WINAPI DrawIcon(HDC hdc, int x, int y, HICON hIcon) {
    (void)hIcon;
    RECT r = {x, y, x + 16, y + 16};
    HBRUSH br = CreateSolidBrush(RGB(128, 128, 128));
    FillRect(hdc, &r, br);
    DeleteObject(br);
    return TRUE;
}

// Gdiplus Implementation
namespace Gdiplus {

Bitmap::Bitmap(INT width, INT height, PixelFormat format) {
    m_width = (UINT)std::max(1, width);
    m_height = (UINT)std::max(1, height);
    m_pixels.resize((size_t)m_width * (size_t)m_height * 4, 0);
    m_status = Ok;
}

Bitmap::Bitmap(IStream* stream, BOOL useEmbeddedColorManagement) {
    (void)useEmbeddedColorManagement;
    if (!stream) { m_status = InvalidParameter; return; }

    STATSTG stat{};
    stream->Stat(&stat, 0);
    size_t size = (size_t)stat.cbSize.QuadPart;
    if (size == 0) { m_status = GenericError; return; }

    std::vector<uint8_t> data(size);
    ULONG read = 0;
    stream->Read(data.data(), (ULONG)size, &read);

    NSData* nsData = [NSData dataWithBytes:data.data() length:data.size()];
    NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:nsData];
    if (!rep) { m_status = GenericError; return; }

    m_width = (UINT)[rep pixelsWide];
    m_height = (UINT)[rep pixelsHigh];
    m_pixels.resize((size_t)m_width * (size_t)m_height * 4, 0);

    // GDI+ PixelFormat32bppARGB is B,G,R,A in memory and not premultiplied; CG can only render premultiplied.
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef ctx = CGBitmapContextCreate(m_pixels.data(), m_width, m_height, 8, m_width * 4, cs,
                                            kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(cs);

    if (ctx) {
        CGImageRef img = [rep CGImage];
        if (img) CGContextDrawImage(ctx, CGRectMake(0, 0, m_width, m_height), img);
        CGContextRelease(ctx);
        for (size_t i = 0; i < m_pixels.size(); i += 4) {
            const uint8_t alpha = m_pixels[i + 3];
            if (alpha != 0 && alpha != 255) {
                for (int c = 0; c < 3; c++) m_pixels[i + c] = (uint8_t)std::min(255, m_pixels[i + c] * 255 / alpha);
            }
        }
        m_status = Ok;
    } else {
        m_status = GenericError;
    }
}

Bitmap* Bitmap::FromStream(IStream* stream, BOOL useEmbeddedColorManagement) {
    Bitmap* bmp = new Bitmap(stream, useEmbeddedColorManagement);
    if (bmp->GetLastStatus() != Ok) {
        delete bmp;
        return nullptr;
    }
    return bmp;
}

Status Bitmap::LockBits(const Rect* rect, UINT flags, PixelFormat format, BitmapData* lockedBitmapData) {
    if (!lockedBitmapData) return InvalidParameter;
    lockedBitmapData->Width = m_width;
    lockedBitmapData->Height = m_height;
    lockedBitmapData->Stride = (INT)m_width * 4;
    lockedBitmapData->PixelFormat = PixelFormat32bppARGB;
    lockedBitmapData->Scan0 = m_pixels.data();
    return Ok;
}

Status Bitmap::UnlockBits(BitmapData* lockedBitmapData) {
    (void)lockedBitmapData;
    return Ok;
}

Metafile::Metafile(const void* data, size_t size) {
    (void)data; (void)size;
    m_status = UnknownImageFormat;
}

Status Graphics::Clear(const Color& color) {
    if (m_target && !m_target->m_pixels.empty()) {
        uint32_t val = (static_cast<uint32_t>(color.A) << 24) |
                       (static_cast<uint32_t>(color.R) << 16) |
                       (static_cast<uint32_t>(color.G) << 8) |
                       static_cast<uint32_t>(color.B);
        if (val == 0) {
            std::memset(m_target->m_pixels.data(), 0, m_target->m_pixels.size());
        } else {
            uint32_t* ptr = reinterpret_cast<uint32_t*>(m_target->m_pixels.data());
            size_t count = m_target->m_pixels.size() / 4;
            std::fill(ptr, ptr + count, val);
        }
    }
    return Ok;
}

Status Graphics::DrawImage(Image* image, INT x, INT y) {
    if (!image) return InvalidParameter;
    return DrawImage(image, x, y, (INT)image->GetWidth(), (INT)image->GetHeight());
}

Status Graphics::DrawImage(Image* image, INT x, INT y, INT width, INT height) {
    if (!image) return InvalidParameter;
    if (m_hdc && m_hdc->cgContext) {
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef prov = CGDataProviderCreateWithData(nullptr, image->m_pixels.data(), image->m_pixels.size(), nullptr);
        CGImageRef img = CGImageCreate(image->m_width, image->m_height, 8, 32, image->m_width * 4, cs,
                                       kCGImageAlphaFirst | kCGBitmapByteOrder32Little, prov, nullptr, false, kCGRenderingIntentDefault);
        if (img) {
            CGRect r = CGRectMake((CGFloat)(x + m_hdc->viewportOrg.x), (CGFloat)(y + m_hdc->viewportOrg.y), (CGFloat)width, (CGFloat)height);
            CGContextSaveGState(m_hdc->cgContext);
            CGContextTranslateCTM(m_hdc->cgContext, r.origin.x, r.origin.y + r.size.height);
            CGContextScaleCTM(m_hdc->cgContext, 1.0f, -1.0f);
            CGContextDrawImage(m_hdc->cgContext, CGRectMake(0, 0, r.size.width, r.size.height), img);
            CGContextRestoreGState(m_hdc->cgContext);
            CGImageRelease(img);
        }
        CGDataProviderRelease(prov);
        CGColorSpaceRelease(cs);
    } else if (m_target) {
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef prov = CGDataProviderCreateWithData(nullptr, image->m_pixels.data(), image->m_pixels.size(), nullptr);
        CGImageRef img = CGImageCreate(image->m_width, image->m_height, 8, 32, image->m_width * 4, cs,
                                       kCGImageAlphaFirst | kCGBitmapByteOrder32Little, prov, nullptr, false, kCGRenderingIntentDefault);
        if (img) {
            CGContextRef ctx = CGBitmapContextCreate(m_target->m_pixels.data(), m_target->m_width, m_target->m_height, 8, m_target->m_width * 4, cs,
                                                     kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
            if (ctx) {
                CGRect r = CGRectMake((CGFloat)x, (CGFloat)(m_target->m_height - y - height), (CGFloat)width, (CGFloat)height);
                CGContextDrawImage(ctx, r, img);
                CGContextRelease(ctx);
            }
            CGImageRelease(img);
        }
        CGDataProviderRelease(prov);
        CGColorSpaceRelease(cs);
    }
    return Ok;
}

Status Graphics::DrawImage(Image* image, const Rect& destRect, INT srcx, INT srcy, INT srcwidth, INT srcheight, Unit srcUnit, const ImageAttributes* attr) {
    if (!image) return InvalidParameter;
    (void)srcUnit; (void)attr;
    if (m_hdc && m_hdc->cgContext) {
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef prov = CGDataProviderCreateWithData(nullptr, image->m_pixels.data(), image->m_pixels.size(), nullptr);
        CGImageRef fullImg = CGImageCreate(image->m_width, image->m_height, 8, 32, image->m_width * 4, cs,
                                           kCGImageAlphaFirst | kCGBitmapByteOrder32Little, prov, nullptr, false, kCGRenderingIntentDefault);
        if (fullImg) {
            CGRect subRect = CGRectMake(srcx, (CGFloat)image->m_height - (CGFloat)(srcy + srcheight), srcwidth, srcheight);
            CGImageRef subImg = CGImageCreateWithImageInRect(fullImg, subRect);
            CGImageRef toDraw = subImg ? subImg : fullImg;
            CGRect r = CGRectMake((CGFloat)(destRect.X + m_hdc->viewportOrg.x), (CGFloat)(destRect.Y + m_hdc->viewportOrg.y), (CGFloat)destRect.Width, (CGFloat)destRect.Height);
            CGContextSaveGState(m_hdc->cgContext);
            CGContextTranslateCTM(m_hdc->cgContext, r.origin.x, r.origin.y + r.size.height);
            CGContextScaleCTM(m_hdc->cgContext, 1.0f, -1.0f);
            CGContextDrawImage(m_hdc->cgContext, CGRectMake(0, 0, r.size.width, r.size.height), toDraw);
            CGContextRestoreGState(m_hdc->cgContext);
            if (subImg) CGImageRelease(subImg);
            CGImageRelease(fullImg);
        }
        CGDataProviderRelease(prov);
        CGColorSpaceRelease(cs);
    } else if (m_target) {
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef prov = CGDataProviderCreateWithData(nullptr, image->m_pixels.data(), image->m_pixels.size(), nullptr);
        CGImageRef fullImg = CGImageCreate(image->m_width, image->m_height, 8, 32, image->m_width * 4, cs,
                                           kCGImageAlphaFirst | kCGBitmapByteOrder32Little, prov, nullptr, false, kCGRenderingIntentDefault);
        if (fullImg) {
            CGRect subRect = CGRectMake(srcx, (CGFloat)image->m_height - (CGFloat)(srcy + srcheight), srcwidth, srcheight);
            CGImageRef subImg = CGImageCreateWithImageInRect(fullImg, subRect);
            CGImageRef toDraw = subImg ? subImg : fullImg;
            CGContextRef ctx = CGBitmapContextCreate(m_target->m_pixels.data(), m_target->m_width, m_target->m_height, 8, m_target->m_width * 4, cs,
                                                     kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
            if (ctx) {
                CGRect r = CGRectMake((CGFloat)destRect.X, (CGFloat)(m_target->m_height - destRect.Y - destRect.Height), (CGFloat)destRect.Width, (CGFloat)destRect.Height);
                CGContextDrawImage(ctx, r, toDraw);
                CGContextRelease(ctx);
            }
            if (subImg) CGImageRelease(subImg);
            CGImageRelease(fullImg);
        }
        CGDataProviderRelease(prov);
        CGColorSpaceRelease(cs);
    }
    return Ok;
}

Status Graphics::DrawImage(Image* image, const RectF& destRect, float srcx, float srcy, float srcwidth, float srcheight, Unit srcUnit) {
    Rect r((INT)destRect.X, (INT)destRect.Y, (INT)destRect.Width, (INT)destRect.Height);
    return DrawImage(image, r, (INT)srcx, (INT)srcy, (INT)srcwidth, (INT)srcheight, srcUnit);
}

Status Graphics::DrawImage(Image* image, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, Unit srcUnit) {
    Rect r(x, y, srcwidth, srcheight);
    return DrawImage(image, r, srcx, srcy, srcwidth, srcheight, srcUnit);
}

} // namespace Gdiplus
