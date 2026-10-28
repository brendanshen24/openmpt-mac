#pragma once
#include "windows.h"

typedef IUnknown* LPUNKNOWN;

namespace ATL {

template <class T>
class CComPtr {
public:
    T* p = nullptr;

    CComPtr() noexcept : p(nullptr) {}
    CComPtr(T* lp) noexcept : p(lp) { if (p) p->AddRef(); }
    CComPtr(const CComPtr<T>& lp) noexcept : p(lp.p) { if (p) p->AddRef(); }
    ~CComPtr() noexcept { if (p) p->Release(); }

    void Release() noexcept {
        T* pTemp = p;
        if (pTemp) {
            p = nullptr;
            pTemp->Release();
        }
    }

    operator T*() const noexcept { return p; }
    T& operator*() const noexcept { return *p; }
    T** operator&() noexcept { return &p; }
    T* operator->() const noexcept { return p; }
    bool operator!() const noexcept { return (p == nullptr); }

    T* Attach(T* p2) noexcept {
        if (p) p->Release();
        p = p2;
        return p;
    }
    T* Detach() noexcept {
        T* pt = p;
        p = nullptr;
        return pt;
    }

    HRESULT CoCreateInstance(REFCLSID rclsid, LPUNKNOWN pUnkOuter = nullptr, DWORD dwClsContext = CLSCTX_ALL) noexcept {
        return ::CoCreateInstance(rclsid, pUnkOuter, dwClsContext, IID_IUnknown, (void**)&p);
    }
};

} // namespace ATL

using ATL::CComPtr;
