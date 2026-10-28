#pragma once

#include "windows.h"

typedef UINT MMRESULT;
typedef UINT MMVERSION;

#define MMSYSERR_NOERROR      0
#define MMSYSERR_ERROR        1
#define MMSYSERR_BADDEVICEID  2
#define MMSYSERR_NOTENABLED   3
#define MMSYSERR_ALLOCATED    4
#define MMSYSERR_INVALHANDLE  5
#define MMSYSERR_NODRIVER     6
#define MMSYSERR_NOMEM        7
#define MMSYSERR_NOTSUPPORTED 8
#define MMSYSERR_INVALPARAM   11

#define CALLBACK_NULL         0x00000000l
#define CALLBACK_WINDOW       0x00010000l
#define CALLBACK_TASK         0x00020000l
#define CALLBACK_FUNCTION     0x00030000l
#define CALLBACK_THREAD       (CALLBACK_TASK)
#define CALLBACK_EVENT        0x00050000l

#define MAXPNAMELEN           32

// MIDI
#define MIDI_MAPPER ((UINT)-1)
typedef HANDLE HMIDI;
typedef HANDLE HMIDISTRM;
typedef HMIDIIN* LPHMIDIIN;
typedef HMIDIOUT* LPHMIDIOUT;

#define MIM_OPEN        0x3C1
#define MIM_CLOSE       0x3C2
#define MIM_DATA        0x3C3
#define MIM_LONGDATA    0x3C4
#define MIM_ERROR       0x3C5
#define MIM_LONGERROR   0x3C6
#define MIM_MOREDATA    0x3CC

struct MIDIINCAPSA {
    WORD wMid;
    WORD wPid;
    MMVERSION vDriverVersion;
    CHAR szPname[MAXPNAMELEN];
    DWORD dwSupport;
};
struct MIDIINCAPSW {
    WORD wMid;
    WORD wPid;
    MMVERSION vDriverVersion;
    WCHAR szPname[MAXPNAMELEN];
    DWORD dwSupport;
};
#ifdef UNICODE
typedef MIDIINCAPSW MIDIINCAPS;
#else
typedef MIDIINCAPSA MIDIINCAPS;
#endif
typedef MIDIINCAPS* LPMIDIINCAPS;

struct MIDIHDR {
    LPSTR lpData;
    DWORD dwBufferLength;
    DWORD dwBytesRecorded;
    DWORD_PTR dwUser;
    DWORD dwFlags;
    struct MIDIHDR* lpNext;
    DWORD_PTR reserved;
    DWORD dwOffset;
    DWORD_PTR dwReserved[8];
};
typedef MIDIHDR* LPMIDIHDR;

#define MHDR_DONE       0x00000001
#define MHDR_PREPARED   0x00000002
#define MHDR_INQUEUE    0x00000004
#define MHDR_ISSTRM     0x00000008

typedef void (CALLBACK *HMIDICALLBACK)(HMIDIIN hmi, UINT wMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2);

// Sound
#define WAVE_MAPPER ((UINT)-1)
#define SND_SYNC        0x0000
#define SND_ASYNC       0x0001
#define SND_NODEFAULT   0x0002
#define SND_MEMORY      0x0004
#define SND_LOOP        0x0008
#define SND_NOSTOP      0x0010
#define SND_NOWAIT      0x00002000L
#define SND_ALIAS       0x00010000L
#define SND_ALIAS_ID    0x00110000L
#define SND_FILENAME    0x00020000L
#define SND_RESOURCE    0x00040004L

#ifndef WAVE_FORMAT_PCM
#define WAVE_FORMAT_PCM 1
#endif
#ifndef WAVE_FORMAT_IEEE_FLOAT
#define WAVE_FORMAT_IEEE_FLOAT 0x0003
#endif
#ifndef WAVE_FORMAT_EXTENSIBLE
#define WAVE_FORMAT_EXTENSIBLE 0xFFFE
#endif

struct WAVEFORMATEX {
    WORD wFormatTag;
    WORD nChannels;
    DWORD nSamplesPerSec;
    DWORD nAvgBytesPerSec;
    WORD nBlockAlign;
    WORD wBitsPerSample;
    WORD cbSize;
};
typedef WAVEFORMATEX* PWAVEFORMATEX;
typedef WAVEFORMATEX* LPWAVEFORMATEX;
typedef const WAVEFORMATEX* LPCWAVEFORMATEX;

extern "C" {
UINT WINAPI midiInGetNumDevs(void);
MMRESULT WINAPI midiInGetDevCapsA(UINT_PTR uDeviceID, MIDIINCAPSA* pmic, UINT cbmic);
MMRESULT WINAPI midiInGetDevCapsW(UINT_PTR uDeviceID, MIDIINCAPSW* pmic, UINT cbmic);
#ifdef UNICODE
#define midiInGetDevCaps midiInGetDevCapsW
#else
#define midiInGetDevCaps midiInGetDevCapsA
#endif
MMRESULT WINAPI midiInOpen(LPHMIDIIN phmi, UINT uDeviceID, DWORD_PTR dwCallback, DWORD_PTR dwInstance, DWORD fdwOpen);
MMRESULT WINAPI midiInClose(HMIDIIN hmi);
MMRESULT WINAPI midiInStart(HMIDIIN hmi);
MMRESULT WINAPI midiInStop(HMIDIIN hmi);
MMRESULT WINAPI midiInReset(HMIDIIN hmi);
MMRESULT WINAPI midiInPrepareHeader(HMIDIIN hmi, LPMIDIHDR pmh, UINT cbmh);
MMRESULT WINAPI midiInUnprepareHeader(HMIDIIN hmi, LPMIDIHDR pmh, UINT cbmh);
MMRESULT WINAPI midiInAddBuffer(HMIDIIN hmi, LPMIDIHDR pmh, UINT cbmh);

BOOL WINAPI PlaySoundA(LPCSTR pszSound, HMODULE hmod, DWORD fdwSound);
BOOL WINAPI PlaySoundW(LPCWSTR pszSound, HMODULE hmod, DWORD fdwSound);
#ifdef UNICODE
#define PlaySound PlaySoundW
#else
#define PlaySound PlaySoundA
#endif

typedef struct timecaps_tag {
    UINT wPeriodMin;
    UINT wPeriodMax;
} TIMECAPS, *PTIMECAPS, *NPTIMECAPS, *LPTIMECAPS;

inline MMRESULT WINAPI timeGetDevCaps(LPTIMECAPS ptc, UINT cbtc) {
    if (ptc && cbtc >= sizeof(TIMECAPS)) {
        ptc->wPeriodMin = 1;
        ptc->wPeriodMax = 1000;
        return MMSYSERR_NOERROR;
    }
    return MMSYSERR_INVALPARAM;
}

DWORD WINAPI timeGetTime(void);
MMRESULT WINAPI timeBeginPeriod(UINT uPeriod);
MMRESULT WINAPI timeEndPeriod(UINT uPeriod);
}
