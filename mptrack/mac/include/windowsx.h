#pragma once

#include "windows.h"

#define GET_X_LPARAM(lp) ((int)(short)LOWORD(lp))
#define GET_Y_LPARAM(lp) ((int)(short)HIWORD(lp))

#define GET_WM_COMMAND_ID(wp, lp)       LOWORD(wp)
#define GET_WM_COMMAND_HWND(wp, lp)     (HWND)(lp)
#define GET_WM_COMMAND_CMD(wp, lp)      HIWORD(wp)

#define SelectBitmap(hdc, hbm)  ((HBITMAP)SelectObject((hdc), (HGDIOBJ)(HBITMAP)(hbm)))
#define SelectPen(hdc, hpen)    ((HPEN)SelectObject((hdc), (HGDIOBJ)(HPEN)(hpen)))
#define SelectBrush(hdc, hbr)   ((HBRUSH)SelectObject((hdc), (HGDIOBJ)(HBRUSH)(hbr)))
#define SelectFont(hdc, hfont)  ((HFONT)SelectObject((hdc), (HGDIOBJ)(HFONT)(hfont)))

#define DeleteBitmap(hbm)       DeleteObject((HGDIOBJ)(HBITMAP)(hbm))
#define DeletePen(hpen)         DeleteObject((HGDIOBJ)(HPEN)(hpen))
#define DeleteBrush(hbr)        DeleteObject((HGDIOBJ)(HBRUSH)(hbr))
#define DeleteFont(hfont)       DeleteObject((HGDIOBJ)(HFONT)(hfont))
#define DeleteRgn(hrgn)         DeleteObject((HGDIOBJ)(HRGN)(hrgn))

#define GetStockBrush(i)        ((HBRUSH)GetStockObject(i))
#define GetStockPen(i)          ((HPEN)GetStockObject(i))
#define GetStockFont(i)         ((HFONT)GetStockObject(i))

#define Edit_GetTextLength(hwndCtl)                 ((int)(DWORD)SendMessage((hwndCtl), WM_GETTEXTLENGTH, 0L, 0L))
#define ComboBox_GetCurSel(hwndCtl)                 ((int)(DWORD)SendMessage((hwndCtl), CB_GETCURSEL, 0L, 0L))
#define ComboBox_SetCurSel(hwndCtl, index)          ((int)(DWORD)SendMessage((hwndCtl), CB_SETCURSEL, (WPARAM)(int)(index), 0L))
#define ComboBox_GetItemData(hwndCtl, index)        ((LRESULT)(ULONG_PTR)SendMessage((hwndCtl), CB_GETITEMDATA, (WPARAM)(int)(index), 0L))
#define ComboBox_SetItemData(hwndCtl, index, data)  ((int)(DWORD)SendMessage((hwndCtl), CB_SETITEMDATA, (WPARAM)(int)(index), (LPARAM)(data)))
#define ComboBox_AddString(hwndCtl, lpsz)           ((int)(DWORD)SendMessage((hwndCtl), CB_ADDSTRING, 0L, (LPARAM)(LPCTSTR)(lpsz)))
#define ComboBox_ResetContent(hwndCtl)              ((int)(DWORD)SendMessage((hwndCtl), CB_RESETCONTENT, 0L, 0L))
#define Button_GetCheck(hwndCtl)                    ((int)(DWORD)SendMessage((hwndCtl), BM_GETCHECK, 0L, 0L))
#define Button_SetCheck(hwndCtl, check)             ((void)SendMessage((hwndCtl), BM_SETCHECK, (WPARAM)(int)(check), 0L))
