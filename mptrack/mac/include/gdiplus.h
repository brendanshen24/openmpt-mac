#pragma once

#include "windows.h"
#include <vector>
#include <memory>

namespace Gdiplus {

enum Status {
    Ok = 0,
    GenericError = 1,
    InvalidParameter = 2,
    OutOfMemory = 3,
    ObjectBusy = 4,
    InsufficientBuffer = 5,
    NotImplemented = 6,
    Win32Error = 7,
    WrongState = 8,
    Aborted = 9,
    FileNotFound = 10,
    ValueOverflow = 11,
    AccessDenied = 12,
    UnknownImageFormat = 13
};

struct GdiplusStartupInput {
    UINT32 GdiplusVersion = 1;
    void* DebugEventCallback = nullptr;
    BOOL SuppressBackgroundThread = FALSE;
    BOOL SuppressExternalCodecs = FALSE;
};

struct GdiplusStartupOutput {
    void* NotificationHook = nullptr;
    void* NotificationUnhook = nullptr;
};

inline Status GdiplusStartup(ULONG_PTR* token, const GdiplusStartupInput*, GdiplusStartupOutput*) {
    if (token) *token = 1;
    return Ok;
}
inline void GdiplusShutdown(ULONG_PTR) {}

typedef int PixelFormat;
#define PixelFormat32bppARGB 0x26200A
#define PixelFormat32bppPARGB 0xE200B
#define PixelFormat24bppRGB  0x21808

enum ImageLockMode {
    ImageLockModeRead = 0x0001,
    ImageLockModeWrite = 0x0002,
    ImageLockModeUserInputBuf = 0x0004
};

enum InterpolationMode {
    InterpolationModeDefault = 0,
    InterpolationModeLowQuality = 1,
    InterpolationModeHighQuality = 2,
    InterpolationModeBilinear = 3,
    InterpolationModeBicubic = 4,
    InterpolationModeNearestNeighbor = 5,
    InterpolationModeHighQualityBilinear = 6,
    InterpolationModeHighQualityBicubic = 7
};

enum CompositingQuality {
    CompositingQualityDefault = 0,
    CompositingQualityHighSpeed = 1,
    CompositingQualityHighQuality = 2
};

enum SmoothingMode {
    SmoothingModeDefault = 0,
    SmoothingModeHighSpeed = 1,
    SmoothingModeHighQuality = 2,
    SmoothingModeNone = 3,
    SmoothingModeAntiAlias = 4
};

enum PixelOffsetMode {
    PixelOffsetModeDefault = 0,
    PixelOffsetModeHighSpeed = 1,
    PixelOffsetModeHighQuality = 2,
    PixelOffsetModeNone = 3,
    PixelOffsetModeHalf = 4
};

enum Unit {
    UnitWorld = 0,
    UnitDisplay = 1,
    UnitPixel = 2
};

struct Point {
    INT X = 0;
    INT Y = 0;
    Point() = default;
    Point(INT x, INT y) : X(x), Y(y) {}
};

struct PointF {
    float X = 0;
    float Y = 0;
    PointF() = default;
    PointF(float x, float y) : X(x), Y(y) {}
};

struct Size {
    INT Width = 0;
    INT Height = 0;
    Size() = default;
    Size(INT w, INT h) : Width(w), Height(h) {}
};

struct SizeF {
    float Width = 0;
    float Height = 0;
    SizeF() = default;
    SizeF(float w, float h) : Width(w), Height(h) {}
};

struct Rect {
    INT X = 0;
    INT Y = 0;
    INT Width = 0;
    INT Height = 0;
    Rect() = default;
    Rect(INT x, INT y, INT w, INT h) : X(x), Y(y), Width(w), Height(h) {}
    Rect(const Point& location, const Size& size) : X(location.X), Y(location.Y), Width(size.Width), Height(size.Height) {}
};

struct RectF {
    float X = 0;
    float Y = 0;
    float Width = 0;
    float Height = 0;
    RectF() = default;
    RectF(float x, float y, float w, float h) : X(x), Y(y), Width(w), Height(h) {}
    RectF(const PointF& location, const SizeF& size) : X(location.X), Y(location.Y), Width(size.Width), Height(size.Height) {}
};

class Color {
public:
    BYTE A = 255;
    BYTE R = 0;
    BYTE G = 0;
    BYTE B = 0;
    Color() = default;
    Color(BYTE a, BYTE r, BYTE g, BYTE b) : A(a), R(r), G(g), B(b) {}
    Color(BYTE r, BYTE g, BYTE b) : A(255), R(r), G(g), B(b) {}
    DWORD GetValue() const { return (static_cast<DWORD>(A) << 24) | (static_cast<DWORD>(R) << 16) | (static_cast<DWORD>(G) << 8) | B; }
};

class ImageAttributes {
public:
    ImageAttributes() = default;
    ~ImageAttributes() = default;
};

struct BitmapData {
    UINT Width = 0;
    UINT Height = 0;
    INT Stride = 0;
    PixelFormat PixelFormat = PixelFormat32bppARGB;
    VOID* Scan0 = nullptr;
    UINT_PTR Reserved = 0;
};

class Image {
public:
    UINT m_width = 0;
    UINT m_height = 0;
    std::vector<uint8_t> m_pixels; // BGRA32 (little-endian ARGB32)
    Status m_status = Ok;

    Image() = default;
    virtual ~Image() = default;

    UINT GetWidth() const { return m_width; }
    UINT GetHeight() const { return m_height; }
    Status GetLastStatus() const { return m_status; }
};

class Bitmap : public Image {
public:
    Bitmap(INT width, INT height, PixelFormat format = PixelFormat32bppARGB);
    Bitmap(IStream* stream, BOOL useEmbeddedColorManagement = FALSE);
    ~Bitmap() override = default;

    static Bitmap* FromStream(IStream* stream, BOOL useEmbeddedColorManagement = FALSE);

    Status LockBits(const Rect* rect, UINT flags, PixelFormat format, BitmapData* lockedBitmapData);
    Status UnlockBits(BitmapData* lockedBitmapData);
};

class Metafile : public Image {
public:
    Metafile(IStream* stream) { (void)stream; m_status = UnknownImageFormat; }
    Metafile(const void* data, size_t size);
};

class Graphics {
public:
    Bitmap* m_target = nullptr;
    HDC m_hdc = nullptr;
    Status m_status = Ok;

    explicit Graphics(Image* image) : m_target(static_cast<Bitmap*>(image)) {}
    explicit Graphics(HDC hdc) : m_hdc(hdc) {}

    static Graphics* FromImage(Image* image) { return new Graphics(image); }

    Status GetLastStatus() const { return m_status; }
    Status SetInterpolationMode(InterpolationMode) { return Ok; }
    Status SetCompositingQuality(CompositingQuality) { return Ok; }
    Status SetSmoothingMode(SmoothingMode) { return Ok; }
    Status SetPixelOffsetMode(PixelOffsetMode) { return Ok; }

    Status Clear(const Color& color = Color(0, 0, 0, 0));

    Status DrawImage(Image* image, INT x, INT y);
    Status DrawImage(Image* image, INT x, INT y, INT width, INT height);
    Status DrawImage(Image* image, const Rect& destRect, INT srcx, INT srcy, INT srcwidth, INT srcheight, Unit srcUnit, const ImageAttributes* attr = nullptr);
    Status DrawImage(Image* image, const RectF& destRect, float srcx, float srcy, float srcwidth, float srcheight, Unit srcUnit);
    Status DrawImage(Image* image, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, Unit srcUnit);
};

} // namespace Gdiplus
