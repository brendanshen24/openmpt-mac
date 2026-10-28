#pragma once

#include "windows.h"

#define ETDT_DISABLE        0x00000001
#define ETDT_ENABLE         0x00000002
#define ETDT_USETABTEXTURE  0x00000004
#define ETDT_ENABLETAB      (ETDT_ENABLE | ETDT_USETABTEXTURE)
#define ETDT_ENABLEAEROWIZARDTAB 0x00000008
#define ETDT_VALIDBITS      (ETDT_DISABLE | ETDT_ENABLE | ETDT_USETABTEXTURE | ETDT_ENABLEAEROWIZARDTAB)

extern "C" {
inline BOOL WINAPI IsThemeActive() { return FALSE; }
inline BOOL WINAPI IsAppThemed() { return FALSE; }
inline HTHEME WINAPI OpenThemeData(HWND, LPCWSTR) { return nullptr; }
inline HRESULT WINAPI CloseThemeData(HTHEME) { return S_OK; }
inline HRESULT WINAPI SetWindowTheme(HWND, LPCWSTR, LPCWSTR) { return S_OK; }
inline HRESULT WINAPI DrawThemeParentBackground(HWND, HDC, const RECT*) { return S_OK; }
inline HRESULT WINAPI DrawThemeBackground(HTHEME, HDC, int, int, const RECT*, const RECT*) { return S_OK; }
inline HRESULT WINAPI GetThemeColor(HTHEME, int, int, int, COLORREF*) { return E_FAIL; }
inline HRESULT WINAPI GetThemePartSize(HTHEME, HDC, int, int, LPCRECT, int, SIZE*) { return E_FAIL; }
inline HRESULT WINAPI EnableThemeDialogTexture(HWND, DWORD) { return S_OK; }
}
