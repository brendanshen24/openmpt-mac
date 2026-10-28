#pragma once

#include "windows.h"

#define TF_INVALID_COOKIE 0xffffffff

#ifndef __RPC__out
#define __RPC__out
#endif

struct ITfLanguageProfileNotifySink : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE OnLanguageChange(LANGID langid, BOOL *pfAccept) = 0;
    virtual HRESULT STDMETHODCALLTYPE OnLanguageChanged() = 0;
};

struct ITfInputProcessorProfiles : public IUnknown {
};

struct ITfSource : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE AdviseSink(REFIID riid, IUnknown *punk, DWORD *pdwCookie) = 0;
    virtual HRESULT STDMETHODCALLTYPE UnadviseSink(DWORD dwCookie) = 0;
};

static const CLSID CLSID_TF_InputProcessorProfiles = {0x33c53a50, 0xf456, 0x4884, {0xb0, 0x49, 0x85, 0xfd, 0x64, 0x3e, 0xc3, 0x27}};
static const IID IID_ITfInputProcessorProfiles = {0x1f02b6c5, 0xd622, 0x11d2, {0x8f, 0xab, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5}};
static const IID IID_ITfSource = {0x4f88e290, 0xd560, 0x11d2, {0x8f, 0xab, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5}};
static const IID IID_ITfLanguageProfileNotifySink = {0x43826d1e, 0xe717, 0x47ee, {0xbc, 0xee, 0x4a, 0x7e, 0x6e, 0x7e, 0x2e, 0x25}};
