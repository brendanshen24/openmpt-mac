#pragma once

#define _CRTDBG_ALLOC_MEM_DF        0x01
#define _CRTDBG_DELAY_FREE_MEM_DF   0x02
#define _CRTDBG_CHECK_ALWAYS_DF     0x04
#define _CRTDBG_RESERVED_DF         0x08
#define _CRTDBG_CHECK_CRT_DF        0x10
#define _CRTDBG_LEAK_CHECK_DF       0x20

#define _CRT_WARN                   0
#define _CRT_ERROR                  1
#define _CRT_ASSERT                 2

inline int _CrtSetDbgFlag(int newFlag) { return newFlag; }
inline int _CrtDumpMemoryLeaks() { return 0; }
inline int _CrtCheckMemory() { return 1; }
