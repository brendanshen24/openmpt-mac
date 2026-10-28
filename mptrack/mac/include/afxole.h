#pragma once

#include "afxwin.h"

typedef WORD CLIPFORMAT;

typedef struct tagDVTARGETDEVICE {
    DWORD tdSize;
    WORD tdDriverNameOffset;
    WORD tdDeviceNameOffset;
    WORD tdPortNameOffset;
    WORD tdExtDevmodeOffset;
    BYTE tdData[1];
} DVTARGETDEVICE;

typedef struct tagFORMATETC {
    CLIPFORMAT cfFormat;
    DVTARGETDEVICE *ptd;
    DWORD dwAspect;
    LONG lindex;
    DWORD tymed;
} FORMATETC, *LPFORMATETC;

#define TYMED_HGLOBAL   1
#define TYMED_FILE      2
#define TYMED_ISTREAM   4
#define TYMED_ISTORAGE  8
#define TYMED_GDI       16
#define TYMED_MFPICT    32
#define TYMED_ENHMF     64
#define TYMED_NULL      0

typedef struct tagSTGMEDIUM {
    DWORD tymed;
    union {
        HBITMAP hBitmap;
        void *hMetaFilePict;
        HENHMETAFILE hEnhMetaFile;
        HGLOBAL hGlobal;
        LPWSTR lpszFileName;
        IStream *pstm;
        void *pstg;
    };
    IUnknown *pUnkForRelease;
} STGMEDIUM, *LPSTGMEDIUM;

#define DRAGDROP_S_DROP             0x00040100L
#define DRAGDROP_S_CANCEL           0x00040101L
#define DRAGDROP_S_USEDEFAULTCURSORS 0x00040102L

typedef DWORD DROPEFFECT;
#define DROPEFFECT_NONE   0
#define DROPEFFECT_COPY   1
#define DROPEFFECT_MOVE   2
#define DROPEFFECT_LINK   4
#define DROPEFFECT_SCROLL 0x80000000

class COleDataObject {
public:
    HGLOBAL m_hData = nullptr;
    CLIPFORMAT m_cfFormat = 0;

    COleDataObject() = default;
    ~COleDataObject() = default;

    BOOL AttachClipboard() { return TRUE; }
    BOOL IsDataAvailable(CLIPFORMAT cfFormat, LPFORMATETC lpFormatEtc = nullptr) {
        (void)lpFormatEtc;
        if (m_hData && m_cfFormat == cfFormat) return TRUE;
        return ::IsClipboardFormatAvailable(cfFormat);
    }
    HGLOBAL GetGlobalData(CLIPFORMAT cfFormat, LPFORMATETC lpFormatEtc = nullptr) {
        (void)lpFormatEtc;
        if (m_hData && m_cfFormat == cfFormat) return m_hData;
        return ::GetClipboardData(cfFormat);
    }
    BOOL GetData(CLIPFORMAT cfFormat, LPSTGMEDIUM lpStgMedium, LPFORMATETC lpFormatEtc = nullptr) {
        if (!lpStgMedium) return FALSE;
        HGLOBAL h = GetGlobalData(cfFormat, lpFormatEtc);
        if (!h) return FALSE;
        lpStgMedium->tymed = TYMED_HGLOBAL;
        lpStgMedium->hGlobal = h;
        lpStgMedium->pUnkForRelease = nullptr;
        return TRUE;
    }
};

class COleDropSource : public CCmdTarget {
public:
    COleDropSource() = default;
    ~COleDropSource() override = default;
    virtual SCODE QueryContinueDrag(BOOL bEscapePressed, DWORD dwKeyState) {
        if (bEscapePressed) return DRAGDROP_S_CANCEL;
        if ((dwKeyState & (MK_LBUTTON | MK_RBUTTON)) == 0) return DRAGDROP_S_DROP;
        return S_OK;
    }
    virtual SCODE GiveFeedback(DROPEFFECT dropEffect) {
        (void)dropEffect;
        return DRAGDROP_S_USEDEFAULTCURSORS;
    }
};

class COleDataSource : public CCmdTarget {
public:
    HGLOBAL m_hData = nullptr;
    CLIPFORMAT m_cfFormat = 0;

    COleDataSource() = default;
    ~COleDataSource() override = default;

    void CacheGlobalData(CLIPFORMAT cfFormat, HGLOBAL hGlobal, LPFORMATETC lpFormatEtc = nullptr) {
        (void)lpFormatEtc;
        m_cfFormat = cfFormat;
        m_hData = hGlobal;
    }
    DROPEFFECT DoDragDrop(DWORD dwEffects = DROPEFFECT_COPY | DROPEFFECT_MOVE | DROPEFFECT_LINK,
                          LPCRECT lpRectStartDrag = nullptr, COleDropSource* pDropSource = nullptr);
};

class COleDropTarget : public CCmdTarget {
public:
    HWND m_hWnd = nullptr;

    COleDropTarget() = default;
    ~COleDropTarget() override { Revoke(); }

    BOOL Register(CWnd* pWnd);
    virtual void Revoke();

    virtual DROPEFFECT OnDragEnter(CWnd* pWnd, COleDataObject* pDataObject, DWORD dwKeyState, CPoint point) {
        (void)pWnd; (void)pDataObject; (void)dwKeyState; (void)point;
        return DROPEFFECT_NONE;
    }
    virtual DROPEFFECT OnDragOver(CWnd* pWnd, COleDataObject* pDataObject, DWORD dwKeyState, CPoint point) {
        (void)pWnd; (void)pDataObject; (void)dwKeyState; (void)point;
        return DROPEFFECT_NONE;
    }
    virtual BOOL OnDrop(CWnd* pWnd, COleDataObject* pDataObject, DROPEFFECT dropEffect, CPoint point) {
        (void)pWnd; (void)pDataObject; (void)dropEffect; (void)point;
        return FALSE;
    }
    virtual DROPEFFECT OnDropEx(CWnd* pWnd, COleDataObject* pDataObject, DROPEFFECT dropDefault, DROPEFFECT dropList, CPoint point) {
        (void)pWnd; (void)pDataObject; (void)dropDefault; (void)dropList; (void)point;
        return (DROPEFFECT)-1;
    }
    virtual void OnDragLeave(CWnd* pWnd) { (void)pWnd; }
    virtual DROPEFFECT OnDragScroll(CWnd* pWnd, DWORD dwKeyState, CPoint point) {
        (void)pWnd; (void)dwKeyState; (void)point;
        return DROPEFFECT_NONE;
    }
};

BOOL AFXAPI AfxOleInit();
