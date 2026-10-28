#pragma once

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import <ImageIO/ImageIO.h>

#include "windows.h"
#include "gdiplus.h"
#include <vector>

// Common base of every GDI object handle (bitmap, font, brush, pen, region) so that
// SelectObject / DeleteObject / GetObject can find out what a HGDIOBJ really is.
struct MacGdiObject {
    bool isStock = false;  // stock objects survive DeleteObject, as on Windows
    virtual ~MacGdiObject() = default;
};

struct MacGraphicsState {
    POINT viewportOrg{0, 0};
    POINT windowOrg{0, 0};
    COLORREF textColor = RGB(0, 0, 0);
    COLORREF bkColor = RGB(255, 255, 255);
    int bkMode = OPAQUE;
    int rop2 = R2_COPYPEN;
    HBITMAP bitmap = nullptr;
    HPEN pen = nullptr;
    HBRUSH brush = nullptr;
    HFONT font = nullptr;
};

struct HDC__ {
    CGContextRef cgContext = nullptr;
    bool isWindowDC = false;
    bool ownsContext = false;
    HWND hWnd = nullptr;

    HBITMAP currentBitmap = nullptr;
    HPEN currentPen = nullptr;
    HBRUSH currentBrush = nullptr;
    HFONT currentFont = nullptr;
    HRGN currentRgn = nullptr;

    COLORREF textColor = RGB(0, 0, 0);
    COLORREF bkColor = RGB(255, 255, 255);
    COLORREF dcBrushColor = RGB(255, 255, 255);
    COLORREF dcPenColor = RGB(0, 0, 0);
    int bkMode = OPAQUE;
    int rop2 = R2_COPYPEN;
    UINT textAlign = TA_LEFT | TA_TOP;

    POINT viewportOrg{0, 0};
    POINT windowOrg{0, 0};

    std::vector<MacGraphicsState> stateStack;
};
typedef struct HDC__ MacHDC;

struct HBITMAP__ : MacGdiObject {
    ~HBITMAP__() override { if (bitmapContext) CGContextRelease(bitmapContext); }
    int width = 0;
    int height = 0;
    int bpp = 32;
    std::vector<uint8_t> pixelData;
    CGContextRef bitmapContext = nullptr;
    RGBQUAD palette[256]{};
    bool isDIBSection = false;
    bool bottomUp = false;  // bottom-up DIB: memory row 0 is the bottom image row
};
typedef struct HBITMAP__ MacBitmap;
void MacFlipBitmapContext(MacBitmap* bmp);

struct HFONT__ : MacGdiObject {
    ~HFONT__() override { if (ctFont) CFRelease(ctFont); }
    CTFontRef ctFont = nullptr;
    LOGFONTA logFont{};
    int height = 12;
    int ascent = 10;
    int descent = 2;
    int aveCharWidth = 7;
};
typedef struct HFONT__ MacFont;

struct HBRUSH__ : MacGdiObject {
    int style = BS_SOLID;
    COLORREF color = RGB(255, 255, 255);
    HBITMAP pattern = nullptr;
};
typedef struct HBRUSH__ MacBrush;

struct HPEN__ : MacGdiObject {
    int style = PS_SOLID;
    int width = 1;
    COLORREF color = RGB(0, 0, 0);
};
typedef struct HPEN__ MacPen;

struct HRGN__ : MacGdiObject {
    ~HRGN__() override { if (path) CGPathRelease(path); }
    CGMutablePathRef path = nullptr;
};
typedef struct HRGN__ MacRgn;

// Icons and cursors: whichever AppKit object the handle came from.
struct HICON__ {
    NSCursor* cursor = nil;
    NSImage* image = nil;
};
