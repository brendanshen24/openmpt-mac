#pragma once

#include "windows.h"

#define DBT_DEVICEARRIVAL           0x8000
#define DBT_DEVICEREMOVECOMPLETE    0x8004
#define DBT_DEVNODES_CHANGED        0x0007

#define DBT_DEVTYP_OEM              0x00000000
#define DBT_DEVTYP_VOLUME           0x00000002
#define DBT_DEVTYP_PORT             0x00000003
#define DBT_DEVTYP_DEVICEINTERFACE  0x00000005
#define DBT_DEVTYP_HANDLE           0x00000006

#define DEVICE_NOTIFY_WINDOW_HANDLE 0x00000000

typedef PVOID HDEVNOTIFY;

struct DEV_BROADCAST_HDR {
    DWORD dbch_size;
    DWORD dbch_devicetype;
    DWORD dbch_reserved;
};
typedef DEV_BROADCAST_HDR* PDEV_BROADCAST_HDR;

struct DEV_BROADCAST_DEVICEINTERFACE_A {
    DWORD dbcc_size;
    DWORD dbcc_devicetype;
    DWORD dbcc_reserved;
    GUID  dbcc_classguid;
    char  dbcc_name[1];
};
struct DEV_BROADCAST_DEVICEINTERFACE_W {
    DWORD   dbcc_size;
    DWORD   dbcc_devicetype;
    DWORD   dbcc_reserved;
    GUID    dbcc_classguid;
    wchar_t dbcc_name[1];
};
#ifdef UNICODE
typedef DEV_BROADCAST_DEVICEINTERFACE_W DEV_BROADCAST_DEVICEINTERFACE;
#else
typedef DEV_BROADCAST_DEVICEINTERFACE_A DEV_BROADCAST_DEVICEINTERFACE;
#endif
typedef DEV_BROADCAST_DEVICEINTERFACE* PDEV_BROADCAST_DEVICEINTERFACE;

extern "C" {
inline HDEVNOTIFY WINAPI RegisterDeviceNotificationA(HANDLE, LPVOID, DWORD) { return nullptr; }
inline HDEVNOTIFY WINAPI RegisterDeviceNotificationW(HANDLE, LPVOID, DWORD) { return nullptr; }
inline BOOL WINAPI UnregisterDeviceNotification(HDEVNOTIFY) { return TRUE; }
#ifdef UNICODE
#define RegisterDeviceNotification RegisterDeviceNotificationW
#else
#define RegisterDeviceNotification RegisterDeviceNotificationA
#endif
}
