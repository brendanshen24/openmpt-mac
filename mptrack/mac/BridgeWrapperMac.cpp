/*
 * BridgeWrapperMac.cpp
 * --------------------
 * Native macOS stub for Windows PluginBridge.
 * On macOS, plugins are loaded natively as Mach-O bundles / AU / VST.
 */

#include "stdafx.h"

#ifdef MPT_WITH_VST
#include "../pluginBridge/BridgeWrapper.h"

OPENMPT_NAMESPACE_BEGIN

std::vector<BridgeCommon *> BridgeCommon::m_plugins;
HWND BridgeCommon::m_communicationWindow = nullptr;
int BridgeCommon::m_instanceCount = 0;
thread_local bool BridgeCommon::m_isAudioThread = false;

std::size_t GetPluginArchPointerSize(PluginArch arch)
{
#if defined(__aarch64__) || defined(__arm64__)
	return (arch == PluginArch_arm64) ? 8 : 4;
#else
	return (arch == PluginArch_amd64) ? 8 : 4;
#endif
}

ComponentPluginBridge::ComponentPluginBridge(PluginArch arch, Generation generation)
	: ComponentBase(ComponentTypeBundled)
	, arch(arch)
	, generation(generation)
{
}

bool ComponentPluginBridge::DoInitialize()
{
	availability = AvailabilityMissing;
	return false;
}

PluginArch BridgeWrapper::GetNativePluginBinaryType()
{
#if defined(__aarch64__) || defined(__arm64__)
	return PluginArch_arm64;
#else
	return PluginArch_amd64;
#endif
}

PluginArch BridgeWrapper::GetPluginBinaryType(const mpt::PathString &/*pluginPath*/)
{
	return GetNativePluginBinaryType();
}

uint64 BridgeWrapper::GetFileVersion(const WCHAR */*exePath*/)
{
	return 0;
}

Vst::AEffect *BridgeWrapper::Create(const VSTPluginLib &/*plugin*/, bool /*forceLegacy*/)
{
	throw BridgeNotFoundException();
}

OPENMPT_NAMESPACE_END

#endif // MPT_WITH_VST
