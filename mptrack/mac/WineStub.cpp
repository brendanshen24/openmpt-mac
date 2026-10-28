/*
 * WineStub.cpp
 * ------------
 * Purpose: macOS Native stub for WineIntegration (not running under Wine).
 */

#include "stdafx.h"
#include "MPTrackWine.h"
#include "../../misc/mptWine.h"

OPENMPT_NAMESPACE_BEGIN

namespace WineIntegration {

void Initialize() {}

bool IsSupported() {
    return false;
}

bool IsCompiled() {
    return false;
}

void Load() {}

} // namespace WineIntegration

namespace mpt::Wine {

// Not running under Wine: host paths are already native POSIX paths.
std::string Context::PathToPosix(mpt::PathString windowsPath) { return windowsPath.ToUTF8(); }
mpt::PathString Context::PathToWindows(std::string hostPath) { return mpt::PathString::FromUTF8(hostPath); }

} // namespace mpt::Wine

ComponentWineWrapper::ComponentWineWrapper() : ComponentLibrary(ComponentTypeBundled) {}
bool ComponentWineWrapper::DoInitialize() { return false; }
ComponentWineWrapper::~ComponentWineWrapper() {}
std::string ComponentWineWrapper::result_as_string(char * str) const { return ""; }

OPENMPT_NAMESPACE_END
