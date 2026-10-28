#import "MacWin32Afx.h"
#import "MacResources.h"
#import "MacGDI.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <Carbon/Carbon.h>
#include "MacFileFilter.h"
#include <dlfcn.h>
#include <queue>
#include <deque>
#include <mach/mach_time.h>
#include <chrono>
#include <map>

static uintptr_t s_nextHwnd = 0x10000;
static std::unordered_map<HWND, WindowRecord> s_windows;
static std::queue<MSG> s_messageQueue;
static CWnd* s_pMainWnd = nullptr;
static CWinApp* s_pApp = nullptr;
static HWND s_captureHwnd = nullptr;
static HWND s_focusHwnd = nullptr;

@interface MPTNSView : NSView <NSTextFieldDelegate> {
@public
    HWND _hWnd;
    NSTrackingArea* _trackingArea;
}
@end

@interface MPTAXItem : NSAccessibilityElement
@property (copy) void (^press)(void);
@end

@implementation MPTAXItem
- (BOOL)accessibilityPerformPress {
    if (self.press) self.press();
    return self.press != nil;
}
@end

@interface MPTNSWindow : NSWindow <NSWindowDelegate> {
@public
    HWND _hWnd;
}
@end

// ---------------------------------------------------------------------------------------------
// Keyboard: Mac key events become WM_KEYDOWN/WM_KEYUP/WM_CHAR, routed like MFC's message pump
// (PreTranslateMessage from the focus window up to the main frame first, where OpenMPT's input handler lives).
// ---------------------------------------------------------------------------------------------

static HWND TopLevelOf(HWND hWnd) {
    while (WindowRecord* rec = GetWindowRecord(hWnd)) {
        if (!(rec->style & WS_CHILD) || !rec->parent) return hWnd;
        hWnd = rec->parent;
    }
    return nullptr;
}

// Returns true when the event was handled (or swallowed) and must not reach AppKit.
bool MacHandleKeyEvent(NSEvent* event) {
    if (![event.window isKindOfClass:[MPTNSWindow class]]) return false;
    UINT vk = 0, scan = 0;
    bool extended = false;
    if (!MacKeyInfo(event.keyCode, &vk, &scan, &extended)) return false;
    const NSEventModifierFlags mods = event.modifierFlags;
    bool down;
    if (event.type == NSEventTypeFlagsChanged) {
        const NSEventModifierFlags flag = vk == VK_SHIFT ? NSEventModifierFlagShift
            : vk == VK_MENU ? NSEventModifierFlagOption
            : vk == VK_CAPITAL ? NSEventModifierFlagCapsLock
            : (event.keyCode == kVK_Command || event.keyCode == kVK_RightCommand) ? NSEventModifierFlagCommand : NSEventModifierFlagControl;
        down = (mods & flag) != 0;
    } else {
        down = event.type == NSEventTypeKeyDown;
    }
    const bool alt = (mods & NSEventModifierFlagOption) || vk == VK_MENU;
    const bool repeat = event.type != NSEventTypeFlagsChanged && event.isARepeat;
    MSG msg{};
    msg.hwnd = GetWindowRecord(GetFocus()) ? GetFocus() : (AfxGetMainWnd() ? AfxGetMainWnd()->m_hWnd : nullptr);
    if (!msg.hwnd) return false;
    msg.message = down ? (alt ? WM_SYSKEYDOWN : WM_KEYDOWN) : (alt ? WM_SYSKEYUP : WM_KEYUP);
    msg.wParam = vk;
    msg.lParam = 1 | (scan << 16) | (extended ? (1 << 24) : 0) | ((repeat || !down) ? (1u << 30) : 0) | (down ? 0 : (1u << 31));
    if (AfxGetApp() && AfxGetApp()->PreTranslateMessage(&msg)) return true;
    const bool command = (mods & NSEventModifierFlagCommand) != 0;
    if (command && event.type == NSEventTypeKeyDown) return false;  // unhandled Cmd+key: let the menu bar have it
    // IsDialogMessage subset for top-level dialogs: Esc cancels, Return presses OK (unless an edit wants it).
    if (down && (vk == VK_ESCAPE || vk == VK_RETURN)) {
        HWND top = TopLevelOf(msg.hwnd);
        WindowRecord* topRec = GetWindowRecord(top);
        WindowRecord* focusRec = GetWindowRecord(msg.hwnd);
        const bool editWantsReturn = focusRec && focusRec->className == "EDIT" && (focusRec->style & ES_WANTRETURN);
        if (topRec && topRec->isDialog && !(vk == VK_RETURN && editWantsReturn)) {
            SendMessageW(top, WM_COMMAND, MAKEWPARAM(vk == VK_ESCAPE ? IDCANCEL : IDOK, BN_CLICKED), 0);
            return true;
        }
    }
    DispatchNativeMessage(msg.hwnd, msg.message, msg.wParam, msg.lParam);
    if (down && event.type == NSEventTypeKeyDown && !command && !(mods & NSEventModifierFlagControl)) {
        // TranslateMessage: characters for the key. Mac delete is Backspace, Return is CR; function keys have none.
        NSString* chars = event.characters;
        for (NSUInteger i = 0; i < chars.length; i++) {
            unichar c = [chars characterAtIndex:i];
            if (c == 0x7F) c = 0x08;
            if (c == 0x03) c = 0x0D;
            if (c >= 0xF700 && c <= 0xF8FF) continue;
            if (GetWindowRecord(msg.hwnd)) DispatchNativeMessage(msg.hwnd, alt ? WM_SYSCHAR : WM_CHAR, c, msg.lParam);
        }
    }
    return true;
}

@implementation MPTNSView

- (bool)isFlipped {
    return YES;
}

- (bool)acceptsFirstResponder {
    return YES;
}

// Group boxes are created after the controls they frame, so they sit on top; like Windows, let clicks through.
- (NSView *)hitTest:(NSPoint)point {
    WindowRecord* rec = GetWindowRecord(_hWnd);
    if (rec && strcasecmp(rec->className.c_str(), "BUTTON") == 0 && (rec->style & BS_TYPEMASK) == BS_GROUPBOX) return nil;
    return [super hitTest:point];
}

static NSString* ToNSString(LPCTSTR lpsz);

// Accessibility: the controls are drawn by hand, so each view reports a role from its Win32 class.
static NSString* AXRole(HWND hWnd) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec) return nil;
    const char* c = rec->className.c_str();
    if (!strcasecmp(c, "BUTTON")) {
        switch (rec->style & BS_TYPEMASK) {
        case BS_GROUPBOX: return NSAccessibilityGroupRole;
        case BS_CHECKBOX: case BS_AUTOCHECKBOX: case BS_3STATE: case BS_AUTO3STATE: return NSAccessibilityCheckBoxRole;
        case BS_RADIOBUTTON: case BS_AUTORADIOBUTTON: return NSAccessibilityRadioButtonRole;
        default: return NSAccessibilityButtonRole;
        }
    }
    if (!strcasecmp(c, "EDIT")) return NSAccessibilityTextFieldRole;
    if (!strcasecmp(c, "STATIC")) return NSAccessibilityStaticTextRole;
    if (!strcasecmp(c, "LISTBOX")) return NSAccessibilityListRole;
    if (!strcasecmp(c, "COMBOBOX")) return NSAccessibilityPopUpButtonRole;
    if (!strcasecmp(c, "msctls_trackbar32")) return NSAccessibilitySliderRole;
    if (!strcasecmp(c, "SysTabControl32")) return NSAccessibilityTabGroupRole;
    return nil;
}

static NSString* AXWindowText(HWND hWnd) {
    std::wstring text((size_t)std::max(0, ::GetWindowTextLengthW(hWnd)), L'\0');
    if (!text.empty()) ::GetWindowTextW(hWnd, text.data(), (int)text.size() + 1);
    std::erase(text, L'&');  // mnemonic markers
    return ToNSString(text.c_str());
}

// A click at the middle of a rectangle, through the control's own mouse handling.
static void AXClick(HWND hWnd, const RECT& rc) {
    const LPARAM pt = MAKELPARAM((rc.left + rc.right) / 2, (rc.top + rc.bottom) / 2);
    ::SendMessageW(hWnd, WM_LBUTTONDOWN, MK_LBUTTON, pt);
    ::SendMessageW(hWnd, WM_LBUTTONUP, 0, pt);
}

- (BOOL)isAccessibilityElement {
    return AXRole(_hWnd) != nil;
}

- (NSString *)accessibilityRole {
    return AXRole(_hWnd) ?: [super accessibilityRole];
}

- (NSString *)accessibilityLabel {
    NSString* role = AXRole(_hWnd);
    if (!role || role == NSAccessibilityTextFieldRole || role == NSAccessibilityListRole) return [super accessibilityLabel];
    return AXWindowText(_hWnd);
}

- (id)accessibilityValue {
    NSString* role = AXRole(_hWnd);
    if (role == NSAccessibilityCheckBoxRole || role == NSAccessibilityRadioButtonRole) return @(::SendMessageW(_hWnd, BM_GETCHECK, 0, 0));
    if (role == NSAccessibilityTextFieldRole || role == NSAccessibilityStaticTextRole) return AXWindowText(_hWnd);
    if (role == NSAccessibilitySliderRole) return @(::SendMessageW(_hWnd, TBM_GETPOS, 0, 0));
    if (role == NSAccessibilityPopUpButtonRole) {
        const int sel = (int)::SendMessageW(_hWnd, CB_GETCURSEL, 0, 0);
        if (sel < 0) return @"";
        std::wstring text((size_t)std::max<LRESULT>(0, ::SendMessageW(_hWnd, CB_GETLBTEXTLEN, sel, 0)), L'\0');
        if (!text.empty()) ::SendMessageW(_hWnd, CB_GETLBTEXT, sel, (LPARAM)text.data());
        return ToNSString(text.c_str());
    }
    return [super accessibilityValue];
}

static std::wstring AXWide(id value) {
    NSData* data = [[value description] dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
    return std::wstring((const wchar_t*)data.bytes, data.length / sizeof(wchar_t));
}

// Typing through accessibility (VoiceOver, automation) edits the field as the keyboard would.
- (void)setAccessibilityValue:(id)value {
    if (AXRole(_hWnd) != NSAccessibilityTextFieldRole) return [super setAccessibilityValue:value];
    ::SetWindowTextW(_hWnd, AXWide(value).c_str());
}

- (void)setAccessibilitySelectedText:(NSString *)text {
    if (AXRole(_hWnd) != NSAccessibilityTextFieldRole) return [super setAccessibilitySelectedText:text];
    ::SendMessageW(_hWnd, EM_REPLACESEL, TRUE, (LPARAM)AXWide(text).c_str());
}

- (BOOL)isAccessibilityEnabled {
    WindowRecord* rec = GetWindowRecord(_hWnd);
    return !rec || rec->isEnabled;
}

- (BOOL)accessibilityPerformPress {
    NSString* role = AXRole(_hWnd);
    if (!role || ![self isAccessibilityEnabled]) return NO;
    if ([role isEqualToString:NSAccessibilityButtonRole] || role == NSAccessibilityCheckBoxRole || role == NSAccessibilityRadioButtonRole) {
        ::SendMessageW(_hWnd, BM_CLICK, 0, 0);
    } else {
        RECT rc;
        ::GetClientRect(_hWnd, &rc);
        AXClick(_hWnd, rc);
    }
    return YES;
}

// List rows and tabs are not windows, so they are reported as child elements that press by clicking.
- (NSArray *)accessibilityChildren {
    NSString* role = AXRole(_hWnd);
    const bool list = role == NSAccessibilityListRole, tabs = role == NSAccessibilityTabGroupRole;
    if (!list && !tabs) return [super accessibilityChildren];
    NSMutableArray* items = [NSMutableArray array];
    const int count = (int)::SendMessageW(_hWnd, list ? LB_GETCOUNT : TCM_GETITEMCOUNT, 0, 0);
    const int sel = (int)::SendMessageW(_hWnd, list ? LB_GETCURSEL : TCM_GETCURSEL, 0, 0);
    auto* checks = list ? dynamic_cast<CCheckListBox*>(CWnd::FromHandlePermanent(_hWnd)) : nullptr;
    RECT client;
    ::GetClientRect(_hWnd, &client);
    for (int i = 0; i < count; i++) {
        RECT rc{};
        std::wstring text;
        if (list) {
            ::SendMessageW(_hWnd, LB_GETITEMRECT, i, (LPARAM)&rc);
            text.assign((size_t)std::max<LRESULT>(0, ::SendMessageW(_hWnd, LB_GETTEXTLEN, i, 0)), L'\0');
            if (!text.empty()) ::SendMessageW(_hWnd, LB_GETTEXT, i, (LPARAM)text.data());
        } else {
            ::SendMessageW(_hWnd, TCM_GETITEMRECT, i, (LPARAM)&rc);
            wchar_t buf[256] = {};
            TCITEMW item{};
            item.mask = TCIF_TEXT;
            item.pszText = buf;
            item.cchTextMax = 255;
            ::SendMessageW(_hWnd, TCM_GETITEMW, i, (LPARAM)&item);
            text = buf;
        }
        RECT visible;
        if (!::IntersectRect(&visible, &rc, &client)) continue;  // scrolled out of view
        MPTAXItem* element = [[MPTAXItem alloc] init];
        element.accessibilityParent = self;
        element.accessibilityRole = checks ? NSAccessibilityCheckBoxRole : list ? NSAccessibilityStaticTextRole : NSAccessibilityRadioButtonRole;
        if (checks) element.accessibilityValue = @(checks->GetCheck(i));
        element.accessibilityLabel = ToNSString(text.c_str());
        element.accessibilitySelected = i == sel;
        // The parent space is bottom-up even though the view is flipped.
        element.accessibilityFrameInParentSpace = NSMakeRect(visible.left, self.bounds.size.height - visible.bottom, visible.right - visible.left, visible.bottom - visible.top);
        HWND hWnd = _hWnd;
        RECT target = visible;
        // Check list rows press their check box, which toggles it; other rows press their text, which selects.
        if (checks) target.right = std::min<LONG>(target.right, target.left + 14);
        else if (list) target.left = std::min<LONG>(target.right, target.left + 20);
        element.press = ^{ AXClick(hWnd, target); };
        [items addObject:element];
    }
    return items;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_trackingArea) [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways)
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)drawRect:(NSRect)dirtyRect {
    WindowRecord* rec = GetWindowRecord(_hWnd);
    if (!rec) return;

    CGContextRef cgCtx = [[NSGraphicsContext currentContext] CGContext];
    // AppKit can hand a layer-backed view a dirty rect beyond its bounds; Win32 paint/clip boxes never exceed the client area.
    dirtyRect = NSIntersectionRect(dirtyRect, self.bounds);
    CGContextClipToRect(cgCtx, dirtyRect);
    MacHDC dc;
    dc.cgContext = cgCtx;
    dc.ownsContext = false;
    dc.isWindowDC = true;
    dc.hWnd = _hWnd;

    if (rec->pWnd || rec->wndProc) {
        PAINTSTRUCT ps{};
        ps.hdc = (HDC)&dc;
        ps.rcPaint = RECT{(int)dirtyRect.origin.x, (int)dirtyRect.origin.y,
                          (int)(dirtyRect.origin.x + dirtyRect.size.width),
                          (int)(dirtyRect.origin.y + dirtyRect.size.height)};
        rec->paintDC = &dc;
        rec->paintRect = ps.rcPaint;
        DispatchNativeMessage(_hWnd, WM_PAINT, (WPARAM)&dc, 0);
        if ((rec = GetWindowRecord(_hWnd))) rec->paintDC = nullptr;
    } else {
        // Default control background
        CGContextSetRGBFillColor(cgCtx, 0.95f, 0.95f, 0.95f, 1.0f);
        CGContextFillRect(cgCtx, dirtyRect);
    }
}

// Win32 mouse messages carry the held buttons and Shift/Ctrl in wParam (Cmd maps to Ctrl, as in the rest of the port).
static WPARAM MouseKeyFlags(NSEvent* event) {
    const NSEventModifierFlags mods = event.modifierFlags;
    const NSUInteger buttons = [NSEvent pressedMouseButtons];
    WPARAM flags = 0;
    if (buttons & 1) flags |= MK_LBUTTON;
    if (buttons & 2) flags |= MK_RBUTTON;
    if (buttons & 4) flags |= MK_MBUTTON;
    if (mods & NSEventModifierFlagShift) flags |= MK_SHIFT;
    if (mods & (NSEventModifierFlagControl | NSEventModifierFlagCommand)) flags |= MK_CONTROL;
    return flags;
}

- (LPARAM)clientPoint:(NSEvent *)event {
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    return MAKELPARAM((int)p.x, (int)p.y);
}

- (void)mouseDown:(NSEvent *)event {
    ::SetFocus(_hWnd);  // with WM_KILLFOCUS/WM_SETFOCUS, so controls and views track focus
    // Only MFC windows get WM_LBUTTONDBLCLK (their classes have CS_DBLCLKS); the built-in controls expect a second button-down.
    WindowRecord* rec = GetWindowRecord(_hWnd);
    const bool dblClk = event.clickCount == 2 && rec && rec->pWnd && !rec->wndProc;
    DispatchNativeMessage(_hWnd, dblClk ? WM_LBUTTONDBLCLK : WM_LBUTTONDOWN, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)mouseUp:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_LBUTTONUP, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)rightMouseDown:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_RBUTTONDOWN, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)rightMouseUp:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_RBUTTONUP, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)otherMouseDown:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_MBUTTONDOWN, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)otherMouseUp:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_MBUTTONUP, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)mouseMoved:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_MOUSEMOVE, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)mouseDragged:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_MOUSEMOVE, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)rightMouseDragged:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_MOUSEMOVE, MouseKeyFlags(event), [self clientPoint:event]);
}

- (void)scrollWheel:(NSEvent *)event {
    // Trackpads report pixels; treat ~10 px as one wheel line so a swipe isn't dozens of notches. OpenMPT accumulates partial steps.
    const CGFloat scale = event.hasPreciseScrollingDeltas ? WHEEL_DELTA / 10.0 : WHEEL_DELTA;
    const short zDelta = (short)std::clamp(event.scrollingDeltaY * scale, -32768.0, 32767.0);
    if (zDelta == 0) return;
    // WM_MOUSEWHEEL carries screen coordinates.
    POINT pt = {LOWORD([self clientPoint:event]), HIWORD([self clientPoint:event])};
    ClientToScreen(_hWnd, &pt);
    DispatchNativeMessage(_hWnd, WM_MOUSEWHEEL, MAKEWPARAM(MouseKeyFlags(event), (WORD)zDelta), MAKELPARAM(pt.x, pt.y));
}

- (void)mouseExited:(NSEvent *)event {
    DispatchNativeMessage(_hWnd, WM_MOUSELEAVE, 0, 0);
}

// Normally CWinApp::Run handles keys before AppKit; these catch them inside AppKit modal loops.
- (void)keyDown:(NSEvent *)event {
    if (!MacHandleKeyEvent(event)) [super keyDown:event];
}

- (void)keyUp:(NSEvent *)event {
    if (!MacHandleKeyEvent(event)) [super keyUp:event];
}

- (void)flagsChanged:(NSEvent *)event {
    if (!MacHandleKeyEvent(event)) [super flagsChanged:event];
}

@end

@implementation MPTNSWindow

- (bool)canBecomeKeyWindow {
    return YES;
}

- (bool)canBecomeMainWindow {
    return YES;
}

- (void)windowDidResize:(NSNotification *)notification {
    WindowRecord* rec = GetWindowRecord(_hWnd);
    if (rec && rec->nsView) {
        NSRect frame = [self.contentView bounds];
        const NSRect content = [self contentRectForFrameRect:self.frame];
        const int top = (int)([NSScreen screens].firstObject.frame.size.height - content.origin.y - content.size.height);
        rec->rect = RECT{(int)content.origin.x, top, (int)(content.origin.x + frame.size.width), top + (int)frame.size.height};
        rec->nsView.frame = frame;
        DispatchNativeMessage(_hWnd, WM_SIZE, SIZE_RESTORED, MAKELPARAM((int)frame.size.width, (int)frame.size.height));
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    MacSetActiveWindow(_hWnd);
}

- (bool)windowShouldClose:(NSWindow *)sender {
    DispatchNativeMessage(_hWnd, WM_CLOSE, 0, 0);
    return NO; // Let OpenMPT handle closing in OnClose()
}

@end

// Win32's active window is per-thread state: it stays set while another application is in front.
static HWND s_activeHwnd = nullptr;

HWND MacGetActiveWindow() {
    return GetWindowRecord(s_activeHwnd) ? s_activeHwnd : nullptr;
}

void MacSetActiveWindow(HWND hWnd) {
    HWND old = MacGetActiveWindow();
    if (old == hWnd) return;
    s_activeHwnd = hWnd;
    if (old) {
        DispatchNativeMessage(old, WM_NCACTIVATE, FALSE, 0);
        DispatchNativeMessage(old, WM_ACTIVATE, MAKEWPARAM(WA_INACTIVE, 0), (LPARAM)hWnd);
    }
    if (hWnd) {
        DispatchNativeMessage(hWnd, WM_NCACTIVATE, TRUE, 0);
        DispatchNativeMessage(hWnd, WM_ACTIVATE, MAKEWPARAM(WA_ACTIVE, 0), (LPARAM)old);
    }
}

WindowRecord* GetWindowRecord(HWND hWnd) {
    if (!hWnd) return nullptr;
    auto it = s_windows.find(hWnd);
    return (it != s_windows.end()) ? &it->second : nullptr;
}

std::vector<HWND> GetAllWindowHandles() {
    std::vector<HWND> result;
    result.reserve(s_windows.size());
    for (const auto& [hWnd, rec] : s_windows) result.push_back(hWnd);
    return result;
}

CWnd* GetMainWindowObject() { return s_pMainWnd; }

MPTNSView* GetNSViewFromHWND(HWND hWnd) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    return rec ? rec->nsView : nil;
}

static NSString* ToNSString(LPCTSTR lpsz) {
    if (!lpsz) return @"";
#ifdef UNICODE
    return [[NSString alloc] initWithBytes:lpsz length:wcslen(lpsz) * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
#else
    return [NSString stringWithUTF8String:lpsz];
#endif
}

static std::string ToStdString(LPCTSTR lpsz) {
    if (!lpsz) return "";
    char buf[1024] = {};
    WideCharToMultiByte(CP_UTF8, 0, lpsz, -1, buf, sizeof(buf), nullptr, nullptr);
    return buf;
}

HWND CreateNativeHWND(CWnd* pWnd, DWORD dwExStyle, LPCTSTR lpClassName, LPCTSTR lpWindowName,
                      DWORD dwStyle, int x, int y, int nWidth, int nHeight,
                      HWND hWndParent, HMENU hMenu, LPVOID lpParam, WNDPROC wndProc) {
    const WNDCLASSW* wndClass = MacFindWindowClass(lpClassName);
    if (wndClass) {
        lpClassName = wndClass->lpszClassName;
        if (!wndProc) wndProc = wndClass->lpfnWndProc;
    } else if (IS_INTRESOURCE(lpClassName)) {
        lpClassName = nullptr;
    }
    HWND hWnd = (HWND)s_nextHwnd++;
    WindowRecord& rec = s_windows[hWnd];
    rec.hWnd = hWnd;
    rec.pWnd = pWnd;
    char clsBuf[256] = {};
    char winBuf[256] = {};
    if (lpClassName) WideCharToMultiByte(CP_UTF8, 0, lpClassName, -1, clsBuf, sizeof(clsBuf), nullptr, nullptr);
    if (lpWindowName) WideCharToMultiByte(CP_UTF8, 0, lpWindowName, -1, winBuf, sizeof(winBuf), nullptr, nullptr);
    rec.className = clsBuf;
    rec.windowText = winBuf;
    rec.style = dwStyle;
    rec.exStyle = dwExStyle;
    rec.id = (UINT_PTR)hMenu;
    rec.parent = hWndParent;
    rec.wndProc = wndProc;
    rec.isVisible = (dwStyle & WS_VISIBLE) != 0;
    rec.isEnabled = (dwStyle & WS_DISABLED) == 0;

    if (pWnd) pWnd->m_hWnd = hWnd;

    // As on Windows, WS_CHILD decides between a child view and a top-level window (whose parent is its owner).
    const bool topLevel = !(dwStyle & WS_CHILD);
    if (topLevel) {
        const NSRect screen = [NSScreen mainScreen].visibleFrame;
        const CGFloat screenTop = [NSScreen screens].firstObject.frame.size.height;
        if (nWidth == CW_USEDEFAULT || nWidth <= 0) nWidth = (int)(screen.size.width * 0.8);
        if (nHeight == CW_USEDEFAULT || nHeight <= 0) nHeight = (int)(screen.size.height * 0.8);
        if (x == CW_USEDEFAULT) {
            x = (int)(screen.origin.x + (screen.size.width - nWidth) / 2);
            y = (int)(screenTop - (screen.origin.y + screen.size.height) + (screen.size.height - nHeight) / 2);
        }
        NSUInteger styleMask = NSWindowStyleMaskBorderless;
        if ((dwStyle & WS_CAPTION) == WS_CAPTION) styleMask |= NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
        if (dwStyle & WS_MINIMIZEBOX) styleMask |= NSWindowStyleMaskMiniaturizable;
        if (dwStyle & WS_THICKFRAME) styleMask |= NSWindowStyleMaskResizable;
        // Win32 screen coordinates are top-down from the primary screen's top edge.
        NSRect contentRect = NSMakeRect(x, screenTop - y - nHeight, nWidth, nHeight);
        MPTNSWindow* win = [[MPTNSWindow alloc] initWithContentRect:contentRect
                                                          styleMask:styleMask
                                                            backing:NSBackingStoreBuffered
                                                              defer:NO];
        win->_hWnd = hWnd;
        win.delegate = win;
        win.releasedWhenClosed = NO;
        [win setTitle:ToNSString(lpWindowName)];
        rec.nsView = [[MPTNSView alloc] initWithFrame:[win.contentView bounds]];
        rec.nsView->_hWnd = hWnd;
        [win.contentView addSubview:rec.nsView];
        rec.nsView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        rec.nsWindow = win;
        rec.rect = RECT{x, y, x + nWidth, y + nHeight};
        // Owned windows stay above their owner; caption-less popups (menus, drop-downs) don't take focus.
        WindowRecord* ownerRec = GetWindowRecord(hWndParent);
        if (ownerRec && ownerRec->nsWindow) [(NSWindow*)ownerRec->nsWindow addChildWindow:win ordered:NSWindowAbove];
        const bool passivePopup = (dwStyle & WS_POPUP) && (dwStyle & WS_CAPTION) != WS_CAPTION;
        if (rec.isVisible) {
            if (passivePopup) [win orderFront:nil];
            else [win makeKeyAndOrderFront:nil];
        }
        if (rec.isVisible && !passivePopup) s_activeHwnd = hWnd;  // activation messages follow once it exists
    } else {
        rec.rect = RECT{x, y, x + nWidth, y + nHeight};
        rec.nsView = [[MPTNSView alloc] initWithFrame:NSMakeRect(x, y, std::max(1, nWidth), std::max(1, nHeight))];
        rec.nsView->_hWnd = hWnd;
        rec.nsView.hidden = !rec.isVisible;
        WindowRecord* parentRec = GetWindowRecord(hWndParent);
        if (parentRec && parentRec->nsView) {
            // shortcut: newer children stack on top, the reverse of a Win32 dialog's z-order; OpenMPT's views
            // rely on later children covering earlier ones, so only group boxes (see hitTest) are special-cased.
            [parentRec->nsView addSubview:rec.nsView];
            parentRec->children.push_back(hWnd);
        }
    }

    CREATESTRUCT cs{};
    cs.lpCreateParams = lpParam;
    cs.hInstance = (HINSTANCE)0x1000;
    cs.hMenu = hMenu;
    cs.hwndParent = hWndParent;
    cs.cy = nHeight;
    cs.cx = nWidth;
    cs.y = y;
    cs.x = x;
    cs.style = dwStyle;
    cs.lpszName = lpWindowName;
    cs.lpszClass = lpClassName;
    cs.dwExStyle = dwExStyle;

    if (DispatchNativeMessage(hWnd, WM_CREATE, 0, (LPARAM)&cs) == -1) {
        DestroyWindow(hWnd);
        if (pWnd) pWnd->m_hWnd = nullptr;
        return nullptr;
    }
    // Windows follows WM_CREATE with the initial WM_SIZE / WM_MOVE.
    if (WindowRecord* created = GetWindowRecord(hWnd)) {
        RECT client{};
        GetClientRect(hWnd, &client);
        DispatchNativeMessage(hWnd, WM_SIZE, SIZE_RESTORED, MAKELPARAM(client.right, client.bottom));
        DispatchNativeMessage(hWnd, WM_MOVE, 0, MAKELPARAM(created->rect.left, created->rect.top));
    }
    return hWnd;
}

HWND CreateNativeHWND(CWnd* pWnd, DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName,
                      DWORD dwStyle, int x, int y, int nWidth, int nHeight,
                      HWND hWndParent, HMENU hMenu, LPVOID lpParam) {
    CString wCls(lpClassName);
    CString wWin(lpWindowName);
    return CreateNativeHWND(pWnd, dwExStyle, wCls.GetString(), wWin.GetString(), dwStyle, x, y, nWidth, nHeight, hWndParent, hMenu, lpParam);
}

void PostAppMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    MSG msg{};
    msg.hwnd = hWnd;
    msg.message = uMsg;
    msg.wParam = wParam;
    msg.lParam = lParam;
    msg.time = (DWORD)std::chrono::duration_cast<std::chrono::milliseconds>(
                   std::chrono::steady_clock::now().time_since_epoch()).count();
    s_messageQueue.push(msg);
}

LRESULT DispatchNativeMessage(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec) return 0;

    if (rec->pWnd) {
        return rec->pWnd->WindowProc(uMsg, wParam, lParam);
    }
    if (rec->wndProc) {
        return rec->wndProc(hWnd, uMsg, wParam, lParam);
    }
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

// Win32 APIs
HWND WINAPI CreateWindowExA(DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName,
                            DWORD dwStyle, int X, int Y, int nWidth, int nHeight,
                            HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam) {
    return CreateNativeHWND(nullptr, dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, lpParam);
}

HWND WINAPI CreateWindowExW(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName,
                            DWORD dwStyle, int X, int Y, int nWidth, int nHeight,
                            HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam) {
    (void)hInstance;
    return CreateNativeHWND(nullptr, dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, lpParam);
}

BOOL WINAPI DestroyWindow(HWND hWnd) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec) return FALSE;

    // Win32 order: WM_DESTROY to the window, then its children are destroyed, then WM_NCDESTROY.
    DispatchNativeMessage(hWnd, WM_DESTROY, 0, 0);
    const std::vector<HWND> children = rec->children;
    for (HWND child : children) DestroyWindow(child);
    if (!(rec = GetWindowRecord(hWnd))) return TRUE;
    DispatchNativeMessage(hWnd, WM_NCDESTROY, 0, 0);
    if (!(rec = GetWindowRecord(hWnd))) return TRUE;
    if (WindowRecord* parent = GetWindowRecord(rec->parent)) std::erase(parent->children, hWnd);

    if (rec->nsView) {
        [rec->nsView removeFromSuperview];
        rec->nsView = nil;
    }
    if (rec->nsWindow) {
        // The owner keeps child windows alive until they are detached.
        if (NSWindow* owner = [rec->nsWindow parentWindow]) [owner removeChildWindow:rec->nsWindow];
        [rec->nsWindow close];
        rec->nsWindow = nil;
    }
    if (s_activeHwnd == hWnd) s_activeHwnd = GetWindowRecord(rec->parent) ? rec->parent : nullptr;
    CWnd* pWnd = rec->pWnd;
    s_windows.erase(hWnd);
    // MFC's OnNcDestroy: detach, then PostNcDestroy (views and frames delete themselves there).
    if (pWnd && pWnd->m_hWnd == hWnd) {
        pWnd->m_hWnd = nullptr;
        pWnd->PostNcDestroy();
    }
    return TRUE;
}

BOOL WINAPI ShowWindow(HWND hWnd, int nCmdShow) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec) return FALSE;
    BOOL wasVisible = rec->isVisible;
    rec->isVisible = (nCmdShow != SW_HIDE);

    if (rec->nsWindow) {
        if (rec->isVisible) {
            [rec->nsWindow makeKeyAndOrderFront:nil];
            if (nCmdShow != SW_SHOWNA && nCmdShow != SW_SHOWNOACTIVATE && !(rec->style & WS_POPUP && (rec->style & WS_CAPTION) != WS_CAPTION)) MacSetActiveWindow(hWnd);
        } else {
            [rec->nsWindow orderOut:nil];
            if (s_activeHwnd == hWnd) MacSetActiveWindow(rec->parent);
        }
    }
    if (rec->nsView) {
        rec->nsView.hidden = !rec->isVisible;
    }
    DispatchNativeMessage(hWnd, WM_SHOWWINDOW, (WPARAM)rec->isVisible, 0);
    return wasVisible;
}

BOOL WINAPI MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec) return FALSE;
    if (rec->nsWindow) {
        // Top-level: X/Y are screen coordinates; the window delegate reports the resulting WM_SIZE.
        NSWindow* win = (NSWindow*)rec->nsWindow;
        const CGFloat screenTop = [NSScreen screens].firstObject.frame.size.height;
        const NSRect frame = [win frameRectForContentRect:NSMakeRect(X, screenTop - Y - nHeight, nWidth, nHeight)];
        [win setFrame:frame display:bRepaint];
        rec->rect = RECT{X, Y, X + nWidth, Y + nHeight};
        return TRUE;
    }
    const bool sizeChanged = (rec->rect.right - rec->rect.left) != nWidth || (rec->rect.bottom - rec->rect.top) != nHeight;
    const bool moved = rec->rect.left != X || rec->rect.top != Y;
    rec->rect = RECT{X, Y, X + nWidth, Y + nHeight};
    if (rec->nsView) {
        rec->nsView.frame = NSMakeRect((CGFloat)X, (CGFloat)Y, (CGFloat)nWidth, (CGFloat)nHeight);
        if (bRepaint) [rec->nsView setNeedsDisplay:YES];
    }
    if (moved) DispatchNativeMessage(hWnd, WM_MOVE, 0, MAKELPARAM(X, Y));
    if (sizeChanged) DispatchNativeMessage(hWnd, WM_SIZE, SIZE_RESTORED, MAKELPARAM(nWidth, nHeight));
    return TRUE;
}

BOOL WINAPI SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec) return FALSE;

    if (!(uFlags & SWP_NOMOVE) || !(uFlags & SWP_NOSIZE)) {
        int x = (uFlags & SWP_NOMOVE) ? rec->rect.left : X;
        int y = (uFlags & SWP_NOMOVE) ? rec->rect.top : Y;
        int w = (uFlags & SWP_NOSIZE) ? (rec->rect.right - rec->rect.left) : cx;
        int h = (uFlags & SWP_NOSIZE) ? (rec->rect.bottom - rec->rect.top) : cy;
        MoveWindow(hWnd, x, y, w, h, !(uFlags & SWP_NOREDRAW));
    }
    if (!(uFlags & SWP_NOZORDER) && rec->nsView && !rec->nsWindow) {
        NSView* view = (NSView*)rec->nsView;
        NSView* superview = view.superview;
        if (superview && (hWndInsertAfter == HWND_TOP || hWndInsertAfter == HWND_TOPMOST)) {
            [view removeFromSuperviewWithoutNeedingDisplay];
            [superview addSubview:view positioned:NSWindowAbove relativeTo:nil];
        } else if (superview && hWndInsertAfter == HWND_BOTTOM) {
            [view removeFromSuperviewWithoutNeedingDisplay];
            [superview addSubview:view positioned:NSWindowBelow relativeTo:nil];
        }
    }
    if (uFlags & SWP_SHOWWINDOW) ShowWindow(hWnd, SW_SHOW);
    if (uFlags & SWP_HIDEWINDOW) ShowWindow(hWnd, SW_HIDE);
    return TRUE;
}

// Win32 window rectangles are in screen coordinates, also for child windows.
BOOL WINAPI GetWindowRect(HWND hWnd, LPRECT lpRect) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec || !lpRect) return FALSE;
    *lpRect = rec->rect;
    if (!rec->nsWindow) {
        POINT origin{0, 0};
        if (ClientToScreen(hWnd, &origin)) {
            const LONG w = rec->rect.right - rec->rect.left, h = rec->rect.bottom - rec->rect.top;
            *lpRect = RECT{origin.x, origin.y, origin.x + w, origin.y + h};
        }
    }
    return TRUE;
}

BOOL WINAPI GetClientRect(HWND hWnd, LPRECT lpRect) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec || !lpRect) return FALSE;
    lpRect->left = 0;
    lpRect->top = 0;
    lpRect->right = rec->rect.right - rec->rect.left;
    lpRect->bottom = rec->rect.bottom - rec->rect.top;
    return TRUE;
}

BOOL WINAPI InvalidateRect(HWND hWnd, const RECT* lpRect, BOOL bErase) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec || !rec->nsView) return FALSE;
    if (lpRect) {
        NSRect r = NSMakeRect((CGFloat)lpRect->left, (CGFloat)lpRect->top,
                              (CGFloat)(lpRect->right - lpRect->left), (CGFloat)(lpRect->bottom - lpRect->top));
        [rec->nsView setNeedsDisplayInRect:r];
    } else {
        [rec->nsView setNeedsDisplay:YES];
    }
    return TRUE;
}

BOOL WINAPI UpdateWindow(HWND hWnd) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (!rec || !rec->nsView) return FALSE;
    [rec->nsView displayIfNeeded];
    return TRUE;
}

BOOL WINAPI RedrawWindow(HWND hWnd, const RECT* lprcUpdate, HRGN hrgnUpdate, UINT flags) {
    (void)hrgnUpdate; (void)flags;
    InvalidateRect(hWnd, lprcUpdate, TRUE);
    UpdateWindow(hWnd);
    return TRUE;
}

LRESULT WINAPI SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return DispatchNativeMessage(hWnd, Msg, wParam, lParam);
}

LRESULT WINAPI SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return SendMessageA(hWnd, Msg, wParam, lParam);
}

BOOL WINAPI PostMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    if ([NSThread isMainThread]) {
        PostAppMessage(hWnd, Msg, wParam, lParam);
        return TRUE;
    }
    // The queue and window table belong to the main thread; audio, MIDI and worker threads post through it.
    dispatch_async(dispatch_get_main_queue(), ^{
        PostAppMessage(hWnd, Msg, wParam, lParam);
        // Wake CWinApp::Run, which otherwise sleeps until the next event or its 50 ms timeout.
        [NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined location:NSZeroPoint modifierFlags:0
                                           timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0]
                 atStart:NO];
    });
    return TRUE;
}

BOOL WINAPI PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return PostMessageA(hWnd, Msg, wParam, lParam);
}

BOOL WINAPI SendNotifyMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return PostMessageA(hWnd, Msg, wParam, lParam);
}

BOOL WINAPI SendNotifyMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return PostMessageW(hWnd, Msg, wParam, lParam);
}

BOOL WINAPI PeekMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg) {
    (void)hWnd; (void)wMsgFilterMin; (void)wMsgFilterMax;
    if (s_messageQueue.empty()) return FALSE;
    if (lpMsg) *lpMsg = s_messageQueue.front();
    if (wRemoveMsg & PM_REMOVE) s_messageQueue.pop();
    return TRUE;
}

BOOL WINAPI PeekMessageW(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg) {
    return PeekMessageA(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);
}

BOOL WINAPI GetMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax) {
    while (s_messageQueue.empty()) {
        NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                            untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]
                                               inMode:NSDefaultRunLoopMode
                                              dequeue:YES];
        if (event) [NSApp sendEvent:event];
    }
    return PeekMessageA(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax, PM_REMOVE);
}

BOOL WINAPI GetMessageW(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax) {
    return GetMessageA(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax);
}

BOOL WINAPI TranslateMessage(const MSG* lpMsg) {
    (void)lpMsg;
    return TRUE;
}

LRESULT WINAPI DispatchMessageA(const MSG* lpMsg) {
    if (!lpMsg) return 0;
    return DispatchNativeMessage(lpMsg->hwnd, lpMsg->message, lpMsg->wParam, lpMsg->lParam);
}

LRESULT WINAPI DispatchMessageW(const MSG* lpMsg) {
    return DispatchMessageA(lpMsg);
}

HWND WINAPI GetFocus() {
    return s_focusHwnd;
}

HWND WINAPI SetFocus(HWND hWnd) {
    HWND old = s_focusHwnd;
    s_focusHwnd = hWnd;
    if (old != hWnd) {
        DispatchNativeMessage(old, WM_KILLFOCUS, (WPARAM)hWnd, 0);
        DispatchNativeMessage(hWnd, WM_SETFOCUS, (WPARAM)old, 0);
    }
    return old;
}

HWND WINAPI SetCapture(HWND hWnd) {
    HWND old = s_captureHwnd;
    s_captureHwnd = hWnd;
    return old;
}

BOOL WINAPI ReleaseCapture() {
    s_captureHwnd = nullptr;
    return TRUE;
}

HWND WINAPI GetCapture() {
    return s_captureHwnd;
}

// Clipboard implementation via NSPasteboard
BOOL WINAPI OpenClipboard(HWND hWnd) {
    (void)hWnd;
    return TRUE;
}

BOOL WINAPI CloseClipboard() {
    return TRUE;
}

BOOL WINAPI EmptyClipboard() {
    [[NSPasteboard generalPasteboard] clearContents];
    return TRUE;
}

HANDLE WINAPI SetClipboardData(UINT uFormat, HANDLE hMem) {
    if (uFormat == CF_TEXT || uFormat == CF_UNICODETEXT) {
        const char* str = (const char*)hMem;
        NSString* nsStr = [NSString stringWithUTF8String:str];
        if (nsStr) {
            [[NSPasteboard generalPasteboard] clearContents];
            [[NSPasteboard generalPasteboard] setString:nsStr forType:NSPasteboardTypeString];
        }
    }
    return hMem;
}

HANDLE WINAPI GetClipboardData(UINT uFormat) {
    if (uFormat == CF_TEXT || uFormat == CF_UNICODETEXT) {
        NSString* nsStr = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
        if (nsStr) {
            static std::string s_clipBuf;
            s_clipBuf = [nsStr UTF8String];
            return (HANDLE)s_clipBuf.c_str();
        }
    }
    return nullptr;
}

BOOL WINAPI IsClipboardFormatAvailable(UINT format) {
    if (format == CF_TEXT || format == CF_UNICODETEXT) {
        return [[NSPasteboard generalPasteboard] canReadItemWithDataConformingToTypes:@[NSPasteboardTypeString]];
    }
    return FALSE;
}

// CoreMIDI Implementation
static MIDIClientRef s_midiClient = 0;
static MIDIPortRef s_midiInPort = 0;

UINT WINAPI midiInGetNumDevs(void) {
    return (UINT)MIDIGetNumberOfSources();
}

MMRESULT WINAPI midiInGetDevCapsA(UINT_PTR uDeviceID, MIDIINCAPSA* pmic, UINT cbmic) {
    if (!pmic) return MMSYSERR_INVALPARAM;
    MIDIEndpointRef src = MIDIGetSource(uDeviceID);
    if (!src) return MMSYSERR_BADDEVICEID;
    CFStringRef name = nullptr;
    MIDIObjectGetStringProperty(src, kMIDIPropertyName, &name);
    memset(pmic, 0, cbmic);
    if (name) {
        CFStringGetCString(name, pmic->szPname, sizeof(pmic->szPname), kCFStringEncodingUTF8);
        CFRelease(name);
    }
    return MMSYSERR_NOERROR;
}

MMRESULT WINAPI midiInGetDevCapsW(UINT_PTR uDeviceID, MIDIINCAPSW* pmic, UINT cbmic) {
    MIDIINCAPSA capsa{};
    MMRESULT res = midiInGetDevCapsA(uDeviceID, &capsa, sizeof(capsa));
    if (res == MMSYSERR_NOERROR && pmic) {
        memset(pmic, 0, cbmic);
        MultiByteToWideChar(CP_UTF8, 0, capsa.szPname, -1, pmic->szPname, MAXPNAMELEN);
    }
    return res;
}

// One MIDI input at a time, as OpenMPT opens it. CoreMIDI reads on its own thread; the bytes are handed to the
// main thread, where all of this state lives, so the callback runs there like a window message would.
struct MacMidiIn {
    HMIDICALLBACK callback = nullptr;
    DWORD_PTR instance = 0;
    MIDIEndpointRef source = 0;
    uintptr_t generation = 0;  // bumped on close, so reads queued before that are dropped
    bool started = false;
    UInt64 startNanos = 0;
    std::deque<LPMIDIHDR> sysexBuffers;  // from midiInAddBuffer, filled in order
    LPMIDIHDR sysex = nullptr;           // buffer being filled
    bool inSysex = false;
    uint8_t status = 0;  // running status
    uint8_t data[2] = {};
    int dataCount = 0;
};
static MacMidiIn s_midiIn;

static UInt64 HostTimeToNanos(UInt64 hostTime) {
    static mach_timebase_info_data_t timebase{};
    if (!timebase.denom) mach_timebase_info(&timebase);
    return hostTime * timebase.numer / timebase.denom;
}

// Data bytes that follow a status byte; system real-time bytes have none.
static int MidiDataLength(uint8_t status) {
    switch (status & 0xF0) {
    case 0xC0: case 0xD0: return 1;
    case 0xF0: return (status == 0xF1 || status == 0xF3) ? 1 : (status == 0xF2 ? 2 : 0);
    default: return 2;
    }
}

static void MidiInDeliver(UINT msg, DWORD_PTR param1, DWORD ms) {
    s_midiIn.callback((HMIDIIN)&s_midiIn, msg, s_midiIn.instance, param1, ms);
}

static void MidiInFinishSysex(DWORD ms) {
    LPMIDIHDR hdr = s_midiIn.sysex;
    s_midiIn.sysex = nullptr;
    if (!hdr) return;
    hdr->dwFlags = (hdr->dwFlags & ~MHDR_INQUEUE) | MHDR_DONE;
    MidiInDeliver(MIM_LONGDATA, (DWORD_PTR)hdr, ms);
}

static void MidiInSysexByte(uint8_t b, DWORD ms) {
    if (!s_midiIn.sysex) {
        if (s_midiIn.sysexBuffers.empty()) return;  // no buffer queued: dropped, as on Windows
        s_midiIn.sysex = s_midiIn.sysexBuffers.front();
        s_midiIn.sysexBuffers.pop_front();
        s_midiIn.sysex->dwBytesRecorded = 0;
    }
    LPMIDIHDR hdr = s_midiIn.sysex;
    hdr->lpData[hdr->dwBytesRecorded++] = (char)b;
    if (b == 0xF7 || hdr->dwBytesRecorded >= hdr->dwBufferLength) MidiInFinishSysex(ms);
}

// Splits a CoreMIDI packet into the short messages and SysEx buffers that winmm delivers.
static void MidiInParse(const std::vector<uint8_t>& bytes, DWORD ms, uintptr_t generation) {
    MacMidiIn& in = s_midiIn;
    for (uint8_t b : bytes) {
        // The callback may close the device (e.g. a MIDI-mapped command).
        if (generation != in.generation || !in.callback || !in.started) return;
        if (b >= 0xF8) {  // real-time bytes may appear anywhere, even inside other messages
            MidiInDeliver(MIM_DATA, b, ms);
            continue;
        }
        if (in.inSysex) {
            if (b < 0x80 || b == 0xF7) {
                in.inSysex = b != 0xF7;
                MidiInSysexByte(b, ms);
                continue;
            }
            // Any other status byte ends the SysEx early.
            in.inSysex = false;
            MidiInFinishSysex(ms);
            if (generation != in.generation) return;
        }
        if (b == 0xF0) {
            in.inSysex = true;
            in.status = 0;
            MidiInSysexByte(b, ms);
        } else if (b >= 0x80) {
            in.status = b;
            in.dataCount = 0;
            if (MidiDataLength(b) == 0) {
                if (b != 0xF7) MidiInDeliver(MIM_DATA, b, ms);
                in.status = 0;
            }
        } else if (in.status) {
            in.data[in.dataCount++] = b;
            if (in.dataCount == MidiDataLength(in.status)) {
                MidiInDeliver(MIM_DATA, in.status | (in.data[0] << 8) | (in.dataCount > 1 ? in.data[1] << 16 : 0), ms);
                in.dataCount = 0;
                if (in.status >= 0xF0) in.status = 0;  // system common messages cancel running status
            }
        }
    }
}

static void MidiReadProc(const MIDIPacketList* pktlist, void*, void* srcConnRefCon) {
    const uintptr_t generation = (uintptr_t)srcConnRefCon;
    const MIDIPacket* packet = &pktlist->packet[0];
    for (UInt32 i = 0; i < pktlist->numPackets; ++i) {
        std::vector<uint8_t> bytes(packet->data, packet->data + packet->length);
        const UInt64 nanos = HostTimeToNanos(packet->timeStamp ? packet->timeStamp : mach_absolute_time());
        dispatch_async(dispatch_get_main_queue(), ^{
            const DWORD ms = (DWORD)((nanos - std::min(nanos, s_midiIn.startNanos)) / 1000000);
            MidiInParse(bytes, ms, generation);
        });
        packet = MIDIPacketNext(packet);
    }
}

MMRESULT WINAPI midiInOpen(LPHMIDIIN phmi, UINT uDeviceID, DWORD_PTR dwCallback, DWORD_PTR dwInstance, DWORD fdwOpen) {
    (void)fdwOpen;
    if (s_midiIn.callback) return MMSYSERR_ALLOCATED;
    if (!s_midiClient) {
        MIDIClientCreate(CFSTR("OpenMPT MIDI Client"), nullptr, nullptr, &s_midiClient);
    }
    if (!s_midiInPort) {
        MIDIInputPortCreate(s_midiClient, CFSTR("OpenMPT MIDI In Port"), MidiReadProc, nullptr, &s_midiInPort);
    }
    MIDIEndpointRef src = MIDIGetSource(uDeviceID);
    if (!src) return MMSYSERR_BADDEVICEID;
    if (MIDIPortConnectSource(s_midiInPort, src, (void*)s_midiIn.generation) != noErr) return MMSYSERR_ERROR;
    s_midiIn.callback = (HMIDICALLBACK)dwCallback;
    s_midiIn.instance = dwInstance;
    s_midiIn.source = src;
    if (phmi) *phmi = (HMIDIIN)&s_midiIn;
    return MMSYSERR_NOERROR;
}

MMRESULT WINAPI midiInReset(HMIDIIN hmi) {
    if (hmi != (HMIDIIN)&s_midiIn) return MMSYSERR_INVALHANDLE;
    // Unlike winmm, queued buffers are not handed back through the callback: the caller may hold the lock that callback takes.
    s_midiIn.started = false;
    s_midiIn.sysexBuffers.clear();
    s_midiIn.sysex = nullptr;
    s_midiIn.inSysex = false;
    s_midiIn.status = 0;
    s_midiIn.dataCount = 0;
    return MMSYSERR_NOERROR;
}

MMRESULT WINAPI midiInClose(HMIDIIN hmi) {
    if (hmi != (HMIDIIN)&s_midiIn || !s_midiIn.callback) return MMSYSERR_INVALHANDLE;
    MIDIPortDisconnectSource(s_midiInPort, s_midiIn.source);
    midiInReset(hmi);
    s_midiIn.callback = nullptr;
    s_midiIn.instance = 0;
    s_midiIn.source = 0;
    s_midiIn.generation++;
    return MMSYSERR_NOERROR;
}

MMRESULT WINAPI midiInStart(HMIDIIN hmi) {
    if (hmi != (HMIDIIN)&s_midiIn) return MMSYSERR_INVALHANDLE;
    s_midiIn.started = true;
    s_midiIn.startNanos = HostTimeToNanos(mach_absolute_time());
    return MMSYSERR_NOERROR;
}
MMRESULT WINAPI midiInStop(HMIDIIN hmi) {
    if (hmi != (HMIDIIN)&s_midiIn) return MMSYSERR_INVALHANDLE;
    s_midiIn.started = false;
    return MMSYSERR_NOERROR;
}
MMRESULT WINAPI midiInPrepareHeader(HMIDIIN hmi, LPMIDIHDR pmh, UINT cbmh) {
    if (pmh) pmh->dwFlags |= MHDR_PREPARED;
    return MMSYSERR_NOERROR;
}
MMRESULT WINAPI midiInUnprepareHeader(HMIDIIN hmi, LPMIDIHDR pmh, UINT cbmh) {
    if (pmh) pmh->dwFlags &= ~MHDR_PREPARED;
    return MMSYSERR_NOERROR;
}
MMRESULT WINAPI midiInAddBuffer(HMIDIIN hmi, LPMIDIHDR pmh, UINT cbmh) {
    if (hmi != (HMIDIIN)&s_midiIn) return MMSYSERR_INVALHANDLE;
    if (!pmh || !pmh->lpData || !pmh->dwBufferLength) return MMSYSERR_INVALPARAM;
    pmh->dwFlags = (pmh->dwFlags & ~MHDR_DONE) | MHDR_INQUEUE;
    pmh->dwBytesRecorded = 0;
    s_midiIn.sysexBuffers.push_back(pmh);
    return MMSYSERR_NOERROR;
}

// Dynamic VST loading (.vst bundle / mach-o)
HMODULE WINAPI LoadLibraryA(LPCSTR lpLibFileName) {
    if (!lpLibFileName) return nullptr;
    NSString* path = [NSString stringWithUTF8String:lpLibFileName];
    if ([path hasSuffix:@".vst"] || [path hasSuffix:@".vst3"]) {
        CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, (__bridge CFURLRef)[NSURL fileURLWithPath:path]);
        if (bundle && CFBundleLoadExecutable(bundle)) {
            return (HMODULE)bundle;
        }
    }
    void* handle = dlopen(lpLibFileName, RTLD_NOW | RTLD_LOCAL);
    return (HMODULE)handle;
}

HMODULE WINAPI LoadLibraryW(LPCWSTR lpLibFileName) {
    char buf[1024] = {};
    WideCharToMultiByte(CP_UTF8, 0, lpLibFileName, -1, buf, sizeof(buf), nullptr, nullptr);
    return LoadLibraryA(buf);
}

FARPROC WINAPI GetProcAddress(HMODULE hModule, LPCSTR lpProcName) {
    if (!hModule || !lpProcName) return nullptr;
    // Check if CFBundleRef
    if (CFGetTypeID((CFTypeRef)hModule) == CFBundleGetTypeID()) {
        CFBundleRef bundle = (CFBundleRef)hModule;
        CFStringRef fnName = CFStringCreateWithCString(kCFAllocatorDefault, lpProcName, kCFStringEncodingUTF8);
        void* ptr = CFBundleGetFunctionPointerForName(bundle, fnName);
        CFRelease(fnName);
        return (FARPROC)ptr;
    }
    return (FARPROC)dlsym((void*)hModule, lpProcName);
}

BOOL WINAPI FreeLibrary(HMODULE hLibModule) {
    if (!hLibModule) return FALSE;
    if (CFGetTypeID((CFTypeRef)hLibModule) == CFBundleGetTypeID()) {
        CFBundleUnloadExecutable((CFBundleRef)hLibModule);
        CFRelease((CFBundleRef)hLibModule);
        return TRUE;
    }
    dlclose((void*)hLibModule);
    return TRUE;
}

// MFC Global Functions
CWinApp* AFXAPI AfxGetApp() { return s_pApp; }
CWnd* AFXAPI AfxGetMainWnd() { return s_pMainWnd; }
HINSTANCE AFXAPI AfxGetInstanceHandle() { return (HINSTANCE)0x1000; }
HINSTANCE AFXAPI AfxGetResourceHandle() { return (HINSTANCE)0x1000; }
LPCTSTR AFXAPI AfxGetAppName() { return _T("OpenMPT"); }
int AFXAPI AfxMessageBox(LPCTSTR lpszText, UINT nType, UINT nIDHelp) {
    (void)nType; (void)nIDHelp;
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = @"OpenMPT";
    alert.informativeText = ToNSString(lpszText);
    [alert runModal];
    return IDOK;
}
int AFXAPI AfxMessageBox(UINT nIDPrompt, UINT nType, UINT nIDHelp) {
    std::string s = MacResourceManager::Instance().GetString((int)nIDPrompt);
    CString str(s.c_str());
    return AfxMessageBox(str, nType, nIDHelp);
}
LPCTSTR AFXAPI AfxRegisterWndClass(UINT nClassStyle, HCURSOR hCursor, HBRUSH hbrBackground, HICON hIcon) {
    (void)nClassStyle; (void)hCursor; (void)hbrBackground; (void)hIcon;
    return _T("MPT_WND_CLASS");
}
BOOL AFXAPI AfxInitRichEdit2() { return TRUE; }
HRESULT AFXAPI AfxDllCanUnloadNow() { return S_OK; }
void AFXAPI AfxSocketInit() {}

// CWinApp
CWinApp::CWinApp(LPCTSTR lpszAppName) {
    s_pApp = this;
    if (lpszAppName) m_pszAppName = lpszAppName;
}
CWinApp::~CWinApp() {
    if (s_pApp == this) s_pApp = nullptr;
}
void CWinApp::AddToRecentFileList(LPCTSTR lpszPathName) {
    if (m_pRecentFileList && lpszPathName) m_pRecentFileList->Add(lpszPathName);
}
void CWinApp::LoadStdProfileSettings(UINT nMaxMRU) {
    m_pRecentFileList = new CRecentFileList(0, _T("Recent File List"), _T("File%d"), nMaxMRU);
}
void CWinApp::ParseCommandLine(CCommandLineInfo& rCmdInfo) {
    NSArray* args = [[NSProcessInfo processInfo] arguments];
    for (NSUInteger i = 1; i < [args count]; ++i) {
        NSString* arg = [args objectAtIndex:i];
        CString strArg([arg UTF8String]);
        rCmdInfo.ParseParam(strArg, FALSE, (i == [args count] - 1));
    }
}
BOOL CWinApp::ProcessShellCommand(CCommandLineInfo& rCmdInfo) {
    if (rCmdInfo.m_nShellCommand == CCommandLineInfo::FileOpen && !rCmdInfo.m_strFileName.IsEmpty()) {
        OpenDocumentFile(rCmdInfo.m_strFileName);
        return TRUE;
    }
    if (rCmdInfo.m_nShellCommand == CCommandLineInfo::FileNew) {
        OnFileNew();
        return TRUE;
    }
    return TRUE;
}
int CWinApp::DoMessageBox(LPCTSTR lpszPrompt, UINT nType, UINT nIDPrompt) {
    return AfxMessageBox(lpszPrompt, nType, nIDPrompt);
}
int CWinApp::Run() {
    [NSApp finishLaunching];
    LONG idleCount = 0;
    bool idle = true;
    for (;;) {
        @autoreleasepool {
            NSDate* until = (idle || !s_messageQueue.empty()) ? [NSDate distantPast] : [NSDate dateWithTimeIntervalSinceNow:0.05];
            NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:until inMode:NSDefaultRunLoopMode dequeue:YES];
            if (event) {
                const bool isKey = event.type == NSEventTypeKeyDown || event.type == NSEventTypeKeyUp || event.type == NSEventTypeFlagsChanged;
                if (!(isKey && MacHandleKeyEvent(event))) [NSApp sendEvent:event];
                idle = true;
                idleCount = 0;
            }
            MSG msg{};
            while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
                if (msg.message == WM_QUIT) return ExitInstance();
                m_msgCur = msg;
                if (!PreTranslateMessage(&msg)) DispatchMessageW(&msg);
                idle = true;
                idleCount = 0;
            }
            if (idle && !event) idle = OnIdle(idleCount++) != FALSE;
        }
    }
}
BOOL CWinApp::OnOpenRecentFile(UINT nID) {
    if (m_pRecentFileList) {
        int idx = (int)(nID - ID_FILE_MRU_FIRST);
        CString path = (*m_pRecentFileList)[idx];
        if (!path.IsEmpty()) {
            OpenDocumentFile(path);
            return TRUE;
        }
    }
    return FALSE;
}

// CWnd Implementation
const CWnd CWnd::wndTop;
const CWnd CWnd::wndBottom;
const CWnd CWnd::wndTopMost;
const CWnd CWnd::wndNoTopMost;
// As in MFC, these stand for the HWND_xxx z-order positions passed to SetWindowPos.
static const bool s_specialWindowsInitialized = [] {
    const_cast<CWnd&>(CWnd::wndTop).m_hWnd = HWND_TOP;
    const_cast<CWnd&>(CWnd::wndBottom).m_hWnd = HWND_BOTTOM;
    const_cast<CWnd&>(CWnd::wndTopMost).m_hWnd = HWND_TOPMOST;
    const_cast<CWnd&>(CWnd::wndNoTopMost).m_hWnd = HWND_NOTOPMOST;
    return true;
}();

IMPLEMENT_DYNCREATE(CWnd, CCmdTarget)
BEGIN_MESSAGE_MAP(CWnd, CCmdTarget)
END_MESSAGE_MAP()

CWnd::~CWnd() {
    DestroyWindow();
}

BOOL CWnd::Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle,
                  const RECT& rect, CWnd* pParentWnd, UINT nID, CCreateContext* pContext) {
    return CreateEx(0, lpszClassName, lpszWindowName, dwStyle, rect.left, rect.top,
                    rect.right - rect.left, rect.bottom - rect.top,
                    pParentWnd ? pParentWnd->GetSafeHwnd() : nullptr, (HMENU)(uintptr_t)nID, pContext);
}

BOOL CWnd::CreateEx(DWORD dwExStyle, LPCTSTR lpszClassName, LPCTSTR lpszWindowName,
                    DWORD dwStyle, int x, int y, int nWidth, int nHeight,
                    HWND hWndParent, HMENU nIDorHMenu, LPVOID lpParam) {
    m_hWnd = CreateNativeHWND(this, dwExStyle, lpszClassName, lpszWindowName, dwStyle, x, y, nWidth, nHeight, hWndParent, nIDorHMenu, lpParam);
    if (!s_pMainWnd && !hWndParent) s_pMainWnd = this;
    return m_hWnd != nullptr;
}

BOOL CWnd::CreateEx(DWORD dwExStyle, LPCTSTR lpszClassName, LPCTSTR lpszWindowName,
                    DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID, LPVOID lpParam) {
    return CreateEx(dwExStyle, lpszClassName, lpszWindowName, dwStyle, rect.left, rect.top,
                    rect.right - rect.left, rect.bottom - rect.top,
                    pParentWnd ? pParentWnd->GetSafeHwnd() : nullptr, (HMENU)(uintptr_t)nID, lpParam);
}

BOOL CWnd::DestroyWindow() {
    // Stay attached so OnDestroy runs; ::DestroyWindow detaches and may delete this via PostNcDestroy.
    return m_hWnd ? ::DestroyWindow(m_hWnd) : FALSE;
}

BOOL CWnd::Attach(HWND hWndNew) {
    m_hWnd = hWndNew;
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (rec) rec->pWnd = this;
    return hWndNew != nullptr;
}

HWND CWnd::Detach() {
    HWND h = m_hWnd;
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (rec && rec->pWnd == this) rec->pWnd = nullptr;
    m_hWnd = nullptr;
    return h;
}

CWnd* CWnd::FromHandle(HWND hWnd) {
    if (!hWnd) return nullptr;
    WindowRecord* rec = GetWindowRecord(hWnd);
    if (rec && rec->pWnd) return rec->pWnd;
    // Temporary wrapper: not registered as the window's owner, so messages keep going to its WNDPROC.
    static std::unordered_map<HWND, CWnd*> s_tempWrappers;
    CWnd*& w = s_tempWrappers[hWnd];
    if (!w) w = new CWnd();
    w->m_hWnd = hWnd;
    return w;
}

CWnd* CWnd::FromHandlePermanent(HWND hWnd) {
    WindowRecord* rec = GetWindowRecord(hWnd);
    return rec ? rec->pWnd : nullptr;
}

BOOL CWnd::SubclassWindow(HWND hWnd) {
    return Attach(hWnd);
}

BOOL CWnd::SubclassDlgItem(UINT nID, CWnd* pParent) {
    if (!pParent) return FALSE;
    HWND h = ::GetDlgItem(pParent->GetSafeHwnd(), (int)nID);
    return h ? SubclassWindow(h) : FALSE;
}

HWND CWnd::UnsubclassWindow() {
    return Detach();
}

CWnd* CWnd::GetDlgItem(int nID) const {
    HWND hChild = ::GetDlgItem(m_hWnd, nID);
    return FromHandle(hChild);
}

BOOL CWnd::ModifyStyle(DWORD dwRemove, DWORD dwAdd, UINT nFlags) {
    DWORD style = GetStyle();
    DWORD newStyle = (style & ~dwRemove) | dwAdd;
    ::SetWindowLongPtr(m_hWnd, GWL_STYLE, newStyle);
    SetWindowPos(nullptr, 0, 0, 0, 0, nFlags | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
    return TRUE;
}

BOOL CWnd::ModifyStyleEx(DWORD dwRemove, DWORD dwAdd, UINT nFlags) {
    DWORD exStyle = GetExStyle();
    DWORD newExStyle = (exStyle & ~dwRemove) | dwAdd;
    ::SetWindowLongPtr(m_hWnd, GWL_EXSTYLE, newExStyle);
    SetWindowPos(nullptr, 0, 0, 0, 0, nFlags | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
    return TRUE;
}

int CWnd::GetScrollLimit(int nBar) {
    SCROLLINFO si{};
    si.fMask = SIF_RANGE | SIF_PAGE;
    GetScrollInfo(nBar, &si);
    return si.nMax - (int)std::max(0u, si.nPage - 1);
}

void CWnd::CenterWindow(CWnd* pAlternateOwner) {
    // Like MFC: child windows centre within their parent's client area, popups over their owner (or the screen).
    RECT rcWnd{};
    GetWindowRect(&rcWnd);
    const int w = rcWnd.right - rcWnd.left, h = rcWnd.bottom - rcWnd.top;
    RECT area{};
    if (GetStyle() & WS_CHILD) {
        ::GetClientRect(::GetParent(m_hWnd), &area);
    } else if (HWND hOwner = pAlternateOwner ? pAlternateOwner->GetSafeHwnd() : ::GetParent(m_hWnd)) {
        ::GetWindowRect(hOwner, &area);
    } else {
        ::SystemParametersInfoW(SPI_GETWORKAREA, 0, &area, 0);
    }
    const int x = area.left + (area.right - area.left - w) / 2;
    const int y = area.top + (area.bottom - area.top - h) / 2;
    SetWindowPos(nullptr, std::max<int>(x, area.left), std::max<int>(y, area.top), 0, 0, SWP_NOSIZE | SWP_NOZORDER);
}

// The message being handled, so Default() can forward it (MFC keeps this in thread state).
static thread_local MSG t_currentMessage{};

LRESULT CWnd::WindowProc(UINT message, WPARAM wParam, LPARAM lParam) {
    const MSG saved = t_currentMessage;
    t_currentMessage = MSG{m_hWnd, message, wParam, lParam};
    LRESULT lResult = 0;
    if (!OnWndMsg(message, wParam, lParam, &lResult)) {
        lResult = DefWindowProc(message, wParam, lParam);
    }
    t_currentMessage = saved;
    return lResult;
}

// The window class procedure (e.g. a built-in control) plays the role of the subclassed original WNDPROC.
LRESULT CWnd::DefWindowProc(UINT message, WPARAM wParam, LPARAM lParam) {
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (rec && rec->wndProc) return rec->wndProc(m_hWnd, message, wParam, lParam);
    return ::DefWindowProc(m_hWnd, message, wParam, lParam);
}

const MSG* CWnd::GetCurrentMessage() const {
    return &t_currentMessage;
}

LRESULT CWnd::Default() {
    const MSG* pMsg = GetCurrentMessage();
    return DefWindowProc(pMsg->message, pMsg->wParam, pMsg->lParam);
}

// Calls a message-map handler with the arguments cracked from wParam/lParam, as MFC's AfxSig table does.
static bool DispatchMsgMapEntry(CWnd* self, const AFX_MSGMAP_ENTRY* e, UINT message, WPARAM wParam, LPARAM lParam, LRESULT& result) {
    using W = CWnd;
    AFX_PMSG pfn = e->pfn;
    const CPoint pt(GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam));
    result = 0;
    switch (e->nSig) {
    case AfxSig_vv: (self->*pfn)(); break;
    case AfxSig_i_LP: result = (self->*reinterpret_cast<int (W::*)(LPCREATESTRUCT)>(pfn))((LPCREATESTRUCT)lParam); break;
    case AfxSig_v_u_i_i: (self->*reinterpret_cast<void (W::*)(UINT, int, int)>(pfn))((UINT)wParam, (short)LOWORD(lParam), (short)HIWORD(lParam)); break;
    case AfxSig_v_i_i: (self->*reinterpret_cast<void (W::*)(int, int)>(pfn))((short)LOWORD(lParam), (short)HIWORD(lParam)); break;
    case AfxSig_v_u_p: (self->*reinterpret_cast<void (W::*)(UINT, CPoint)>(pfn))((UINT)wParam, pt); break;
    case AfxSig_v_u_u_p: (self->*reinterpret_cast<void (W::*)(UINT, UINT, CPoint)>(pfn))(LOWORD(wParam), HIWORD(wParam), pt); break;
    case AfxSig_b_u_s_p: {
        CPoint screen = pt;  // WM_MOUSEWHEEL carries screen coordinates
        result = (self->*reinterpret_cast<BOOL (W::*)(UINT, short, CPoint)>(pfn))(LOWORD(wParam), (short)HIWORD(wParam), screen);
        break;
    }
    case AfxSig_v_u_s_p: (self->*reinterpret_cast<void (W::*)(UINT, short, CPoint)>(pfn))(LOWORD(wParam), (short)HIWORD(wParam), pt); break;
    case AfxSig_v_u_u_u: (self->*reinterpret_cast<void (W::*)(UINT, UINT, UINT)>(pfn))((UINT)wParam, LOWORD(lParam), HIWORD(lParam)); break;
    case AfxSig_v_u_u_W: (self->*reinterpret_cast<void (W::*)(UINT, UINT, CScrollBar*)>(pfn))(LOWORD(wParam), (short)HIWORD(wParam), (CScrollBar*)CWnd::FromHandle((HWND)lParam)); break;
    case AfxSig_v_u: (self->*reinterpret_cast<void (W::*)(UINT_PTR)>(pfn))((UINT_PTR)wParam); break;
    case AfxSig_v_b: (self->*reinterpret_cast<void (W::*)(BOOL)>(pfn))((BOOL)wParam); break;
    case AfxSig_v_b_u: (self->*reinterpret_cast<void (W::*)(BOOL, UINT)>(pfn))((BOOL)wParam, (UINT)lParam); break;
    case AfxSig_b_b: result = (self->*reinterpret_cast<BOOL (W::*)(BOOL)>(pfn))((BOOL)wParam); break;
    case AfxSig_b_v: result = (self->*reinterpret_cast<BOOL (W::*)()>(pfn))(); break;
    case AfxSig_u_v: result = (self->*reinterpret_cast<UINT (W::*)()>(pfn))(); break;
    case AfxSig_u_p: result = (self->*reinterpret_cast<LRESULT (W::*)(CPoint)>(pfn))(pt); break;
    case AfxSig_b_D: result = (self->*reinterpret_cast<BOOL (W::*)(CDC*)>(pfn))(CDC::FromHandle((HDC)wParam)); break;
    case AfxSig_v_D: (self->*reinterpret_cast<void (W::*)(CDC*)>(pfn))(CDC::FromHandle((HDC)wParam)); break;
    case AfxSig_v_W: (self->*reinterpret_cast<void (W::*)(CWnd*)>(pfn))(CWnd::FromHandle((HWND)wParam)); break;
    case AfxSig_v_W_p: (self->*reinterpret_cast<void (W::*)(CWnd*, CPoint)>(pfn))(CWnd::FromHandle((HWND)wParam), pt); break;
    case AfxSig_v_u_W_b: (self->*reinterpret_cast<void (W::*)(UINT, CWnd*, BOOL)>(pfn))(LOWORD(wParam), CWnd::FromHandle((HWND)lParam), HIWORD(wParam)); break;
    case AfxSig_v_b_W_W: (self->*reinterpret_cast<void (W::*)(BOOL, CWnd*, CWnd*)>(pfn))((HWND)lParam == self->m_hWnd, CWnd::FromHandle((HWND)lParam), CWnd::FromHandle((HWND)wParam)); break;
    case AfxSig_i_W_u_u: result = (self->*reinterpret_cast<int (W::*)(CWnd*, UINT, UINT)>(pfn))(CWnd::FromHandle((HWND)wParam), LOWORD(lParam), HIWORD(lParam)); break;
    case AfxSig_b_W_u_u: result = (self->*reinterpret_cast<BOOL (W::*)(CWnd*, UINT, UINT)>(pfn))(CWnd::FromHandle((HWND)wParam), LOWORD(lParam), HIWORD(lParam)); break;
    case AfxSig_b_W_p: result = (self->*reinterpret_cast<BOOL (W::*)(CWnd*, LPARAM)>(pfn))(CWnd::FromHandle((HWND)wParam), lParam); break;
    case AfxSig_v_p: (self->*reinterpret_cast<void (W::*)(void*)>(pfn))((void*)lParam); break;
    case AfxSig_v_b_p: (self->*reinterpret_cast<void (W::*)(BOOL, void*)>(pfn))((BOOL)wParam, (void*)lParam); break;
    case AfxSig_v_u_r: (self->*reinterpret_cast<void (W::*)(UINT, LPRECT)>(pfn))((UINT)wParam, (LPRECT)lParam); break;
    case AfxSig_l_w_l: result = (self->*reinterpret_cast<LRESULT (W::*)(WPARAM, LPARAM)>(pfn))(wParam, lParam); break;
    case AfxSig_v_h: (self->*reinterpret_cast<void (W::*)(HANDLE)>(pfn))((HANDLE)wParam); break;
    case AfxSig_v_M: (self->*reinterpret_cast<void (W::*)(CMenu*)>(pfn))(CMenu::FromHandle((HMENU)wParam)); break;
    case AfxSig_v_M_u_b: (self->*reinterpret_cast<void (W::*)(CMenu*, UINT, BOOL)>(pfn))(CMenu::FromHandle((HMENU)wParam), LOWORD(lParam), HIWORD(lParam)); break;
    case AfxSig_v_u_u_M: (self->*reinterpret_cast<void (W::*)(UINT, UINT, HMENU)>(pfn))(LOWORD(wParam), HIWORD(wParam), (HMENU)lParam); break;
    case AfxSig_v_i_p: (self->*reinterpret_cast<void (W::*)(int, void*)>(pfn))((int)wParam, (void*)lParam); break;
    case AfxSig_i_i_p: result = (self->*reinterpret_cast<int (W::*)(int, void*)>(pfn))((int)wParam, (void*)lParam); break;
    case AfxSig_i_u_W_u: result = (self->*reinterpret_cast<int (W::*)(UINT, CWnd*, UINT)>(pfn))(LOWORD(wParam), CWnd::FromHandle((HWND)lParam), HIWORD(wParam)); break;
    case AfxSig_v_u_s: (self->*reinterpret_cast<void (W::*)(UINT, LPCTSTR)>(pfn))((UINT)wParam, (LPCTSTR)lParam); break;
    case AfxSig_v_u_l: (self->*reinterpret_cast<void (W::*)(UINT, LPARAM)>(pfn))((UINT)wParam, lParam); break;
    case AfxSig_b_u_l: result = (self->*reinterpret_cast<BOOL (W::*)(UINT, DWORD_PTR)>(pfn))((UINT)wParam, (DWORD_PTR)lParam); break;
    case AfxSig_B_D_W_u: {
        const UINT ctlType = message - WM_CTLCOLORMSGBOX;
        result = (LRESULT)(self->*reinterpret_cast<HBRUSH (W::*)(CDC*, CWnd*, UINT)>(pfn))(CDC::FromHandle((HDC)wParam), CWnd::FromHandle((HWND)lParam), ctlType);
        break;
    }
    case AfxSig_B_D_u: result = (LRESULT)(self->*reinterpret_cast<HBRUSH (W::*)(CDC*, UINT)>(pfn))(CDC::FromHandle((HDC)wParam), message - WM_REFLECT_BASE - WM_CTLCOLORMSGBOX); break;
    default: return false;
    }
    return true;
}

BOOL CWnd::OnWndMsg(UINT message, WPARAM wParam, LPARAM lParam, LRESULT* pResult) {
    LRESULT dummy = 0;
    LRESULT& result = pResult ? *pResult : dummy;
    if (message == WM_COMMAND) {
        if (OnCommand(wParam, lParam)) { result = 1; return TRUE; }
        return FALSE;
    }
    if (message == WM_NOTIFY) {
        return OnNotify(wParam, lParam, &result);
    }
    // All WM_CTLCOLORxxx messages go to the single ON_WM_CTLCOLOR entry (and its reflected form).
    const bool isCtlColor = message >= WM_CTLCOLORMSGBOX && message <= WM_CTLCOLORSTATIC;
    const bool isReflectedCtlColor = message >= WM_REFLECT_BASE + WM_CTLCOLORMSGBOX && message <= WM_REFLECT_BASE + WM_CTLCOLORSTATIC;
    const UINT lookup = isCtlColor ? WM_CTLCOLOR : (isReflectedCtlColor ? WM_REFLECT_BASE + WM_CTLCOLOR : message);

    for (const AFX_MSGMAP* pMap = GetMessageMap(); pMap != nullptr; pMap = pMap->pfnGetBaseMap ? pMap->pfnGetBaseMap() : nullptr) {
        for (const AFX_MSGMAP_ENTRY* pEntry = pMap->lpEntries; pEntry && pEntry->nSig != AfxSig_end; ++pEntry) {
            if (!pEntry->pfn) continue;
            if (pEntry->nMessage == 0xC000) {
                // ON_REGISTERED_MESSAGE stores a pointer to the message ID in nSig.
                if (*reinterpret_cast<const UINT*>(pEntry->nSig) == message) {
                    result = (this->*reinterpret_cast<LRESULT (CWnd::*)(WPARAM, LPARAM)>(pEntry->pfn))(wParam, lParam);
                    return TRUE;
                }
                continue;
            }
            if (pEntry->nMessage != lookup) continue;
            // Reflected WM_COMMAND / WM_NOTIFY entries also match on the notification code.
            if (message == WM_REFLECT_BASE + WM_COMMAND) {
                if (pEntry->nCode != HIWORD(wParam)) continue;
                if (pEntry->nSig == AfxSig_refl_b) { result = 0; return (this->*reinterpret_cast<BOOL (CCmdTarget::*)()>(pEntry->pfn))(); }
                (this->*pEntry->pfn)();
                return TRUE;
            }
            if (message == WM_REFLECT_BASE + WM_NOTIFY) {
                NMHDR* nmhdr = reinterpret_cast<NMHDR*>(lParam);
                if (!nmhdr || pEntry->nCode != nmhdr->code) continue;
                auto fn = reinterpret_cast<BOOL (CCmdTarget::*)(NMHDR*, LRESULT*)>(pEntry->pfn);
                if (pEntry->nSig == AfxSig_refl_notify_b) return (this->*fn)(nmhdr, &result);
                (this->*reinterpret_cast<void (CCmdTarget::*)(NMHDR*, LRESULT*)>(pEntry->pfn))(nmhdr, &result);
                return TRUE;
            }
            if (DispatchMsgMapEntry(this, pEntry, message, wParam, lParam, result)) return TRUE;
        }
    }
    // MFC reflects owner-draw requests the parent doesn't handle back to the control class.
    if (message == WM_DRAWITEM && lParam) {
        auto* dis = reinterpret_cast<LPDRAWITEMSTRUCT>(lParam);
        if (auto* button = dynamic_cast<CButton*>(CWnd::FromHandlePermanent(dis->hwndItem))) {
            button->DrawItem(dis);
            result = TRUE;
            return TRUE;
        }
        if (auto* list = dynamic_cast<CListBox*>(CWnd::FromHandlePermanent(dis->hwndItem))) {
            list->DrawItem(dis);
            result = TRUE;
            return TRUE;
        }
    }
    return FALSE;
}

// WM_COMMAND: give the child control a chance to handle it (reflection), then route through OnCmdMsg.
BOOL CWnd::OnCommand(WPARAM wParam, LPARAM lParam) {
    const UINT nID = LOWORD(wParam);
    const int nCode = HIWORD(wParam);
    HWND hWndCtrl = (HWND)lParam;
    if (hWndCtrl) {
        if (CWnd* child = CWnd::FromHandlePermanent(hWndCtrl)) {
            LRESULT r = 0;
            if (child->OnWndMsg(WM_REFLECT_BASE + WM_COMMAND, wParam, lParam, &r)) return TRUE;
        }
    }
    return OnCmdMsg(nID, nCode, nullptr, nullptr);
}

BOOL CWnd::OnNotify(WPARAM wParam, LPARAM lParam, LRESULT* pResult) {
    NMHDR* pNMHDR = (NMHDR*)lParam;
    if (!pNMHDR) return FALSE;
    if (CWnd* child = CWnd::FromHandlePermanent(pNMHDR->hwndFrom)) {
        if (child != this && child->OnWndMsg(WM_REFLECT_BASE + WM_NOTIFY, wParam, lParam, pResult)) return TRUE;
    }
    const UINT nCode = pNMHDR->code;
    const UINT_PTR nID = pNMHDR->idFrom;
    for (const AFX_MSGMAP* pMap = GetMessageMap(); pMap != nullptr; pMap = pMap->pfnGetBaseMap ? pMap->pfnGetBaseMap() : nullptr) {
        for (const AFX_MSGMAP_ENTRY* pEntry = pMap->lpEntries; pEntry && pEntry->nSig != AfxSig_end; ++pEntry) {
            if (pEntry->nMessage != WM_NOTIFY || pEntry->nCode != nCode || nID < pEntry->nID || nID > pEntry->nLastID) continue;
            switch (pEntry->nSig) {
            case AfxSig_notify_v:
                (this->*reinterpret_cast<void (CCmdTarget::*)(NMHDR*, LRESULT*)>(pEntry->pfn))(pNMHDR, pResult);
                return TRUE;
            case AfxSig_notify_range:
                (this->*reinterpret_cast<void (CCmdTarget::*)(UINT, NMHDR*, LRESULT*)>(pEntry->pfn))((UINT)nID, pNMHDR, pResult);
                return TRUE;
            case AfxSig_notify_b:
                if ((this->*reinterpret_cast<BOOL (CCmdTarget::*)(UINT, NMHDR*, LRESULT*)>(pEntry->pfn))((UINT)nID, pNMHDR, pResult)) return TRUE;
                break;
            }
        }
    }
    return FALSE;
}

BOOL CWnd::OnChildNotify(UINT message, WPARAM wParam, LPARAM lParam, LRESULT* pResult) {
    return FALSE;
}

BOOL CWnd::ReflectLastMsg(HWND hWndChild, LRESULT* pResult) {
    return FALSE;
}

void CWnd::UpdateDialogControls(CCmdTarget* pTarget, BOOL bDisableIfNoHndler) {}
// Docks visible control bars against the client edges in creation order; the child with ID
// nIDLeftOver (if any) receives the remaining rectangle, which is also returned in lpRectParam.
void CWnd::RepositionBars(UINT nIDFirst, UINT nIDLast, UINT nIDLeftOver, UINT nFlag, LPRECT lpRectParam, LPCRECT lpRectClient, BOOL bStretch) {
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (!rec) return;
    CRect rect;
    if (lpRectClient) rect = *lpRectClient;
    else GetClientRect(&rect);
    HWND leftOver = nullptr;
    const std::vector<HWND> children = rec->children;
    for (HWND child : children) {
        WindowRecord* c = GetWindowRecord(child);
        if (!c) continue;
        if (c->id == nIDLeftOver) leftOver = child;
        auto* bar = dynamic_cast<CControlBar*>(c->pWnd);
        if (!bar || !c->isVisible || c->id < nIDFirst || c->id > nIDLast) continue;
        const DWORD style = bar->m_dwStyle;
        const bool horz = (style & CBRS_ORIENT_HORZ) != 0;
        const CSize size = (style & CBRS_SIZE_DYNAMIC)
            ? bar->CalcDynamicLayout(-1, horz ? (LM_HORZ | LM_HORZDOCK) : LM_VERTDOCK)
            : bar->CalcFixedLayout(bStretch, horz);
        CRect r = rect;
        if (style & CBRS_ALIGN_TOP) { r.bottom = r.top + size.cy; rect.top = r.bottom; }
        else if (style & CBRS_ALIGN_BOTTOM) { r.top = r.bottom - size.cy; rect.bottom = r.top; }
        else if (style & CBRS_ALIGN_LEFT) { r.right = r.left + std::min<int>(size.cx, rect.Width()); rect.left = r.right; }
        else if (style & CBRS_ALIGN_RIGHT) { r.left = r.right - std::min<int>(size.cx, rect.Width()); rect.right = r.left; }
        else continue;
        if (nFlag != reposQuery) ::MoveWindow(child, r.left, r.top, r.Width(), r.Height(), TRUE);
    }
    if (lpRectParam) *lpRectParam = rect;
    if (leftOver && nFlag != reposQuery) ::MoveWindow(leftOver, rect.left, rect.top, rect.Width(), rect.Height(), TRUE);
}
void CWnd::SendMessageToDescendants(UINT message, WPARAM wParam, LPARAM lParam, BOOL bDeep, BOOL bOnlyPerm) {
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (!rec) return;
    const std::vector<HWND> children = rec->children;  // handlers may create or destroy windows
    for (HWND child : children) {
        if (!::IsWindow(child)) continue;
        CWnd* wnd = CWnd::FromHandlePermanent(child);
        if (wnd) wnd->SendMessage(message, wParam, lParam);
        else if (!bOnlyPerm) ::SendMessageW(child, message, wParam, lParam);
        if (bDeep && ::IsWindow(child)) CWnd::FromHandle(child)->SendMessageToDescendants(message, wParam, lParam, bDeep, bOnlyPerm);
    }
}

// Dialog
IMPLEMENT_DYNAMIC(CDialog, CWnd)
BEGIN_MESSAGE_MAP(CDialog, CWnd)
    ON_MESSAGE(WM_INITDIALOG, &CDialog::HandleInitDialog)
    ON_MESSAGE(WM_CLOSE, &CDialog::HandleClose)
    ON_COMMAND(IDOK, &CDialog::OnOK)
    ON_COMMAND(IDCANCEL, &CDialog::OnCancel)
END_MESSAGE_MAP()

// DefDlgProc turns the close box into Cancel.
LRESULT CDialog::HandleClose(WPARAM, LPARAM) {
    SendMessage(WM_COMMAND, MAKEWPARAM(IDCANCEL, BN_CLICKED), 0);
    return 0;
}

CDialog::CDialog(LPCTSTR lpszTemplateName, CWnd* pParentWnd) {
    m_lpszTemplateName = lpszTemplateName;
}
CDialog::CDialog(UINT nIDTemplate, CWnd* pParentWnd) {
    m_lpszTemplateName = MAKEINTRESOURCE(nIDTemplate);
}

// mptrack's dialogs all use "MS Shell Dlg" 8pt, whose dialog base units at 96 DPI are 6 x 13 pixels.
static constexpr int kDluBaseX = 6, kDluBaseY = 13;
static int DluToPixelsX(int v) { return MulDiv(v, kDluBaseX, 4); }
static int DluToPixelsY(int v) { return MulDiv(v, kDluBaseY, 8); }

static std::wstring Utf8ToWide(const std::string& s) {
    std::wstring w(s.size() + 1, L'\0');
    w.resize(std::max(0, MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), w.data(), (int)w.size())));
    return w;
}

static HFONT DialogFont(const RCDialogDef& def) {
    static std::map<std::pair<std::string, int>, HFONT> cache;
    const std::string face = def.fontName.empty() ? "MS Shell Dlg" : def.fontName;
    const int points = def.fontSize > 0 ? def.fontSize : 8;
    HFONT& font = cache[{face, points}];
    if (!font) {
        LOGFONTW lf{};
        lf.lfHeight = -MulDiv(points, 96, 72);
        lf.lfWeight = FW_NORMAL;
        wcsncpy(lf.lfFaceName, Utf8ToWide(face).c_str(), LF_FACESIZE - 1);
        font = CreateFontIndirectW(&lf);
    }
    return font;
}

static const RCDialogDef* FindDialogTemplate(LPCTSTR lpszTemplateName) {
    if (IS_INTRESOURCE(lpszTemplateName)) return MacResourceManager::Instance().GetDialog((int)(uintptr_t)lpszTemplateName);
    if (!lpszTemplateName) return nullptr;
    return MacResourceManager::Instance().GetDialog(ToStdString(lpszTemplateName).c_str());
}

// Builds a dialog window and its controls from a template, then sends WM_INITDIALOG, like CreateDialogIndirectParam.
static HWND CreateDialogFromTemplate(CWnd* pWnd, const RCDialogDef& def, HWND hParent, LPVOID createParam = nullptr) {
    const DWORD style = def.style ? def.style : (WS_POPUP | WS_CAPTION | WS_SYSMENU);
    HWND hDlg = CreateNativeHWND(pWnd, def.exStyle, L"#32770", Utf8ToWide(def.title).c_str(), style & ~WS_VISIBLE,
                                 DluToPixelsX(def.x), DluToPixelsY(def.y), DluToPixelsX(def.cx), DluToPixelsY(def.cy),
                                 hParent, nullptr, createParam);
    WindowRecord* rec = GetWindowRecord(hDlg);
    if (!rec) return nullptr;
    rec->isDialog = true;
    HFONT font = DialogFont(def);
    rec->font = font;
    HWND firstTabStop = nullptr;
    for (const RCControlDef& ctrl : def.controls) {
        HWND hCtrl = CreateNativeHWND(nullptr, ctrl.exStyle, Utf8ToWide(ctrl.className).c_str(), Utf8ToWide(ctrl.title).c_str(), ctrl.style | WS_CHILD,
                                      DluToPixelsX(ctrl.x), DluToPixelsY(ctrl.y), DluToPixelsX(ctrl.cx), DluToPixelsY(ctrl.cy),
                                      hDlg, (HMENU)(intptr_t)ctrl.id, nullptr);
        if (!hCtrl) continue;
        ::SendMessageW(hCtrl, WM_SETFONT, (WPARAM)font, FALSE);
        for (const std::string& item : ctrl.dlgInitStrings) ::SendMessageW(hCtrl, CB_ADDSTRING, 0, (LPARAM)Utf8ToWide(item).c_str());
        if (!firstTabStop && (ctrl.style & WS_TABSTOP)) firstTabStop = hCtrl;
    }
    if (::SendMessageW(hDlg, WM_INITDIALOG, (WPARAM)firstTabStop, 0) && firstTabStop) ::SetFocus(firstTabStop);
    if (style & DS_CENTER) {
        if (CWnd* w = CWnd::FromHandle(hDlg)) w->CenterWindow();
    }
    if (style & WS_VISIBLE) ::ShowWindow(hDlg, SW_SHOW);
    return hDlg;
}

BOOL CDialog::Create(LPCTSTR lpszTemplateName, CWnd* pParentWnd) {
    const RCDialogDef* def = FindDialogTemplate(lpszTemplateName);
    if (!def) return FALSE;
    if (!m_lpszTemplateName) m_lpszTemplateName = lpszTemplateName;
    return CreateDialogFromTemplate(this, *def, pParentWnd ? pParentWnd->GetSafeHwnd() : nullptr) != nullptr;
}

LRESULT CDialog::HandleInitDialog(WPARAM, LPARAM) {
    return OnInitDialog();
}

BOOL CWnd::UpdateData(BOOL bSaveAndValidate) {
    CDataExchange dx(this, bSaveAndValidate);
    DoDataExchange(&dx);
    return TRUE;
}

BOOL CDialog::CreateIndirect(LPCDLGTEMPLATE lpDialogTemplate, CWnd* pParentWnd, void* lpDialogInit) {
    (void)lpDialogTemplate; (void)lpDialogInit;
    return Create(m_lpszTemplateName, pParentWnd);
}

INT_PTR CDialog::DoModal() {
    Create(m_lpszTemplateName, nullptr);
    CenterWindow();
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (rec && rec->nsWindow) {
        [NSApp runModalForWindow:rec->nsWindow];
    }
    return m_nModalResult;
}

BOOL CDialog::OnInitDialog() {
    UpdateData(FALSE);
    return TRUE;
}

void CDialog::OnOK() {
    CDataExchange dx(this, TRUE);
    DoDataExchange(&dx);
    EndDialog(IDOK);
}

void CDialog::OnCancel() {
    EndDialog(IDCANCEL);
}

void CDialog::EndDialog(int nResult) {
    m_nModalResult = nResult;
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (rec && rec->nsWindow) {
        [NSApp stopModalWithCode:nResult];
    }
    DestroyWindow();
}

// CFileDialog
IMPLEMENT_DYNAMIC(CFileDialog, CCommonDialog)
CFileDialog::CFileDialog(BOOL bOpenFileDialog, LPCTSTR lpszDefExt, LPCTSTR lpszFileName,
                         DWORD dwFlags, LPCTSTR lpszFilter, CWnd* pParentWnd, DWORD dwSize, BOOL bVistaStyle)
    : m_bOpenFileDialog(bOpenFileDialog) {
    (void)dwSize; (void)bVistaStyle;
    m_ofn.Flags = dwFlags;
    if (lpszDefExt) m_strDefExt = lpszDefExt;
    if (lpszFileName) m_strFileName = lpszFileName;
    if (lpszFilter) m_strFilter = lpszFilter;
}

static CString FromNSString(NSString* s) {
    NSData* data = [s dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
    return CString(std::wstring((const wchar_t*)data.bytes, data.length / sizeof(wchar_t)).c_str());
}

INT_PTR CFileDialog::DoModal() {
    NSSavePanel* panel;
    // A file name with a folder (OpenMPT passes full paths) starts the panel in that folder.
    std::wstring name = m_strFileName.GetString(), folder = m_ofn.lpstrInitialDir ? m_ofn.lpstrInitialDir : L"";
    if (const size_t slash = name.rfind(L'/'); slash != std::wstring::npos) {
        if (folder.empty()) folder = name.substr(0, slash);
        name.erase(0, slash + 1);
    }
    if (m_bOpenFileDialog) {
        NSOpenPanel* open = [NSOpenPanel openPanel];
        open.canChooseFiles = !m_bPickFoldersMode;
        open.canChooseDirectories = m_bPickFoldersMode;
        open.canCreateDirectories = m_bPickFoldersMode;
        open.allowsMultipleSelection = !m_bPickFoldersMode && (m_ofn.Flags & OFN_ALLOWMULTISELECT) != 0;
        if (!m_bPickFoldersMode) {
            // Only offer files the caller's filter accepts (OpenMPT passes every format it can load).
            // shortcut: prefix patterns like "mod.*" are not expressible as a UTType, so such files are greyed out; add a panel delegate if users need them.
            NSMutableArray<UTType*>* types = [NSMutableArray array];
            for (const auto& ext : MacFilterExtensions(std::wstring(m_strFilter.GetString()))) {
                if (UTType* type = [UTType typeWithFilenameExtension:ToNSString(ext.c_str())]) [types addObject:type];
            }
            if (types.count > 0) open.allowedContentTypes = types;
        } else if (folder.empty()) {
            folder = m_strFileName.GetString();  // the folder picker is given the current folder as its file name
        }
        panel = open;
    } else {
        panel = [NSSavePanel savePanel];
        if (!name.empty()) panel.nameFieldStringValue = ToNSString(name.c_str());
        // The save panel adds the default extension when the user leaves it out, as OFN's lpstrDefExt does.
        if (!m_strDefExt.IsEmpty()) {
            if (UTType* type = [UTType typeWithFilenameExtension:ToNSString(m_strDefExt.GetString())]) {
                panel.allowedContentTypes = @[type];
                panel.allowsOtherFileTypes = YES;
            }
        }
    }
    if (!folder.empty()) panel.directoryURL = [NSURL fileURLWithPath:ToNSString(folder.c_str()) isDirectory:YES];
    if (m_ofn.lpstrTitle && *m_ofn.lpstrTitle) panel.message = ToNSString(m_ofn.lpstrTitle);
    if ([panel runModal] != NSModalResponseOK) return IDCANCEL;

    m_paths.clear();
    NSArray<NSURL*>* urls = m_bOpenFileDialog ? ((NSOpenPanel*)panel).URLs : @[panel.URL];
    for (NSURL* url in urls) m_paths.push_back(FromNSString(url.path));
    if (m_paths.empty()) return IDCANCEL;
    m_strFileName = m_paths.front();
    return IDOK;
}

CString CFileDialog::GetPathName() const { return m_strFileName; }
CString CFileDialog::GetFileName() const {
    int pos = m_strFileName.ReverseFind('/');
    return (pos >= 0) ? m_strFileName.Mid(pos + 1) : m_strFileName;
}
CString CFileDialog::GetFileExt() const {
    int pos = m_strFileName.ReverseFind('.');
    return (pos >= 0) ? m_strFileName.Mid(pos + 1) : _T("");
}
CString CFileDialog::GetFileTitle() const {
    CString fn = GetFileName();
    int pos = fn.ReverseFind('.');
    return (pos >= 0) ? fn.Left(pos) : fn;
}
// POSITION is the 1-based index of the next path, as an opaque handle.
POSITION CFileDialog::GetStartPosition() const { return m_paths.empty() ? nullptr : (POSITION)(uintptr_t)1; }
CString CFileDialog::GetNextPathName(POSITION& pos) const {
    const size_t i = (uintptr_t)pos - 1;
    if (i >= m_paths.size()) { pos = nullptr; return CString(); }
    pos = (i + 1 < m_paths.size()) ? (POSITION)(uintptr_t)(i + 2) : nullptr;
    return m_paths[i];
}

// CColorDialog
IMPLEMENT_DYNAMIC(CColorDialog, CCommonDialog)
CColorDialog::CColorDialog(COLORREF clrInit, DWORD dwFlags, CWnd* pParentWnd) {
    m_cc.rgbResult = clrInit;
}
INT_PTR CColorDialog::DoModal() {
    NSColorPanel* panel = [NSColorPanel sharedColorPanel];
    CGFloat r = GetRValue(m_cc.rgbResult) / 255.0f;
    CGFloat g = GetGValue(m_cc.rgbResult) / 255.0f;
    CGFloat b = GetBValue(m_cc.rgbResult) / 255.0f;
    panel.color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0f];
    [NSApp runModalForWindow:panel];
    NSColor* c = [panel.color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    m_cc.rgbResult = RGB((int)(c.redComponent * 255), (int)(c.greenComponent * 255), (int)(c.blueComponent * 255));
    return IDOK;
}

// CFontDialog
IMPLEMENT_DYNAMIC(CFontDialog, CCommonDialog)
CFontDialog::CFontDialog(LPLOGFONT lplfInitial, DWORD dwFlags, CDC* pdcPrinter, CWnd* pParentWnd) {
    if (lplfInitial) m_lf = *lplfInitial;
}
INT_PTR CFontDialog::DoModal() {
    NSFontPanel* panel = [NSFontPanel sharedFontPanel];
    [NSApp runModalForWindow:panel];
    return IDOK;
}

// CTaskDialog
INT_PTR CTaskDialog::DoModal(CWnd* pParent) {
    (void)pParent;
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = ToNSString(m_strMainInstruction.GetString());
    alert.informativeText = ToNSString(m_strContent.GetString());

    if (!m_commandControls.empty()) {
        for (const auto& cmd : m_commandControls) {
            [alert addButtonWithTitle:ToNSString(cmd.text.GetString())];
        }
    } else {
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
    }
    NSModalResponse resp = [alert runModal];
    m_nSelectedCommandControl = (int)(resp - NSAlertFirstButtonReturn);
    return IDOK;
}

// CDataExchange & DDX helpers
HWND CDataExchange::PrepareCtrl(int nIDC) {
    return m_pDlgWnd ? ::GetDlgItem(m_pDlgWnd->GetSafeHwnd(), nIDC) : nullptr;
}
void AFXAPI DDX_Control(CDataExchange* pDX, int nIDC, CWnd& rControl) {
    if (rControl.m_hWnd == nullptr && pDX->m_pDlgWnd) {
        HWND hWndCtrl = pDX->PrepareCtrl(nIDC);
        if (hWndCtrl) rControl.SubclassWindow(hWndCtrl);
    }
}
void AFXAPI DDX_Text(CDataExchange* pDX, int nIDC, CString& value) {
    if (pDX->m_bSaveAndValidate) {
        pDX->m_pDlgWnd->GetDlgItemText(nIDC, value);
    } else {
        pDX->m_pDlgWnd->SetDlgItemText(nIDC, value);
    }
}
void AFXAPI DDX_Text(CDataExchange* pDX, int nIDC, int& value) {
    if (pDX->m_bSaveAndValidate) {
        value = (int)pDX->m_pDlgWnd->GetDlgItemInt(nIDC, nullptr, TRUE);
    } else {
        pDX->m_pDlgWnd->SetDlgItemInt(nIDC, (UINT)value, TRUE);
    }
}
void AFXAPI DDX_Text(CDataExchange* pDX, int nIDC, UINT& value) {
    if (pDX->m_bSaveAndValidate) {
        value = pDX->m_pDlgWnd->GetDlgItemInt(nIDC, nullptr, FALSE);
    } else {
        pDX->m_pDlgWnd->SetDlgItemInt(nIDC, value, FALSE);
    }
}
void AFXAPI DDX_Check(CDataExchange* pDX, int nIDC, int& value) {
    if (pDX->m_bSaveAndValidate) {
        value = (int)pDX->m_pDlgWnd->IsDlgButtonChecked(nIDC);
    } else {
        pDX->m_pDlgWnd->CheckDlgButton(nIDC, (UINT)value);
    }
}

// CDC paint helpers
CPaintDC::CPaintDC(CWnd* pWnd) {
    m_hWnd = pWnd ? pWnd->GetSafeHwnd() : nullptr;
    m_hDC = ::BeginPaint(m_hWnd, &m_ps);
}
CPaintDC::~CPaintDC() {
    ::EndPaint(m_hWnd, &m_ps);
    Detach();
}
CClientDC::CClientDC(CWnd* pWnd) {
    m_hWnd = pWnd ? pWnd->GetSafeHwnd() : nullptr;
    m_hDC = ::GetDC(m_hWnd);
}
CClientDC::~CClientDC() {
    ::ReleaseDC(m_hWnd, Detach());
}
CWindowDC::CWindowDC(CWnd* pWnd) {
    m_hWnd = pWnd ? pWnd->GetSafeHwnd() : nullptr;
    m_hDC = ::GetWindowDC(m_hWnd);
}
CWindowDC::~CWindowDC() {
    ::ReleaseDC(m_hWnd, Detach());
}

// Frame & View Implementation
IMPLEMENT_DYNCREATE(CFrameWnd, CWnd)
const CRect CFrameWnd::rectDefault(CW_USEDEFAULT, CW_USEDEFAULT, 800, 600);
BEGIN_MESSAGE_MAP(CFrameWnd, CWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
END_MESSAGE_MAP()

// As in MFC, the client area (views or the MDI client) is built while handling WM_CREATE.
int CFrameWnd::OnCreate(LPCREATESTRUCT lpCreateStruct) {
    CCreateContext* pContext = lpCreateStruct ? static_cast<CCreateContext*>(lpCreateStruct->lpCreateParams) : nullptr;
    return OnCreateClient(lpCreateStruct, pContext) ? 0 : -1;
}

BOOL CFrameWnd::LoadFrame(UINT nIDResource, DWORD dwDefaultStyle, CWnd* pParentWnd, CCreateContext* pContext) {
    // Like MFC: the frame's title, menu and icon all come from the nIDResource resources.
    CString title = _T("OpenMPT");
    std::string resTitle = MacResourceManager::Instance().GetString((int)nIDResource);
    if (!resTitle.empty()) title = CString(resTitle.substr(0, resTitle.find('\n')).c_str());
    if (!Create(nullptr, title, dwDefaultStyle, rectDefault, pParentWnd, nullptr, 0, pContext)) return FALSE;
    if (HMENU menu = ::LoadMenuW(AfxGetResourceHandle(), MAKEINTRESOURCE(nIDResource))) {
        ::SetMenu(m_hWnd, menu);
    }
    return TRUE;
}
BOOL CFrameWnd::Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle,
                       const RECT& rect, CWnd* pParentWnd, LPCTSTR lpszMenuName,
                       DWORD dwExStyle, CCreateContext* pContext) {
    return CreateEx(dwExStyle, lpszClassName, lpszWindowName, dwStyle, rect, pParentWnd, 0, pContext);
}
BOOL CFrameWnd::OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext) {
    if (pContext && pContext->m_pNewViewClass) {
        CreateView(pContext);
    }
    return TRUE;
}
CWnd* CFrameWnd::CreateView(CCreateContext* pContext, UINT nID) {
    if (!pContext || !pContext->m_pNewViewClass) return nullptr;
    CView* pView = (CView*)pContext->m_pNewViewClass->CreateObject();
    if (!pView) return nullptr;
    CRect rect;
    GetClientRect(&rect);
    pView->Create(nullptr, nullptr, WS_CHILD | WS_VISIBLE, rect, this, nID, pContext);
    SetActiveView(pView);
    return pView;
}
CDocument* CFrameWnd::GetActiveDocument() {
    return m_pViewActive ? m_pViewActive->GetDocument() : nullptr;
}
void CFrameWnd::SetActiveView(CView* pViewNew, BOOL bNotify) {
    m_pViewActive = pViewNew;
    if (pViewNew && bNotify) pViewNew->OnActivateView(TRUE, pViewNew, nullptr);
}
void CFrameWnd::RecalcLayout(BOOL bNotify) {
    (void)bNotify;
    RepositionBars(0, 0xFFFF, AFX_IDW_PANE_FIRST);
}
void CMDIFrameWnd::RecalcLayout(BOOL bNotify) {
    (void)bNotify;
    CRect rect;
    RepositionBars(0, 0xFFFF, 0xFFFF, reposDefault, &rect);
    if (m_hWndMDIClient) ::MoveWindow(m_hWndMDIClient, rect.left, rect.top, rect.Width(), rect.Height(), TRUE);
}
void CFrameWnd::OnSize(UINT nType, int cx, int cy) {
    (void)cx; (void)cy;
    if (nType != SIZE_MINIMIZED) RecalcLayout();
}
// MFC routing: active view (and its document), then the frame itself, then the application.
BOOL CFrameWnd::OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) {
    if (m_pViewActive && m_pViewActive->OnCmdMsg(nID, nCode, pExtra, pHandlerInfo)) return TRUE;
    if (CWnd::OnCmdMsg(nID, nCode, pExtra, pHandlerInfo)) return TRUE;
    CWinApp* app = AfxGetApp();
    return app && app->OnCmdMsg(nID, nCode, pExtra, pHandlerInfo);
}
BOOL CMDIFrameWnd::OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) {
    if (CMDIChildWnd* child = MDIGetActive(); child && child->OnCmdMsg(nID, nCode, pExtra, pHandlerInfo)) return TRUE;
    return CFrameWnd::OnCmdMsg(nID, nCode, pExtra, pHandlerInfo);
}
BOOL CView::OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) {
    if (CWnd::OnCmdMsg(nID, nCode, pExtra, pHandlerInfo)) return TRUE;
    return m_pDocument && m_pDocument->OnCmdMsg(nID, nCode, pExtra, pHandlerInfo);
}
BOOL CDocument::OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) {
    return CCmdTarget::OnCmdMsg(nID, nCode, pExtra, pHandlerInfo);
}
void CFrameWnd::ActivateFrame(int nCmdShow) {
    ShowWindow(nCmdShow >= 0 ? nCmdShow : SW_SHOWNORMAL);
}
void CFrameWnd::InitialUpdateFrame(CDocument* pDoc, BOOL bMakeVisible) {
    (void)pDoc;
    if (!m_pViewActive) {
        if (auto* view = dynamic_cast<CView*>(GetDescendantWindow(AFX_IDW_PANE_FIRST, TRUE))) SetActiveView(view, FALSE);
    }
    SendMessageToDescendants(WM_INITIALUPDATE, 0, 0, TRUE, TRUE);
    if (bMakeVisible) {
        ActivateFrame();
        if (m_pViewActive) m_pViewActive->OnActivateView(TRUE, m_pViewActive, m_pViewActive);
    }
}

CWnd* CWnd::GetDescendantWindow(int nID, BOOL bOnlyPerm) const {
    WindowRecord* rec = GetWindowRecord(m_hWnd);
    if (!rec) return nullptr;
    // As in MFC: direct children first; one with the ID defers to its own same-ID child (splitter -> first pane).
    for (HWND child : rec->children) {
        WindowRecord* c = GetWindowRecord(child);
        if (!c || (int)c->id != nID) continue;
        if (CWnd* inner = CWnd::FromHandle(child)->GetDescendantWindow(nID, bOnlyPerm)) return inner;
        if (!bOnlyPerm || c->pWnd) return CWnd::FromHandle(child);
    }
    for (HWND child : rec->children) {
        if (CWnd* found = CWnd::FromHandle(child)->GetDescendantWindow(nID, bOnlyPerm)) return found;
    }
    return nullptr;
}
void CFrameWnd::OnUpdateFrameTitle(BOOL bAddToTitle) {}
void CFrameWnd::DockControlBar(CControlBar* pBar, UINT nDockBarID, LPCRECT lpRect) {}
void CFrameWnd::ShowControlBar(CControlBar* pBar, BOOL bShow, BOOL bDelay) {}
CControlBar* CFrameWnd::GetControlBar(UINT nID) { return nullptr; }
CWnd* CFrameWnd::GetMessageBar() { return nullptr; }
void CFrameWnd::SetMessageText(LPCTSTR lpszText) {}
void CFrameWnd::SetMessageText(UINT nID) {}
BOOL CFrameWnd::OnBarCheck(UINT nID) { return TRUE; }
void CFrameWnd::OnUpdateControlBarMenu(CCmdUI* pCmdUI) {}

// CMDIFrameWnd
IMPLEMENT_DYNCREATE(CMDIFrameWnd, CFrameWnd)
BEGIN_MESSAGE_MAP(CMDIFrameWnd, CFrameWnd)
END_MESSAGE_MAP()

BOOL CMDIFrameWnd::CreateClient(LPCREATESTRUCT lpCreateStruct, CMenu* pWindowMenu) {
    m_hWndMDIClient = CreateNativeHWND(nullptr, 0, _T("MDICLIENT"), nullptr, WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN,
                                      0, 0, 800, 600, m_hWnd, nullptr, nullptr);
    return m_hWndMDIClient != nullptr;
}
CMDIChildWnd* CMDIFrameWnd::MDIGetActive(BOOL* pbMaximized) const {
    if (pbMaximized) *pbMaximized = m_pActiveChild ? m_pActiveChild->m_bMaximized : FALSE;
    return m_pActiveChild;
}
void CMDIFrameWnd::MDIActivate(CWnd* pWndActivate) {
    CMDIChildWnd* next = dynamic_cast<CMDIChildWnd*>(pWndActivate);
    CMDIChildWnd* old = m_pActiveChild;
    if (next == old) return;
    m_pActiveChild = next;
    HWND hOld = old ? old->GetSafeHwnd() : nullptr, hNew = next ? next->GetSafeHwnd() : nullptr;
    if (hNew) ::SetWindowPos(hNew, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    // WM_MDIACTIVATE: wParam = window losing activation, lParam = window gaining it.
    if (hOld && ::IsWindow(hOld)) ::SendMessageW(hOld, WM_MDIACTIVATE, (WPARAM)hOld, (LPARAM)hNew);
    if (hNew) {
        ::SendMessageW(hNew, WM_MDIACTIVATE, (WPARAM)hOld, (LPARAM)hNew);
        if (CView* view = next->GetActiveView()) view->SetFocus();
    }
    OnUpdateFrameTitle(TRUE);
}
void CFrameWnd::SwitchToActiveView() {
    if (m_pViewActive) m_pViewActive->SetFocus();
}
void CMDIFrameWnd::MDINext() {
    if (m_children.empty()) return;
    auto it = std::find(m_children.begin(), m_children.end(), m_pActiveChild);
    if (it != m_children.end() && ++it != m_children.end()) MDIActivate(*it);
    else MDIActivate(m_children.front());
}
void CMDIFrameWnd::MDIPrev() {
    if (m_children.empty()) return;
    auto it = std::find(m_children.begin(), m_children.end(), m_pActiveChild);
    if (it != m_children.end() && it != m_children.begin()) MDIActivate(*(--it));
    else MDIActivate(m_children.back());
}
void CMDIFrameWnd::MDIMaximize(CWnd* pWnd) {
    if (pWnd) {
        ((CMDIChildWnd*)pWnd)->m_bMaximized = TRUE;
        MDIActivate(pWnd);
    }
}
void CMDIFrameWnd::MDIRestore(CWnd* pWnd) {
    if (pWnd) ((CMDIChildWnd*)pWnd)->m_bMaximized = FALSE;
}
CFrameWnd* CMDIFrameWnd::GetActiveFrame() {
    return m_pActiveChild ? (CFrameWnd*)m_pActiveChild : (CFrameWnd*)this;
}

// CMDIChildWnd
IMPLEMENT_DYNCREATE(CMDIChildWnd, CFrameWnd)
BEGIN_MESSAGE_MAP(CMDIChildWnd, CFrameWnd)
    ON_WM_MDIACTIVATE()
END_MESSAGE_MAP()

CMDIChildWnd::~CMDIChildWnd() {
    if (m_pMDIFrame) {
        auto it = std::find(m_pMDIFrame->m_children.begin(), m_pMDIFrame->m_children.end(), this);
        if (it != m_pMDIFrame->m_children.end()) m_pMDIFrame->m_children.erase(it);
        if (m_pMDIFrame->m_pActiveChild == this) {
            m_pMDIFrame->m_pActiveChild = m_pMDIFrame->m_children.empty() ? nullptr : m_pMDIFrame->m_children.back();
        }
    }
}
BOOL CMDIChildWnd::Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle,
                          const RECT& rect, CMDIFrameWnd* pParentWnd, CCreateContext* pContext) {
    m_pMDIFrame = pParentWnd;
    HWND hParent = pParentWnd ? pParentWnd->m_hWndMDIClient : nullptr;
    // shortcut: MDI children are always shown maximized (no in-client captions); add restored MDI windows if needed.
    RECT client{0, 0, 0, 0};
    if (hParent) ::GetClientRect(hParent, &client);
    m_bMaximized = TRUE;
    BOOL res = CreateEx(0, lpszClassName, lpszWindowName, (dwStyle | WS_CHILD | WS_CLIPSIBLINGS) & ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME), 0, 0,
                        client.right, client.bottom, hParent, nullptr, pContext);
    if (res && pParentWnd) pParentWnd->m_children.push_back(this);
    return res;
}
// As in MFC: document frames are MDI children of the main frame, titled from the resource string.
BOOL CMDIChildWnd::LoadFrame(UINT nIDResource, DWORD dwDefaultStyle, CWnd* pParentWnd, CCreateContext* pContext) {
    auto* mdiFrame = dynamic_cast<CMDIFrameWnd*>(pParentWnd ? pParentWnd : AfxGetMainWnd());
    CString title;
    const std::string resTitle = MacResourceManager::Instance().GetString((int)nIDResource);
    if (!resTitle.empty()) title = CString(resTitle.substr(0, resTitle.find('\n')).c_str());
    return Create(nullptr, title, dwDefaultStyle, rectDefault, mdiFrame, pContext);
}
CMDIFrameWnd* CMDIChildWnd::GetMDIFrame() { return m_pMDIFrame; }
void CMDIChildWnd::MDIDestroy() { DestroyWindow(); }
void CMDIChildWnd::MDIActivate() { if (m_pMDIFrame) m_pMDIFrame->MDIActivate(this); }
void CMDIChildWnd::MDIMaximize() { if (m_pMDIFrame) m_pMDIFrame->MDIMaximize(this); }
void CMDIChildWnd::MDIRestore() { if (m_pMDIFrame) m_pMDIFrame->MDIRestore(this); }
void CMDIChildWnd::ActivateFrame(int nCmdShow) {
    ShowWindow(nCmdShow >= 0 ? nCmdShow : SW_SHOWNORMAL);
    MDIActivate();
}

// CView
IMPLEMENT_DYNAMIC(CView, CWnd)
BEGIN_MESSAGE_MAP(CView, CWnd)
    ON_WM_PAINT()
    ON_WM_CREATE()
    ON_MESSAGE(WM_INITIALUPDATE, &CView::OnInitialUpdateMessage)
END_MESSAGE_MAP()

LRESULT CView::OnInitialUpdateMessage(WPARAM, LPARAM) {
    OnInitialUpdate();
    return 0;
}

int CView::OnCreate(LPCREATESTRUCT lpcs) {
    auto* context = lpcs ? static_cast<CCreateContext*>(lpcs->lpCreateParams) : nullptr;
    if (context && context->m_pCurrentDoc && !m_pDocument) context->m_pCurrentDoc->AddView(this);
    return 0;
}

CView::~CView() {
    if (m_pDocument) m_pDocument->RemoveView(this);
    // MFC clears this in CView::OnDestroy; here the view may outlive its window, so clear it on deletion.
    for (HWND h : GetAllWindowHandles())
        if (WindowRecord* rec = GetWindowRecord(h); rec && rec->pWnd)
            if (auto* frame = dynamic_cast<CFrameWnd*>(rec->pWnd); frame && frame->GetActiveView() == this) frame->SetActiveView(nullptr, FALSE);
}
void CView::OnInitialUpdate() { OnUpdate(nullptr, 0, nullptr); }
void CView::OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) { Invalidate(TRUE); }
void CView::OnPaint() {
    CPaintDC dc(this);
    OnDraw(&dc);
}

// CScrollView
IMPLEMENT_DYNAMIC(CScrollView, CView)
BEGIN_MESSAGE_MAP(CScrollView, CView)
    ON_WM_SIZE()
    ON_WM_HSCROLL()
    ON_WM_VSCROLL()
    ON_WM_MOUSEWHEEL()
END_MESSAGE_MAP()

void CScrollView::SetScrollSizes(int nMapMode, SIZE sizeTotal, const SIZE& sizePage, const SIZE& sizeLine) {
    m_nMapMode = nMapMode;
    m_totalLog = sizeTotal;
    m_totalDev = sizeTotal;
    m_pageDev = (sizePage.cx == 0 && sizePage.cy == 0) ? CSize(sizeTotal.cx / 10, sizeTotal.cy / 10) : sizePage;
    m_lineDev = (sizeLine.cx == 0 && sizeLine.cy == 0) ? CSize(sizeTotal.cx / 100, sizeTotal.cy / 100) : sizeLine;
    UpdateBars();
}
// As in MFC: the scroll page is the client size, and a bar (WS_VSCROLL / WS_HSCROLL) exists only while the content is larger.
// Views such as CViewPattern::OnScrollBy refuse to scroll along an axis without its style bit.
// shortcut: the bars are not drawn, so there is no thumb to drag; draw them if users need mouse-driven scrolling beyond the wheel.
void CScrollView::UpdateBars() {
    if (!m_hWnd) return;
    CRect client;
    GetClientRect(&client);
    const bool needV = m_totalDev.cy > client.Height(), needH = m_totalDev.cx > client.Width();
    SCROLLINFO si{};
    si.fMask = SIF_RANGE | SIF_PAGE;
    si.nMin = 0;
    si.nMax = std::max(0, (int)m_totalDev.cy - 1); si.nPage = (UINT)std::max(0, (int)client.Height());
    SetScrollInfo(SB_VERT, &si);
    si.nMax = std::max(0, (int)m_totalDev.cx - 1); si.nPage = (UINT)std::max(0, (int)client.Width());
    SetScrollInfo(SB_HORZ, &si);
    if (!needV) SetScrollPos(SB_VERT, 0);
    if (!needH) SetScrollPos(SB_HORZ, 0);
    const DWORD style = (GetStyle() & ~(WS_VSCROLL | WS_HSCROLL)) | (needV ? WS_VSCROLL : 0) | (needH ? WS_HSCROLL : 0);
    if (style != GetStyle()) ::SetWindowLongPtr(m_hWnd, GWL_STYLE, style);  // not ModifyStyle: its SetWindowPos would re-enter OnSize
}
CPoint CScrollView::GetScrollPosition() const {
    return CPoint(GetScrollPos(SB_HORZ), GetScrollPos(SB_VERT));
}
void CScrollView::ScrollToPosition(POINT pt) {
    SetScrollPos(SB_HORZ, pt.x);
    SetScrollPos(SB_VERT, pt.y);
    Invalidate();
}
void CScrollView::OnPrepareDC(CDC* pDC, CPrintInfo* pInfo) {
    (void)pInfo;
    CPoint pt = GetScrollPosition();
    pDC->SetViewportOrg(-pt.x, -pt.y);
}
BOOL CScrollView::OnScroll(UINT nScrollCode, UINT nPos, BOOL bDoScroll) {
    return TRUE;
}
BOOL CScrollView::OnScrollBy(CSize sizeScroll, BOOL bDoScroll) {
    ScrollToPosition(GetScrollPosition() + sizeScroll);
    return TRUE;
}
void CScrollView::OnSize(UINT nType, int cx, int cy) {
    CView::OnSize(nType, cx, cy);
    UpdateBars();
}
void CScrollView::OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) {
    int cur = GetScrollPos(SB_HORZ);
    if (nSBCode == SB_LINELEFT) cur -= m_lineDev.cx;
    else if (nSBCode == SB_LINERIGHT) cur += m_lineDev.cx;
    else if (nSBCode == SB_PAGELEFT) cur -= m_pageDev.cx;
    else if (nSBCode == SB_PAGERIGHT) cur += m_pageDev.cx;
    else if (nSBCode == SB_THUMBTRACK || nSBCode == SB_THUMBPOSITION) cur = nPos;
    SetScrollPos(SB_HORZ, cur);
    Invalidate();
}
void CScrollView::OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) {
    int cur = GetScrollPos(SB_VERT);
    if (nSBCode == SB_LINEUP) cur -= m_lineDev.cy;
    else if (nSBCode == SB_LINEDOWN) cur += m_lineDev.cy;
    else if (nSBCode == SB_PAGEUP) cur -= m_pageDev.cy;
    else if (nSBCode == SB_PAGEDOWN) cur += m_pageDev.cy;
    else if (nSBCode == SB_THUMBTRACK || nSBCode == SB_THUMBPOSITION) cur = nPos;
    SetScrollPos(SB_VERT, cur);
    Invalidate();
}
BOOL CScrollView::OnMouseWheel(UINT nFlags, short zDelta, CPoint pt) {
    return DoMouseWheel(nFlags, zDelta, pt);
}
// MFC's implementation: three lines per notch (capped at a page) on the vertical bar, else the horizontal one.
BOOL CScrollView::DoMouseWheel(UINT fFlags, short zDelta, CPoint point) {
    (void)fFlags; (void)point;
    const bool hasV = (GetStyle() & WS_VSCROLL) != 0, hasH = (GetStyle() & WS_HSCROLL) != 0;
    if (!hasV && !hasH) return FALSE;
    const int toScroll = MulDiv(-zDelta, 3, WHEEL_DELTA);
    BOOL result;
    if (hasV) {
        int d = toScroll * m_lineDev.cy;
        d = std::clamp(d, -(int)m_pageDev.cy, (int)m_pageDev.cy);
        result = OnScrollBy(CSize(0, d), TRUE);
    } else {
        int d = toScroll * m_lineDev.cx;
        d = std::clamp(d, -(int)m_pageDev.cx, (int)m_pageDev.cx);
        result = OnScrollBy(CSize(d, 0), TRUE);
    }
    if (result) UpdateWindow();
    return result;
}

// CDocument
IMPLEMENT_DYNAMIC(CDocument, CCmdTarget)
BEGIN_MESSAGE_MAP(CDocument, CCmdTarget)
    ON_COMMAND(ID_FILE_CLOSE, &CDocument::OnFileClose)
    ON_COMMAND(ID_FILE_SAVE, &CDocument::OnFileSave)
    ON_COMMAND(ID_FILE_SAVE_AS, &CDocument::OnFileSaveAs)
END_MESSAGE_MAP()

void CDocument::SetTitle(LPCTSTR lpszTitle) { m_strTitle = lpszTitle ? lpszTitle : _T(""); }
void CDocument::SetPathName(LPCTSTR lpszPathName, BOOL bAddToMRU) {
    m_strPathName = lpszPathName ? lpszPathName : _T("");
    if (bAddToMRU && AfxGetApp()) AfxGetApp()->AddToRecentFileList(lpszPathName);
}
void CDocument::AddView(CView* pView) {
    if (pView) {
        m_viewList.push_back(pView);
        pView->m_pDocument = this;
    }
}
void CDocument::RemoveView(CView* pView) {
    auto it = std::find(m_viewList.begin(), m_viewList.end(), pView);
    if (it != m_viewList.end()) m_viewList.erase(it);
}
POSITION CDocument::GetFirstViewPosition() const {
    return m_viewList.empty() ? nullptr : (POSITION)(uintptr_t)1;
}
CView* CDocument::GetNextView(POSITION& rPosition) const {
    uintptr_t idx = (uintptr_t)rPosition;
    if (idx == 0 || idx > m_viewList.size()) { rPosition = nullptr; return nullptr; }
    CView* v = m_viewList[idx - 1];
    rPosition = (idx < m_viewList.size()) ? (POSITION)(idx + 1) : nullptr;
    return v;
}
void CDocument::UpdateAllViews(CView* pSender, LPARAM lHint, CObject* pHint) {
    for (auto* v : m_viewList) {
        if (v != pSender) v->OnUpdate(pSender, lHint, pHint);
    }
}
BOOL CDocument::OnNewDocument() { DeleteContents(); SetModifiedFlag(FALSE); return TRUE; }
BOOL CDocument::OnOpenDocument(LPCTSTR lpszPathName) { SetPathName(lpszPathName); SetModifiedFlag(FALSE); return TRUE; }
BOOL CDocument::OnSaveDocument(LPCTSTR lpszPathName) { SetModifiedFlag(FALSE); return TRUE; }
void CDocument::OnCloseDocument() {
    if (m_pDocTemplate) m_pDocTemplate->RemoveDocument(this);
    if (m_bAutoDelete) delete this;
}
BOOL CDocument::SaveModified() {
    if (!IsModified()) return TRUE;
    int res = AfxMessageBox(_T("Save changes to document?"), MB_YESNOCANCEL);
    if (res == IDYES) return DoFileSave();
    if (res == IDNO) return TRUE;
    return FALSE;
}
BOOL CDocument::DoSave(LPCTSTR lpszPathName, BOOL bReplace) {
    CString path = lpszPathName ? CString(lpszPathName) : m_strPathName;
    if (path.IsEmpty()) {
        CFileDialog dlg(FALSE, _T("mptm"), nullptr, OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT);
        if (dlg.DoModal() != IDOK) return FALSE;
        path = dlg.GetPathName();
    }
    return OnSaveDocument(path);
}
BOOL CDocument::DoFileSave() { return DoSave(m_strPathName, TRUE); }
void CDocument::OnFileClose() { OnCloseDocument(); }
void CDocument::OnFileSave() { DoFileSave(); }
void CDocument::OnFileSaveAs() { DoSave(nullptr, TRUE); }

// CDocTemplate & CMultiDocTemplate
IMPLEMENT_DYNAMIC(CDocTemplate, CCmdTarget)
IMPLEMENT_DYNAMIC(CMultiDocTemplate, CDocTemplate)

void CDocTemplate::AddDocument(CDocument* pDoc) {
    if (pDoc) {
        m_docList.push_back(pDoc);
        pDoc->m_pDocTemplate = this;
    }
}
void CDocTemplate::RemoveDocument(CDocument* pDoc) {
    auto it = std::find(m_docList.begin(), m_docList.end(), pDoc);
    if (it != m_docList.end()) m_docList.erase(it);
}
POSITION CDocTemplate::GetFirstDocPosition() const {
    return m_docList.empty() ? nullptr : (POSITION)(uintptr_t)1;
}
CDocument* CDocTemplate::GetNextDoc(POSITION& rPos) const {
    uintptr_t idx = (uintptr_t)rPos;
    if (idx == 0 || idx > m_docList.size()) { rPos = nullptr; return nullptr; }
    CDocument* doc = m_docList[idx - 1];
    rPos = (idx < m_docList.size()) ? (POSITION)(idx + 1) : nullptr;
    return doc;
}
CDocTemplate::Confidence CDocTemplate::MatchDocType(LPCTSTR lpszPathName, CDocument*& rpDocMatch) {
    rpDocMatch = nullptr;
    return yesAttemptNative;
}
CDocument* CDocTemplate::CreateNewDocument() {
    return m_pDocClass ? (CDocument*)m_pDocClass->CreateObject() : nullptr;
}
CFrameWnd* CDocTemplate::CreateNewFrame(CDocument* pDoc, CFrameWnd* pOther) {
    CCreateContext ctx{};
    ctx.m_pCurrentDoc = pDoc;
    ctx.m_pNewDocTemplate = this;
    ctx.m_pNewViewClass = m_pViewClass;
    ctx.m_pCurrentFrame = pOther;
    CFrameWnd* pFrame = m_pFrameClass ? (CFrameWnd*)m_pFrameClass->CreateObject() : nullptr;
    if (pFrame) pFrame->LoadFrame(m_nIDResource, WS_OVERLAPPEDWINDOW, nullptr, &ctx);
    return pFrame;
}
void CDocTemplate::InitialUpdateFrame(CFrameWnd* pFrame, CDocument* pDoc, BOOL bMakeVisible) {
    if (pFrame) pFrame->InitialUpdateFrame(pDoc, bMakeVisible);
}
BOOL CDocTemplate::GetDocString(CString& rString, enum DocStringIndex index) const {
    return rString.LoadString(m_nIDResource);
}
void CDocTemplate::CloseAllDocuments(BOOL bEndSession) {
    for (auto* doc : m_docList) doc->OnCloseDocument();
}
BOOL CDocTemplate::SaveAllModified() {
    for (auto* doc : m_docList) if (!doc->SaveModified()) return FALSE;
    return TRUE;
}

CDocument* CMultiDocTemplate::OpenDocumentFile(LPCTSTR lpszPathName, BOOL bMakeVisible) {
    CDocument* pDoc = CreateNewDocument();
    if (!pDoc) return nullptr;
    AddDocument(pDoc);
    CFrameWnd* pFrame = CreateNewFrame(pDoc, nullptr);
    if (!pFrame) return nullptr;
    // As in MFC: a document that fails to open or initialise takes its new frame down with it.
    const BOOL ok = lpszPathName ? pDoc->OnOpenDocument(lpszPathName) : pDoc->OnNewDocument();
    if (!ok) {
        pFrame->DestroyWindow();
        // shortcut: the document object is leaked because views may still point at it; delete it once views are destroyed with their frames.
        RemoveDocument(pDoc);
        return nullptr;
    }
    if (lpszPathName) pDoc->SetPathName(lpszPathName);
    InitialUpdateFrame(pFrame, pDoc, bMakeVisible);
    return pDoc;
}
void CMultiDocTemplate::SetDefaultTitle(CDocument* pDocument) {
    if (pDocument) pDocument->SetTitle(_T("Untitled"));
}

// CCommandLineInfo
void CCommandLineInfo::ParseParam(const TCHAR* pszParam, BOOL bFlag, BOOL bLast) {
    if (bFlag) {
        if (_tcscmp(pszParam, _T("Embedding")) == 0) m_bRunEmbedded = TRUE;
        else if (_tcscmp(pszParam, _T("Automation")) == 0) m_bRunAutomated = TRUE;
        else if (_tcscmp(pszParam, _T("UnregServer")) == 0) m_nShellCommand = AppUnregister;
        else if (_tcscmp(pszParam, _T("RegServer")) == 0) m_nShellCommand = AppRegister;
    } else {
        m_strFileName = pszParam;
        m_nShellCommand = FileOpen;
    }
}

// CWinThread
IMPLEMENT_DYNAMIC(CWinThread, CCmdTarget)
int CWinThread::Run() {
    while (PumpMessage()) {}
    return ExitInstance();
}
BOOL CWinThread::PumpMessage() {
    MSG msg{};
    if (!GetMessage(&msg, nullptr, 0, 0)) return FALSE;
    if (!PreTranslateMessage(&msg)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return TRUE;
}
// MFC's WalkPreTranslateTree: the target window and each parent, stopping at the main window.
BOOL CWinThread::PreTranslateMessage(MSG* pMsg) {
    HWND stop = m_pMainWnd ? m_pMainWnd->m_hWnd : nullptr;
    for (HWND h = pMsg->hwnd; h; ) {
        if (CWnd* w = CWnd::FromHandlePermanent(h); w && w->PreTranslateMessage(pMsg)) return TRUE;
        if (h == stop) return FALSE;
        WindowRecord* rec = GetWindowRecord(h);
        h = rec ? rec->parent : nullptr;
    }
    return (m_pMainWnd) ? m_pMainWnd->PreTranslateMessage(pMsg) : FALSE;
}
// First idle pass refreshes toolbar buttons and status panes through ON_UPDATE_COMMAND_UI, as MFC does.
BOOL CWinThread::OnIdle(LONG lCount) {
    if (lCount <= 0) {
        if (auto* frame = dynamic_cast<CFrameWnd*>(m_pMainWnd)) {
            if (WindowRecord* rec = GetWindowRecord(frame->m_hWnd)) {
                const std::vector<HWND> children = rec->children;
                for (HWND child : children) {
                    WindowRecord* c = GetWindowRecord(child);
                    if (auto* bar = c ? dynamic_cast<CControlBar*>(c->pWnd) : nullptr; bar && c->isVisible)
                        bar->OnUpdateCmdUI(frame, TRUE);
                }
            }
        }
    }
    return lCount <= 0;
}
BOOL CWinThread::IsIdleMessage(MSG* pMsg) { return TRUE; }

// CCmdUI
void CCmdUI::Enable(BOOL bOn) {
    m_bEnableChanged = TRUE;
    if (m_pOther) m_pOther->EnableWindow(bOn);
}
void CCmdUI::SetCheck(int nCheck) {
    if (m_pOther) ((CButton*)m_pOther)->SetCheck(nCheck);
}
void CCmdUI::SetRadio(BOOL bOn) {
    SetCheck(bOn ? 1 : 0);
}
void CCmdUI::SetText(LPCTSTR lpszText) {
    if (m_pOther) m_pOther->SetWindowText(lpszText);
}
void CCmdUI::DoUpdate(CCmdTarget* pTarget, BOOL bDisableIfNoHndler) {
    if (m_nID == 0 || !pTarget) return;
    m_bEnableChanged = FALSE;
    const BOOL handled = pTarget->OnCmdMsg(m_nID, CN_UPDATE_COMMAND_UI, this, nullptr);
    // Like MFC: commands with no update handler and no command handler show up disabled.
    if (bDisableIfNoHndler && !handled && !m_bEnableChanged) {
        int dummy = 0;
        Enable(pTarget->OnCmdMsg(m_nID, CN_COMMAND, this, &dummy));
    }
}

// CCmdTarget
IMPLEMENT_DYNAMIC(CCmdTarget, CObject)
const AFX_MSGMAP* CCmdTarget::GetThisMessageMap() {
    static const AFX_MSGMAP_ENTRY entries[] = { {0, 0, 0, 0, AfxSig_end, (AFX_PMSG)0} };
    static const AFX_MSGMAP map = { nullptr, entries };
    return &map;
}
// nCode is CN_COMMAND (0) / a control notification for commands, CN_UPDATE_COMMAND_UI (-1) for UI updates.
// pHandlerInfo != nullptr only asks whether a handler exists.
BOOL CCmdTarget::OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) {
    for (const AFX_MSGMAP* pMap = GetMessageMap(); pMap != nullptr; pMap = pMap->pfnGetBaseMap ? pMap->pfnGetBaseMap() : nullptr) {
        for (const AFX_MSGMAP_ENTRY* pEntry = pMap->lpEntries; pEntry && pEntry->nSig != AfxSig_end; ++pEntry) {
            if (pEntry->nMessage != WM_COMMAND || pEntry->nCode != (UINT)nCode || nID < pEntry->nID || nID > pEntry->nLastID) continue;
            if (pHandlerInfo) return TRUE;
            switch (pEntry->nSig) {
            case AfxSig_cmd_vv:
                (this->*pEntry->pfn)();
                return TRUE;
            case AfxSig_cmd_range:
                (this->*reinterpret_cast<void (CCmdTarget::*)(UINT)>(pEntry->pfn))(nID);
                return TRUE;
            case AfxSig_cmd_b:
            case AfxSig_cmd_range_b:
                if ((this->*reinterpret_cast<BOOL (CCmdTarget::*)(UINT)>(pEntry->pfn))(nID)) return TRUE;
                break;
            case AfxSig_cmdui:
            case AfxSig_cmdui_range: {
                CCmdUI* pCmdUI = static_cast<CCmdUI*>(pExtra);
                pCmdUI->m_bContinueRouting = FALSE;
                (this->*reinterpret_cast<void (CCmdTarget::*)(CCmdUI*)>(pEntry->pfn))(pCmdUI);
                if (!pCmdUI->m_bContinueRouting) return TRUE;
                break;
            }
            }
        }
    }
    return FALSE;
}

// CFile
BOOL CFile::Open(LPCTSTR lpszFileName, UINT nOpenFlags, CFileException* pError) {
    m_strFileName = lpszFileName ? lpszFileName : _T("");
    const char* mode = "rb";
    if (nOpenFlags & modeCreate) mode = (nOpenFlags & modeReadWrite) ? "w+b" : "wb";
    else if (nOpenFlags & modeReadWrite) mode = "r+b";
    char szPath[1024] = {};
    WideCharToMultiByte(CP_UTF8, 0, m_strFileName.GetString(), -1, szPath, sizeof(szPath), nullptr, nullptr);
    m_pStream = fopen(szPath, mode);
    return m_pStream != nullptr;
}
UINT CFile::Read(void* lpBuf, UINT nCount) {
    return m_pStream ? (UINT)fread(lpBuf, 1, nCount, m_pStream) : 0;
}
void CFile::Write(const void* lpBuf, UINT nCount) {
    if (m_pStream) fwrite(lpBuf, 1, nCount, m_pStream);
}
ULONGLONG CFile::Seek(LONGLONG lOff, UINT nFrom) {
    if (!m_pStream) return 0;
    int origin = (nFrom == begin) ? SEEK_SET : ((nFrom == current) ? SEEK_CUR : SEEK_END);
    fseek(m_pStream, (long)lOff, origin);
    return (ULONGLONG)ftell(m_pStream);
}
ULONGLONG CFile::GetLength() const {
    if (!m_pStream) return 0;
    long cur = ftell(m_pStream);
    fseek(m_pStream, 0, SEEK_END);
    long end = ftell(m_pStream);
    fseek(m_pStream, cur, SEEK_SET);
    return (ULONGLONG)end;
}
ULONGLONG CFile::GetPosition() const {
    return m_pStream ? (ULONGLONG)ftell(m_pStream) : 0;
}
void CFile::SetLength(ULONGLONG dwNewLen) {
    if (m_pStream) ftruncate(fileno(m_pStream), (off_t)dwNewLen);
}
void CFile::Flush() { if (m_pStream) fflush(m_pStream); }
void CFile::Close() {
    if (m_pStream) { fclose(m_pStream); m_pStream = nullptr; }
}

// Controls: CListCtrl, CTreeCtrl, CTabCtrl
IMPLEMENT_DYNAMIC(CListCtrl, CWnd)
IMPLEMENT_DYNAMIC(CTreeCtrl, CWnd)
IMPLEMENT_DYNAMIC(CTabCtrl, CWnd)
IMPLEMENT_DYNAMIC(CSliderCtrl, CWnd)
IMPLEMENT_DYNAMIC(CSpinButtonCtrl, CWnd)
IMPLEMENT_DYNAMIC(CProgressCtrl, CWnd)
IMPLEMENT_DYNAMIC(CButton, CWnd)
IMPLEMENT_DYNAMIC(CEdit, CWnd)
IMPLEMENT_DYNAMIC(CStatic, CWnd)
IMPLEMENT_DYNAMIC(CListBox, CWnd)
IMPLEMENT_DYNAMIC(CCheckListBox, CListBox)
IMPLEMENT_DYNAMIC(CComboBox, CWnd)
IMPLEMENT_DYNAMIC(CComboBoxEx, CComboBox)
IMPLEMENT_DYNAMIC(CScrollBar, CWnd)
IMPLEMENT_DYNAMIC(CHeaderCtrl, CWnd)
IMPLEMENT_DYNAMIC(CMFCHeaderCtrl, CHeaderCtrl)
IMPLEMENT_DYNAMIC(CMFCListCtrl, CListCtrl)
IMPLEMENT_DYNAMIC(CToolBarCtrl, CWnd)
IMPLEMENT_DYNAMIC(CStatusBarCtrl, CWnd)
IMPLEMENT_DYNAMIC(CToolTipCtrl, CWnd)
IMPLEMENT_DYNAMIC(CControlBar, CWnd)
IMPLEMENT_DYNAMIC(CToolBar, CControlBar)
IMPLEMENT_DYNAMIC(CStatusBar, CControlBar)
IMPLEMENT_DYNAMIC(CDialogBar, CControlBar)
IMPLEMENT_DYNAMIC(CSplitterWnd, CWnd)
IMPLEMENT_DYNAMIC(CFormView, CScrollView)
IMPLEMENT_DYNAMIC(CCtrlView, CView)
IMPLEMENT_DYNAMIC(CTreeView, CCtrlView)
IMPLEMENT_DYNAMIC(CListView, CCtrlView)
IMPLEMENT_DYNAMIC(CCommonDialog, CDialog)
IMPLEMENT_DYNAMIC(CPropertyPage, CDialog)
IMPLEMENT_DYNAMIC(CPropertySheet, CWnd)

BEGIN_MESSAGE_MAP(CControlBar, CWnd)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CToolBar, CControlBar)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CStatusBar, CControlBar)
    ON_WM_SIZE()
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CDialogBar, CControlBar)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CSplitterWnd, CWnd)
    ON_WM_SIZE()
    ON_WM_PAINT()
    ON_WM_LBUTTONDOWN()
    ON_WM_MOUSEMOVE()
    ON_WM_LBUTTONUP()
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CFormView, CScrollView)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CCtrlView, CView)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CTreeView, CCtrlView)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CListView, CCtrlView)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CMFCListCtrl, CListCtrl)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CPropertyPage, CDialog)
END_MESSAGE_MAP()
BEGIN_MESSAGE_MAP(CPropertySheet, CWnd)
    ON_MESSAGE(WM_CLOSE, &CPropertySheet::OnSheetClose)
END_MESSAGE_MAP()

// Control implementations
// TabCtrl
LONG CTabCtrl::InsertItem(int nItem, LPCTSTR lpszItem) {
    TCITEMW item{};
    item.mask = TCIF_TEXT;
    item.pszText = (LPWSTR)lpszItem;
    return (LONG)::SendMessageW(m_hWnd, TCM_INSERTITEMW, nItem, (LPARAM)&item);
}
LONG CTabCtrl::InsertItem(int nItem, LPCTSTR lpszItem, int nImage) {
    TCITEMW item{};
    item.mask = TCIF_TEXT | TCIF_IMAGE;
    item.pszText = (LPWSTR)lpszItem;
    item.iImage = nImage;
    return (LONG)::SendMessageW(m_hWnd, TCM_INSERTITEMW, nItem, (LPARAM)&item);
}
LONG CTabCtrl::InsertItem(UINT nMask, int nItem, LPCTSTR lpszItem, int nImage, LPARAM lParam) {
    TCITEMW item{};
    item.mask = nMask;
    item.pszText = (LPWSTR)lpszItem;
    item.iImage = nImage;
    item.lParam = lParam;
    return (LONG)::SendMessageW(m_hWnd, TCM_INSERTITEMW, nItem, (LPARAM)&item);
}
LONG CTabCtrl::InsertItem(UINT nMask, int nItem, LPCTSTR lpszItem, int nImage, LPARAM lParam, DWORD dwState, DWORD dwStateMask) {
    TCITEMW item{};
    item.mask = nMask | TCIF_STATE;
    item.pszText = (LPWSTR)lpszItem;
    item.iImage = nImage;
    item.lParam = lParam;
    item.dwState = dwState;
    item.dwStateMask = dwStateMask;
    return (LONG)::SendMessageW(m_hWnd, TCM_INSERTITEMW, nItem, (LPARAM)&item);
}

// ComboBoxEx
CImageList* CComboBoxEx::SetImageList(CImageList* pImageList) { return nullptr; }
CImageList* CComboBoxEx::GetImageList() const { return nullptr; }

// DialogBar
// As in MFC: an invisible child dialog from the template, sized later by the frame's RecalcLayout.
BOOL CDialogBar::Create(CWnd* pParentWnd, LPCTSTR lpszTemplateName, UINT nStyle, UINT nID) {
    m_dwStyle = nStyle & CBRS_ALL;
    const RCDialogDef* def = FindDialogTemplate(lpszTemplateName);
    if (!def || !pParentWnd) return FALSE;
    RCDialogDef childDef = *def;
    childDef.style = (def->style | WS_CHILD) & ~(WS_POPUP | WS_CAPTION | WS_VISIBLE);
    if (!CreateDialogFromTemplate(this, childDef, pParentWnd->GetSafeHwnd())) return FALSE;
    if (WindowRecord* rec = GetWindowRecord(m_hWnd)) rec->id = nID;
    CRect rect;
    GetWindowRect(&rect);
    m_sizeDefault = rect.Size();
    ShowWindow(SW_SHOW);
    if (auto* frame = dynamic_cast<CFrameWnd*>(pParentWnd)) frame->AddControlBar(this);
    return TRUE;
}

// SplitterWnd: a static splitter like MFC's, with 7px bars between panes that can be dragged.
static constexpr int kSplitterBar = 7;

BOOL CSplitterWnd::CreateStatic(CWnd* pParentWnd, int nRows, int nCols, DWORD dwStyle, UINT nID) {
    m_nRows = m_nMaxRows = std::clamp(nRows, 1, 4);
    m_nCols = m_nMaxCols = std::clamp(nCols, 1, 4);
    CRect rect;
    if (pParentWnd) pParentWnd->GetClientRect(&rect);
    return CWnd::Create(_T("SPLITTER"), nullptr, dwStyle | WS_CHILD | WS_VISIBLE, rect, pParentWnd, nID);
}
BOOL CSplitterWnd::Create(CWnd* pParentWnd, int nMaxRows, int nMaxCols, SIZE sizeMin, CCreateContext* pContext, DWORD dwStyle, UINT nID) {
    (void)sizeMin; (void)pContext;
    return CreateStatic(pParentWnd, nMaxRows, nMaxCols, dwStyle, nID);
}
BOOL CSplitterWnd::CreateView(int row, int col, CRuntimeClass* pViewClass, SIZE sizeInit, CCreateContext* pContext) {
    if (row < 0 || col < 0 || row >= m_nRows || col >= m_nCols || !pViewClass) return FALSE;
    CWnd* pWnd = (CWnd*)pViewClass->CreateObject();
    if (!pWnd) return FALSE;
    // As in MFC: without a context, borrow the document of an existing view and send the initial update ourselves.
    CCreateContext contextT;
    const bool sendInitialUpdate = !pContext;
    if (!pContext) {
        std::vector<CWnd*> candidates{GetActivePane()};
        for (int r = 0; r < m_nRows; r++)
            for (int c = 0; c < m_nCols; c++) candidates.push_back(m_panes[r][c]);
        for (CWnd* pane : candidates) {
            if (pane && pane != pWnd && pane->IsKindOf(RUNTIME_CLASS(CView)) && static_cast<CView*>(pane)->GetDocument()) {
                contextT.m_pLastView = static_cast<CView*>(pane);
                contextT.m_pCurrentDoc = contextT.m_pLastView->GetDocument();
                contextT.m_pNewDocTemplate = contextT.m_pCurrentDoc->GetDocTemplate();
                break;
            }
        }
        pContext = &contextT;
    }
    if (sizeInit.cy > 0) m_rowHeights[row] = sizeInit.cy;
    if (sizeInit.cx > 0) m_colWidths[col] = sizeInit.cx;
    m_panes[row][col] = pWnd;
    if (!pWnd->Create(nullptr, nullptr, WS_CHILD | WS_VISIBLE, CRect(0, 0, sizeInit.cx, sizeInit.cy), this, IdFromRowCol(row, col), pContext)) {
        m_panes[row][col] = nullptr;
        return FALSE;
    }
    if (sendInitialUpdate) pWnd->SendMessage(WM_INITIALUPDATE);
    RecalcLayout();
    return TRUE;
}
CWnd* CSplitterWnd::GetPane(int row, int col) const {
    return (row >= 0 && col >= 0 && row < 4 && col < 4) ? m_panes[row][col] : nullptr;
}
void CSplitterWnd::SetActivePane(int row, int col, CWnd* pWnd) {
    CWnd* pane = pWnd ? pWnd : GetPane(row, col);
    if (pane) pane->SetFocus();
}
CWnd* CSplitterWnd::GetActivePane(int* pRow, int* pCol) {
    HWND focus = ::GetFocus();
    for (int r = 0; r < m_nRows; r++)
        for (int c = 0; c < m_nCols; c++)
            if (m_panes[r][c] && (m_panes[r][c]->m_hWnd == focus || ::IsChild(m_panes[r][c]->m_hWnd, focus))) {
                if (pRow) *pRow = r;
                if (pCol) *pCol = c;
                return m_panes[r][c];
            }
    if (pRow) *pRow = 0;
    if (pCol) *pCol = 0;
    return m_panes[0][0];
}
// Rows/columns other than the last keep their ideal size; the last one takes what is left.
static std::vector<std::pair<int, int>> SplitterExtents(const int* ideal, int count, int total) {
    std::vector<std::pair<int, int>> extents;
    int pos = 0;
    for (int i = 0; i < count; i++) {
        const int remaining = std::max(0, total - pos);
        const int size = (i == count - 1) ? remaining : std::min(std::max(ideal[i], 0), std::max(0, remaining - kSplitterBar));
        extents.push_back({pos, size});
        pos += size + kSplitterBar;
    }
    return extents;
}
void CSplitterWnd::RecalcLayout() {
    CRect rect;
    GetClientRect(&rect);
    const auto rows = SplitterExtents(m_rowHeights, m_nRows, rect.Height());
    const auto cols = SplitterExtents(m_colWidths, m_nCols, rect.Width());
    for (int r = 0; r < m_nRows; r++)
        for (int c = 0; c < m_nCols; c++)
            if (m_panes[r][c] && m_panes[r][c]->m_hWnd)
                m_panes[r][c]->MoveWindow(cols[c].first, rows[r].first, cols[c].second, rows[r].second);
    Invalidate(FALSE);
}
void CSplitterWnd::GetRowInfo(int row, int& cyCur, int& cyMin) const {
    cyMin = 10;
    cyCur = m_rowHeights[row & 3];
    if (CWnd* pane = GetPane(row, 0); pane && pane->m_hWnd) {
        CRect r;
        pane->GetClientRect(&r);
        cyCur = r.Height();
    }
}
void CSplitterWnd::GetColumnInfo(int col, int& cxCur, int& cxMin) const {
    cxMin = 10;
    cxCur = m_colWidths[col & 3];
    if (CWnd* pane = GetPane(0, col); pane && pane->m_hWnd) {
        CRect r;
        pane->GetClientRect(&r);
        cxCur = r.Width();
    }
}
// Which bar is under the point: rows are encoded as 0..3, columns as 4..7, -1 for none.
int CSplitterWnd::HitTestBar(CPoint pt) const {
    CRect rect;
    GetClientRect(&rect);
    const auto rows = SplitterExtents(m_rowHeights, m_nRows, rect.Height());
    for (int r = 0; r + 1 < m_nRows; r++) {
        const int barTop = rows[r].first + rows[r].second;
        if (pt.y >= barTop && pt.y < barTop + kSplitterBar) return r;
    }
    const auto cols = SplitterExtents(m_colWidths, m_nCols, rect.Width());
    for (int c = 0; c + 1 < m_nCols; c++) {
        const int barLeft = cols[c].first + cols[c].second;
        if (pt.x >= barLeft && pt.x < barLeft + kSplitterBar) return 4 + c;
    }
    return -1;
}
void CSplitterWnd::OnSize(UINT nType, int cx, int cy) {
    (void)nType; (void)cx; (void)cy;
    RecalcLayout();
}
void CSplitterWnd::OnPaint() {
    CPaintDC dc(this);
    CRect rect;
    GetClientRect(&rect);
    dc.FillSolidRect(&rect, ::GetSysColor(COLOR_BTNFACE));
}
void CSplitterWnd::OnLButtonDown(UINT nFlags, CPoint point) {
    (void)nFlags;
    m_trackingBar = HitTestBar(point);
    if (m_trackingBar >= 0) SetCapture();
}
void CSplitterWnd::OnMouseMove(UINT nFlags, CPoint point) {
    (void)nFlags;
    const int bar = m_trackingBar >= 0 ? m_trackingBar : HitTestBar(point);
    if (bar >= 0) ::SetCursor(::LoadCursorW(nullptr, bar < 4 ? IDC_SIZENS : IDC_SIZEWE));
    if (m_trackingBar < 0) return;
    if (m_trackingBar < 4) {
        int top = 0;
        for (int r = 0; r < m_trackingBar; r++) top += m_rowHeights[r] + kSplitterBar;
        m_rowHeights[m_trackingBar] = std::max(0, (int)point.y - top - kSplitterBar / 2);
    } else {
        const int c = m_trackingBar - 4;
        int left = 0;
        for (int i = 0; i < c; i++) left += m_colWidths[i] + kSplitterBar;
        m_colWidths[c] = std::max(0, (int)point.x - left - kSplitterBar / 2);
    }
    RecalcLayout();
}
void CSplitterWnd::OnLButtonUp(UINT nFlags, CPoint point) {
    (void)nFlags; (void)point;
    if (m_trackingBar >= 0) ReleaseCapture();
    m_trackingBar = -1;
}

// FormView
BOOL CFormView::Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle,
                       const RECT& rect, CWnd* pParentWnd, UINT nID, CCreateContext* pContext) {
    (void)lpszClassName; (void)lpszWindowName;
    const RCDialogDef* def = FindDialogTemplate(m_lpszTemplateName);
    if (!def || !pParentWnd) return FALSE;
    RCDialogDef childDef = *def;
    childDef.style = (def->style | WS_CHILD | dwStyle) & ~(WS_POPUP | WS_CAPTION);
    if (!CreateDialogFromTemplate(this, childDef, pParentWnd->GetSafeHwnd(), pContext)) return FALSE;
    if (WindowRecord* rec = GetWindowRecord(m_hWnd)) rec->id = nID;
    MoveWindow(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    return TRUE;
}
void CFormView::OnInitialUpdate() {
    CScrollView::OnInitialUpdate();
    CDataExchange dx(this, FALSE);
    DoDataExchange(&dx);
}

// PropertySheet & PropertyPage
CPropertyPage::CPropertyPage() {}
CPropertyPage::CPropertyPage(UINT nIDTemplate, UINT nIDCaption, DWORD dwSize)
    : CDialog(nIDTemplate) {}
CPropertyPage::CPropertyPage(LPCTSTR lpszTemplateName, UINT nIDCaption, DWORD dwSize)
    : CDialog(lpszTemplateName) {}
// As in MFC, Apply is enabled while any page has unapplied changes.
void CPropertyPage::SetModified(BOOL bChanged) {
    m_bModified = bChanged;
    if (m_pSheet) m_pSheet->UpdateApply();
}

void CPropertySheet::UpdateApply() {
    if (!m_hWnd) return;
    bool modified = false;
    for (CPropertyPage* page : m_pages) modified |= page->m_bModified;
    ::EnableWindow(::GetDlgItem(m_hWnd, ID_APPLY_NOW), modified);
}

CPropertySheet::CPropertySheet() {}
CPropertySheet::CPropertySheet(UINT nIDCaption, CWnd* pParentWnd, UINT iSelectPage) { Construct(nIDCaption, pParentWnd, iSelectPage); }
CPropertySheet::CPropertySheet(LPCTSTR pszCaption, CWnd* pParentWnd, UINT iSelectPage) { Construct(pszCaption, pParentWnd, iSelectPage); }
void CPropertySheet::Construct(UINT nIDCaption, CWnd* pParentWnd, UINT iSelectPage) {
    CString caption(MacResourceManager::Instance().GetString((int)nIDCaption).c_str());
    Construct(caption.GetString(), pParentWnd, iSelectPage);
}
void CPropertySheet::Construct(LPCTSTR pszCaption, CWnd* pParentWnd, UINT iSelectPage) {
    m_strCaption = pszCaption ? pszCaption : _T("");
    m_pParentWnd = pParentWnd;
    m_nActivePage = (int)iSelectPage;
}
BOOL CPropertySheet::Create(CWnd* pParentWnd, DWORD dwStyle, DWORD dwExStyle) { return FALSE; }  // no modeless sheets in OpenMPT

// The sheet lists the page titles on the left (OpenMPT's 11 setup pages don't fit in one row of tabs),
// shows the active page beside them and OK / Cancel / Apply below, like a macOS settings window.
static constexpr int kSheetMargin = 12, kSheetListWidth = 150, kSheetButtonWidth = 80, kSheetButtonHeight = 24;
static constexpr UINT kSheetListID = 0x3020;

INT_PTR CPropertySheet::DoModal() {
    int pageW = 0, pageH = 0;
    const RCDialogDef* firstDef = nullptr;
    for (CPropertyPage* page : m_pages) {
        if (const RCDialogDef* def = FindDialogTemplate(page->m_lpszTemplateName)) {
            if (!firstDef) firstDef = def;
            pageW = std::max(pageW, DluToPixelsX(def->cx));
            pageH = std::max(pageH, DluToPixelsY(def->cy));
        }
    }
    if (!firstDef) return IDCANCEL;
    const int pageX = 2 * kSheetMargin + kSheetListWidth, buttonY = 2 * kSheetMargin + pageH;
    const int width = pageX + pageW + kSheetMargin, height = buttonY + kSheetButtonHeight + kSheetMargin;
    HWND hSheet = CreateNativeHWND(this, 0, L"#32770", m_strCaption.GetString(), WS_POPUP | WS_CAPTION | WS_SYSMENU,
                                   CW_USEDEFAULT, CW_USEDEFAULT, width, height,
                                   m_pParentWnd ? m_pParentWnd->GetSafeHwnd() : nullptr, nullptr, nullptr);
    WindowRecord* rec = GetWindowRecord(hSheet);
    if (!rec) return IDCANCEL;
    rec->isDialog = true;  // Return and Esc press OK and Cancel
    HFONT font = DialogFont(*firstDef);
    rec->font = font;
    auto addControl = [&](LPCWSTR cls, LPCWSTR text, DWORD style, int x, int y, int w, int h, UINT id) {
        HWND hCtrl = CreateNativeHWND(nullptr, 0, cls, text, style | WS_CHILD | WS_VISIBLE | WS_TABSTOP,
                                      x, y, w, h, hSheet, (HMENU)(uintptr_t)id, nullptr);
        ::SendMessageW(hCtrl, WM_SETFONT, (WPARAM)font, FALSE);
        return hCtrl;
    };
    HWND hList = addControl(L"LISTBOX", L"", WS_BORDER | WS_VSCROLL | LBS_NOTIFY, kSheetMargin, kSheetMargin, kSheetListWidth, pageH, kSheetListID);
    for (CPropertyPage* page : m_pages) {
        const RCDialogDef* def = FindDialogTemplate(page->m_lpszTemplateName);
        ::SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM)Utf8ToWide(def ? def->title : std::string()).c_str());
    }
    const int okX = width - kSheetMargin - kSheetButtonWidth;
    addControl(L"BUTTON", L"OK", BS_DEFPUSHBUTTON, okX, buttonY, kSheetButtonWidth, kSheetButtonHeight, IDOK);
    addControl(L"BUTTON", L"Cancel", BS_PUSHBUTTON, okX - kSheetButtonWidth - 8, buttonY, kSheetButtonWidth, kSheetButtonHeight, IDCANCEL);
    ::EnableWindow(addControl(L"BUTTON", L"Apply", BS_PUSHBUTTON, kSheetMargin, buttonY, kSheetButtonWidth, kSheetButtonHeight, ID_APPLY_NOW), FALSE);

    m_nModalResult = IDCANCEL;
    const int startPage = (m_nActivePage >= 0 && m_nActivePage < GetPageCount()) ? m_nActivePage : 0;
    m_nActivePage = -1;
    if (!ShowPage(startPage) && startPage != 0) ShowPage(0);
    OnInitDialog();
    if ((rec = GetWindowRecord(hSheet)) && rec->nsWindow) [NSApp runModalForWindow:rec->nsWindow];
    return m_nModalResult;
}
BOOL CPropertySheet::OnInitDialog() { return TRUE; }

// Creates the page on first use, as Windows does, so pages that were never shown are never applied.
bool CPropertySheet::ShowPage(int nPage) {
    CPropertyPage* next = GetPage(nPage);
    if (!next) return false;
    CPropertyPage* cur = GetActivePage();
    if (cur == next) return true;
    if (cur && cur->m_hWnd && !cur->OnKillActive()) return false;
    if (!next->m_hWnd) {
        const RCDialogDef* def = FindDialogTemplate(next->m_lpszTemplateName);
        if (!def) return false;
        // Page templates are captioned, disabled children; in the sheet they are plain children at the page position.
        RCDialogDef pageDef = *def;
        pageDef.style = (def->style & ~(WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_DISABLED | WS_VISIBLE)) | WS_CHILD;
        pageDef.x = pageDef.y = 0;
        if (!CreateDialogFromTemplate(next, pageDef, m_hWnd)) return false;
        next->m_bModified = false;  // controls filled in by OnInitDialog are not user changes
        UpdateApply();
        ::MoveWindow(next->m_hWnd, 2 * kSheetMargin + kSheetListWidth, kSheetMargin, DluToPixelsX(def->cx), DluToPixelsY(def->cy), FALSE);
    }
    if (cur && cur->m_hWnd) cur->ShowWindow(SW_HIDE);
    m_nActivePage = nPage;
    next->OnSetActive();
    next->ShowWindow(SW_SHOW);
    ::SendMessageW(::GetDlgItem(m_hWnd, kSheetListID), LB_SETCURSEL, nPage, 0);
    return true;
}

// As in MFC: the active page validates, then every page that was shown applies.
bool CPropertySheet::ApplyPages() {
    if (CPropertyPage* cur = GetActivePage(); cur && cur->m_hWnd && !cur->OnKillActive()) return false;
    for (CPropertyPage* page : m_pages) {
        if (page->m_hWnd && !page->OnApply()) return false;
        page->m_bModified = false;
    }
    UpdateApply();
    return true;
}

BOOL CPropertySheet::OnCommand(WPARAM wParam, LPARAM lParam) {
    switch (LOWORD(wParam)) {
    case IDOK:
        if (ApplyPages()) EndDialog(IDOK);
        return TRUE;
    case IDCANCEL:
        if (CPropertyPage* cur = GetActivePage(); cur && cur->m_hWnd && !cur->OnQueryCancel()) return TRUE;
        for (CPropertyPage* page : m_pages) {
            if (page->m_hWnd) page->OnReset();
        }
        EndDialog(IDCANCEL);
        return TRUE;
    case ID_APPLY_NOW:
        ApplyPages();
        return TRUE;
    case kSheetListID:
        if (HIWORD(wParam) == LBN_SELCHANGE && !ShowPage((int)::SendMessageW((HWND)lParam, LB_GETCURSEL, 0, 0)))
            ::SendMessageW((HWND)lParam, LB_SETCURSEL, m_nActivePage, 0);
        return TRUE;
    }
    return CWnd::OnCommand(wParam, lParam);
}

// The close box cancels, as DefDlgProc does.
LRESULT CPropertySheet::OnSheetClose(WPARAM, LPARAM) {
    SendMessage(WM_COMMAND, MAKEWPARAM(IDCANCEL, BN_CLICKED), 0);
    return 0;
}

BOOL CPropertySheet::SetActivePage(int nPage) {
    if (nPage < 0 || nPage >= GetPageCount()) return FALSE;
    if (m_hWnd) return ShowPage(nPage);
    m_nActivePage = nPage;
    return TRUE;
}
void CPropertySheet::AddPage(CPropertyPage* pPage) {
    if (pPage) {
        m_pages.push_back(pPage);
        pPage->m_pSheet = this;
    }
}
void CPropertySheet::RemovePage(CPropertyPage* pPage) {
    auto it = std::find(m_pages.begin(), m_pages.end(), pPage);
    if (it != m_pages.end()) m_pages.erase(it);
}
void CPropertySheet::RemovePage(int nPage) {
    if (nPage >= 0 && (size_t)nPage < m_pages.size()) m_pages.erase(m_pages.begin() + nPage);
}
void CPropertySheet::EndDialog(int nEndID) {
    m_nModalResult = nEndID;
    if (WindowRecord* rec = GetWindowRecord(m_hWnd); rec && rec->nsWindow) [NSApp stopModalWithCode:nEndID];
    DestroyWindow();
}
BOOL CPropertySheet::PressButton(int nButton) {
    const UINT id = nButton == PSBTN_OK ? IDOK : nButton == PSBTN_CANCEL ? IDCANCEL : nButton == PSBTN_APPLYNOW ? ID_APPLY_NOW : 0;
    if (!id || !m_hWnd) return FALSE;
    SendMessage(WM_COMMAND, MAKEWPARAM(id, BN_CLICKED), 0);
    return TRUE;
}

// CMenu Implementation
CMenu* CMenu::FromHandle(HMENU hMenu) {
    if (!hMenu) return nullptr;
    CMenu* m = new CMenu();
    m->m_hMenu = hMenu;
    return m;
}
BOOL CMenu::LoadMenu(LPCTSTR lpszResourceName) {
    const RCMenuDef* def = nullptr;
    if (IS_INTRESOURCE(lpszResourceName)) {
        def = MacResourceManager::Instance().GetMenu((int)(uintptr_t)lpszResourceName);
    } else {
        std::string name = ToStdString(lpszResourceName);
        def = MacResourceManager::Instance().GetMenu(name.c_str());
    }
    (void)def;
    return Attach(::LoadMenuW(AfxGetResourceHandle(), lpszResourceName));
}
CMenu* CMenu::GetSubMenu(int nPos) const {
    HMENU hSub = ::GetSubMenu(m_hMenu, nPos);
    return FromHandle(hSub);
}
BOOL CMenu::TrackPopupMenu(UINT nFlags, int x, int y, CWnd* pWnd, LPCRECT lpRect) {
    return ::TrackPopupMenu(m_hMenu, nFlags, x, y, 0, pWnd ? pWnd->GetSafeHwnd() : nullptr, lpRect);
}
BOOL CMenu::TrackPopupMenuEx(UINT nFlags, int x, int y, CWnd* pWnd, LPTPMPARAMS lptpm) {
    return ::TrackPopupMenuEx(m_hMenu, nFlags, x, y, pWnd ? pWnd->GetSafeHwnd() : nullptr, lptpm);
}

// SHFileOperation implementation via NSFileManager
int WINAPI SHFileOperationW(LPSHFILEOPSTRUCTW lpFileOp) {
    if (!lpFileOp || !lpFileOp->pFrom) return -1;
    @autoreleasepool {
        NSFileManager* fm = [NSFileManager defaultManager];
        const wchar_t* p = lpFileOp->pFrom;
        while (*p) {
            std::wstring wpath(p);
            p += wpath.length() + 1;
            NSString* path = [[NSString alloc] initWithBytes:wpath.data() length:wpath.length() * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
            if (!path) continue;
            if (lpFileOp->wFunc == FO_DELETE) {
                if (lpFileOp->fFlags & FOF_ALLOWUNDO) {
                    NSURL* url = [NSURL fileURLWithPath:path];
                    NSError* err = nil;
                    [fm trashItemAtURL:url resultingItemURL:nil error:&err];
                } else {
                    [fm removeItemAtPath:path error:nil];
                }
            }
        }
    }
    return 0;
}

int WINAPI SHFileOperationA(LPSHFILEOPSTRUCTA lpFileOp) {
    if (!lpFileOp || !lpFileOp->pFrom) return -1;
    @autoreleasepool {
        NSFileManager* fm = [NSFileManager defaultManager];
        const char* p = lpFileOp->pFrom;
        while (*p) {
            std::string apath(p);
            p += apath.length() + 1;
            NSString* path = [NSString stringWithUTF8String:apath.c_str()];
            if (!path) continue;
            if (lpFileOp->wFunc == FO_DELETE) {
                if (lpFileOp->fFlags & FOF_ALLOWUNDO) {
                    NSURL* url = [NSURL fileURLWithPath:path];
                    NSError* err = nil;
                    [fm trashItemAtURL:url resultingItemURL:nil error:&err];
                } else {
                    [fm removeItemAtPath:path error:nil];
                }
            }
        }
    }
    return 0;
}

