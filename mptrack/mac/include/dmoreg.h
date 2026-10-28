#pragma once
#include "windows.h"

#define DMO_INPLACE_NORMAL 0
#define DMO_SET_TYPEF_CLEAR 0x00000001

typedef LONGLONG REFERENCE_TIME;

struct DMO_MEDIA_TYPE {
    GUID majortype;
    GUID subtype;
    BOOL bFixedSizeSamples;
    BOOL bTemporalCompression;
    ULONG lSampleSize;
    GUID formattype;
    IUnknown *pUnk;
    ULONG cbFormat;
    BYTE *pbFormat;
};

struct IMediaObject : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE GetStreamCount(DWORD *pcInputStreams, DWORD *pcOutputStreams) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetInputStreamInfo(DWORD dwInputStreamIndex, DWORD *pdwFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetOutputStreamInfo(DWORD dwOutputStreamIndex, DWORD *pdwFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetInputType(DWORD dwInputStreamIndex, const DMO_MEDIA_TYPE *pmt, DWORD dwFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetOutputType(DWORD dwOutputStreamIndex, const DMO_MEDIA_TYPE *pmt, DWORD dwFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE Flush(void) = 0;
    virtual HRESULT STDMETHODCALLTYPE Discontinuity(DWORD dwInputStreamIndex) = 0;
};

struct IMediaObjectInPlace : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Process(ULONG ulSize, BYTE *pData, REFERENCE_TIME rtStart, DWORD dwFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE Clone(IMediaObjectInPlace **ppMediaObject) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetLatency(REFERENCE_TIME *prtLatency) = 0;
};

static const IID IID_IMediaObject = {0xd8266aac, 0xd464, 0x4eb6, {0x96, 0x82, 0x9f, 0xa9, 0x14, 0x38, 0xaa, 0x99}};
static const IID IID_IMediaObjectInPlace = {0x651b9ad0, 0x0fc7, 0x4aa9, {0x95, 0x38, 0xd8, 0x99, 0x32, 0x04, 0x23, 0xa6}};
