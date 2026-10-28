#pragma once

#include <unistd.h>
#include <fcntl.h>

#ifndef _O_BINARY
#define _O_BINARY 0
#endif
#ifndef _O_TEXT
#define _O_TEXT 0
#endif

#define _read read
#define _write write
#define _close close
#define _open open
#define _lseek lseek
#define _unlink unlink
#define _access access
#define _fileno fileno
inline int _setmode(int, int) { return 0; }
