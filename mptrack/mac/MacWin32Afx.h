#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreMIDI/MIDIServices.h>

#include "windows.h"
#include "mmsystem.h"
#include "afxwin.h"
#include "afxext.h"
#include "afxcmn.h"
#include "afxcview.h"
#include "afxdlgs.h"
#include "afxlistctrl.h"
#include "afxpriv.h"
#include "afxtaskdialog.h"
#include "MacGDI.h"
#include "MacResources.h"

// windows.h maps the COM keyword `interface` to `struct`, which breaks `@interface`.
#undef interface

@class MPTNSView;
@class MPTNSWindow;

struct WindowRecord {
    HWND hWnd = nullptr;
    CWnd* pWnd = nullptr;
    MPTNSView* nsView = nil;
    MPTNSWindow* nsWindow = nil;
    HWND parent = nullptr;
    std::vector<HWND> children;
    std::string className;
    std::string windowText;
    RECT rect{};
    DWORD style = 0;
    DWORD exStyle = 0;
    UINT_PTR id = 0;
    WNDPROC wndProc = nullptr;
    bool isDialog = false;
    bool isVisible = false;
    bool isEnabled = true;
    HFONT font = nullptr;
    HMENU menu = nullptr;
    HDC paintDC = nullptr;  // valid only while WM_PAINT is being dispatched from drawRect
    RECT paintRect{};
    LONG_PTR userData = 0;

    // Controls data
    std::vector<std::string> items;
    std::vector<DWORD_PTR> itemData;
    int curSel = -1;
    int checkState = 0;
    int scrollMin = 0, scrollMax = 100, scrollPos = 0, scrollPage = 10;
};

WindowRecord* GetWindowRecord(HWND hWnd);
std::vector<HWND> GetAllWindowHandles();
CWnd* GetMainWindowObject();
HWND MacGetActiveWindow();
void MacSetActiveWindow(HWND hWnd);
MPTNSView* GetNSViewFromHWND(HWND hWnd);
HWND CreateNativeHWND(CWnd* pWnd, DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName,
                      DWORD dwStyle, int x, int y, int nWidth, int nHeight,
                      HWND hWndParent, HMENU hMenu, LPVOID lpParam);
HWND CreateNativeHWND(CWnd* pWnd, DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName,
                      DWORD dwStyle, int x, int y, int nWidth, int nHeight,
                      HWND hWndParent, HMENU hMenu, LPVOID lpParam, WNDPROC wndProc = nullptr);
// Looks up a class registered with RegisterClass, by name or by the ATOM it returned.
const WNDCLASSW* MacFindWindowClass(LPCWSTR lpClassName);

// Mac key code -> Win32 virtual key / PC scan code / extended flag (MacWin32Api.mm).
bool MacKeyInfo(unsigned short macKeyCode, UINT* vk, UINT* scan, bool* extended);
bool MacHandleKeyEvent(NSEvent* event);

void PostAppMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT DispatchNativeMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
