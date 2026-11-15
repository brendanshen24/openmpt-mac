// Run with a stereo output selected. From the repository root:
// c++ -std=c++17 -Iinclude/rtaudio mptrack/mac/tests/coreaudio-buffer.cpp build-mac/libopenmpt-rtaudio.a -framework CoreAudio -framework CoreFoundation -o /tmp/check-buffer && /tmp/check-buffer
#include "RtAudio.h"

#include <CoreAudio/CoreAudio.h>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <thread>

struct Playback
{
	unsigned int frames = 0;
	std::atomic_uint callbacks{0};
	std::atomic_bool mismatch{false};
};

static int RenderSilence(void *output, void *, unsigned int frames, double, RtAudioStreamStatus, void *context)
{
	auto &playback = *static_cast<Playback *>(context);
	std::fill_n(static_cast<float *>(output), frames * 2, 0.0f);
	if(frames != playback.frames)
		playback.mismatch = true;
	++playback.callbacks;
	return 0;
}

int main()
{
	AudioObjectPropertyAddress property{kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
	AudioDeviceID device = 0;
	UInt32 size = sizeof(device);
	if(AudioObjectGetPropertyData(kAudioObjectSystemObject, &property, 0, nullptr, &size, &device) != noErr || !device)
		return 1;
	property = {kAudioDevicePropertyBufferFrameSize, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain};
	UInt32 original = 0;
	size = sizeof(original);
	if(AudioObjectGetPropertyData(device, &property, 0, nullptr, &size, &original) != noErr)
		return 1;

	RtAudio audio(RtAudio::MACOSX_CORE);
	RtAudio::StreamParameters output;
	output.deviceId = audio.getDefaultOutputDevice();
	output.nChannels = 2;
	const auto rate = audio.getDeviceInfo(output.deviceId).currentSampleRate;
	const unsigned int requested = (rate + 100) / 200; // OpenMPT's default 5 ms update interval.
	Playback playback;
	playback.frames = requested;
	bool ok = audio.openStream(&output, nullptr, RTAUDIO_FLOAT32, rate, &playback.frames, RenderSilence, &playback) == RTAUDIO_NO_ERROR;
	UInt32 actual = 0;
	if(ok)
	{
		ok = AudioObjectGetPropertyData(device, &property, 0, nullptr, &size, &actual) == noErr && actual == playback.frames;
		if(ok && audio.startStream() == RTAUDIO_NO_ERROR)
		{
			std::this_thread::sleep_for(std::chrono::seconds(1));
			ok = audio.stopStream() == RTAUDIO_NO_ERROR;
		}
		audio.closeStream();
	}
	const OSStatus restore = AudioObjectSetPropertyData(device, &property, 0, nullptr, sizeof(original), &original);
	std::printf("Requested %u, RtAudio %u, CoreAudio %u, silent callbacks %u\n", requested, playback.frames, actual, playback.callbacks.load());
	return ok && restore == noErr && playback.callbacks > 0 && !playback.mismatch ? 0 : 1;
}
