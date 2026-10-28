#pragma once
#include "windows.h"

enum MINIDUMP_TYPE {
    MiniDumpNormal         = 0x00000000,
    MiniDumpWithDataSegs   = 0x00000001,
    MiniDumpWithFullMemory = 0x00000002,
    MiniDumpWithHandleData = 0x00000004
};
