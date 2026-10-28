#pragma once
// Drawing helpers shared by the built-in control implementations (MacControls.mm, MacListTree.mm).

#import "MacWin32Afx.h"
#import "MacGDI.h"

void FillSolid(HDC dc, const RECT &r, COLORREF color);
void Outline(HDC dc, const RECT &r, COLORREF color);  // 1px, inside r
HFONT ControlFont(HWND hWnd);
void DrawImageRect(HDC dc, CGImageRef image, int x, int y, int w, int h, CGFloat alpha = 1);
