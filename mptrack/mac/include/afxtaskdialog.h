#pragma once

#include "afxwin.h"

#define TDF_ENABLE_HYPERLINKS           0x0001
#define TDF_USE_HICON_MAIN              0x0002
#define TDF_USE_HICON_FOOTER            0x0004
#define TDF_ALLOW_DIALOG_CANCELLATION   0x0008
#define TDF_USE_COMMAND_LINKS           0x0010
#define TDF_USE_COMMAND_LINKS_NO_ICON   0x0020
#define TDF_EXPAND_FOOTER_AREA          0x0040
#define TDF_EXPANDED_BY_DEFAULT         0x0080
#define TDF_VERIFICATION_FLAG_CHECKED   0x0100
#define TDF_SHOW_PROGRESS_BAR           0x0200
#define TDF_SHOW_MARQUEE_PROGRESS_BAR   0x0400
#define TDF_CALLBACK_TIMER              0x0800
#define TDF_POSITION_RELATIVE_TO_WINDOW 0x1000
#define TDF_RTL_LAYOUT                  0x2000
#define TDF_NO_DEFAULT_RADIO_BUTTON     0x4000
#define TDF_CAN_BE_MINIMIZED            0x8000

#define TDCBF_OK_BUTTON      0x0001
#define TDCBF_YES_BUTTON     0x0002
#define TDCBF_NO_BUTTON      0x0004
#define TDCBF_CANCEL_BUTTON  0x0008
#define TDCBF_RETRY_BUTTON   0x0010
#define TDCBF_CLOSE_BUTTON   0x0020

class CTaskDialog : public CObject {
public:
    struct CommandCtrl {
        int id;
        CString text;
    };
    CString m_strContent;
    CString m_strMainInstruction;
    CString m_strTitle;
    int m_nCommonButtons = 0;
    int m_nOptions = 0;
    CString m_strFooter;
    int m_nDefaultCommandControl = 0;
    int m_nSelectedCommandControl = 0;
    BOOL m_bVerified = FALSE;
    CString m_strVerificationText;
    std::vector<CommandCtrl> m_commandControls;

    static BOOL IsSupported() { return TRUE; }

    CTaskDialog(const CString& strContent, const CString& strMainInstruction, const CString& strTitle,
                int nCommonButtons = TDCBF_OK_BUTTON | TDCBF_CANCEL_BUTTON,
                int nTaskDialogOptions = TDF_ENABLE_HYPERLINKS | TDF_USE_COMMAND_LINKS,
                const CString& strFooter = CString())
        : m_strContent(strContent), m_strMainInstruction(strMainInstruction), m_strTitle(strTitle),
          m_nCommonButtons(nCommonButtons), m_nOptions(nTaskDialogOptions), m_strFooter(strFooter) {}

    void SetWindowTitle(const CString& strTitle) { m_strTitle = strTitle; }
    void SetMainInstruction(const CString& strInstruction) { m_strMainInstruction = strInstruction; }
    void SetContent(const CString& strContent) { m_strContent = strContent; }
    void SetFooterText(const CString& strFooter) { m_strFooter = strFooter; }
    void SetVerificationCheckboxText(const CString& strVerificationText) { m_strVerificationText = strVerificationText; }
    void SetVerificationCheckbox(BOOL bChecked) { m_bVerified = bChecked; }
    void SetCommonButtons(int nButtonMask, int nDisabledButtonMask = 0, int nElevationButtonMask = 0) {
        (void)nDisabledButtonMask; (void)nElevationButtonMask;
        m_nCommonButtons = nButtonMask;
    }
    void SetOptions(int nOptionFlag) { m_nOptions = nOptionFlag; }
    int GetOptions() const { return m_nOptions; }
    void SetMainIcon(HICON hMainIcon) { (void)hMainIcon; }
    void SetMainIcon(LPCWSTR lpszMainIcon) { (void)lpszMainIcon; }
    void SetDialogWidth(int nWidth) { (void)nWidth; }

    void AddCommandControl(int nCommandControlID, const CString& strCaption, BOOL bEnabled = TRUE, BOOL bRequiresElevation = FALSE) {
        (void)bEnabled; (void)bRequiresElevation;
        m_commandControls.push_back({nCommandControlID, strCaption});
    }
    void SetDefaultCommandControl(int nCommandControlID) { m_nDefaultCommandControl = nCommandControlID; }
    int GetSelectedCommandControlID() const { return m_nSelectedCommandControl; }
    BOOL GetVerificationCheckboxState() const { return m_bVerified; }

    INT_PTR DoModal(CWnd* pParent = nullptr);
};
