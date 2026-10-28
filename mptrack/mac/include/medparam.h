#pragma once
#include "windows.h"

typedef float MP_DATA;

enum _MP_Type {
    MPT_INT = 0,
    MPT_FLOAT = 1,
    MPT_BOOL = 2,
    MPT_ENUM = 3,
    MPT_MAX = 4
};

struct MP_PARAMINFO {
    _MP_Type mpType;
    MP_DATA mpdMinValue;
    MP_DATA mpdMaxValue;
    MP_DATA mpdNeutralValue;
    WCHAR szUnitText[32];
    WCHAR szLabel[32];
};

struct IMediaParamInfo : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE GetParamCount(DWORD *pdwParams) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetParamInfo(DWORD dwParamIndex, MP_PARAMINFO *pInfo) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetParamText(DWORD dwParamIndex, WCHAR **ppwchText) = 0;
};

struct IMediaParams : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE GetParam(DWORD dwParamIndex, MP_DATA *pValue) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetParam(DWORD dwParamIndex, MP_DATA value) = 0;
};

static const IID IID_IMediaParamInfo = {0x6d6cbb60, 0xa223, 0x44aa, {0x84, 0x2f, 0xa2, 0xf0, 0x67, 0x50, 0xbe, 0x6d}};
static const IID IID_IMediaParams = {0x6d6cbb61, 0xa223, 0x44aa, {0x84, 0x2f, 0xa2, 0xf0, 0x67, 0x50, 0xbe, 0x6d}};
