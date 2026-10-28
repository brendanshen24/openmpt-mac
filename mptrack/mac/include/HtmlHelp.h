#pragma once

#include "windows.h"

#define HH_DISPLAY_TOPIC        0x0000
#define HH_HELP_FINDER          0x0000
#define HH_DISPLAY_TOC          0x0001
#define HH_DISPLAY_INDEX        0x0002
#define HH_DISPLAY_SEARCH       0x0003
#define HH_HELP_CONTEXT         0x000F
#define HH_CLOSE_ALL            0x0012

struct HH_AKLINK {
    int       cbStruct;
    BOOL      fReserved;
    LPCTSTR   pszKeywords;
    LPCTSTR   pszUrl;
    LPCTSTR   pszMsgText;
    LPCTSTR   pszMsgTitle;
    LPCTSTR   pszWindow;
    BOOL      fIndexOnFail;
};
