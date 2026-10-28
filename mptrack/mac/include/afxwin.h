#pragma once

#include "afx.h"

class CWnd;
class CDC;
class CMenu;
class CBitmap;
struct CCreateContext;
class CDocument;
class CDocTemplate;
class CMultiDocTemplate;
class CView;
class CFrameWnd;
class CMDIFrameWnd;
class CMDIChildWnd;
class CDialog;
class CWinApp;
class CControlBar;
class CToolBar;
class CStatusBar;
class CListBox;
class CDataExchange;
class CCmdUI;

// Message map structures and macros
class CCmdTarget;
typedef void (CCmdTarget::*AFX_PMSG)(void);
typedef void (CWnd::*AFX_PMSGW)(void);

enum AfxSig {
    AfxSig_end = 0,
    AfxSig_vv,          // void ()
    AfxSig_vw,          // void (UINT)
    AfxSig_is,          // int (LPTSTR)
    AfxSig_i_v_v,       // int ()
    AfxSig_v_u_u,       // void (UINT, UINT)
    AfxSig_v_u_p,       // void (UINT, CPoint)
    AfxSig_b_u_s_p,     // BOOL (UINT, short, CPoint)
    AfxSig_v_u_u_u,     // void (UINT, UINT, UINT)
    AfxSig_v_i_i,       // void (int, int)
    AfxSig_v_u_i_i,     // void (UINT, int, int)
    AfxSig_v_b_h,       // void (BOOL, HANDLE)
    AfxSig_v_h,         // void (HANDLE) / void (HDROP) / void (HMENU)
    AfxSig_v_W_u_u,     // void (CWnd*, UINT, UINT)
    AfxSig_v_u_W_b,     // void (UINT, CWnd*, BOOL)
    AfxSig_v_W,         // void (CWnd*)
    AfxSig_v_W_p,       // void (CWnd*, CPoint)
    AfxSig_b_W_u_u,     // BOOL (CWnd*, UINT, UINT)
    AfxSig_b_D,         // BOOL (CDC*)
    AfxSig_B_D_W_u,     // HBRUSH (CDC*, CWnd*, UINT)
    AfxSig_i_LP,        // int (LPCREATESTRUCT)
    AfxSig_v_p,         // void (MINMAXINFO*) / void (WINDOWPOS*) / void (NCCALCSIZE_PARAMS*)
    AfxSig_v_b_p,       // void (BOOL, NCCALCSIZE_PARAMS*)
    AfxSig_v_u_r,       // void (UINT, LPRECT)
    AfxSig_l_w_l,       // LRESULT (WPARAM, LPARAM)
    AfxSig_b_v,         // BOOL ()
    AfxSig_b_u,         // BOOL (UINT)
    AfxSig_v_u,         // void (UINT_PTR) / void (UINT)
    AfxSig_b_b,         // BOOL (BOOL)
    AfxSig_v_b,         // void (BOOL)
    AfxSig_u_p,         // LRESULT/UINT (CPoint)
    AfxSig_u_v,         // UINT ()
    AfxSig_v_D,         // void (CDC*)
    AfxSig_v_M_u_b,     // void (CMenu*, UINT, BOOL)
    AfxSig_v_u_M,       // void (UINT, CMenu*)
    AfxSig_b_u_p,       // BOOL (UINT, CPoint)
    AfxSig_i_u_W_u,     // int (UINT, CWnd*, UINT)
    AfxSig_v_u_u_W,     // void (UINT, UINT, CScrollBar*)
    AfxSig_v_i_p,       // void (int, LPTSTR)
    AfxSig_cmd_vv,      // ON_COMMAND: void ()
    AfxSig_cmd_b,       // ON_COMMAND_EX: BOOL (UINT)
    AfxSig_cmd_range,   // ON_COMMAND_RANGE: void (UINT)
    AfxSig_cmd_range_b, // ON_COMMAND_EX_RANGE: BOOL (UINT)
    AfxSig_cmdui,       // ON_UPDATE_COMMAND_UI: void (CCmdUI*)
    AfxSig_cmdui_range, // ON_UPDATE_COMMAND_UI_RANGE: void (CCmdUI*)
    AfxSig_notify_v,    // ON_NOTIFY: void (NMHDR*, LRESULT*)
    AfxSig_notify_b,    // ON_NOTIFY_EX: BOOL (UINT, NMHDR*, LRESULT*)
    AfxSig_notify_range,// ON_NOTIFY_RANGE: void (UINT, NMHDR*, LRESULT*)
    AfxSig_refl_vv,     // ON_CONTROL_REFLECT: void ()
    AfxSig_refl_b,      // ON_CONTROL_REFLECT_EX: BOOL ()
    AfxSig_refl_notify, // ON_NOTIFY_REFLECT: void (NMHDR*, LRESULT*)
    AfxSig_refl_notify_b// ON_NOTIFY_REFLECT_EX: BOOL (NMHDR*, LRESULT*)
};

struct AFX_MSGMAP_ENTRY {
    UINT nMessage;
    UINT nCode;
    UINT nID;
    UINT nLastID;
    UINT_PTR nSig;
    AFX_PMSG pfn;
};

struct AFX_MSGMAP {
    const AFX_MSGMAP* (*pfnGetBaseMap)();
    const AFX_MSGMAP_ENTRY* lpEntries;
};

#define DECLARE_MESSAGE_MAP() \
protected: \
    static const AFX_MSGMAP* GetThisMessageMap(); \
    virtual const AFX_MSGMAP* GetMessageMap() const override;

#define BEGIN_MESSAGE_MAP(theClass, baseClass) \
    const AFX_MSGMAP* theClass::GetMessageMap() const { return GetThisMessageMap(); } \
    const AFX_MSGMAP* theClass::GetThisMessageMap() { \
        typedef theClass ThisClass; \
        typedef baseClass TheBaseClass; \
        static const AFX_MSGMAP_ENTRY _messageEntries[] = {

#define BEGIN_TEMPLATE_MESSAGE_MAP(theClass, type_name, baseClass) \
    template <typename type_name> \
    const AFX_MSGMAP* theClass<type_name>::GetMessageMap() const { return GetThisMessageMap(); } \
    template <typename type_name> \
    const AFX_MSGMAP* theClass<type_name>::GetThisMessageMap() { \
        typedef theClass<type_name> ThisClass; \
        typedef baseClass TheBaseClass; \
        static const AFX_MSGMAP_ENTRY _messageEntries[] = {

#define END_MESSAGE_MAP() \
            {0, 0, 0, 0, AfxSig_end, (AFX_PMSG)0 } \
        }; \
        static const AFX_MSGMAP messageMap = { &TheBaseClass::GetThisMessageMap, &_messageEntries[0] }; \
        return &messageMap; \
    }

// Message map entry macros
#define ON_COMMAND(id, memberFxn) \
    { WM_COMMAND, 0, (WORD)id, (WORD)id, AfxSig_cmd_vv, static_cast<AFX_PMSG>(memberFxn) },
#define ON_COMMAND_EX(id, memberFxn) \
    { WM_COMMAND, 0, (WORD)id, (WORD)id, AfxSig_cmd_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CCmdTarget::*)(UINT)>(memberFxn))) },
#define ON_COMMAND_RANGE(id, idLast, memberFxn) \
    { WM_COMMAND, 0, (WORD)id, (WORD)idLast, AfxSig_cmd_range, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(UINT)>(memberFxn))) },
#define ON_COMMAND_EX_RANGE(id, idLast, memberFxn) \
    { WM_COMMAND, 0, (WORD)id, (WORD)idLast, AfxSig_cmd_range_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CCmdTarget::*)(UINT)>(memberFxn))) },

#define ON_UPDATE_COMMAND_UI(id, memberFxn) \
    { WM_COMMAND, (UINT)-1, (WORD)id, (WORD)id, AfxSig_cmdui, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(CCmdUI*)>(memberFxn))) },
#define ON_UPDATE_COMMAND_UI_RANGE(id, idLast, memberFxn) \
    { WM_COMMAND, (UINT)-1, (WORD)id, (WORD)idLast, AfxSig_cmdui_range, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(CCmdUI*)>(memberFxn))) },

#define ON_CONTROL(wNotifyCode, id, memberFxn) \
    { WM_COMMAND, (WORD)wNotifyCode, (WORD)id, (WORD)id, AfxSig_cmd_vv, static_cast<AFX_PMSG>(memberFxn) },
#define ON_CONTROL_RANGE(wNotifyCode, id, idLast, memberFxn) \
    { WM_COMMAND, (WORD)wNotifyCode, (WORD)id, (WORD)idLast, AfxSig_cmd_range, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(UINT)>(memberFxn))) },
#define ON_CONTROL_REFLECT(wNotifyCode, memberFxn) \
    { WM_COMMAND + WM_REFLECT_BASE, (WORD)wNotifyCode, 0, 0, AfxSig_refl_vv, static_cast<AFX_PMSG>(memberFxn) },
#define ON_CONTROL_REFLECT_EX(wNotifyCode, memberFxn) \
    { WM_COMMAND + WM_REFLECT_BASE, (WORD)wNotifyCode, 0, 0, AfxSig_refl_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CCmdTarget::*)()>(memberFxn))) },

#define ON_NOTIFY(wNotifyCode, id, memberFxn) \
    { WM_NOTIFY, (UINT)(int)wNotifyCode, (WORD)id, (WORD)id, AfxSig_notify_v, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(NMHDR*, LRESULT*)>(memberFxn))) },
#define ON_NOTIFY_RANGE(wNotifyCode, id, idLast, memberFxn) \
    { WM_NOTIFY, (UINT)(int)wNotifyCode, (WORD)id, (WORD)idLast, AfxSig_notify_range, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(UINT, NMHDR*, LRESULT*)>(memberFxn))) },
#define ON_NOTIFY_EX(wNotifyCode, id, memberFxn) \
    { WM_NOTIFY, (UINT)(int)wNotifyCode, (WORD)id, (WORD)id, AfxSig_notify_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CCmdTarget::*)(UINT, NMHDR*, LRESULT*)>(memberFxn))) },
#define ON_NOTIFY_EX_RANGE(wNotifyCode, id, idLast, memberFxn) \
    { WM_NOTIFY, (UINT)(int)wNotifyCode, (WORD)id, (WORD)idLast, AfxSig_notify_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CCmdTarget::*)(UINT, NMHDR*, LRESULT*)>(memberFxn))) },
#define ON_NOTIFY_REFLECT(wNotifyCode, memberFxn) \
    { WM_NOTIFY + WM_REFLECT_BASE, (UINT)(int)wNotifyCode, 0, 0, AfxSig_refl_notify, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CCmdTarget::*)(NMHDR*, LRESULT*)>(memberFxn))) },
#define ON_NOTIFY_REFLECT_EX(wNotifyCode, memberFxn) \
    { WM_NOTIFY + WM_REFLECT_BASE, (UINT)(int)wNotifyCode, 0, 0, AfxSig_refl_notify_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CCmdTarget::*)(NMHDR*, LRESULT*)>(memberFxn))) },

#define ON_MESSAGE(message, memberFxn) \
    { (message), 0, 0, 0, AfxSig_l_w_l, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<LRESULT (CWnd::*)(WPARAM, LPARAM)>(memberFxn))) },
#define ON_REGISTERED_MESSAGE(nMessageVariable, memberFxn) \
    { 0xC000, 0, 0, 0, (UINT_PTR)&nMessageVariable, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<LRESULT (CWnd::*)(WPARAM, LPARAM)>(memberFxn))) },

// Standard control notification macros
#define ON_BN_CLICKED(id, memberFxn)        ON_CONTROL(BN_CLICKED, id, memberFxn)
#define ON_BN_DOUBLECLICKED(id, memberFxn)  ON_CONTROL(BN_DOUBLECLICKED, id, memberFxn)
#define ON_EN_CHANGE(id, memberFxn)         ON_CONTROL(EN_CHANGE, id, memberFxn)
#define ON_EN_UPDATE(id, memberFxn)         ON_CONTROL(EN_UPDATE, id, memberFxn)
#define ON_EN_KILLFOCUS(id, memberFxn)      ON_CONTROL(EN_KILLFOCUS, id, memberFxn)
#define ON_EN_SETFOCUS(id, memberFxn)       ON_CONTROL(EN_SETFOCUS, id, memberFxn)
#define ON_CBN_SELCHANGE(id, memberFxn)     ON_CONTROL(CBN_SELCHANGE, id, memberFxn)
#define ON_CBN_SELENDOK(id, memberFxn)      ON_CONTROL(CBN_SELENDOK, id, memberFxn)
#define ON_CBN_SELENDCANCEL(id, memberFxn)  ON_CONTROL(CBN_SELENDCANCEL, id, memberFxn)
#define ON_CBN_EDITCHANGE(id, memberFxn)    ON_CONTROL(CBN_EDITCHANGE, id, memberFxn)
#define ON_CBN_DROPDOWN(id, memberFxn)      ON_CONTROL(CBN_DROPDOWN, id, memberFxn)
#define ON_CBN_CLOSEUP(id, memberFxn)       ON_CONTROL(CBN_CLOSEUP, id, memberFxn)
#define ON_CBN_KILLFOCUS(id, memberFxn)     ON_CONTROL(CBN_KILLFOCUS, id, memberFxn)
#define ON_CBN_SETFOCUS(id, memberFxn)      ON_CONTROL(CBN_SETFOCUS, id, memberFxn)
#define ON_LBN_SELCHANGE(id, memberFxn)     ON_CONTROL(LBN_SELCHANGE, id, memberFxn)
#define ON_LBN_DBLCLK(id, memberFxn)        ON_CONTROL(LBN_DBLCLK, id, memberFxn)
#define ON_LBN_KILLFOCUS(id, memberFxn)     ON_CONTROL(LBN_KILLFOCUS, id, memberFxn)
#define ON_CLBN_CHKCHANGE(id, memberFxn)    ON_CONTROL(CLBN_CHKCHANGE, id, memberFxn)

// Common control notification macros
#define ON_NM_CLICK(id, memberFxn)              ON_NOTIFY(NM_CLICK, id, memberFxn)
#define ON_NM_DBLCLK(id, memberFxn)             ON_NOTIFY(NM_DBLCLK, id, memberFxn)
#define ON_NM_RCLICK(id, memberFxn)             ON_NOTIFY(NM_RCLICK, id, memberFxn)
#define ON_NM_RDBLCLK(id, memberFxn)            ON_NOTIFY(NM_RDBLCLK, id, memberFxn)
#define ON_NM_RETURN(id, memberFxn)             ON_NOTIFY(NM_RETURN, id, memberFxn)
#define ON_NM_KILLFOCUS(id, memberFxn)          ON_NOTIFY(NM_KILLFOCUS, id, memberFxn)
#define ON_NM_SETFOCUS(id, memberFxn)           ON_NOTIFY(NM_SETFOCUS, id, memberFxn)
#define ON_NM_CUSTOMDRAW(id, memberFxn)         ON_NOTIFY(NM_CUSTOMDRAW, id, memberFxn)
#define ON_LVN_ITEMCHANGED(id, memberFxn)       ON_NOTIFY(LVN_ITEMCHANGED, id, memberFxn)
#define ON_LVN_ITEMCHANGING(id, memberFxn)      ON_NOTIFY(LVN_ITEMCHANGING, id, memberFxn)
#define ON_LVN_COLUMNCLICK(id, memberFxn)       ON_NOTIFY(LVN_COLUMNCLICK, id, memberFxn)
#define ON_LVN_BEGINDRAG(id, memberFxn)         ON_NOTIFY(LVN_BEGINDRAG, id, memberFxn)
#define ON_LVN_BEGINLABELEDIT(id, memberFxn)    ON_NOTIFY(LVN_BEGINLABELEDIT, id, memberFxn)
#define ON_LVN_ENDLABELEDIT(id, memberFxn)      ON_NOTIFY(LVN_ENDLABELEDIT, id, memberFxn)
#define ON_LVN_GETDISPINFO(id, memberFxn)       ON_NOTIFY(LVN_GETDISPINFO, id, memberFxn)
#define ON_LVN_INSERTITEM(id, memberFxn)        ON_NOTIFY(LVN_INSERTITEM, id, memberFxn)
#define ON_LVN_DELETEALLITEMS(id, memberFxn)    ON_NOTIFY(LVN_DELETEALLITEMS, id, memberFxn)
#define ON_LVN_KEYDOWN(id, memberFxn)           ON_NOTIFY(LVN_KEYDOWN, id, memberFxn)
#define ON_TVN_SELCHANGED(id, memberFxn)        ON_NOTIFY(TVN_SELCHANGED, id, memberFxn)
#define ON_TVN_ITEMEXPANDING(id, memberFxn)     ON_NOTIFY(TVN_ITEMEXPANDING, id, memberFxn)
#define ON_TVN_BEGINDRAG(id, memberFxn)         ON_NOTIFY(TVN_BEGINDRAG, id, memberFxn)
#define ON_TVN_BEGINRDRAG(id, memberFxn)        ON_NOTIFY(TVN_BEGINRDRAG, id, memberFxn)
#define ON_TVN_BEGINLABELEDIT(id, memberFxn)    ON_NOTIFY(TVN_BEGINLABELEDIT, id, memberFxn)
#define ON_TVN_ENDLABELEDIT(id, memberFxn)      ON_NOTIFY(TVN_ENDLABELEDIT, id, memberFxn)
#define ON_TVN_KEYDOWN(id, memberFxn)           ON_NOTIFY(TVN_KEYDOWN, id, memberFxn)
#define ON_TCN_SELCHANGE(id, memberFxn)         ON_NOTIFY(TCN_SELCHANGE, id, memberFxn)
#define ON_TCN_SELCHANGING(id, memberFxn)       ON_NOTIFY(TCN_SELCHANGING, id, memberFxn)
#define ON_UDN_DELTAPOS(id, memberFxn)          ON_NOTIFY(UDN_DELTAPOS, id, memberFxn)
#define ON_HDN_ITEMCLICK(id, memberFxn)         ON_NOTIFY(HDN_ITEMCLICK, id, memberFxn)
#define ON_HDN_ENDTRACK(id, memberFxn)          ON_NOTIFY(HDN_ENDTRACK, id, memberFxn)

// WM_* message macros
#define ON_WM_CREATE() \
    { WM_CREATE, 0, 0, 0, AfxSig_i_LP, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<int (CWnd::*)(LPCREATESTRUCT)>(&ThisClass::OnCreate))) },
#define ON_WM_DESTROY() \
    { WM_DESTROY, 0, 0, 0, AfxSig_vv, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)()>(&ThisClass::OnDestroy))) },
#define ON_WM_CLOSE() \
    { WM_CLOSE, 0, 0, 0, AfxSig_vv, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)()>(&ThisClass::OnClose))) },
#define ON_WM_SIZE() \
    { WM_SIZE, 0, 0, 0, AfxSig_v_u_i_i, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, int, int)>(&ThisClass::OnSize))) },
#define ON_WM_SIZING() \
    { WM_SIZING, 0, 0, 0, AfxSig_v_u_r, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, LPRECT)>(&ThisClass::OnSizing))) },
#define ON_WM_MOVE() \
    { WM_MOVE, 0, 0, 0, AfxSig_v_i_i, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(int, int)>(&ThisClass::OnMove))) },
#define ON_WM_PAINT() \
    { WM_PAINT, 0, 0, 0, AfxSig_vv, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)()>(&ThisClass::OnPaint))) },
#define ON_WM_ERASEBKGND() \
    { WM_ERASEBKGND, 0, 0, 0, AfxSig_b_D, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)(CDC*)>(&ThisClass::OnEraseBkgnd))) },
#define ON_WM_PRINTCLIENT() \
    { WM_PRINTCLIENT, 0, 0, 0, AfxSig_v_D_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnPrintClient)) },
#define ON_WM_SETFOCUS() \
    { WM_SETFOCUS, 0, 0, 0, AfxSig_v_W, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(CWnd*)>(&ThisClass::OnSetFocus))) },
#define ON_WM_KILLFOCUS() \
    { WM_KILLFOCUS, 0, 0, 0, AfxSig_v_W, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(CWnd*)>(&ThisClass::OnKillFocus))) },
#define ON_WM_ACTIVATE() \
    { WM_ACTIVATE, 0, 0, 0, AfxSig_v_u_W_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CWnd*, BOOL)>(&ThisClass::OnActivate))) },
#define ON_WM_MOUSEACTIVATE() \
    { WM_MOUSEACTIVATE, 0, 0, 0, AfxSig_i_W_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnMouseActivate)) },
#define ON_WM_MDIACTIVATE() \
    { WM_MDIACTIVATE, 0, 0, 0, AfxSig_v_b_W_W, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnMDIActivate)) },
#define ON_WM_ENABLE() \
    { WM_ENABLE, 0, 0, 0, AfxSig_v_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(BOOL)>(&ThisClass::OnEnable))) },
#define ON_WM_SHOWWINDOW() \
    { WM_SHOWWINDOW, 0, 0, 0, AfxSig_v_b_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnShowWindow)) },
#define ON_WM_GETMINMAXINFO() \
    { WM_GETMINMAXINFO, 0, 0, 0, AfxSig_v_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(MINMAXINFO*)>(&ThisClass::OnGetMinMaxInfo))) },
#define ON_WM_WINDOWPOSCHANGED() \
    { WM_WINDOWPOSCHANGED, 0, 0, 0, AfxSig_v_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(WINDOWPOS*)>(&ThisClass::OnWindowPosChanged))) },
#define ON_WM_NCCALCSIZE() \
    { WM_NCCALCSIZE, 0, 0, 0, AfxSig_v_b_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(BOOL, NCCALCSIZE_PARAMS*)>(&ThisClass::OnNcCalcSize))) },
#define ON_WM_NCHITTEST() \
    { WM_NCHITTEST, 0, 0, 0, AfxSig_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<LRESULT (CWnd::*)(CPoint)>(&ThisClass::OnNcHitTest))) },
#define ON_WM_NCPAINT() \
    { WM_NCPAINT, 0, 0, 0, AfxSig_vv, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)()>(&ThisClass::OnNcPaint))) },
#define ON_WM_NCACTIVATE() \
    { WM_NCACTIVATE, 0, 0, 0, AfxSig_b_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)(BOOL)>(&ThisClass::OnNcActivate))) },
#define ON_WM_NCLBUTTONDOWN() \
    { WM_NCLBUTTONDOWN, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnNcLButtonDown))) },
#define ON_WM_NCLBUTTONUP() \
    { WM_NCLBUTTONUP, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnNcLButtonUp))) },
#define ON_WM_NCLBUTTONDBLCLK() \
    { WM_NCLBUTTONDBLCLK, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnNcLButtonDblClk))) },
#define ON_WM_NCMOUSEMOVE() \
    { WM_NCMOUSEMOVE, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnNcMouseMove))) },
#define ON_WM_MOUSEMOVE() \
    { WM_MOUSEMOVE, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnMouseMove))) },
#define ON_WM_MOUSEHOVER() \
    { WM_MOUSEHOVER, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnMouseHover))) },
#define ON_WM_MOUSELEAVE() \
    { WM_MOUSELEAVE, 0, 0, 0, AfxSig_vv, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)()>(&ThisClass::OnMouseLeave))) },
#define ON_WM_LBUTTONDOWN() \
    { WM_LBUTTONDOWN, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnLButtonDown))) },
#define ON_WM_LBUTTONUP() \
    { WM_LBUTTONUP, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnLButtonUp))) },
#define ON_WM_LBUTTONDBLCLK() \
    { WM_LBUTTONDBLCLK, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnLButtonDblClk))) },
#define ON_WM_RBUTTONDOWN() \
    { WM_RBUTTONDOWN, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnRButtonDown))) },
#define ON_WM_RBUTTONUP() \
    { WM_RBUTTONUP, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnRButtonUp))) },
#define ON_WM_RBUTTONDBLCLK() \
    { WM_RBUTTONDBLCLK, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnRButtonDblClk))) },
#define ON_WM_MBUTTONDOWN() \
    { WM_MBUTTONDOWN, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnMButtonDown))) },
#define ON_WM_MBUTTONUP() \
    { WM_MBUTTONUP, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnMButtonUp))) },
#define ON_WM_MBUTTONDBLCLK() \
    { WM_MBUTTONDBLCLK, 0, 0, 0, AfxSig_v_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, CPoint)>(&ThisClass::OnMButtonDblClk))) },
#define ON_WM_XBUTTONDOWN() \
    { WM_XBUTTONDOWN, 0, 0, 0, AfxSig_v_u_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnXButtonDown)) },
#define ON_WM_XBUTTONUP() \
    { WM_XBUTTONUP, 0, 0, 0, AfxSig_v_u_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnXButtonUp)) },
#define ON_WM_XBUTTONDBLCLK() \
    { WM_XBUTTONDBLCLK, 0, 0, 0, AfxSig_v_u_u_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnXButtonDblClk)) },
#define ON_WM_MOUSEWHEEL() \
    { WM_MOUSEWHEEL, 0, 0, 0, AfxSig_b_u_s_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)(UINT, short, CPoint)>(&ThisClass::OnMouseWheel))) },
#define ON_WM_MOUSEHWHEEL() \
    { WM_MOUSEHWHEEL, 0, 0, 0, AfxSig_v_u_s_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnMouseHWheel)) },
#define ON_WM_KEYDOWN() \
    { WM_KEYDOWN, 0, 0, 0, AfxSig_v_u_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, UINT)>(&ThisClass::OnKeyDown))) },
#define ON_WM_KEYUP() \
    { WM_KEYUP, 0, 0, 0, AfxSig_v_u_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, UINT)>(&ThisClass::OnKeyUp))) },
#define ON_WM_SYSKEYDOWN() \
    { WM_SYSKEYDOWN, 0, 0, 0, AfxSig_v_u_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, UINT)>(&ThisClass::OnSysKeyDown))) },
#define ON_WM_SYSKEYUP() \
    { WM_SYSKEYUP, 0, 0, 0, AfxSig_v_u_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, UINT)>(&ThisClass::OnSysKeyUp))) },
#define ON_WM_CHAR() \
    { WM_CHAR, 0, 0, 0, AfxSig_v_u_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, UINT)>(&ThisClass::OnChar))) },
#define ON_WM_HSCROLL() \
    { WM_HSCROLL, 0, 0, 0, AfxSig_v_u_u_W, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, CScrollBar*)>(&ThisClass::OnHScroll))) },
#define ON_WM_VSCROLL() \
    { WM_VSCROLL, 0, 0, 0, AfxSig_v_u_u_W, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, UINT, CScrollBar*)>(&ThisClass::OnVScroll))) },
#define ON_WM_TIMER() \
    { WM_TIMER, 0, 0, 0, AfxSig_v_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT_PTR)>(&ThisClass::OnTimer))) },
#define ON_WM_SETCURSOR() \
    { WM_SETCURSOR, 0, 0, 0, AfxSig_b_W_u_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)(CWnd*, UINT, UINT)>(&ThisClass::OnSetCursor))) },
#define ON_WM_CONTEXTMENU() \
    { WM_CONTEXTMENU, 0, 0, 0, AfxSig_v_W_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(CWnd*, CPoint)>(&ThisClass::OnContextMenu))) },
#define ON_WM_INITMENU() \
    { WM_INITMENU, 0, 0, 0, AfxSig_v_M, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnInitMenu)) },
#define ON_WM_INITMENUPOPUP() \
    { WM_INITMENUPOPUP, 0, 0, 0, AfxSig_v_M_u_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(CMenu*, UINT, BOOL)>(&ThisClass::OnInitMenuPopup))) },
#define ON_WM_ENTERMENULOOP() \
    { WM_ENTERMENULOOP, 0, 0, 0, AfxSig_v_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnEnterMenuLoop)) },
#define ON_WM_EXITMENULOOP() \
    { WM_EXITMENULOOP, 0, 0, 0, AfxSig_v_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnExitMenuLoop)) },
#define ON_WM_MENUSELECT() \
    { WM_MENUSELECT, 0, 0, 0, AfxSig_v_u_u_M, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnMenuSelect)) },
#define ON_WM_CTLCOLOR() \
    { WM_CTLCOLOR, 0, 0, 0, AfxSig_B_D_W_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<HBRUSH (CWnd::*)(CDC*, CWnd*, UINT)>(&ThisClass::OnCtlColor))) },
#ifndef WM_REFLECT_BASE
#define WM_REFLECT_BASE 0xBC00
#endif
#define ON_WM_CTLCOLOR_REFLECT() \
    { WM_CTLCOLOR + WM_REFLECT_BASE, 0, 0, 0, AfxSig_B_D_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::CtlColor)) },
#define ON_WM_DRAWITEM() \
    { WM_DRAWITEM, 0, 0, 0, AfxSig_v_i_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(int, LPDRAWITEMSTRUCT)>(&ThisClass::OnDrawItem))) },
#define ON_WM_MEASUREITEM() \
    { WM_MEASUREITEM, 0, 0, 0, AfxSig_v_i_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(int, LPMEASUREITEMSTRUCT)>(&ThisClass::OnMeasureItem))) },
#define ON_WM_COMPAREITEM() \
    { WM_COMPAREITEM, 0, 0, 0, AfxSig_i_i_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnCompareItem)) },
#define ON_WM_DELETEITEM() \
    { WM_DELETEITEM, 0, 0, 0, AfxSig_v_i_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnDeleteItem)) },
#define ON_WM_VKEYTOITEM() \
    { WM_VKEYTOITEM, 0, 0, 0, AfxSig_i_u_W_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnVKeyToItem)) },
#define ON_WM_CHARTOITEM() \
    { WM_CHARTOITEM, 0, 0, 0, AfxSig_i_u_W_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnCharToItem)) },
#define ON_WM_DROPFILES() \
    { WM_DROPFILES, 0, 0, 0, AfxSig_v_h, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(HDROP)>(&ThisClass::OnDropFiles))) },
#define ON_WM_GETDLGCODE() \
    { WM_GETDLGCODE, 0, 0, 0, AfxSig_u_v, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<UINT (CWnd::*)()>(&ThisClass::OnGetDlgCode))) },
#define ON_WM_QUERYENDSESSION() \
    { WM_QUERYENDSESSION, 0, 0, 0, AfxSig_b_v, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)()>(&ThisClass::OnQueryEndSession))) },
#define ON_WM_ENDSESSION() \
    { WM_ENDSESSION, 0, 0, 0, AfxSig_v_b, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(BOOL)>(&ThisClass::OnEndSession))) },
#define ON_WM_SYSCOLORCHANGE() \
    { WM_SYSCOLORCHANGE, 0, 0, 0, AfxSig_vv, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)()>(&ThisClass::OnSysColorChange))) },
#define ON_WM_SETTINGCHANGE() \
    { WM_SETTINGCHANGE, 0, 0, 0, AfxSig_v_u_s, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(&ThisClass::OnSettingChange)) },
#define ON_WM_SYSCOMMAND() \
    { WM_SYSCOMMAND, 0, 0, 0, AfxSig_v_u_l, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(UINT, LPARAM)>(&ThisClass::OnSysCommand))) },
#define ON_WM_COPYDATA() \
    { WM_COPYDATA, 0, 0, 0, AfxSig_b_W_p, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)(CWnd*, COPYDATASTRUCT*)>(&ThisClass::OnCopyData))) },
#define ON_WM_DEVICECHANGE() \
    { WM_DEVICECHANGE, 0, 0, 0, AfxSig_b_u_l, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<BOOL (CWnd::*)(UINT, DWORD_PTR)>(&ThisClass::OnDeviceChange))) },
#define ON_WM_ACTIVATEAPP() \
    { WM_ACTIVATEAPP, 0, 0, 0, AfxSig_v_b_u, static_cast<AFX_PMSG>(reinterpret_cast<void (CCmdTarget::*)()>(static_cast<void (CWnd::*)(BOOL, DWORD)>(&ThisClass::OnActivateApp))) },

enum {
    AfxSig_v_D_u = 100,
    AfxSig_i_W_u_u,
    AfxSig_v_b_W_W,
    AfxSig_v_b_u,
    AfxSig_v_u_u_p,
    AfxSig_v_u_s_p,
    AfxSig_v_M,
    AfxSig_v_u_u_M,
    AfxSig_B_D_u,
    AfxSig_i_i_p,
    AfxSig_v_u_s,
    AfxSig_v_u_l,
    AfxSig_b_W_p,
    AfxSig_b_u_l
};

#define CN_COMMAND 0
#define CN_UPDATE_COMMAND_UI ((UINT)(-1))

// CCmdUI
class CCmdUI {
public:
    UINT m_nID = 0;
    UINT m_nIndex = 0;
    CMenu* m_pMenu = nullptr;
    CMenu* m_pSubMenu = nullptr;
    CWnd* m_pOther = nullptr;
    BOOL m_bEnableChanged = FALSE;
    BOOL m_bContinueRouting = FALSE;
    UINT m_nIndexMax = 0;

    virtual void Enable(BOOL bOn = TRUE);
    virtual void SetCheck(int nCheck = 1);
    virtual void SetRadio(BOOL bOn = TRUE);
    virtual void SetText(LPCTSTR lpszText);
    void ContinueRouting() { m_bContinueRouting = TRUE; }
    void DoUpdate(CCmdTarget* pTarget, BOOL bDisableIfNoHndler);
};

// CCmdTarget
class CCmdTarget : public CObject {
    DECLARE_DYNAMIC(CCmdTarget)
public:
    CCmdTarget() = default;
    ~CCmdTarget() override = default;

    void BeginWaitCursor() {}
    void EndWaitCursor() {}
    void RestoreWaitCursor() {}

    virtual BOOL OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo);
protected:
    static const AFX_MSGMAP* GetThisMessageMap();
    virtual const AFX_MSGMAP* GetMessageMap() const { return GetThisMessageMap(); }
};

// GDI classes: CGdiObject, CPen, CBrush, CFont, CBitmap, CRgn, CPalette
class CGdiObject : public CObject {
public:
    HGDIOBJ m_hObject = nullptr;

    CGdiObject() = default;
    ~CGdiObject() override { DeleteObject(); }

    operator HGDIOBJ() const noexcept { return m_hObject; }
    HGDIOBJ GetSafeHandle() const noexcept { return this ? m_hObject : nullptr; }

    BOOL Attach(HGDIOBJ hObject) {
        if (m_hObject && m_hObject != hObject) ::DeleteObject(m_hObject);
        m_hObject = hObject;
        return hObject != nullptr;
    }
    HGDIOBJ Detach() {
        HGDIOBJ h = m_hObject;
        m_hObject = nullptr;
        return h;
    }
    BOOL DeleteObject() {
        if (!m_hObject) return FALSE;
        return ::DeleteObject(Detach());
    }
    int GetObject(int nCount, LPVOID lpObject) const {
        return ::GetObject(m_hObject, nCount, lpObject);
    }
    BOOL CreateStockObject(int nIndex) {
        return (m_hObject = ::GetStockObject(nIndex)) != nullptr;
    }
};

class CPen : public CGdiObject {
public:
    CPen() = default;
    CPen(int nPenStyle, int nWidth, COLORREF crColor) { CreatePen(nPenStyle, nWidth, crColor); }
    operator HPEN() const noexcept { return (HPEN)m_hObject; }
    static CPen* FromHandle(HPEN hPen);
    BOOL CreatePen(int nPenStyle, int nWidth, COLORREF crColor) {
        return Attach(::CreatePen(nPenStyle, nWidth, crColor));
    }
};

class CBrush : public CGdiObject {
public:
    CBrush() = default;
    explicit CBrush(COLORREF crColor) { CreateSolidBrush(crColor); }
    operator HBRUSH() const noexcept { return (HBRUSH)m_hObject; }
    static CBrush* FromHandle(HBRUSH hBrush);
    BOOL CreateSolidBrush(COLORREF crColor) {
        return Attach(::CreateSolidBrush(crColor));
    }
    BOOL CreateSysColorBrush(int nIndex) {
        return Attach(::GetSysColorBrush(nIndex));
    }
    BOOL CreatePatternBrush(CBitmap* pBitmap);
};

class CFont : public CGdiObject {
public:
    CFont() = default;
    operator HFONT() const noexcept { return (HFONT)m_hObject; }
    static CFont* FromHandle(HFONT hFont);
    BOOL CreateFontIndirect(const LOGFONT* lpLogFont) {
        return Attach(::CreateFontIndirect(lpLogFont));
    }
    BOOL CreateFont(int nHeight, int nWidth, int nEscapement, int nOrientation, int nWeight,
                    BYTE bItalic, BYTE bUnderline, BYTE cStrikeOut, BYTE nCharSet,
                    BYTE nOutPrecision, BYTE nClipPrecision, BYTE nQuality,
                    BYTE nPitchAndFamily, LPCTSTR lpszFacename) {
        return Attach(::CreateFont(nHeight, nWidth, nEscapement, nOrientation, nWeight,
                                   bItalic, bUnderline, cStrikeOut, nCharSet,
                                   nOutPrecision, nClipPrecision, nQuality,
                                   nPitchAndFamily, lpszFacename));
    }
    BOOL CreatePointFont(int nPointSize, LPCTSTR lpszFaceName, CDC* pDC = nullptr);
    BOOL CreatePointFontIndirect(const LOGFONT* lpLogFont, CDC* pDC = nullptr);
    int GetLogFont(LOGFONT* pLogFont) const {
        return ::GetObject(m_hObject, sizeof(LOGFONT), pLogFont);
    }
};

class CBitmap : public CGdiObject {
public:
    CBitmap() = default;
    operator HBITMAP() const noexcept { return (HBITMAP)m_hObject; }
    static CBitmap* FromHandle(HBITMAP hBitmap);
    BOOL LoadBitmap(LPCTSTR lpszResourceName);
    BOOL LoadBitmap(UINT nIDResource) { return LoadBitmap(MAKEINTRESOURCE(nIDResource)); }
    BOOL CreateBitmap(int nWidth, int nHeight, UINT nPlanes, UINT nBitcount, const void* lpBits) {
        return Attach(::CreateBitmap(nWidth, nHeight, nPlanes, nBitcount, lpBits));
    }
    BOOL CreateCompatibleBitmap(CDC* pDC, int nWidth, int nHeight);
    int GetBitmap(BITMAP* pBitMap) const {
        return ::GetObject(m_hObject, sizeof(BITMAP), pBitMap);
    }
};

class CRgn : public CGdiObject {
public:
    CRgn() = default;
    operator HRGN() const noexcept { return (HRGN)m_hObject; }
    static CRgn* FromHandle(HRGN hRgn);
    BOOL CreateRectRgn(int x1, int y1, int x2, int y2) {
        return Attach(::CreateRectRgn(x1, y1, x2, y2));
    }
    BOOL CreateRectRgnIndirect(LPCRECT lpRect) {
        return Attach(::CreateRectRgnIndirect(lpRect));
    }
    BOOL CreatePolygonRgn(LPPOINT lpPoints, int nCount, int nMode) {
        return Attach(::CreatePolygonRgn(lpPoints, nCount, nMode));
    }
    int CombineRgn(const CRgn* pRgn1, const CRgn* pRgn2, int nCombineMode) {
        return ::CombineRgn((HRGN)m_hObject, (HRGN)pRgn1->GetSafeHandle(), (HRGN)pRgn2->GetSafeHandle(), nCombineMode);
    }
    BOOL PtInRegion(int x, int y) const { return ::PtInRegion((HRGN)m_hObject, x, y); }
    BOOL PtInRegion(POINT point) const { return ::PtInRegion((HRGN)m_hObject, point.x, point.y); }
};

class CPalette : public CGdiObject {
public:
    CPalette() = default;
    operator HPALETTE() const noexcept { return (HPALETTE)m_hObject; }
};

// CDC and derived classes
class CDC : public CObject {
    DECLARE_DYNAMIC(CDC)
public:
    HDC m_hDC = nullptr;
    HDC m_hAttribDC = nullptr;
    BOOL m_bPrinting = FALSE;

    CDC() = default;
    ~CDC() override { DeleteDC(); }

    operator HDC() const noexcept { return m_hDC; }
    HDC GetSafeHdc() const noexcept { return this ? m_hDC : nullptr; }
    static CDC* FromHandle(HDC hDC);

    BOOL Attach(HDC hDC) {
        m_hDC = m_hAttribDC = hDC;
        return hDC != nullptr;
    }
    HDC Detach() {
        HDC h = m_hDC;
        m_hDC = m_hAttribDC = nullptr;
        return h;
    }
    BOOL CreateCompatibleDC(CDC* pDC) {
        return Attach(::CreateCompatibleDC(pDC ? pDC->GetSafeHdc() : nullptr));
    }
    BOOL DeleteDC() {
        if (!m_hDC) return FALSE;
        return ::DeleteDC(Detach());
    }

    virtual int SaveDC() { return ::SaveDC(m_hDC); }
    virtual BOOL RestoreDC(int nSavedDC) { return ::RestoreDC(m_hDC, nSavedDC); }
    int GetDeviceCaps(int nIndex) const { return ::GetDeviceCaps(m_hDC, nIndex); }

    HGDIOBJ SelectObject(HGDIOBJ hObject) { return ::SelectObject(m_hDC, hObject); }
    CGdiObject* SelectObject(CGdiObject* pObject);
    CPen* SelectObject(CPen* pPen);
    CBrush* SelectObject(CBrush* pBrush);
    virtual CFont* SelectObject(CFont* pFont);
    CBitmap* SelectObject(CBitmap* pBitmap);
    int SelectObject(CRgn* pRgn) { return ::SelectClipRgn(m_hDC, pRgn ? (HRGN)pRgn->GetSafeHandle() : nullptr); }
    virtual CGdiObject* SelectStockObject(int nIndex);

    COLORREF GetBkColor() const { return ::GetBkColor(m_hDC); }
    virtual COLORREF SetBkColor(COLORREF crColor) { return ::SetBkColor(m_hDC, crColor); }
    int GetBkMode() const { return ::GetBkMode(m_hDC); }
    int SetBkMode(int nBkMode) { return ::SetBkMode(m_hDC, nBkMode); }
    int GetROP2() const { return ::GetROP2(m_hDC); }
    int SetROP2(int nDrawMode) { return ::SetROP2(m_hDC, nDrawMode); }
    int SetStretchBltMode(int nStretchMode) { return ::SetStretchBltMode(m_hDC, nStretchMode); }
    COLORREF GetTextColor() const { return ::GetTextColor(m_hDC); }
    virtual COLORREF SetTextColor(COLORREF crColor) { return ::SetTextColor(m_hDC, crColor); }
    UINT SetTextAlign(UINT nFlags) { return ::SetTextAlign(m_hDC, nFlags); }
    COLORREF SetDCBrushColor(COLORREF crColor) { return ::SetDCBrushColor(m_hDC, crColor); }
    COLORREF SetDCPenColor(COLORREF crColor) { return ::SetDCPenColor(m_hDC, crColor); }

    CPoint GetViewportOrg() const { POINT pt{}; ::GetViewportOrgEx(m_hDC, &pt); return pt; }
    virtual CPoint SetViewportOrg(int x, int y) { POINT pt{}; ::SetViewportOrgEx(m_hDC, x, y, &pt); return pt; }
    CPoint SetViewportOrg(POINT point) { return SetViewportOrg(point.x, point.y); }
    virtual CPoint OffsetViewportOrg(int nWidth, int nHeight) { POINT pt{}; ::OffsetViewportOrgEx(m_hDC, nWidth, nHeight, &pt); return pt; }
    CPoint GetWindowOrg() const { POINT pt{}; ::GetWindowOrgEx(m_hDC, &pt); return pt; }
    CPoint SetWindowOrg(int x, int y) { POINT pt{}; ::SetWindowOrgEx(m_hDC, x, y, &pt); return pt; }
    CPoint SetWindowOrg(POINT point) { return SetWindowOrg(point.x, point.y); }

    virtual int SelectClipRgn(CRgn* pRgn) { return ::SelectClipRgn(m_hDC, pRgn ? (HRGN)pRgn->GetSafeHandle() : nullptr); }
    int SelectClipRgn(CRgn* pRgn, int nMode) { return ::ExtSelectClipRgn(m_hDC, pRgn ? (HRGN)pRgn->GetSafeHandle() : nullptr, nMode); }
    int ExcludeClipRect(int x1, int y1, int x2, int y2) { return ::ExcludeClipRect(m_hDC, x1, y1, x2, y2); }
    int ExcludeClipRect(LPCRECT lpRect) { return ::ExcludeClipRect(m_hDC, lpRect->left, lpRect->top, lpRect->right, lpRect->bottom); }
    int IntersectClipRect(int x1, int y1, int x2, int y2) { return ::IntersectClipRect(m_hDC, x1, y1, x2, y2); }
    int IntersectClipRect(LPCRECT lpRect) { return ::IntersectClipRect(m_hDC, lpRect->left, lpRect->top, lpRect->right, lpRect->bottom); }
    int GetClipBox(LPRECT lpRect) const { return ::GetClipBox(m_hDC, lpRect); }
    BOOL RectVisible(LPCRECT lpRect) const { return ::RectVisible(m_hDC, lpRect); }

    CPoint MoveTo(int x, int y) { POINT pt{}; ::MoveToEx(m_hDC, x, y, &pt); return pt; }
    CPoint MoveTo(POINT point) { return MoveTo(point.x, point.y); }
    BOOL LineTo(int x, int y) { return ::LineTo(m_hDC, x, y); }
    BOOL LineTo(POINT point) { return ::LineTo(m_hDC, point.x, point.y); }
    BOOL Polyline(const POINT* lpPoints, int nCount) { return ::Polyline(m_hDC, lpPoints, nCount); }
    BOOL Polygon(const POINT* lpPoints, int nCount) { return ::Polygon(m_hDC, lpPoints, nCount); }
    BOOL Rectangle(int x1, int y1, int x2, int y2) { return ::Rectangle(m_hDC, x1, y1, x2, y2); }
    BOOL Rectangle(LPCRECT lpRect) { return ::Rectangle(m_hDC, lpRect->left, lpRect->top, lpRect->right, lpRect->bottom); }
    BOOL RoundRect(int x1, int y1, int x2, int y2, int x3, int y3) { return ::RoundRect(m_hDC, x1, y1, x2, y2, x3, y3); }
    BOOL RoundRect(LPCRECT lpRect, POINT point) { return ::RoundRect(m_hDC, lpRect->left, lpRect->top, lpRect->right, lpRect->bottom, point.x, point.y); }
    BOOL Ellipse(int x1, int y1, int x2, int y2) { return ::Ellipse(m_hDC, x1, y1, x2, y2); }
    BOOL Ellipse(LPCRECT lpRect) { return ::Ellipse(m_hDC, lpRect->left, lpRect->top, lpRect->right, lpRect->bottom); }
    BOOL Arc(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) { return ::Arc(m_hDC, x1, y1, x2, y2, x3, y3, x4, y4); }
    BOOL Arc(LPCRECT lpRect, POINT ptStart, POINT ptEnd) { return ::Arc(m_hDC, lpRect->left, lpRect->top, lpRect->right, lpRect->bottom, ptStart.x, ptStart.y, ptEnd.x, ptEnd.y); }
    BOOL Pie(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) { return ::Pie(m_hDC, x1, y1, x2, y2, x3, y3, x4, y4); }
    BOOL FillRgn(CRgn* pRgn, CBrush* pBrush) { return ::FillRgn(m_hDC, (HRGN)pRgn->GetSafeHandle(), (HBRUSH)pBrush->GetSafeHandle()); }

    void FillRect(LPCRECT lpRect, CBrush* pBrush) { ::FillRect(m_hDC, lpRect, pBrush ? (HBRUSH)pBrush->GetSafeHandle() : nullptr); }
    void FrameRect(LPCRECT lpRect, CBrush* pBrush) { ::FrameRect(m_hDC, lpRect, pBrush ? (HBRUSH)pBrush->GetSafeHandle() : nullptr); }
    void InvertRect(LPCRECT lpRect) { ::InvertRect(m_hDC, lpRect); }
    BOOL DrawIcon(int x, int y, HICON hIcon) { return ::DrawIcon(m_hDC, x, y, hIcon); }
    BOOL DrawIcon(POINT point, HICON hIcon) { return ::DrawIcon(m_hDC, point.x, point.y, hIcon); }

    void FillSolidRect(LPCRECT lpRect, COLORREF clr) {
        if (!lpRect) return;
        HBRUSH hbr = ::CreateSolidBrush(clr);
        ::FillRect(m_hDC, lpRect, hbr);
        ::DeleteObject(hbr);
    }
    void FillSolidRect(int x, int y, int cx, int cy, COLORREF clr) {
        RECT r = {x, y, x + cx, y + cy};
        FillSolidRect(&r, clr);
    }
    void Draw3dRect(LPCRECT lpRect, COLORREF clrTopLeft, COLORREF clrBottomRight) {
        if (lpRect) Draw3dRect(lpRect->left, lpRect->top, lpRect->right - lpRect->left, lpRect->bottom - lpRect->top, clrTopLeft, clrBottomRight);
    }
    void Draw3dRect(int x, int y, int cx, int cy, COLORREF clrTopLeft, COLORREF clrBottomRight) {
        FillSolidRect(x, y, cx - 1, 1, clrTopLeft);
        FillSolidRect(x, y, 1, cy - 1, clrTopLeft);
        FillSolidRect(x + cx, y, -1, cy, clrBottomRight);
        FillSolidRect(x, y + cy, cx, -1, clrBottomRight);
    }

    BOOL DrawEdge(LPRECT lpRect, UINT nEdge, UINT nFlags) { return ::DrawEdge(m_hDC, lpRect, nEdge, nFlags); }
    BOOL DrawFrameControl(LPRECT lpRect, UINT nType, UINT nState) { return ::DrawFrameControl(m_hDC, lpRect, nType, nState); }
    void DrawFocusRect(LPCRECT lpRect) { ::DrawFocusRect(m_hDC, lpRect); }

    BOOL BitBlt(int x, int y, int nWidth, int nHeight, CDC* pSrcDC, int xSrc, int ySrc, DWORD dwRop) {
        return ::BitBlt(m_hDC, x, y, nWidth, nHeight, pSrcDC ? pSrcDC->GetSafeHdc() : nullptr, xSrc, ySrc, dwRop);
    }
    BOOL StretchBlt(int x, int y, int nWidth, int nHeight, CDC* pSrcDC, int xSrc, int ySrc, int nSrcWidth, int nSrcHeight, DWORD dwRop) {
        return ::StretchBlt(m_hDC, x, y, nWidth, nHeight, pSrcDC ? pSrcDC->GetSafeHdc() : nullptr, xSrc, ySrc, nSrcWidth, nSrcHeight, dwRop);
    }
    BOOL TransparentBlt(int xDest, int yDest, int nDestWidth, int nDestHeight, CDC* pSrcDC, int xSrc, int ySrc, int nSrcWidth, int nSrcHeight, UINT clrTransparent) {
        return ::TransparentBlt(m_hDC, xDest, yDest, nDestWidth, nDestHeight, pSrcDC ? pSrcDC->GetSafeHdc() : nullptr, xSrc, ySrc, nSrcWidth, nSrcHeight, clrTransparent);
    }
    BOOL PatBlt(int x, int y, int nWidth, int nHeight, DWORD dwRop) {
        return ::PatBlt(m_hDC, x, y, nWidth, nHeight, dwRop);
    }
    static CBrush* GetHalftoneBrush() {
        static CBrush halftoneBrush;
        static bool init = false;
        if (!init) {
            WORD grayPattern[8] = { 0x5555, 0xAAAA, 0x5555, 0xAAAA, 0x5555, 0xAAAA, 0x5555, 0xAAAA };
            HBITMAP hBitmap = ::CreateBitmap(8, 8, 1, 1, grayPattern);
            if (hBitmap) {
                halftoneBrush.CreatePatternBrush(CBitmap::FromHandle(hBitmap));
                ::DeleteObject(hBitmap);
            }
            init = true;
        }
        return &halftoneBrush;
    }
    COLORREF GetPixel(int x, int y) const { return ::GetPixel(m_hDC, x, y); }
    COLORREF GetPixel(POINT point) const { return ::GetPixel(m_hDC, point.x, point.y); }
    COLORREF SetPixel(int x, int y, COLORREF crColor) { return ::SetPixel(m_hDC, x, y, crColor); }
    COLORREF SetPixel(POINT point, COLORREF crColor) { return ::SetPixel(m_hDC, point.x, point.y, crColor); }
    BOOL SetPixelV(int x, int y, COLORREF crColor) { return ::SetPixelV(m_hDC, x, y, crColor); }
    BOOL SetPixelV(POINT point, COLORREF crColor) { return ::SetPixelV(m_hDC, point.x, point.y, crColor); }

    BOOL TextOut(int x, int y, LPCTSTR lpszString, int nCount) { return ::TextOut(m_hDC, x, y, lpszString, nCount); }
    BOOL TextOut(int x, int y, const CString& str) { return ::TextOut(m_hDC, x, y, str.GetString(), str.GetLength()); }
    BOOL ExtTextOut(int x, int y, UINT nOptions, LPCRECT lpRect, LPCTSTR lpszString, UINT nCount, LPINT lpDxWidths = nullptr) {
        return ::ExtTextOut(m_hDC, x, y, nOptions, lpRect, lpszString, nCount, lpDxWidths);
    }
    BOOL ExtTextOut(int x, int y, UINT nOptions, LPCRECT lpRect, const CString& str, LPINT lpDxWidths = nullptr) {
        return ::ExtTextOut(m_hDC, x, y, nOptions, lpRect, str.GetString(), str.GetLength(), lpDxWidths);
    }
    virtual int DrawText(LPCTSTR lpszString, int nCount, LPRECT lpRect, UINT nFormat) {
        return ::DrawText(m_hDC, lpszString, nCount, lpRect, nFormat);
    }
    int DrawText(const CString& str, LPRECT lpRect, UINT nFormat) {
        return ::DrawText(m_hDC, str.GetString(), str.GetLength(), lpRect, nFormat);
    }
    CSize GetTextExtent(LPCTSTR lpszString, int nCount) const {
        SIZE sz{};
        ::GetTextExtentPoint32(m_hDC, lpszString, nCount, &sz);
        return sz;
    }
    CSize GetTextExtent(const CString& str) const {
        return GetTextExtent(str.GetString(), str.GetLength());
    }
    BOOL GetTextMetrics(LPTEXTMETRIC lpMetrics) const {
        return ::GetTextMetrics(m_hDC, lpMetrics);
    }
    void LPtoDP(LPSIZE lpSize) const { (void)lpSize; }
    void DPtoLP(LPSIZE lpSize) const { (void)lpSize; }
    void LPtoDP(LPRECT lpRect) const { (void)lpRect; }
    void DPtoLP(LPRECT lpRect) const { (void)lpRect; }
};

class CPaintDC : public CDC {
public:
    HWND m_hWnd = nullptr;
    PAINTSTRUCT m_ps{};
    explicit CPaintDC(CWnd* pWnd);
    ~CPaintDC() override;
};

class CClientDC : public CDC {
public:
    HWND m_hWnd = nullptr;
    explicit CClientDC(CWnd* pWnd);
    ~CClientDC() override;
};

class CWindowDC : public CDC {
public:
    HWND m_hWnd = nullptr;
    explicit CWindowDC(CWnd* pWnd);
    ~CWindowDC() override;
};

class CMetaFileDC : public CDC {
public:
    CMetaFileDC() = default;
    BOOL CreateEnhanced(CDC* pDCRef, LPCTSTR lpszFileName, LPCRECT lpBounds, LPCTSTR lpszDescription) {
        (void)pDCRef; (void)lpszFileName; (void)lpBounds; (void)lpszDescription;
        return CreateCompatibleDC(pDCRef);
    }
    HENHMETAFILE CloseEnhanced() {
        DeleteDC();
        return nullptr;
    }
};

// CMenu
class CMenu : public CObject {
public:
    HMENU m_hMenu = nullptr;

    CMenu() = default;
    ~CMenu() override { DestroyMenu(); }

    operator HMENU() const noexcept { return m_hMenu; }
    HMENU GetSafeHmenu() const noexcept { return this ? m_hMenu : nullptr; }
    static CMenu* FromHandle(HMENU hMenu);

    BOOL Attach(HMENU hMenu) { m_hMenu = hMenu; return hMenu != nullptr; }
    HMENU Detach() { HMENU h = m_hMenu; m_hMenu = nullptr; return h; }
    BOOL CreateMenu() { return Attach(::CreateMenu()); }
    BOOL CreatePopupMenu() { return Attach(::CreatePopupMenu()); }
    BOOL LoadMenu(LPCTSTR lpszResourceName);
    BOOL LoadMenu(UINT nIDResource) { return LoadMenu(MAKEINTRESOURCE(nIDResource)); }
    BOOL DestroyMenu() {
        if (!m_hMenu) return FALSE;
        return ::DestroyMenu(Detach());
    }

    BOOL AppendMenu(UINT nFlags, UINT_PTR nIDNewItem = 0, LPCTSTR lpszNewItem = nullptr) {
        return ::AppendMenu(m_hMenu, nFlags, nIDNewItem, lpszNewItem);
    }
    BOOL AppendMenu(UINT nFlags, UINT_PTR nIDNewItem, const CBitmap* pBmp) {
        return ::AppendMenu(m_hMenu, nFlags | MF_BITMAP, nIDNewItem, (LPCTSTR)pBmp->GetSafeHandle());
    }
    BOOL InsertMenu(UINT nPosition, UINT nFlags, UINT_PTR nIDNewItem = 0, LPCTSTR lpszNewItem = nullptr) {
        return ::InsertMenu(m_hMenu, nPosition, nFlags, nIDNewItem, lpszNewItem);
    }
    BOOL ModifyMenu(UINT nPosition, UINT nFlags, UINT_PTR nIDNewItem = 0, LPCTSTR lpszNewItem = nullptr) {
        return ::ModifyMenu(m_hMenu, nPosition, nFlags, nIDNewItem, lpszNewItem);
    }
    BOOL ModifyMenu(UINT nPosition, UINT nFlags, UINT_PTR nIDNewItem, const CBitmap* pBmp) {
        return ::ModifyMenu(m_hMenu, nPosition, nFlags | MF_BITMAP, nIDNewItem, (LPCTSTR)pBmp->GetSafeHandle());
    }
    BOOL RemoveMenu(UINT nPosition, UINT nFlags) { return ::RemoveMenu(m_hMenu, nPosition, nFlags); }
    BOOL DeleteMenu(UINT nPosition, UINT nFlags) { return ::DeleteMenu(m_hMenu, nPosition, nFlags); }

    UINT CheckMenuItem(UINT nIDCheckItem, UINT nCheck) { return ::CheckMenuItem(m_hMenu, nIDCheckItem, nCheck); }
    BOOL CheckMenuRadioItem(UINT nIDFirst, UINT nIDLast, UINT nIDItem, UINT nFlags) {
        return ::CheckMenuRadioItem(m_hMenu, nIDFirst, nIDLast, nIDItem, nFlags);
    }
    UINT EnableMenuItem(UINT nIDEnableItem, UINT nEnable) { return ::EnableMenuItem(m_hMenu, nIDEnableItem, nEnable); }
    BOOL SetDefaultItem(UINT uItem, BOOL fByPos = FALSE) { return ::SetMenuDefaultItem(m_hMenu, uItem, fByPos); }
    UINT GetMenuItemCount() const { return (UINT)::GetMenuItemCount(m_hMenu); }
    UINT GetMenuItemID(int nPos) const { return ::GetMenuItemID(m_hMenu, nPos); }
    UINT GetMenuState(UINT nID, UINT nFlags) const { return ::GetMenuState(m_hMenu, nID, nFlags); }
    int GetMenuString(UINT nIDItem, LPTSTR lpString, int nMaxCount, UINT nFlags) const {
        return ::GetMenuString(m_hMenu, nIDItem, lpString, nMaxCount, nFlags);
    }
    int GetMenuString(UINT nIDItem, CString& rString, UINT nFlags) const {
        char buf[512] = {};
        int len = ::GetMenuStringA(m_hMenu, nIDItem, buf, sizeof(buf), nFlags);
        rString = buf;
        return len;
    }
    BOOL GetMenuItemInfo(UINT uItem, LPMENUITEMINFO lpMenuItemInfo, BOOL fByPos = FALSE) {
        return ::GetMenuItemInfo(m_hMenu, uItem, fByPos, lpMenuItemInfo);
    }
    BOOL SetMenuItemInfo(UINT uItem, LPMENUITEMINFO lpMenuItemInfo, BOOL fByPos = FALSE) {
        return ::SetMenuItemInfo(m_hMenu, uItem, fByPos, lpMenuItemInfo);
    }
    BOOL SetMenuItemBitmaps(UINT nPosition, UINT nFlags, const CBitmap* pBmpUnchecked, const CBitmap* pBmpChecked) {
        return ::SetMenuItemBitmaps(m_hMenu, nPosition, nFlags,
            (HBITMAP)(pBmpUnchecked ? pBmpUnchecked->GetSafeHandle() : nullptr),
            (HBITMAP)(pBmpChecked ? pBmpChecked->GetSafeHandle() : nullptr));
    }
    CMenu* GetSubMenu(int nPos) const;
    BOOL TrackPopupMenu(UINT nFlags, int x, int y, CWnd* pWnd, LPCRECT lpRect = nullptr);
    BOOL TrackPopupMenuEx(UINT nFlags, int x, int y, CWnd* pWnd, LPTPMPARAMS lptpm = nullptr);
};

// CDataExchange
class CDataExchange {
public:
    BOOL m_bSaveAndValidate = FALSE;
    CWnd* m_pDlgWnd = nullptr;

    CDataExchange(CWnd* pDlgWnd, BOOL bSaveAndValidate)
        : m_bSaveAndValidate(bSaveAndValidate), m_pDlgWnd(pDlgWnd) {}

    HWND PrepareCtrl(int nIDC);
    HWND PrepareEditCtrl(int nIDC) { return PrepareCtrl(nIDC); }
    void Fail() {}
};

void AFXAPI DDX_Control(CDataExchange* pDX, int nIDC, CWnd& rControl);
void AFXAPI DDX_Text(CDataExchange* pDX, int nIDC, CString& value);
void AFXAPI DDX_Text(CDataExchange* pDX, int nIDC, int& value);
void AFXAPI DDX_Text(CDataExchange* pDX, int nIDC, UINT& value);
void AFXAPI DDX_Check(CDataExchange* pDX, int nIDC, int& value);

// CScrollBar forward / definition
class CScrollBar;

// CWnd
class CWnd : public CCmdTarget {
    DECLARE_DYNCREATE(CWnd)
public:
    HWND m_hWnd = nullptr;
    UINT m_nFlags = 0;

    static const CWnd wndTop;
    static const CWnd wndBottom;
    static const CWnd wndTopMost;
    static const CWnd wndNoTopMost;

    CWnd() = default;
    ~CWnd() override;

    operator HWND() const noexcept { return this ? m_hWnd : nullptr; }
    HWND GetSafeHwnd() const noexcept { return this ? m_hWnd : nullptr; }
    static CWnd* FromHandle(HWND hWnd);
    static CWnd* FromHandlePermanent(HWND hWnd);

    BOOL Attach(HWND hWndNew);
    HWND Detach();
    BOOL SubclassWindow(HWND hWnd);
    BOOL SubclassDlgItem(UINT nID, CWnd* pParent);
    HWND UnsubclassWindow();

    virtual BOOL PreCreateWindow(CREATESTRUCT& cs) { (void)cs; return TRUE; }
    virtual BOOL Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle,
                        const RECT& rect, CWnd* pParentWnd, UINT nID, CCreateContext* pContext = nullptr);
    virtual BOOL CreateEx(DWORD dwExStyle, LPCTSTR lpszClassName, LPCTSTR lpszWindowName,
                          DWORD dwStyle, int x, int y, int nWidth, int nHeight,
                          HWND hWndParent, HMENU nIDorHMenu, LPVOID lpParam = nullptr);
    virtual BOOL CreateEx(DWORD dwExStyle, LPCTSTR lpszClassName, LPCTSTR lpszWindowName,
                          DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID, LPVOID lpParam = nullptr);
    virtual BOOL DestroyWindow();
    virtual void PreSubclassWindow() {}
    virtual void PostNcDestroy() {}

    // Message sending
    LRESULT SendMessage(UINT message, WPARAM wParam = 0, LPARAM lParam = 0) const {
        return ::SendMessage(m_hWnd, message, wParam, lParam);
    }
    BOOL PostMessage(UINT message, WPARAM wParam = 0, LPARAM lParam = 0) {
        return ::PostMessage(m_hWnd, message, wParam, lParam);
    }
    BOOL SendNotifyMessage(UINT message, WPARAM wParam = 0, LPARAM lParam = 0) {
        return ::SendNotifyMessage(m_hWnd, message, wParam, lParam);
    }
    LRESULT SendDlgItemMessage(int nID, UINT message, WPARAM wParam = 0, LPARAM lParam = 0) const {
        return ::SendDlgItemMessage(m_hWnd, nID, message, wParam, lParam);
    }

    // Window state & attributes
    DWORD GetStyle() const { return (DWORD)::GetWindowLongPtr(m_hWnd, GWL_STYLE); }
    DWORD GetExStyle() const { return (DWORD)::GetWindowLongPtr(m_hWnd, GWL_EXSTYLE); }
    BOOL ModifyStyle(DWORD dwRemove, DWORD dwAdd, UINT nFlags = 0);
    BOOL ModifyStyleEx(DWORD dwRemove, DWORD dwAdd, UINT nFlags = 0);
    int GetDlgCtrlID() const { return ::GetDlgCtrlID(m_hWnd); }
    int SetDlgCtrlID(int nID) { return (int)::SetWindowLongPtr(m_hWnd, GWLP_ID, nID); }

    BOOL IsWindowVisible() const { return ::IsWindowVisible(m_hWnd); }
    BOOL IsVisible() const { return IsWindowVisible(); }
    BOOL IsWindowEnabled() const { return ::IsWindowEnabled(m_hWnd); }
    BOOL EnableWindow(BOOL bEnable = TRUE) { return ::EnableWindow(m_hWnd, bEnable); }
    BOOL ShowWindow(int nCmdShow) { return ::ShowWindow(m_hWnd, nCmdShow); }
    BOOL IsIconic() const { return ::IsIconic(m_hWnd); }
    BOOL IsZoomed() const { return ::IsZoomed(m_hWnd); }

    // Geometry & positioning
    void MoveWindow(int x, int y, int nWidth, int nHeight, BOOL bRepaint = TRUE) {
        ::MoveWindow(m_hWnd, x, y, nWidth, nHeight, bRepaint);
    }
    void MoveWindow(LPCRECT lpRect, BOOL bRepaint = TRUE) {
        if (lpRect) ::MoveWindow(m_hWnd, lpRect->left, lpRect->top, lpRect->right - lpRect->left, lpRect->bottom - lpRect->top, bRepaint);
    }
    BOOL SetWindowPos(const CWnd* pWndInsertAfter, int x, int y, int cx, int cy, UINT nFlags) {
        return ::SetWindowPos(m_hWnd, pWndInsertAfter ? pWndInsertAfter->GetSafeHwnd() : nullptr, x, y, cx, cy, nFlags);
    }
    void GetWindowRect(LPRECT lpRect) const { ::GetWindowRect(m_hWnd, lpRect); }
    void GetClientRect(LPRECT lpRect) const { ::GetClientRect(m_hWnd, lpRect); }
    BOOL GetUpdateRect(LPRECT lpRect, BOOL bErase = FALSE) const { return ::GetUpdateRect(m_hWnd, lpRect, bErase); }
    void ClientToScreen(LPPOINT lpPoint) const { ::ClientToScreen(m_hWnd, lpPoint); }
    void ClientToScreen(LPRECT lpRect) const {
        ::ClientToScreen(m_hWnd, (LPPOINT)lpRect);
        ::ClientToScreen(m_hWnd, ((LPPOINT)lpRect) + 1);
    }
    void ScreenToClient(LPPOINT lpPoint) const { ::ScreenToClient(m_hWnd, lpPoint); }
    void ScreenToClient(LPRECT lpRect) const {
        ::ScreenToClient(m_hWnd, (LPPOINT)lpRect);
        ::ScreenToClient(m_hWnd, ((LPPOINT)lpRect) + 1);
    }
    void MapWindowPoints(CWnd* pwndTo, LPPOINT lpPoint, UINT nCount) const {
        ::MapWindowPoints(m_hWnd, pwndTo ? pwndTo->GetSafeHwnd() : nullptr, lpPoint, nCount);
    }
    void MapWindowPoints(CWnd* pwndTo, LPRECT lpRect) const {
        ::MapWindowPoints(m_hWnd, pwndTo ? pwndTo->GetSafeHwnd() : nullptr, (LPPOINT)lpRect, 2);
    }
    BOOL GetWindowPlacement(WINDOWPLACEMENT* lpwndpl) const { return ::GetWindowPlacement(m_hWnd, lpwndpl); }
    BOOL SetWindowPlacement(const WINDOWPLACEMENT* lpwndpl) { return ::SetWindowPlacement(m_hWnd, lpwndpl); }
    void CenterWindow(CWnd* pAlternateOwner = nullptr);
    virtual void CalcWindowRect(LPRECT lpClientRect, UINT nAdjustType = 0) {
        ::AdjustWindowRectEx(lpClientRect, GetStyle(), FALSE, GetExStyle());
        (void)nAdjustType;
    }

    // Painting & Redraw
    CDC* GetDC() { return CDC::FromHandle(::GetDC(m_hWnd)); }
    CDC* GetWindowDC() { return CDC::FromHandle(::GetWindowDC(m_hWnd)); }
    int ReleaseDC(CDC* pDC) { return ::ReleaseDC(m_hWnd, pDC ? pDC->GetSafeHdc() : nullptr); }
    CDC* BeginPaint(LPPAINTSTRUCT lpPaint) { return CDC::FromHandle(::BeginPaint(m_hWnd, lpPaint)); }
    void EndPaint(LPPAINTSTRUCT lpPaint) { ::EndPaint(m_hWnd, lpPaint); }
    void Invalidate(BOOL bErase = TRUE) { ::InvalidateRect(m_hWnd, nullptr, bErase); }
    void InvalidateRect(LPCRECT lpRect, BOOL bErase = TRUE) { ::InvalidateRect(m_hWnd, lpRect, bErase); }
    void ValidateRect(LPCRECT lpRect) { ::ValidateRect(m_hWnd, lpRect); }
    void UpdateWindow() { ::UpdateWindow(m_hWnd); }
    BOOL RedrawWindow(LPCRECT lpRectUpdate = nullptr, CRgn* prgnUpdate = nullptr, UINT flags = RDW_INVALIDATE | RDW_UPDATENOW | RDW_ERASE) {
        return ::RedrawWindow(m_hWnd, lpRectUpdate, prgnUpdate ? (HRGN)prgnUpdate->GetSafeHandle() : nullptr, flags);
    }
    void SetRedraw(BOOL bRedraw = TRUE) { ::SendMessage(m_hWnd, WM_SETREDRAW, bRedraw, 0); }
    BOOL LockWindowUpdate() { return ::LockWindowUpdate(m_hWnd); }
    void UnlockWindowUpdate() { ::LockWindowUpdate(nullptr); }
    void NotifyWinEvent(DWORD event, LONG idObject, LONG idChild) { (void)event; (void)idObject; (void)idChild; }

    // Text & Fonts
    void SetWindowText(LPCTSTR lpszString) { ::SetWindowText(m_hWnd, lpszString); }
    void SetWindowText(LPCSTR lpszString) { ::SetWindowTextA(m_hWnd, lpszString); }
    int GetWindowText(LPTSTR lpszStringBuf, int nMaxCount) const { return ::GetWindowText(m_hWnd, lpszStringBuf, nMaxCount); }
    void GetWindowText(CString& rString) const {
        int len = ::GetWindowTextLength(m_hWnd);
        if (len > 0) {
            ::GetWindowText(m_hWnd, rString.GetBufferSetLength(len), len + 1);
            rString.ReleaseBuffer(len);
        } else {
            rString.Empty();
        }
    }
    int GetWindowTextLength() const { return ::GetWindowTextLength(m_hWnd); }
    void SetFont(CFont* pFont, BOOL bRedraw = TRUE) {
        ::SendMessage(m_hWnd, WM_SETFONT, (WPARAM)(pFont ? pFont->GetSafeHandle() : nullptr), MAKELPARAM(bRedraw, 0));
    }
    CFont* GetFont() const { return CFont::FromHandle((HFONT)::SendMessage(m_hWnd, WM_GETFONT, 0, 0)); }

    // Hierarchy & Focus
    CWnd* GetParent() const { return FromHandle(::GetParent(m_hWnd)); }
    CWnd* SetParent(CWnd* pWndNewParent) { return FromHandle(::SetParent(m_hWnd, pWndNewParent ? pWndNewParent->GetSafeHwnd() : nullptr)); }
    CFrameWnd* GetParentFrame() const;
    CWnd* GetDescendantWindow(int nID, BOOL bOnlyPerm = FALSE) const;
    CWnd* GetTopLevelParent() const;
    CWnd* GetOwner() const { return GetParent(); }
    void SetOwner(CWnd* pOwnerWnd) { (void)pOwnerWnd; }
    CWnd* GetWindow(UINT nCmd) const { return FromHandle(::GetWindow(m_hWnd, nCmd)); }
    CWnd* GetNextWindow(UINT nDirection = GW_HWNDNEXT) const { return GetWindow(nDirection); }
    CWnd* GetLastActivePopup() const { return const_cast<CWnd*>(this); }
    CWnd* GetNextDlgTabItem(CWnd* pWndCtl, BOOL bPrevious = FALSE) const {
        return FromHandle(::GetNextDlgTabItem(m_hWnd, pWndCtl ? pWndCtl->GetSafeHwnd() : nullptr, bPrevious));
    }
    CWnd* GetNextDlgGroupItem(CWnd* pWndCtl, BOOL bPrevious = FALSE) const {
        return FromHandle(::GetNextDlgGroupItem(m_hWnd, pWndCtl ? pWndCtl->GetSafeHwnd() : nullptr, bPrevious));
    }
    BOOL IsChild(const CWnd* pWnd) const { return ::IsChild(m_hWnd, pWnd ? pWnd->GetSafeHwnd() : nullptr); }
    static CWnd* GetDesktopWindow() { return FromHandle(::GetDesktopWindow()); }
    static CWnd* GetForegroundWindow() { return FromHandle(::GetForegroundWindow()); }
    BOOL SetForegroundWindow() { return ::SetForegroundWindow(m_hWnd); }
    static CWnd* GetActiveWindow() { return FromHandle(::GetActiveWindow()); }
    CWnd* SetActiveWindow() { return FromHandle(::SetActiveWindow(m_hWnd)); }
    static CWnd* GetFocus() { return FromHandle(::GetFocus()); }
    CWnd* SetFocus() { return FromHandle(::SetFocus(m_hWnd)); }
    static CWnd* GetCapture() { return FromHandle(::GetCapture()); }
    CWnd* SetCapture() { return FromHandle(::SetCapture(m_hWnd)); }
    static CWnd* WindowFromPoint(POINT point) { return FromHandle(::WindowFromPoint(point)); }
    CWnd* ChildWindowFromPoint(POINT point, UINT nFlags = 0) const {
        return FromHandle(::ChildWindowFromPointEx(m_hWnd, point, nFlags));
    }

    // Dialog item helpers
    CWnd* GetDlgItem(int nID) const;
    void GetDlgItem(int nID, HWND* phWnd) const { if (phWnd) *phWnd = ::GetDlgItem(m_hWnd, nID); }
    void SetDlgItemInt(int nID, UINT nValue, BOOL bSigned = TRUE) { ::SetDlgItemInt(m_hWnd, nID, nValue, bSigned); }
    UINT GetDlgItemInt(int nID, BOOL* lpTrans = nullptr, BOOL bSigned = TRUE) const { return ::GetDlgItemInt(m_hWnd, nID, lpTrans, bSigned); }
    void SetDlgItemText(int nID, LPCTSTR lpszString) { ::SetDlgItemText(m_hWnd, nID, lpszString); }
    void SetDlgItemText(int nID, LPCSTR lpszString) {
        if (!lpszString) return;
        CString s(lpszString);
        ::SetDlgItemText(m_hWnd, nID, s);
    }
    int GetDlgItemText(int nID, LPTSTR lpStr, int nMaxCount) const { return ::GetDlgItemText(m_hWnd, nID, lpStr, nMaxCount); }
    int GetDlgItemText(int nID, CString& rString) const {
        HWND hItem = ::GetDlgItem(m_hWnd, nID);
        if (!hItem) { rString.Empty(); return 0; }
        int len = ::GetWindowTextLength(hItem);
        if (len > 0) {
            ::GetWindowText(hItem, rString.GetBufferSetLength(len), len + 1);
            rString.ReleaseBuffer(len);
        } else {
            rString.Empty();
        }
        return len;
    }
    void CheckDlgButton(int nIDButton, UINT nCheck) { ::CheckDlgButton(m_hWnd, nIDButton, nCheck); }
    UINT IsDlgButtonChecked(int nIDButton) const { return ::IsDlgButtonChecked(m_hWnd, nIDButton); }
    void CheckRadioButton(int nIDFirstButton, int nIDLastButton, int nIDCheckButton) {
        ::CheckRadioButton(m_hWnd, nIDFirstButton, nIDLastButton, nIDCheckButton);
    }
    int GetCheckedRadioButton(int nIDFirstButton, int nIDLastButton) const;
    BOOL UpdateData(BOOL bSaveAndValidate = TRUE);
    virtual void DoDataExchange(CDataExchange* pDX) { (void)pDX; }

    // Accessibility
    virtual void EnableActiveAccessibility() {}
    virtual HRESULT get_accName(VARIANT, BSTR*) { return S_OK; }
    virtual HRESULT get_accValue(VARIANT, BSTR*) { return S_OK; }
    virtual HRESULT get_accDescription(VARIANT, BSTR*) { return S_OK; }
    virtual BOOL OnGestureZoom(CPoint ptCenter, long lDelta) { (void)ptCenter; (void)lDelta; return FALSE; }
    virtual BOOL OnGesturePan(CPoint ptFrom, CPoint ptTo) { (void)ptFrom; (void)ptTo; return FALSE; }
    virtual BOOL OnGestureRotate(CPoint ptCenter, double dblAngle) { (void)ptCenter; (void)dblAngle; return FALSE; }
    virtual BOOL OnGestureTwoFingerTap(CPoint ptCenter) { (void)ptCenter; return FALSE; }
    virtual BOOL OnGesturePressAndTap(CPoint ptFirstFinger, long lDelta) { (void)ptFirstFinger; (void)lDelta; return FALSE; }

    // Menus, Icons, Scrollbars, Timers, Caret, Clipboard, DragDrop
    virtual CMenu* GetMenu() const { return CMenu::FromHandle(::GetMenu(m_hWnd)); }
    virtual BOOL SetMenu(CMenu* pMenu) { return ::SetMenu(m_hWnd, pMenu ? pMenu->GetSafeHmenu() : nullptr); }
    CMenu* GetSystemMenu(BOOL bRevert) const { return CMenu::FromHandle(::GetSystemMenu(m_hWnd, bRevert)); }
    void DrawMenuBar() { ::DrawMenuBar(m_hWnd); }
    HICON SetIcon(HICON hIcon, BOOL bBigIcon) { return (HICON)::SendMessage(m_hWnd, WM_SETICON, bBigIcon ? ICON_BIG : ICON_SMALL, (LPARAM)hIcon); }
    HICON GetIcon(BOOL bBigIcon) const { return (HICON)::SendMessage(m_hWnd, WM_GETICON, bBigIcon ? ICON_BIG : ICON_SMALL, 0); }

    UINT_PTR SetTimer(UINT_PTR nIDEvent, UINT nElapse, TIMERPROC lpfnTimer = nullptr) {
        return ::SetTimer(m_hWnd, nIDEvent, nElapse, lpfnTimer);
    }
    BOOL KillTimer(UINT_PTR nIDEvent) { return ::KillTimer(m_hWnd, nIDEvent); }

    void DragAcceptFiles(BOOL bAccept = TRUE) { ::DragAcceptFiles(m_hWnd, bAccept); }

    BOOL OpenClipboard() { return ::OpenClipboard(m_hWnd); }

    void CreateSolidCaret(int nWidth, int nHeight) { ::CreateCaret(m_hWnd, nullptr, nWidth, nHeight); }
    void ShowCaret() { ::ShowCaret(m_hWnd); }
    void HideCaret() { ::HideCaret(m_hWnd); }
    static CPoint GetCaretPos() { POINT pt{}; ::GetCaretPos(&pt); return pt; }
    static void SetCaretPos(POINT point) { ::SetCaretPos(point.x, point.y); }

    virtual CScrollBar* GetScrollBarCtrl(int nBar) const { (void)nBar; return nullptr; }
    int SetScrollPos(int nBar, int nPos, BOOL bRedraw = TRUE) { return ::SetScrollPos(m_hWnd, nBar, nPos, bRedraw); }
    int GetScrollPos(int nBar) const { return ::GetScrollPos(m_hWnd, nBar); }
    void SetScrollRange(int nBar, int nMinPos, int nMaxPos, BOOL bRedraw = TRUE) { ::SetScrollRange(m_hWnd, nBar, nMinPos, nMaxPos, bRedraw); }
    void GetScrollRange(int nBar, LPINT lpMinPos, LPINT lpMaxPos) const { ::GetScrollRange(m_hWnd, nBar, lpMinPos, lpMaxPos); }
    void ScrollWindow(int xAmount, int yAmount, LPCRECT lpRect = nullptr, LPCRECT lpClipRect = nullptr) {
        ::ScrollWindow(m_hWnd, xAmount, yAmount, lpRect, lpClipRect);
    }
    int ScrollWindowEx(int dx, int dy, LPCRECT lpRectScroll, LPCRECT lpRectClip, CRgn* prgnUpdate, LPRECT lpRectUpdate, UINT flags) {
        return ::ScrollWindowEx(m_hWnd, dx, dy, lpRectScroll, lpRectClip, prgnUpdate ? (HRGN)prgnUpdate->GetSafeHandle() : nullptr, lpRectUpdate, flags);
    }
    BOOL SetScrollInfo(int nBar, LPSCROLLINFO lpScrollInfo, BOOL bRedraw = TRUE) {
        return ::SetScrollInfo(m_hWnd, nBar, lpScrollInfo, bRedraw);
    }
    BOOL GetScrollInfo(int nBar, LPSCROLLINFO lpScrollInfo, UINT nMask = SIF_ALL) {
        if (lpScrollInfo) lpScrollInfo->fMask = nMask;
        return ::GetScrollInfo(m_hWnd, nBar, lpScrollInfo);
    }
    int GetScrollLimit(int nBar);
    BOOL EnableScrollBarCtrl(int nBar, BOOL bEnable = TRUE) {
        return ::EnableScrollBar(m_hWnd, nBar, bEnable ? ESB_ENABLE_BOTH : ESB_DISABLE_BOTH);
    }
    BOOL ShowScrollBar(UINT nBar, BOOL bShow = TRUE) { return ::ShowScrollBar(m_hWnd, nBar, bShow); }

    // Tooltips
    BOOL EnableToolTips(BOOL bEnable = TRUE) { (void)bEnable; return TRUE; }
    virtual INT_PTR OnToolHitTest(CPoint point, TOOLINFO* pTI) const { (void)point; (void)pTI; return -1; }

    // Message box
    int MessageBox(LPCTSTR lpszText, LPCTSTR lpszCaption = nullptr, UINT nType = MB_OK) {
        return ::MessageBox(m_hWnd, lpszText, lpszCaption, nType);
    }

    // Message routing & default handlers
    const MSG* GetCurrentMessage() const;
    LRESULT Default();
    virtual LRESULT DefWindowProc(UINT message, WPARAM wParam, LPARAM lParam);
    virtual LRESULT WindowProc(UINT message, WPARAM wParam, LPARAM lParam);
    virtual BOOL OnWndMsg(UINT message, WPARAM wParam, LPARAM lParam, LRESULT* pResult);
    virtual BOOL PreTranslateMessage(MSG* pMsg) { (void)pMsg; return FALSE; }
    virtual BOOL OnCommand(WPARAM wParam, LPARAM lParam);
    virtual BOOL OnNotify(WPARAM wParam, LPARAM lParam, LRESULT* pResult);
    virtual BOOL OnChildNotify(UINT message, WPARAM wParam, LPARAM lParam, LRESULT* pResult);
    BOOL ReflectLastMsg(HWND hWndChild, LRESULT* pResult = nullptr);

    void UpdateDialogControls(CCmdTarget* pTarget, BOOL bDisableIfNoHndler);
    enum RepositionFlags { reposDefault = 0, reposQuery = 1, reposExtra = 2 };
    void RepositionBars(UINT nIDFirst, UINT nIDLast, UINT nIDLeftOver, UINT nFlag = 0, LPRECT lpRectParam = nullptr, LPCRECT lpRectClient = nullptr, BOOL bStretch = TRUE);
    void SendMessageToDescendants(UINT message, WPARAM wParam = 0, LPARAM lParam = 0, BOOL bDeep = TRUE, BOOL bOnlyPerm = FALSE);

    // Virtual message handlers that derived classes may call on BaseClass
    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) { (void)lpCreateStruct; return (int)Default(); }
    afx_msg void OnDestroy() { Default(); }
    afx_msg void OnClose() { Default(); }
    afx_msg void OnSize(UINT nType, int cx, int cy) { (void)nType; (void)cx; (void)cy; Default(); }
    afx_msg void OnSizing(UINT fwSide, LPRECT pRect) { (void)fwSide; (void)pRect; Default(); }
    afx_msg void OnMove(int x, int y) { (void)x; (void)y; Default(); }
    afx_msg void OnPaint() { Default(); }
    afx_msg BOOL OnEraseBkgnd(CDC* pDC) { (void)pDC; return (BOOL)Default(); }
    afx_msg void OnPrintClient(CDC* pDC, UINT nFlags) { (void)pDC; (void)nFlags; Default(); }
    afx_msg void OnSetFocus(CWnd* pOldWnd) { (void)pOldWnd; Default(); }
    afx_msg void OnKillFocus(CWnd* pNewWnd) { (void)pNewWnd; Default(); }
    afx_msg void OnActivate(UINT nState, CWnd* pWndOther, BOOL bMinimized) { (void)nState; (void)pWndOther; (void)bMinimized; Default(); }
    afx_msg int OnMouseActivate(CWnd* pDesktopWnd, UINT nHitTest, UINT message) { (void)pDesktopWnd; (void)nHitTest; (void)message; return MA_ACTIVATE; }
    afx_msg void OnEnable(BOOL bEnable) { (void)bEnable; Default(); }
    afx_msg void OnShowWindow(BOOL bShow, UINT nStatus) { (void)bShow; (void)nStatus; Default(); }
    afx_msg void OnGetMinMaxInfo(MINMAXINFO* lpMMI) { (void)lpMMI; Default(); }
    afx_msg void OnWindowPosChanged(WINDOWPOS* lpwndpos) { (void)lpwndpos; Default(); }
    afx_msg void OnNcCalcSize(BOOL bCalcValidRects, NCCALCSIZE_PARAMS* lpncsp) { (void)bCalcValidRects; (void)lpncsp; Default(); }
    afx_msg LRESULT OnNcHitTest(CPoint point) { (void)point; return Default(); }
    afx_msg void OnNcPaint() { Default(); }
    afx_msg BOOL OnNcActivate(BOOL bActive) { (void)bActive; return TRUE; }
    afx_msg void OnNcLButtonDown(UINT nHitTest, CPoint point) { (void)nHitTest; (void)point; Default(); }
    afx_msg void OnNcLButtonUp(UINT nHitTest, CPoint point) { (void)nHitTest; (void)point; Default(); }
    afx_msg void OnNcLButtonDblClk(UINT nHitTest, CPoint point) { (void)nHitTest; (void)point; Default(); }
    afx_msg void OnNcMouseMove(UINT nHitTest, CPoint point) { (void)nHitTest; (void)point; Default(); }
    afx_msg void OnMouseMove(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnMouseHover(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnMouseLeave() { Default(); }
    afx_msg void OnLButtonDown(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnLButtonUp(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnLButtonDblClk(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnRButtonDown(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnRButtonUp(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnRButtonDblClk(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnMButtonDown(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnMButtonUp(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnMButtonDblClk(UINT nFlags, CPoint point) { (void)nFlags; (void)point; Default(); }
    afx_msg void OnXButtonDown(UINT nFlags, UINT nButton, CPoint point) { (void)nFlags; (void)nButton; (void)point; Default(); }
    afx_msg void OnXButtonUp(UINT nFlags, UINT nButton, CPoint point) { (void)nFlags; (void)nButton; (void)point; Default(); }
    afx_msg void OnXButtonDblClk(UINT nFlags, UINT nButton, CPoint point) { (void)nFlags; (void)nButton; (void)point; Default(); }
    afx_msg BOOL OnMouseWheel(UINT nFlags, short zDelta, CPoint pt) { (void)nFlags; (void)zDelta; (void)pt; return (BOOL)Default(); }
    afx_msg void OnMouseHWheel(UINT nFlags, short zDelta, CPoint pt) { (void)nFlags; (void)zDelta; (void)pt; Default(); }
    afx_msg void OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags) { (void)nChar; (void)nRepCnt; (void)nFlags; Default(); }
    afx_msg void OnKeyUp(UINT nChar, UINT nRepCnt, UINT nFlags) { (void)nChar; (void)nRepCnt; (void)nFlags; Default(); }
    afx_msg void OnSysKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags) { (void)nChar; (void)nRepCnt; (void)nFlags; Default(); }
    afx_msg void OnSysKeyUp(UINT nChar, UINT nRepCnt, UINT nFlags) { (void)nChar; (void)nRepCnt; (void)nFlags; Default(); }
    afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags) { (void)nChar; (void)nRepCnt; (void)nFlags; Default(); }
    afx_msg void OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) { (void)nSBCode; (void)nPos; (void)pScrollBar; Default(); }
    afx_msg void OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) { (void)nSBCode; (void)nPos; (void)pScrollBar; Default(); }
    afx_msg void OnTimer(UINT_PTR nIDEvent) { (void)nIDEvent; Default(); }
    afx_msg BOOL OnSetCursor(CWnd* pWnd, UINT nHitTest, UINT message) { (void)pWnd; (void)nHitTest; (void)message; return (BOOL)Default(); }
    afx_msg void OnContextMenu(CWnd* pWnd, CPoint pos) { (void)pWnd; (void)pos; Default(); }
    afx_msg void OnInitMenu(CMenu* pMenu) { (void)pMenu; Default(); }
    afx_msg void OnInitMenuPopup(CMenu* pPopupMenu, UINT nIndex, BOOL bSysMenu) { (void)pPopupMenu; (void)nIndex; (void)bSysMenu; Default(); }
    afx_msg void OnEnterMenuLoop(BOOL bIsTrackPopupMenu) { (void)bIsTrackPopupMenu; Default(); }
    afx_msg void OnExitMenuLoop(BOOL bIsTrackPopupMenu) { (void)bIsTrackPopupMenu; Default(); }
    afx_msg void OnMenuSelect(UINT nItemID, UINT nFlags, HMENU hSysMenu) { (void)nItemID; (void)nFlags; (void)hSysMenu; Default(); }
    afx_msg HBRUSH OnCtlColor(CDC* pDC, CWnd* pWnd, UINT nCtlColor) { (void)pDC; (void)pWnd; (void)nCtlColor; return (HBRUSH)Default(); }
    afx_msg void OnDrawItem(int nIDCtl, LPDRAWITEMSTRUCT lpDrawItemStruct) { (void)nIDCtl; (void)lpDrawItemStruct; Default(); }
    afx_msg void OnMeasureItem(int nIDCtl, LPMEASUREITEMSTRUCT lpMeasureItemStruct) { (void)nIDCtl; (void)lpMeasureItemStruct; Default(); }
    afx_msg int OnCompareItem(int nIDCtl, LPCOMPAREITEMSTRUCT lpCompareItemStruct) { (void)nIDCtl; (void)lpCompareItemStruct; return 0; }
    afx_msg void OnDeleteItem(int nIDCtl, LPDELETEITEMSTRUCT lpDeleteItemStruct) { (void)nIDCtl; (void)lpDeleteItemStruct; Default(); }
    afx_msg int OnVKeyToItem(UINT nKey, CListBox* pListBox, UINT nIndex) { (void)nKey; (void)pListBox; (void)nIndex; return -1; }
    afx_msg int OnCharToItem(UINT nKey, CListBox* pListBox, UINT nIndex) { (void)nKey; (void)pListBox; (void)nIndex; return -1; }
    afx_msg void OnDropFiles(HDROP hDropInfo) { (void)hDropInfo; Default(); }
    afx_msg UINT OnGetDlgCode() { return (UINT)Default(); }
    afx_msg BOOL OnQueryEndSession() { return TRUE; }
    afx_msg void OnEndSession(BOOL bEnding) { (void)bEnding; }
    afx_msg void OnSysColorChange() { Default(); }
    afx_msg void OnSettingChange(UINT uFlags, LPCTSTR lpszSection) { (void)uFlags; (void)lpszSection; Default(); }
    afx_msg void OnSysCommand(UINT nID, LPARAM lParam) { (void)nID; (void)lParam; Default(); }
    afx_msg BOOL OnCopyData(CWnd* pWnd, COPYDATASTRUCT* pCopyDataStruct) { (void)pWnd; (void)pCopyDataStruct; return FALSE; }

    DECLARE_MESSAGE_MAP()
};

// Standard Control Classes
class CStatic : public CWnd {
    DECLARE_DYNAMIC(CStatic)
public:
    BOOL Create(LPCTSTR lpszText, DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID = 0xffff) {
        return CWnd::Create(_T("STATIC"), lpszText, dwStyle, rect, pParentWnd, nID);
    }
    HICON SetIcon(HICON hIcon) { return (HICON)::SendMessage(m_hWnd, STM_SETICON, (WPARAM)hIcon, 0L); }
    HICON GetIcon() const { return (HICON)::SendMessage(m_hWnd, STM_GETICON, 0, 0L); }
    HBITMAP SetBitmap(HBITMAP hBitmap) { return (HBITMAP)::SendMessage(m_hWnd, STM_SETIMAGE, IMAGE_BITMAP, (LPARAM)hBitmap); }
    HBITMAP GetBitmap() const { return (HBITMAP)::SendMessage(m_hWnd, STM_GETIMAGE, IMAGE_BITMAP, 0L); }
};

class CButton : public CWnd {
    DECLARE_DYNAMIC(CButton)
public:
    BOOL Create(LPCTSTR lpszCaption, DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(_T("BUTTON"), lpszCaption, dwStyle, rect, pParentWnd, nID);
    }
    UINT GetState() const { return (UINT)::SendMessage(m_hWnd, BM_GETSTATE, 0, 0); }
    void SetState(BOOL bHighlight) { ::SendMessage(m_hWnd, BM_SETSTATE, bHighlight, 0); }
    int GetCheck() const { return (int)::SendMessage(m_hWnd, BM_GETCHECK, 0, 0); }
    void SetCheck(int nCheck) { ::SendMessage(m_hWnd, BM_SETCHECK, nCheck, 0); }
    UINT GetButtonStyle() const { return (UINT)GetStyle() & 0xFFFF; }
    void SetButtonStyle(UINT nStyle, BOOL bRedraw = TRUE) { ::SendMessage(m_hWnd, BM_SETSTYLE, nStyle, (LPARAM)bRedraw); }
    HICON SetIcon(HICON hIcon) { return (HICON)::SendMessage(m_hWnd, BM_SETIMAGE, IMAGE_ICON, (LPARAM)hIcon); }
    HICON GetIcon() const { return (HICON)::SendMessage(m_hWnd, BM_GETIMAGE, IMAGE_ICON, 0L); }
    HBITMAP SetBitmap(HBITMAP hBitmap) { return (HBITMAP)::SendMessage(m_hWnd, BM_SETIMAGE, IMAGE_BITMAP, (LPARAM)hBitmap); }
    HBITMAP GetBitmap() const { return (HBITMAP)::SendMessage(m_hWnd, BM_GETIMAGE, IMAGE_BITMAP, 0L); }
    virtual void DrawItem(LPDRAWITEMSTRUCT lpDrawItemStruct) { (void)lpDrawItemStruct; }
};

class CEdit : public CWnd {
    DECLARE_DYNAMIC(CEdit)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(_T("EDIT"), nullptr, dwStyle, rect, pParentWnd, nID);
    }
    void SetSel(DWORD dwSelection, BOOL bNoScroll = FALSE) {
        ::SendMessage(m_hWnd, EM_SETSEL, LOWORD(dwSelection), HIWORD(dwSelection));
        if (!bNoScroll) ::SendMessage(m_hWnd, EM_SCROLLCARET, 0, 0);
    }
    void SetSel(int nStartChar, int nEndChar, BOOL bNoScroll = FALSE) {
        ::SendMessage(m_hWnd, EM_SETSEL, nStartChar, nEndChar);
        if (!bNoScroll) ::SendMessage(m_hWnd, EM_SCROLLCARET, 0, 0);
    }
    DWORD GetSel() const { return (DWORD)::SendMessage(m_hWnd, EM_GETSEL, 0, 0); }
    void GetSel(int& nStartChar, int& nEndChar) const {
        DWORD s = 0, e = 0;
        ::SendMessage(m_hWnd, EM_GETSEL, (WPARAM)&s, (LPARAM)&e);
        nStartChar = (int)s; nEndChar = (int)e;
    }
    void ReplaceSel(LPCTSTR lpszNewText, BOOL bCanUndo = FALSE) {
        ::SendMessage(m_hWnd, EM_REPLACESEL, (WPARAM)bCanUndo, (LPARAM)lpszNewText);
    }
    void LimitText(int nChars = 0) { ::SendMessage(m_hWnd, EM_LIMITTEXT, nChars, 0); }
    void SetLimitText(UINT nMax) { ::SendMessage(m_hWnd, EM_SETLIMITTEXT, nMax, 0); }
    UINT GetLimitText() const { return (UINT)::SendMessage(m_hWnd, EM_GETLIMITTEXT, 0, 0); }
    BOOL GetModify() const { return (BOOL)::SendMessage(m_hWnd, EM_GETMODIFY, 0, 0); }
    void SetModify(BOOL bModified = TRUE) { ::SendMessage(m_hWnd, EM_SETMODIFY, bModified, 0); }
    BOOL FmtLines(BOOL bAddEOL) { return (BOOL)::SendMessage(m_hWnd, EM_FMTLINES, bAddEOL, 0); }
    int LineIndex(int nLine = -1) const { return (int)::SendMessage(m_hWnd, EM_LINEINDEX, nLine, 0); }
    int LineFromChar(int nIndex = -1) const { return (int)::SendMessage(m_hWnd, EM_LINEFROMCHAR, nIndex, 0); }
    int GetLineCount() const { return (int)::SendMessage(m_hWnd, EM_GETLINECOUNT, 0, 0); }
    int GetLine(int nIndex, LPTSTR lpszBuffer, int nMaxLength) const {
        if (!lpszBuffer || nMaxLength <= 0) return 0;
        *(WORD*)lpszBuffer = (WORD)nMaxLength;
        return (int)::SendMessage(m_hWnd, EM_GETLINE, nIndex, (LPARAM)lpszBuffer);
    }
    BOOL SetReadOnly(BOOL bReadOnly = TRUE) { return (BOOL)::SendMessage(m_hWnd, EM_SETREADONLY, bReadOnly, 0L); }
    void SetPasswordChar(TCHAR ch) { ::SendMessage(m_hWnd, EM_SETPASSWORDCHAR, ch, 0); }
    void SetMargins(UINT nLeft, UINT nRight) { ::SendMessage(m_hWnd, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, MAKELONG(nLeft, nRight)); }
    CPoint PosFromChar(UINT nChar) const {
        LRESULT r = ::SendMessage(m_hWnd, EM_POSFROMCHAR, nChar, 0);
        return CPoint(LOWORD(r), HIWORD(r));
    }
    int CharFromPos(CPoint pt) const { return (int)::SendMessage(m_hWnd, EM_CHARFROMPOS, 0, MAKELPARAM(pt.x, pt.y)); }
    void ShowBalloonTip(LPCWSTR lpszTitle, LPCWSTR lpszText, INT ttiIcon = 0) { (void)lpszTitle; (void)lpszText; (void)ttiIcon; }
    void HideBalloonTip() {}
    void EmptyUndoBuffer() { ::SendMessage(m_hWnd, EM_EMPTYUNDOBUFFER, 0, 0); }
    void Undo() { ::SendMessage(m_hWnd, EM_UNDO, 0, 0); }
    void Clear() { ::SendMessage(m_hWnd, WM_CLEAR, 0, 0); }
    void Copy() { ::SendMessage(m_hWnd, WM_COPY, 0, 0); }
    void Cut() { ::SendMessage(m_hWnd, WM_CUT, 0, 0); }
    void Paste() { ::SendMessage(m_hWnd, WM_PASTE, 0, 0); }
};

class CListBox : public CWnd {
    DECLARE_DYNAMIC(CListBox)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(_T("LISTBOX"), nullptr, dwStyle, rect, pParentWnd, nID);
    }
    int GetCount() const { return (int)::SendMessage(m_hWnd, LB_GETCOUNT, 0, 0); }
    int GetCurSel() const { return (int)::SendMessage(m_hWnd, LB_GETCURSEL, 0, 0); }
    int SetCurSel(int nSelect) { return (int)::SendMessage(m_hWnd, LB_SETCURSEL, nSelect, 0); }
    int GetSel(int nIndex) const { return (int)::SendMessage(m_hWnd, LB_GETSEL, nIndex, 0); }
    int SetSel(int nIndex, BOOL bSelect = TRUE) { return (int)::SendMessage(m_hWnd, LB_SETSEL, bSelect, nIndex); }
    int GetSelCount() const { return (int)::SendMessage(m_hWnd, LB_GETSELCOUNT, 0, 0); }
    int GetSelItems(int nMaxItems, LPINT rgIndex) const { return (int)::SendMessage(m_hWnd, LB_GETSELITEMS, nMaxItems, (LPARAM)rgIndex); }
    int SelItemRange(BOOL bSelect, int nFirstItem, int nLastItem) {
        return (int)::SendMessage(m_hWnd, LB_SELITEMRANGEEX, bSelect ? nFirstItem : nLastItem, bSelect ? nLastItem : nFirstItem);
    }
    int AddString(LPCTSTR lpszItem) { return (int)::SendMessage(m_hWnd, LB_ADDSTRING, 0, (LPARAM)lpszItem); }
    int DeleteString(UINT nIndex) { return (int)::SendMessage(m_hWnd, LB_DELETESTRING, nIndex, 0); }
    int InsertString(int nIndex, LPCTSTR lpszItem) { return (int)::SendMessage(m_hWnd, LB_INSERTSTRING, nIndex, (LPARAM)lpszItem); }
    void ResetContent() { ::SendMessage(m_hWnd, LB_RESETCONTENT, 0, 0); }
    DWORD_PTR GetItemData(int nIndex) const { return ::SendMessage(m_hWnd, LB_GETITEMDATA, nIndex, 0); }
    int SetItemData(int nIndex, DWORD_PTR dwItemData) { return (int)::SendMessage(m_hWnd, LB_SETITEMDATA, nIndex, (LPARAM)dwItemData); }
    void* GetItemDataPtr(int nIndex) const { return (void*)::SendMessage(m_hWnd, LB_GETITEMDATA, nIndex, 0); }
    int SetItemDataPtr(int nIndex, void* pData) { return SetItemData(nIndex, (DWORD_PTR)pData); }
    int GetItemRect(int nIndex, LPRECT lpRect) const { return (int)::SendMessage(m_hWnd, LB_GETITEMRECT, nIndex, (LPARAM)lpRect); }
    int GetText(int nIndex, LPTSTR lpszBuffer) const { return (int)::SendMessage(m_hWnd, LB_GETTEXT, nIndex, (LPARAM)lpszBuffer); }
    void GetText(int nIndex, CString& rString) const {
        int len = GetTextLen(nIndex);
        if (len > 0) {
            GetText(nIndex, rString.GetBufferSetLength(len));
            rString.ReleaseBuffer(len);
        } else {
            rString.Empty();
        }
    }
    int GetTextLen(int nIndex) const { return (int)::SendMessage(m_hWnd, LB_GETTEXTLEN, nIndex, 0); }
    void SetColumnWidth(int cxWidth) { ::SendMessage(m_hWnd, LB_SETCOLUMNWIDTH, cxWidth, 0); }
    BOOL SetTabStops(int nTabStops, LPINT rgTabStops) { return (BOOL)::SendMessage(m_hWnd, LB_SETTABSTOPS, nTabStops, (LPARAM)rgTabStops); }
    BOOL SetTabStops() { return (BOOL)::SendMessage(m_hWnd, LB_SETTABSTOPS, 0, 0); }
    BOOL SetTabStops(const int& cxEachStop) { return (BOOL)::SendMessage(m_hWnd, LB_SETTABSTOPS, 1, (LPARAM)(LPINT)&cxEachStop); }
    int SetItemHeight(int nIndex, UINT cyItemHeight) { return (int)::SendMessage(m_hWnd, LB_SETITEMHEIGHT, nIndex, MAKELONG(cyItemHeight, 0)); }
    int GetItemHeight(int nIndex) const { return (int)::SendMessage(m_hWnd, LB_GETITEMHEIGHT, nIndex, 0); }
    int FindStringExact(int nIndexStart, LPCTSTR lpszFind) const { return (int)::SendMessage(m_hWnd, LB_FINDSTRINGEXACT, nIndexStart, (LPARAM)lpszFind); }
    int SelectString(int nStartAfter, LPCTSTR lpszItem) { return (int)::SendMessage(m_hWnd, LB_SELECTSTRING, nStartAfter, (LPARAM)lpszItem); }
    int SetTopIndex(int nIndex) { return (int)::SendMessage(m_hWnd, LB_SETTOPINDEX, nIndex, 0); }
    int GetTopIndex() const { return (int)::SendMessage(m_hWnd, LB_GETTOPINDEX, 0, 0); }
    void SetHorizontalExtent(int cxExtent) { ::SendMessage(m_hWnd, LB_SETHORIZONTALEXTENT, cxExtent, 0); }
    int GetHorizontalExtent() const { return (int)::SendMessage(m_hWnd, LB_GETHORIZONTALEXTENT, 0, 0); }
    int InitStorage(int nItems, UINT nBytes) { return (int)::SendMessage(m_hWnd, LB_INITSTORAGE, (WPARAM)nItems, nBytes); }
    UINT ItemFromPoint(CPoint pt, BOOL& bOutside) const {
        DWORD dw = (DWORD)::SendMessage(m_hWnd, LB_ITEMFROMPOINT, 0, MAKELPARAM(pt.x, pt.y));
        bOutside = !!HIWORD(dw);
        return LOWORD(dw);
    }
    virtual void DrawItem(LPDRAWITEMSTRUCT lpDrawItemStruct) { (void)lpDrawItemStruct; }
    virtual void MeasureItem(LPMEASUREITEMSTRUCT lpMeasureItemStruct) { (void)lpMeasureItemStruct; }
    virtual int CompareItem(LPCOMPAREITEMSTRUCT lpCompareItemStruct) { (void)lpCompareItemStruct; return 0; }
    virtual void DeleteItem(LPDELETEITEMSTRUCT lpDeleteItemStruct) { (void)lpDeleteItemStruct; }
};

class CCheckListBox : public CListBox {
    DECLARE_DYNAMIC(CCheckListBox)
    std::vector<int> m_checks;
public:
    void SetCheck(int nIndex, int nCheck);
    int GetCheck(int nIndex) const;
    void Enable(int nIndex, BOOL bEnabled = TRUE);
    BOOL IsEnabled(int nIndex) const;
};

class CComboBox : public CWnd {
    DECLARE_DYNAMIC(CComboBox)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(_T("COMBOBOX"), nullptr, dwStyle, rect, pParentWnd, nID);
    }
    int GetCount() const { return (int)::SendMessage(m_hWnd, CB_GETCOUNT, 0, 0); }
    int GetCurSel() const { return (int)::SendMessage(m_hWnd, CB_GETCURSEL, 0, 0); }
    int SetCurSel(int nSelect) { return (int)::SendMessage(m_hWnd, CB_SETCURSEL, nSelect, 0); }
    DWORD GetEditSel() const { return (DWORD)::SendMessage(m_hWnd, CB_GETEDITSEL, 0, 0); }
    BOOL LimitText(int nMaxChars) { return (BOOL)::SendMessage(m_hWnd, CB_LIMITTEXT, nMaxChars, 0); }
    BOOL SetEditSel(int nStartChar, int nEndChar) { return (BOOL)::SendMessage(m_hWnd, CB_SETEDITSEL, 0, MAKELONG(nStartChar, nEndChar)); }
    DWORD_PTR GetItemData(int nIndex) const { return ::SendMessage(m_hWnd, CB_GETITEMDATA, nIndex, 0); }
    int SetItemData(int nIndex, DWORD_PTR dwItemData) { return (int)::SendMessage(m_hWnd, CB_SETITEMDATA, nIndex, (LPARAM)dwItemData); }
    void* GetItemDataPtr(int nIndex) const { return (void*)GetItemData(nIndex); }
    int SetItemDataPtr(int nIndex, void* pData) { return SetItemData(nIndex, (DWORD_PTR)pData); }
    int GetLBText(int nIndex, LPTSTR lpszText) const { return (int)::SendMessage(m_hWnd, CB_GETLBTEXT, nIndex, (LPARAM)lpszText); }
    void GetLBText(int nIndex, CString& rString) const {
        int len = GetLBTextLen(nIndex);
        if (len > 0) {
            GetLBText(nIndex, rString.GetBufferSetLength(len));
            rString.ReleaseBuffer(len);
        } else {
            rString.Empty();
        }
    }
    int GetLBTextLen(int nIndex) const { return (int)::SendMessage(m_hWnd, CB_GETLBTEXTLEN, nIndex, 0); }
    void ShowDropDown(BOOL bShowIt = TRUE) { ::SendMessage(m_hWnd, CB_SHOWDROPDOWN, bShowIt, 0); }
    BOOL GetDroppedState() const { return (BOOL)::SendMessage(m_hWnd, CB_GETDROPPEDSTATE, 0, 0); }
    int AddString(LPCTSTR lpszString) { return (int)::SendMessage(m_hWnd, CB_ADDSTRING, 0, (LPARAM)lpszString); }
    int DeleteString(UINT nIndex) { return (int)::SendMessage(m_hWnd, CB_DELETESTRING, nIndex, 0); }
    int InsertString(int nIndex, LPCTSTR lpszString) { return (int)::SendMessage(m_hWnd, CB_INSERTSTRING, nIndex, (LPARAM)lpszString); }
    void ResetContent() { ::SendMessage(m_hWnd, CB_RESETCONTENT, 0, 0); }
    void Clear() { ::SendMessage(m_hWnd, WM_CLEAR, 0, 0); }
    int FindString(int nStartAfter, LPCTSTR lpszString) const { return (int)::SendMessage(m_hWnd, CB_FINDSTRING, nStartAfter, (LPARAM)lpszString); }
    int FindStringExact(int nIndexStart, LPCTSTR lpszFind) const { return (int)::SendMessage(m_hWnd, CB_FINDSTRINGEXACT, nIndexStart, (LPARAM)lpszFind); }
    int SelectString(int nStartAfter, LPCTSTR lpszString) { return (int)::SendMessage(m_hWnd, CB_SELECTSTRING, nStartAfter, (LPARAM)lpszString); }
    int SetItemHeight(int nIndex, UINT cyItemHeight) { return (int)::SendMessage(m_hWnd, CB_SETITEMHEIGHT, nIndex, MAKELONG(cyItemHeight, 0)); }
    int GetItemHeight(int nIndex) const { return (int)::SendMessage(m_hWnd, CB_GETITEMHEIGHT, nIndex, 0); }
    int SetDroppedWidth(UINT nWidth) { return (int)::SendMessage(m_hWnd, CB_SETDROPPEDWIDTH, nWidth, 0); }
    int GetDroppedWidth() const { return (int)::SendMessage(m_hWnd, CB_GETDROPPEDWIDTH, 0, 0); }
    int InitStorage(int nItems, UINT nBytes) { return (int)::SendMessage(m_hWnd, CB_INITSTORAGE, (WPARAM)nItems, nBytes); }
    BOOL GetComboBoxInfo(PCOMBOBOXINFO pcbi) const { return ::GetComboBoxInfo(m_hWnd, pcbi); }
    virtual void DrawItem(LPDRAWITEMSTRUCT lpDrawItemStruct) { (void)lpDrawItemStruct; }
    virtual void MeasureItem(LPMEASUREITEMSTRUCT lpMeasureItemStruct) { (void)lpMeasureItemStruct; }
    virtual int CompareItem(LPCOMPAREITEMSTRUCT lpCompareItemStruct) { (void)lpCompareItemStruct; return 0; }
    virtual void DeleteItem(LPDELETEITEMSTRUCT lpDeleteItemStruct) { (void)lpDeleteItemStruct; }
};

class CScrollBar : public CWnd {
    DECLARE_DYNAMIC(CScrollBar)
public:
    BOOL Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID) {
        return CWnd::Create(_T("SCROLLBAR"), nullptr, dwStyle, rect, pParentWnd, nID);
    }
    int GetScrollPos() const { return ::GetScrollPos(m_hWnd, SB_CTL); }
    int SetScrollPos(int nPos, BOOL bRedraw = TRUE) { return ::SetScrollPos(m_hWnd, SB_CTL, nPos, bRedraw); }
    void GetScrollRange(LPINT lpMinPos, LPINT lpMaxPos) const { ::GetScrollRange(m_hWnd, SB_CTL, lpMinPos, lpMaxPos); }
    void SetScrollRange(int nMinPos, int nMaxPos, BOOL bRedraw = TRUE) { ::SetScrollRange(m_hWnd, SB_CTL, nMinPos, nMaxPos, bRedraw); }
    void ShowScrollBar(BOOL bShow = TRUE) { ::ShowScrollBar(m_hWnd, SB_CTL, bShow); }
    BOOL EnableScrollBar(UINT nArrowFlags = ESB_ENABLE_BOTH) { return ::EnableScrollBar(m_hWnd, SB_CTL, nArrowFlags); }
    BOOL SetScrollInfo(LPSCROLLINFO lpScrollInfo, BOOL bRedraw = TRUE) { return ::SetScrollInfo(m_hWnd, SB_CTL, lpScrollInfo, bRedraw); }
    BOOL GetScrollInfo(LPSCROLLINFO lpScrollInfo, UINT nMask = SIF_ALL) {
        if (lpScrollInfo) lpScrollInfo->fMask = nMask;
        return ::GetScrollInfo(m_hWnd, SB_CTL, lpScrollInfo);
    }
    int GetScrollLimit() { return CWnd::GetScrollLimit(SB_CTL); }
};

class CMFCDynamicLayout {
public:
    struct MoveSettings {
        int m_nXRatio = 0, m_nYRatio = 0;
        bool IsHorizontal() const { return m_nXRatio > 0; }
        bool IsVertical() const { return m_nYRatio > 0; }
        bool IsNone() const { return m_nXRatio <= 0 && m_nYRatio <= 0; }
    };
    struct SizeSettings {
        int m_nXRatio = 0, m_nYRatio = 0;
        bool IsHorizontal() const { return m_nXRatio > 0; }
        bool IsVertical() const { return m_nYRatio > 0; }
        bool IsNone() const { return m_nXRatio <= 0 && m_nYRatio <= 0; }
    };
};

class CMFCDynamicLayoutData {
public:
    struct Item {
        CMFCDynamicLayout::MoveSettings m_moveSettings;
        CMFCDynamicLayout::SizeSettings m_sizeSettings;
    };
protected:
    struct CListCtrls {
        std::vector<Item> items;
        POSITION GetHeadPosition() const { return items.empty() ? nullptr : (POSITION)(intptr_t)1; }
        const Item& GetNext(POSITION& pos) const {
            size_t idx = (size_t)(intptr_t)pos - 1;
            pos = (idx + 1 < items.size()) ? (POSITION)(intptr_t)(idx + 2) : nullptr;
            return items[idx];
        }
    } m_listCtrls;
public:
    virtual ~CMFCDynamicLayoutData() = default;
    BOOL ReadResource(void* pResource, UINT nSize) {
        if (!pResource || nSize < 4) return FALSE;
        const uint8_t* p = static_cast<const uint8_t*>(pResource);
        uint16_t version = *reinterpret_cast<const uint16_t*>(p);
        p += 2;
        nSize -= 2;
        if (version == 0) {
            if (nSize < 2) return FALSE;
            uint16_t cbHeader = *reinterpret_cast<const uint16_t*>(p);
            p += 2;
            nSize -= 2;
            while (nSize >= 8) {
                Item item;
                item.m_moveSettings.m_nXRatio = *reinterpret_cast<const int16_t*>(p); p += 2;
                item.m_moveSettings.m_nYRatio = *reinterpret_cast<const int16_t*>(p); p += 2;
                item.m_sizeSettings.m_nXRatio = *reinterpret_cast<const int16_t*>(p); p += 2;
                item.m_sizeSettings.m_nYRatio = *reinterpret_cast<const int16_t*>(p); p += 2;
                nSize -= 8;
                m_listCtrls.items.push_back(item);
            }
        }
        return TRUE;
    }
};

// CDialog
class CDialog : public CWnd {
    DECLARE_DYNAMIC(CDialog)
public:
    UINT m_nIDHelp = 0;
    LPCTSTR m_lpszTemplateName = nullptr;
    INT_PTR m_nModalResult = 0;
    bool m_bContinuingModal = false;

    CDialog() = default;
    explicit CDialog(LPCTSTR lpszTemplateName, CWnd* pParentWnd = nullptr);
    explicit CDialog(UINT nIDTemplate, CWnd* pParentWnd = nullptr);
    ~CDialog() override = default;

    virtual BOOL Create(LPCTSTR lpszTemplateName, CWnd* pParentWnd = nullptr);
    virtual BOOL Create(UINT nIDTemplate, CWnd* pParentWnd = nullptr) {
        return Create(MAKEINTRESOURCE(nIDTemplate), pParentWnd);
    }
    virtual BOOL CreateIndirect(LPCDLGTEMPLATE lpDialogTemplate, CWnd* pParentWnd = nullptr, void* lpDialogInit = nullptr);
    virtual INT_PTR DoModal();
    virtual BOOL OnInitDialog();
    afx_msg LRESULT HandleInitDialog(WPARAM, LPARAM);
    afx_msg LRESULT HandleClose(WPARAM, LPARAM);
    virtual void OnSetFont(CFont* pFont) { (void)pFont; }
    virtual void OnOK();
    virtual void OnCancel();
    void EndDialog(int nResult);

    virtual void ResizeDynamicLayout() {}
    virtual void EnableDynamicLayout(BOOL bEnable = TRUE) { (void)bEnable; }
    virtual CMFCDynamicLayout* GetDynamicLayout() { return nullptr; }

    DWORD GetDefID() const { return (DWORD)::SendMessage(m_hWnd, DM_GETDEFID, 0, 0); }
    void SetDefID(UINT nID) { ::SendMessage(m_hWnd, DM_SETDEFID, nID, 0); }
    void NextDlgCtrl() const { ::SendMessage(m_hWnd, WM_NEXTDLGCTL, 0, 0); }
    void PrevDlgCtrl() const { ::SendMessage(m_hWnd, WM_NEXTDLGCTL, 1, 0); }
    void GotoDlgCtrl(CWnd* pWndCtrl) { ::SendMessage(m_hWnd, WM_NEXTDLGCTL, (WPARAM)pWndCtrl->GetSafeHwnd(), 1L); }
    void MapDialogRect(LPRECT lpRect) const { ::MapDialogRect(m_hWnd, lpRect); }

    DECLARE_MESSAGE_MAP()
};

// Document / View / Frame architecture
struct CCreateContext {
    CRuntimeClass* m_pNewViewClass = nullptr;
    CDocument* m_pCurrentDoc = nullptr;
    CDocTemplate* m_pNewDocTemplate = nullptr;
    CView* m_pLastView = nullptr;
    CFrameWnd* m_pCurrentFrame = nullptr;
};

class CDocument : public CCmdTarget {
    DECLARE_DYNAMIC(CDocument)
public:
    BOOL OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) override;
    CString m_strTitle;
    CString m_strPathName;
    CDocTemplate* m_pDocTemplate = nullptr;
    std::vector<CView*> m_viewList;
    BOOL m_bModified = FALSE;
    BOOL m_bAutoDelete = TRUE;

    CDocument() = default;
    ~CDocument() override = default;

    const CString& GetTitle() const { return m_strTitle; }
    virtual void SetTitle(LPCTSTR lpszTitle);
    const CString& GetPathName() const { return m_strPathName; }
    virtual void SetPathName(LPCTSTR lpszPathName, BOOL bAddToMRU = TRUE);
    CDocTemplate* GetDocTemplate() const { return m_pDocTemplate; }
    virtual BOOL IsModified() { return m_bModified; }
    virtual void SetModifiedFlag(BOOL bModified = TRUE) { m_bModified = bModified; }

    void AddView(CView* pView);
    void RemoveView(CView* pView);
    virtual POSITION GetFirstViewPosition() const;
    virtual CView* GetNextView(POSITION& rPosition) const;
    void UpdateAllViews(CView* pSender, LPARAM lHint = 0L, CObject* pHint = nullptr);

    virtual BOOL OnNewDocument();
    virtual BOOL OnOpenDocument(LPCTSTR lpszPathName);
    virtual BOOL OnSaveDocument(LPCTSTR lpszPathName);
    virtual void OnCloseDocument();
    virtual void DeleteContents() {}
    virtual BOOL SaveModified();
    virtual BOOL DoSave(LPCTSTR lpszPathName, BOOL bReplace = TRUE);
    virtual BOOL DoFileSave();
    virtual void UpdateFrameCounts() {}
    virtual BOOL CanCloseFrame(CFrameWnd* pFrame) { (void)pFrame; return SaveModified(); }

    afx_msg void OnFileClose();
    afx_msg void OnFileSave();
    afx_msg void OnFileSaveAs();

    DECLARE_MESSAGE_MAP()
};

#define CBRS_ALIGN_LEFT     0x1000L
#define CBRS_ALIGN_TOP      0x2000L
#define CBRS_ALIGN_RIGHT    0x4000L
#define CBRS_ALIGN_BOTTOM   0x8000L
#define CBRS_ALIGN_ANY      0xF000L
#define CBRS_BORDER_LEFT    0x0100L
#define CBRS_BORDER_TOP     0x0200L
#define CBRS_BORDER_RIGHT   0x0400L
#define CBRS_BORDER_BOTTOM  0x0800L
#define CBRS_BORDER_ANY     0x0F00L
#define CBRS_TOOLTIPS       0x0010L
#define CBRS_FLYBY          0x0020L
#define CBRS_FLOAT_MULTI    0x0040L
#define CBRS_SIZE_DYNAMIC   0x0080L
#define CBRS_SIZE_FIXED     0x0002L
#define CBRS_FLOATING       0x0001L
#define CBRS_GRIPPER        0x00400000L
#define CBRS_ORIENT_HORZ    (CBRS_ALIGN_TOP|CBRS_ALIGN_BOTTOM)
#define CBRS_ORIENT_VERT    (CBRS_ALIGN_LEFT|CBRS_ALIGN_RIGHT)
#define CBRS_ORIENT_ANY     (CBRS_ORIENT_HORZ|CBRS_ORIENT_VERT)
#define CBRS_ALL            0x0040FFFFL
#define CBRS_NOALIGN        0x00000000L
#define CBRS_LEFT           (CBRS_ALIGN_LEFT|CBRS_BORDER_RIGHT)
#define CBRS_TOP            (CBRS_ALIGN_TOP|CBRS_BORDER_BOTTOM)
#define CBRS_RIGHT          (CBRS_ALIGN_RIGHT|CBRS_BORDER_LEFT)
#define CBRS_BOTTOM         (CBRS_ALIGN_BOTTOM|CBRS_BORDER_TOP)

#define FWS_ADDTOTITLE      0x00008000L
#define FWS_PREFIXTITLE     0x00004000L
#define FWS_SNAPTOBARS      0x00002000L

class CFrameWnd : public CWnd {
    DECLARE_DYNCREATE(CFrameWnd)
public:
    static const CRect rectDefault;
    CString m_strTitle;
    CView* m_pViewActive = nullptr;
    std::vector<CControlBar*> m_listControlBars;

    CFrameWnd() = default;
    ~CFrameWnd() override = default;

    virtual BOOL LoadFrame(UINT nIDResource, DWORD dwDefaultStyle = WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE,
                           CWnd* pParentWnd = nullptr, CCreateContext* pContext = nullptr);
    virtual BOOL Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName,
                        DWORD dwStyle = WS_OVERLAPPEDWINDOW, const RECT& rect = rectDefault,
                        CWnd* pParentWnd = nullptr, LPCTSTR lpszMenuName = nullptr,
                        DWORD dwExStyle = 0, CCreateContext* pContext = nullptr);
    virtual BOOL OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext);
    CWnd* CreateView(CCreateContext* pContext, UINT nID = AFX_IDW_PANE_FIRST);
    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);

    virtual CDocument* GetActiveDocument();
    BOOL OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) override;
    afx_msg void OnSize(UINT nType, int cx, int cy);
    CView* GetActiveView() const { return m_pViewActive; }
    void SetActiveView(CView* pViewNew, BOOL bNotify = TRUE);
    virtual CFrameWnd* GetActiveFrame() { return this; }

    void SetTitle(LPCTSTR lpszTitle) { m_strTitle = lpszTitle ? lpszTitle : _T(""); }
    CString GetTitle() const { return m_strTitle; }
    virtual void OnUpdateFrameTitle(BOOL bAddToTitle);
    virtual void OnUpdateFrameMenu(HMENU hMenuAlt) { (void)hMenuAlt; }
    virtual HACCEL GetDefaultAccelerator() { return nullptr; }
    virtual void RecalcLayout(BOOL bNotify = TRUE);
    virtual void ActivateFrame(int nCmdShow = -1);
    void InitialUpdateFrame(CDocument* pDoc, BOOL bMakeVisible);

    void EnableDocking(DWORD dwDockStyle) { (void)dwDockStyle; }
    void DockControlBar(CControlBar* pBar, UINT nDockBarID = 0, LPCRECT lpRect = nullptr);
    void ShowControlBar(CControlBar* pBar, BOOL bShow, BOOL bDelay);
    CControlBar* GetControlBar(UINT nID);
    void RemoveControlBar(CControlBar* pBar) {
        auto it = std::find(m_listControlBars.begin(), m_listControlBars.end(), pBar);
        if (it != m_listControlBars.end()) m_listControlBars.erase(it);
    }
    void AddControlBar(CControlBar* pBar) {
        if (pBar) m_listControlBars.push_back(pBar);
    }
    void SaveBarState(LPCTSTR lpszProfileName) { (void)lpszProfileName; }
    void LoadBarState(LPCTSTR lpszProfileName) { (void)lpszProfileName; }
    void UpdateFrameTitleForDocument(LPCTSTR lpszDocName) { (void)lpszDocName; }
    BOOL OnDeviceChange(UINT nEventType, DWORD_PTR dwData) { (void)nEventType; (void)dwData; return TRUE; }
    void OnActivateApp(BOOL bActive, DWORD dwThreadID) { (void)bActive; (void)dwThreadID; }
    void SwitchToActiveView();

    virtual CWnd* GetMessageBar();
    void SetMessageText(LPCTSTR lpszText);
    void SetMessageText(UINT nID);

    BOOL OnBarCheck(UINT nID);
    void OnUpdateControlBarMenu(CCmdUI* pCmdUI);

    DECLARE_MESSAGE_MAP()
};

class CMDIFrameWnd : public CFrameWnd {
    DECLARE_DYNCREATE(CMDIFrameWnd)
public:
    HWND m_hWndMDIClient = nullptr;
    CMDIChildWnd* m_pActiveChild = nullptr;
    std::vector<CMDIChildWnd*> m_children;

    CMDIFrameWnd() = default;
    ~CMDIFrameWnd() override = default;

    virtual BOOL CreateClient(LPCREATESTRUCT lpCreateStruct, CMenu* pWindowMenu);
    BOOL OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext) override { (void)pContext; return CreateClient(lpcs, nullptr); }
    CMDIChildWnd* MDIGetActive(BOOL* pbMaximized = nullptr) const;
    BOOL OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) override;
    void RecalcLayout(BOOL bNotify = TRUE) override;
    void MDIActivate(CWnd* pWndActivate);
    void MDINext();
    void MDIPrev();
    void MDIMaximize(CWnd* pWnd);
    void MDIRestore(CWnd* pWnd);
    void MDITile(int nType = 0) { (void)nType; }
    void MDICascade(int nType = 0) { (void)nType; }
    void MDIIconArrange() {}
    CFrameWnd* GetActiveFrame() override;

    DECLARE_MESSAGE_MAP()
};

class CMDIChildWnd : public CFrameWnd {
    DECLARE_DYNCREATE(CMDIChildWnd)
public:
    CMDIFrameWnd* m_pMDIFrame = nullptr;
    BOOL m_bMaximized = FALSE;
    int m_nWindow = 0;

    CMDIChildWnd() = default;
    ~CMDIChildWnd() override;

    BOOL LoadFrame(UINT nIDResource, DWORD dwDefaultStyle = WS_CHILD | WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                   CWnd* pParentWnd = nullptr, CCreateContext* pContext = nullptr) override;
    virtual BOOL Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName,
                        DWORD dwStyle = WS_CHILD | WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                        const RECT& rect = rectDefault, CMDIFrameWnd* pParentWnd = nullptr,
                        CCreateContext* pContext = nullptr);
    CMDIFrameWnd* GetMDIFrame();
    void MDIDestroy();
    void MDIActivate();
    void MDIMaximize();
    void MDIRestore();
    void ActivateFrame(int nCmdShow = -1) override;

    afx_msg void OnMDIActivate(BOOL bActivate, CWnd* pActivateWnd, CWnd* pDeactivateWnd) {
        (void)bActivate; (void)pActivateWnd; (void)pDeactivateWnd;
    }

    DECLARE_MESSAGE_MAP()
};

class CPrintDialog;

struct CPrintInfo {
    CPrintDialog* m_pPD = nullptr;
    BOOL m_bPreview = FALSE;
    BOOL m_bDirect = FALSE;
    BOOL m_bDocObject = FALSE;
    BOOL m_bContinuePrinting = TRUE;
    UINT m_nCurPage = 1;
    UINT m_nNumPreviewPages = 1;
    LPVOID m_lpUserData = nullptr;
    CRect m_rectDraw;
    CString m_strPageDesc;
    UINT GetMinPage() const { return 1; }
    UINT GetMaxPage() const { return 1; }
    void SetMinPage(UINT nMinPage) { (void)nMinPage; }
    void SetMaxPage(UINT nMaxPage) { (void)nMaxPage; }
    UINT GetFromPage() const { return 1; }
    UINT GetToPage() const { return 1; }
};

class CView : public CWnd {
    DECLARE_DYNAMIC(CView)
public:
    CDocument* m_pDocument = nullptr;

    CView() = default;
    ~CView() override;

    CDocument* GetDocument() const { return m_pDocument; }
    BOOL OnCmdMsg(UINT nID, int nCode, void* pExtra, void* pHandlerInfo) override;
    afx_msg int OnCreate(LPCREATESTRUCT lpcs);
    afx_msg LRESULT OnInitialUpdateMessage(WPARAM, LPARAM);
    virtual void OnInitialUpdate();
    virtual void OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint);
    virtual void OnDraw(CDC* pDC) = 0;
    virtual void OnPrepareDC(CDC* pDC, CPrintInfo* pInfo = nullptr) { (void)pDC; (void)pInfo; }
    virtual BOOL OnPreparePrinting(CPrintInfo* pInfo) { (void)pInfo; return FALSE; }
    virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo) { (void)pDC; (void)pInfo; }
    virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo) { (void)pDC; (void)pInfo; }
    virtual void OnPrint(CDC* pDC, CPrintInfo* pInfo) { (void)pInfo; OnDraw(pDC); }
    virtual void OnActivateView(BOOL bActivate, CView* pActivateView, CView* pDeactiveView) {
        (void)bActivate; (void)pActivateView; (void)pDeactiveView;
    }
    virtual void OnActivateFrame(UINT nState, CFrameWnd* pFrameWnd) { (void)nState; (void)pFrameWnd; }
    void PostNcDestroy() override { delete this; }

    afx_msg void OnPaint();

    DECLARE_MESSAGE_MAP()
};

#define MM_TEXT 1

class CScrollView : public CView {
    DECLARE_DYNAMIC(CScrollView)
public:
    static inline const CSize sizeDefault{0, 0};
    int m_nMapMode = MM_TEXT;
    CSize m_totalLog{100, 100};
    CSize m_totalDev{100, 100};
    CSize m_pageDev{10, 10};
    CSize m_lineDev{1, 1};

    CScrollView() = default;
    ~CScrollView() override = default;

    void SetScrollSizes(int nMapMode, SIZE sizeTotal, const SIZE& sizePage = sizeDefault, const SIZE& sizeLine = sizeDefault);
    void SetScaleToFitSize(SIZE sizeTotal) { SetScrollSizes(MM_TEXT, sizeTotal); }
    CPoint GetScrollPosition() const;
    CPoint GetDeviceScrollPosition() const { return GetScrollPosition(); }
    void ScrollToPosition(POINT pt);
    void ScrollToDevicePosition(POINT ptDev) { ScrollToPosition(ptDev); }
    CSize GetTotalSize() const { return m_totalLog; }
    void GetDeviceScrollSizes(int& nMapMode, SIZE& sizeTotal, SIZE& sizePage, SIZE& sizeLine) const {
        nMapMode = m_nMapMode; sizeTotal = m_totalDev; sizePage = m_pageDev; sizeLine = m_lineDev;
    }
    void ResizeParentToFit(BOOL bShrinkOnly = TRUE) { (void)bShrinkOnly; }

    virtual void OnPrepareDC(CDC* pDC, CPrintInfo* pInfo = nullptr) override;
    virtual BOOL OnScroll(UINT nScrollCode, UINT nPos, BOOL bDoScroll = TRUE);
    virtual BOOL OnScrollBy(CSize sizeScroll, BOOL bDoScroll = TRUE);
    virtual BOOL DoMouseWheel(UINT fFlags, short zDelta, CPoint point);
    void UpdateBars();

    afx_msg void OnSize(UINT nType, int cx, int cy);
    afx_msg void OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar);
    afx_msg void OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar);
    afx_msg BOOL OnMouseWheel(UINT nFlags, short zDelta, CPoint pt);

    DECLARE_MESSAGE_MAP()
};

// CDocTemplate, CMultiDocTemplate, CDocManager
class CDocTemplate : public CCmdTarget {
    DECLARE_DYNAMIC(CDocTemplate)
public:
    enum DocStringIndex {
        windowTitle,
        docName,
        fileNewName,
        filterName,
        filterExt,
        regFileTypeId,
        regFileTypeName
    };
    enum Confidence {
        noAttempt,
        maybeAttemptForeign,
        maybeAttemptNative,
        yesAttemptForeign,
        yesAttemptNative,
        yesAlreadyOpen
    };

    UINT m_nIDResource = 0;
    CRuntimeClass* m_pDocClass = nullptr;
    CRuntimeClass* m_pFrameClass = nullptr;
    CRuntimeClass* m_pViewClass = nullptr;
    std::vector<CDocument*> m_docList;

    CDocTemplate(UINT nIDResource, CRuntimeClass* pDocClass, CRuntimeClass* pFrameClass, CRuntimeClass* pViewClass)
        : m_nIDResource(nIDResource), m_pDocClass(pDocClass), m_pFrameClass(pFrameClass), m_pViewClass(pViewClass) {}
    ~CDocTemplate() override = default;

    virtual void AddDocument(CDocument* pDoc);
    virtual void RemoveDocument(CDocument* pDoc);
    virtual POSITION GetFirstDocPosition() const;
    virtual CDocument* GetNextDoc(POSITION& rPos) const;
    virtual Confidence MatchDocType(LPCTSTR lpszPathName, CDocument*& rpDocMatch);
    virtual CDocument* CreateNewDocument();
    virtual CFrameWnd* CreateNewFrame(CDocument* pDoc, CFrameWnd* pOther);
    virtual void InitialUpdateFrame(CFrameWnd* pFrame, CDocument* pDoc, BOOL bMakeVisible = TRUE);
    virtual CDocument* OpenDocumentFile(LPCTSTR lpszPathName, BOOL bMakeVisible = TRUE) = 0;
    virtual CDocument* OpenDocumentFile(LPCTSTR lpszPathName, BOOL bAddToMRU, BOOL bMakeVisible) {
        (void)bAddToMRU;
        return OpenDocumentFile(lpszPathName, bMakeVisible);
    }
    virtual BOOL GetDocString(CString& rString, enum DocStringIndex index) const;
    virtual void CloseAllDocuments(BOOL bEndSession);
    virtual BOOL SaveAllModified();
    virtual BOOL OnDDECommand(LPTSTR lpszCommand) { (void)lpszCommand; return FALSE; }
};

class CMultiDocTemplate : public CDocTemplate {
    DECLARE_DYNAMIC(CMultiDocTemplate)
public:
    HMENU m_hMenuShared = nullptr;
    HACCEL m_hAccelTable = nullptr;
    UINT m_nUntitledCount = 0;

    CMultiDocTemplate(UINT nIDResource, CRuntimeClass* pDocClass, CRuntimeClass* pFrameClass, CRuntimeClass* pViewClass)
        : CDocTemplate(nIDResource, pDocClass, pFrameClass, pViewClass) {}
    ~CMultiDocTemplate() override = default;

    CDocument* OpenDocumentFile(LPCTSTR lpszPathName, BOOL bMakeVisible = TRUE) override;
    CDocument* OpenDocumentFile(LPCTSTR lpszPathName, BOOL bAddToMRU, BOOL bMakeVisible) override {
        (void)bAddToMRU;
        return OpenDocumentFile(lpszPathName, bMakeVisible);
    }
    BOOL OnDDECommand(LPTSTR lpszCommand) override { (void)lpszCommand; return FALSE; }
    void SetDefaultTitle(CDocument* pDocument);
};

class CDocManager : public CObject {
public:
    std::vector<CDocTemplate*> m_templateList;

    virtual void AddDocTemplate(CDocTemplate* pTemplate) {
        if (pTemplate) m_templateList.push_back(pTemplate);
    }
    virtual POSITION GetFirstDocTemplatePosition() const {
        return m_templateList.empty() ? nullptr : (POSITION)(uintptr_t)1;
    }
    virtual CDocTemplate* GetNextDocTemplate(POSITION& pos) const {
        uintptr_t idx = (uintptr_t)pos;
        if (idx == 0 || idx > m_templateList.size()) { pos = nullptr; return nullptr; }
        CDocTemplate* t = m_templateList[idx - 1];
        pos = (idx < m_templateList.size()) ? (POSITION)(idx + 1) : nullptr;
        return t;
    }
    virtual CDocument* OpenDocumentFile(LPCTSTR lpszFileName, BOOL bAddToMRU = TRUE) {
        if (m_templateList.empty()) return nullptr;
        return m_templateList[0]->OpenDocumentFile(lpszFileName, bAddToMRU, TRUE);
    }
    virtual BOOL SaveAllModified() {
        for (auto* t : m_templateList) {
            if (!t->SaveAllModified()) return FALSE;
        }
        return TRUE;
    }
    virtual void CloseAllDocuments(BOOL bEndSession) {
        for (auto* t : m_templateList) t->CloseAllDocuments(bEndSession);
    }
    virtual void OnFileNew() {
        if (!m_templateList.empty()) m_templateList[0]->OpenDocumentFile(nullptr);
    }
    virtual void OnFileOpen() {}
    virtual BOOL OnDDECommand(LPTSTR lpszCommand) { (void)lpszCommand; return FALSE; }
};

// CCommandLineInfo
class CCommandLineInfo : public CObject {
public:
    enum {
        FileNew,
        FileOpen,
        FilePrint,
        FilePrintTo,
        FileDDE,
        AppRegister,
        AppUnregister,
        FileNothing = -1
    } m_nShellCommand = FileNew;

    BOOL m_bShowSplash = TRUE;
    BOOL m_bRunEmbedded = FALSE;
    BOOL m_bRunAutomated = FALSE;
    CString m_strFileName;
    CString m_strPrinterName;
    CString m_strDriverName;
    CString m_strPortName;

    CCommandLineInfo() = default;
    ~CCommandLineInfo() override = default;
    virtual void ParseParam(const TCHAR* pszParam, BOOL bFlag, BOOL bLast);
};

// CRecentFileList (defined in afxpriv.h, forward declared here)
class CRecentFileList;
class CDataRecoveryHandler;

// CWinThread and CWinApp
class CWinThread : public CCmdTarget {
    DECLARE_DYNAMIC(CWinThread)
public:
    CWnd* m_pMainWnd = nullptr;
    BOOL m_bAutoDelete = TRUE;
    HANDLE m_hThread = nullptr;
    DWORD m_nThreadID = 0;
    MSG m_msgCur{};

    CWinThread() = default;
    ~CWinThread() override = default;

    virtual BOOL InitInstance() { return TRUE; }
    virtual int Run();
    virtual BOOL PreTranslateMessage(MSG* pMsg);
    virtual BOOL PumpMessage();
    virtual BOOL OnIdle(LONG lCount);
    virtual BOOL IsIdleMessage(MSG* pMsg);
    virtual int ExitInstance() { return 0; }
    virtual LRESULT ProcessWndProcException(CException* e, const MSG* pMsg) { (void)e; (void)pMsg; return 0; }
    BOOL PostThreadMessage(UINT message, WPARAM wParam, LPARAM lParam) {
        return ::PostThreadMessage(m_nThreadID, message, wParam, lParam);
    }
};

class CWinApp : public CWinThread {
    DECLARE_DYNAMIC(CWinApp)
public:
    HINSTANCE m_hInstance = (HINSTANCE)0x1000;
    LPTSTR m_lpCmdLine = nullptr;
    int m_nCmdShow = SW_SHOWNORMAL;
    LPCTSTR m_pszAppName = _T("OpenMPT");
    LPCTSTR m_pszRegistryKey = nullptr;
    LPCTSTR m_pszProfileName = nullptr;
    LPCTSTR m_pszHelpFilePath = nullptr;
    LPCTSTR m_pszExeName = _T("OpenMPT");
    CRecentFileList* m_pRecentFileList = nullptr;
    CDocManager* m_pDocManager = nullptr;

    CWinApp(LPCTSTR lpszAppName = nullptr);
    ~CWinApp() override;

    void AddDocTemplate(CDocTemplate* pTemplate) {
        if (!m_pDocManager) m_pDocManager = new CDocManager();
        m_pDocManager->AddDocTemplate(pTemplate);
    }
    POSITION GetFirstDocTemplatePosition() const {
        return m_pDocManager ? m_pDocManager->GetFirstDocTemplatePosition() : nullptr;
    }
    CDocTemplate* GetNextDocTemplate(POSITION& pos) const {
        return m_pDocManager ? m_pDocManager->GetNextDocTemplate(pos) : nullptr;
    }
    CWnd* GetMainWnd() const { return m_pMainWnd; }
    virtual CDocument* OpenDocumentFile(LPCTSTR lpszFileName) {
        return m_pDocManager ? m_pDocManager->OpenDocumentFile(lpszFileName, TRUE) : nullptr;
    }
    virtual CDocument* OpenDocumentFile(LPCTSTR lpszFileName, BOOL bAddToMRU) {
        return m_pDocManager ? m_pDocManager->OpenDocumentFile(lpszFileName, bAddToMRU) : nullptr;
    }
    virtual CDocument* OpenDocumentFile(LPCSTR lpszFileName) {
        CString s(lpszFileName);
        return OpenDocumentFile(s.GetString(), TRUE);
    }
    virtual CDocument* OpenDocumentFile(LPCSTR lpszFileName, BOOL bAddToMRU) {
        CString s(lpszFileName);
        return OpenDocumentFile(s.GetString(), bAddToMRU);
    }
    virtual void AddToRecentFileList(LPCTSTR lpszPathName);
    void SetRegistryKey(LPCTSTR lpszRegistryKey) { m_pszRegistryKey = lpszRegistryKey; }
    void SetRegistryKey(UINT nIDRegistryKey) { (void)nIDRegistryKey; }
    virtual UINT GetProfileInt(LPCTSTR lpszSection, LPCTSTR lpszEntry, int nDefault);
    virtual BOOL WriteProfileInt(LPCTSTR lpszSection, LPCTSTR lpszEntry, int nValue);
    virtual CString GetProfileString(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPCTSTR lpszDefault = NULL);
    virtual BOOL WriteProfileString(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPCTSTR lpszValue);
    virtual BOOL GetProfileBinary(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPBYTE* ppData, UINT* pBytes);
    virtual BOOL WriteProfileBinary(LPCTSTR lpszSection, LPCTSTR lpszEntry, LPBYTE pData, UINT nBytes);
    void LoadStdProfileSettings(UINT nMaxMRU = 4);
    void ParseCommandLine(CCommandLineInfo& rCmdInfo);
    BOOL ProcessShellCommand(CCommandLineInfo& rCmdInfo);
    void EnableHtmlHelp() {}
    void EnableShellOpen() {}
    virtual void WinHelp(DWORD_PTR dwData, UINT nCmd = HELP_CONTEXT) { (void)dwData; (void)nCmd; }
    virtual void HtmlHelp(DWORD_PTR dwData, UINT nCmd = 0x000F) { (void)dwData; (void)nCmd; }

    HCURSOR LoadStandardCursor(LPCTSTR lpszCursorName) const { return ::LoadCursor(nullptr, lpszCursorName); }
    HCURSOR LoadCursor(LPCTSTR lpszResourceName) const { return ::LoadCursor(m_hInstance, lpszResourceName); }
    HCURSOR LoadCursor(UINT nIDResource) const { return ::LoadCursor(m_hInstance, MAKEINTRESOURCE(nIDResource)); }
    HICON LoadIcon(LPCTSTR lpszResourceName) const { return ::LoadIcon(m_hInstance, lpszResourceName); }
    HICON LoadIcon(UINT nIDResource) const { return ::LoadIcon(m_hInstance, MAKEINTRESOURCE(nIDResource)); }

    virtual int DoMessageBox(LPCTSTR lpszPrompt, UINT nType, UINT nIDPrompt);
    DWORD m_dwRestartManagerSupportFlags = 0;
    int m_nAutosaveInterval = 0;
    CDataRecoveryHandler* m_pDataRecoveryHandler = nullptr;
    BOOL SupportsRestartManager() const { return (m_dwRestartManagerSupportFlags & 0x01) != 0; }
    BOOL SupportsApplicationRecovery() const { return (m_dwRestartManagerSupportFlags & 0x02) != 0; }
    virtual CDataRecoveryHandler* GetDataRecoveryHandler() { return m_pDataRecoveryHandler; }

    BOOL InitInstance() override { return TRUE; }
    int ExitInstance() override { return 0; }
    int Run() override;

    afx_msg void OnFileNew() { if (m_pDocManager) m_pDocManager->OnFileNew(); }
    afx_msg void OnFileOpen() { if (m_pDocManager) m_pDocManager->OnFileOpen(); }
    afx_msg BOOL OnOpenRecentFile(UINT nID);

    DECLARE_MESSAGE_MAP()
};

// Global AFX functions
CWinApp* AFXAPI AfxGetApp();
CWnd* AFXAPI AfxGetMainWnd();
HINSTANCE AFXAPI AfxGetInstanceHandle();
HINSTANCE AFXAPI AfxGetResourceHandle();
LPCTSTR AFXAPI AfxGetAppName();
int AFXAPI AfxMessageBox(LPCTSTR lpszText, UINT nType = MB_OK, UINT nIDHelp = 0);
int AFXAPI AfxMessageBox(UINT nIDPrompt, UINT nType = MB_OK, UINT nIDHelp = (UINT)-1);
LPCTSTR AFXAPI AfxRegisterWndClass(UINT nClassStyle, HCURSOR hCursor = nullptr, HBRUSH hbrBackground = nullptr, HICON hIcon = nullptr);
BOOL AFXAPI AfxInitRichEdit2();
HRESULT AFXAPI AfxDllCanUnloadNow();
void AFXAPI AfxSocketInit();
inline void AFXAPI AfxSetWindowText(HWND hWndCtrl, LPCTSTR lpszNew) {
    ::SetWindowText(hWndCtrl, lpszNew);
}
