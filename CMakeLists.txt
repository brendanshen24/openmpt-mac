cmake_minimum_required(VERSION 3.20)
project(OpenMPT LANGUAGES C CXX OBJCXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OBJCXX_STANDARD 20)
set(CMAKE_OBJCXX_STANDARD_REQUIRED ON)

# Global Defines
add_definitions(
    -DMPT_WITH_MFC
    -DMODPLUG_TRACKER
    -DUNICODE
    -D_UNICODE
    -DMPT_WITH_RTAUDIO
    -DMPT_WITH_RTMIDI
    -DMPT_WITH_ZLIB
    -DMPT_WITH_MINIZIP
    -DMPT_WITH_OGG
    -DMPT_WITH_VORBIS
    -DMPT_WITH_VORBISENC
    -DMPT_WITH_VORBISFILE
    -DMPT_WITH_MPG123
    -DMPT_WITH_FLAC
    -DMPT_WITH_LAME
    -DMPT_WITH_LHASA
    -DMPT_WITH_ANCIENT
    -DMPT_WITH_UNRAR
    -DMPT_WITH_DMO
    -DMPT_WITH_VST
    -DMPT_USTRING_MODE_UTF8_FORCE
    -DMPT_CHECK_WINDOWS_IGNORE_WARNING_NO_UNICODE
    -D_CSTRING_DISABLE_NARROW_WIDE_CONVERSION
)

# Global Include Directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/common
    ${CMAKE_CURRENT_SOURCE_DIR}/soundlib
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/misc
    ${CMAKE_CURRENT_SOURCE_DIR}/tracklib
    ${CMAKE_CURRENT_SOURCE_DIR}/mptrack
    ${CMAKE_CURRENT_SOURCE_DIR}/mptrack/plugins
    ${CMAKE_CURRENT_SOURCE_DIR}/mptrack/mac/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ancient/api
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ancient/api/ancient
    ${CMAKE_CURRENT_SOURCE_DIR}/include/flac/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/lame/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/lhasa/lib/public
    ${CMAKE_CURRENT_SOURCE_DIR}/include/mpg123/src/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ogg/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/rtaudio
    ${CMAKE_CURRENT_SOURCE_DIR}/include/rtmidi
    ${CMAKE_CURRENT_SOURCE_DIR}/include/unrar
    ${CMAKE_CURRENT_SOURCE_DIR}/include/vorbis/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/zlib
    ${CMAKE_CURRENT_SOURCE_DIR}/include/zlib/contrib/minizip
    ${CMAKE_CURRENT_SOURCE_DIR}/include/SignalsmithStretch
    ${CMAKE_CURRENT_SOURCE_DIR}/build/svn_version
    ${CMAKE_BINARY_DIR}/gen_include
)

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/gen_include/lame)
file(CREATE_LINK ${CMAKE_CURRENT_SOURCE_DIR}/include/lame/include/lame.h ${CMAKE_BINARY_DIR}/gen_include/lame/lame.h SYMBOLIC)

# Compiler Warnings Suppressions
add_compile_options(
    -Wno-inconsistent-missing-override
    -Wno-invalid-noreturn
    -Wno-deprecated-declarations
    -Wno-unused-variable
    -Wno-unused-function
    -Wno-switch
    -Wno-parentheses
    -Wno-undefined-bool-conversion
)

# ==============================================================================
# 3rd-Party Bundled Static Libraries
# ==============================================================================

# 1. zlib
add_library(openmpt-zlib STATIC
    include/zlib/adler32.c
    include/zlib/compress.c
    include/zlib/crc32.c
    include/zlib/deflate.c
    include/zlib/gzclose.c
    include/zlib/gzlib.c
    include/zlib/gzread.c
    include/zlib/gzwrite.c
    include/zlib/infback.c
    include/zlib/inffast.c
    include/zlib/inflate.c
    include/zlib/inftrees.c
    include/zlib/trees.c
    include/zlib/uncompr.c
    include/zlib/zutil.c
)
target_compile_definitions(openmpt-zlib PUBLIC Z_HAVE_UNISTD_H)
target_include_directories(openmpt-zlib PUBLIC include/zlib)

# 2. minizip
add_library(openmpt-minizip STATIC
    include/zlib/contrib/minizip/ioapi.c
    include/zlib/contrib/minizip/mztools.c
    include/zlib/contrib/minizip/unzip.c
    include/zlib/contrib/minizip/zip.c
)
target_include_directories(openmpt-minizip PUBLIC include/zlib include/zlib/contrib/minizip)

# 3. ogg
add_library(openmpt-ogg STATIC
    include/ogg/src/bitwise.c
    include/ogg/src/framing.c
)
target_include_directories(openmpt-ogg PUBLIC include/ogg/include)

# 4. vorbis
add_library(openmpt-vorbis STATIC
    include/vorbis/lib/analysis.c
    include/vorbis/lib/bitrate.c
    include/vorbis/lib/block.c
    include/vorbis/lib/codebook.c
    include/vorbis/lib/envelope.c
    include/vorbis/lib/floor0.c
    include/vorbis/lib/floor1.c
    include/vorbis/lib/info.c
    include/vorbis/lib/lookup.c
    include/vorbis/lib/lpc.c
    include/vorbis/lib/lsp.c
    include/vorbis/lib/mapping0.c
    include/vorbis/lib/mdct.c
    include/vorbis/lib/psy.c
    include/vorbis/lib/registry.c
    include/vorbis/lib/res0.c
    include/vorbis/lib/sharedbook.c
    include/vorbis/lib/smallft.c
    include/vorbis/lib/synthesis.c
    include/vorbis/lib/vorbisenc.c
    include/vorbis/lib/vorbisfile.c
    include/vorbis/lib/window.c
)
target_include_directories(openmpt-vorbis PUBLIC include/vorbis/include include/vorbis/lib include/ogg/include)

# 5. mpg123
add_library(openmpt-mpg123 STATIC
    include/mpg123/src/compat/compat.c
    include/mpg123/src/compat/compat_str.c
    include/mpg123/src/libmpg123/dct64.c
    include/mpg123/src/libmpg123/dither.c
    include/mpg123/src/libmpg123/equalizer.c
    include/mpg123/src/libmpg123/feature.c
    include/mpg123/src/libmpg123/format.c
    include/mpg123/src/libmpg123/frame.c
    include/mpg123/src/libmpg123/icy.c
    include/mpg123/src/libmpg123/icy2utf8.c
    include/mpg123/src/libmpg123/id3.c
    include/mpg123/src/libmpg123/index.c
    include/mpg123/src/libmpg123/layer1.c
    include/mpg123/src/libmpg123/layer2.c
    include/mpg123/src/libmpg123/layer3.c
    include/mpg123/src/libmpg123/lfs_wrap.c
    include/mpg123/src/libmpg123/libmpg123.c
    include/mpg123/src/libmpg123/ntom.c
    include/mpg123/src/libmpg123/optimize.c
    include/mpg123/src/libmpg123/parse.c
    include/mpg123/src/libmpg123/readers.c
    include/mpg123/src/libmpg123/stringbuf.c
    include/mpg123/src/libmpg123/synth.c
    include/mpg123/src/libmpg123/synth_8bit.c
    include/mpg123/src/libmpg123/synth_real.c
    include/mpg123/src/libmpg123/synth_s32.c
    include/mpg123/src/libmpg123/tabinit.c
)
target_compile_definitions(openmpt-mpg123 PRIVATE MPG123_NO_LARGENAME OPT_GENERIC)
target_include_directories(openmpt-mpg123 PUBLIC include/mpg123/ports/generic include/mpg123/src/include include/mpg123/src/libmpg123)

# 6. flac
add_library(openmpt-flac STATIC
    include/flac/src/libFLAC/bitmath.c
    include/flac/src/libFLAC/bitreader.c
    include/flac/src/libFLAC/bitwriter.c
    include/flac/src/libFLAC/cpu.c
    include/flac/src/libFLAC/crc.c
    include/flac/src/libFLAC/fixed.c
    include/flac/src/libFLAC/float.c
    include/flac/src/libFLAC/format.c
    include/flac/src/libFLAC/lpc.c
    include/flac/src/libFLAC/md5.c
    include/flac/src/libFLAC/memory.c
    include/flac/src/libFLAC/metadata_iterators.c
    include/flac/src/libFLAC/metadata_object.c
    include/flac/src/libFLAC/ogg_decoder_aspect.c
    include/flac/src/libFLAC/ogg_encoder_aspect.c
    include/flac/src/libFLAC/ogg_helper.c
    include/flac/src/libFLAC/ogg_mapping.c
    include/flac/src/libFLAC/stream_decoder.c
    include/flac/src/libFLAC/stream_encoder.c
    include/flac/src/libFLAC/stream_encoder_framing.c
    include/flac/src/libFLAC/window.c
)
target_compile_definitions(openmpt-flac PRIVATE PACKAGE_VERSION="1.5.0" FLAC__NO_DLL FLAC__HAS_OGG=1 HAVE_PTHREAD HAVE_FSEEKO=1 HAVE_LROUND=1)
target_include_directories(openmpt-flac PUBLIC include/flac/include include/flac/src/libFLAC/include include/ogg/include)

# 7. lame
add_library(openmpt-lame STATIC
    include/lame/mpglib/common.c
    include/lame/mpglib/dct64_i386.c
    include/lame/mpglib/decode_i386.c
    include/lame/mpglib/interface.c
    include/lame/mpglib/layer1.c
    include/lame/mpglib/layer2.c
    include/lame/mpglib/layer3.c
    include/lame/mpglib/tabinit.c
    include/lame/libmp3lame/bitstream.c
    include/lame/libmp3lame/encoder.c
    include/lame/libmp3lame/fft.c
    include/lame/libmp3lame/gain_analysis.c
    include/lame/libmp3lame/id3tag.c
    include/lame/libmp3lame/lame.c
    include/lame/libmp3lame/mpglib_interface.c
    include/lame/libmp3lame/newmdct.c
    include/lame/libmp3lame/presets.c
    include/lame/libmp3lame/psymodel.c
    include/lame/libmp3lame/quantize.c
    include/lame/libmp3lame/quantize_pvt.c
    include/lame/libmp3lame/reservoir.c
    include/lame/libmp3lame/set_get.c
    include/lame/libmp3lame/tables.c
    include/lame/libmp3lame/takehiro.c
    include/lame/libmp3lame/util.c
    include/lame/libmp3lame/vbrquantize.c
    include/lame/libmp3lame/VbrTag.c
    include/lame/libmp3lame/version.c
)
target_compile_definitions(openmpt-lame PRIVATE HAVE_CONFIG_H HAVE_MPGLIB USE_LAYER_2 STDC_HEADERS HAVE_STRING_H HAVE_MEMCPY HAVE_STRCHR)
target_include_directories(openmpt-lame BEFORE PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/build/premake/inc/lame ${CMAKE_CURRENT_SOURCE_DIR}/include/lame/include ${CMAKE_CURRENT_SOURCE_DIR}/include/lame/mpglib ${CMAKE_CURRENT_SOURCE_DIR}/include/lame/libmp3lame)

# 8. lhasa
add_library(openmpt-lhasa STATIC
    include/lhasa/lib/crc16.c
    include/lhasa/lib/ext_header.c
    include/lhasa/lib/lh1_decoder.c
    include/lhasa/lib/lh5_decoder.c
    include/lhasa/lib/lh6_decoder.c
    include/lhasa/lib/lh7_decoder.c
    include/lhasa/lib/lha_arch_unix.c
    include/lhasa/lib/lha_basic_reader.c
    include/lhasa/lib/lha_decoder.c
    include/lhasa/lib/lha_endian.c
    include/lhasa/lib/lha_file_header.c
    include/lhasa/lib/lha_input_stream.c
    include/lhasa/lib/lha_reader.c
    include/lhasa/lib/lhx_decoder.c
    include/lhasa/lib/lk7_decoder.c
    include/lhasa/lib/lz5_decoder.c
    include/lhasa/lib/lzs_decoder.c
    include/lhasa/lib/macbinary.c
    include/lhasa/lib/null_decoder.c
    include/lhasa/lib/pm1_decoder.c
    include/lhasa/lib/pm2_decoder.c
)
target_include_directories(openmpt-lhasa PUBLIC include/lhasa/lib include/lhasa/lib/public)

# 9. ancient
file(GLOB ANCIENT_SOURCES include/ancient/src/*.cpp include/ancient/src/common/*.cpp)
add_library(openmpt-ancient STATIC ${ANCIENT_SOURCES})
target_include_directories(openmpt-ancient PUBLIC include/ancient/api include/ancient/api/ancient include/ancient/src)

# 10. unrar
add_library(openmpt-unrar STATIC
    include/unrar/archive.cpp
    include/unrar/arcread.cpp
    include/unrar/blake2s.cpp
    include/unrar/cmddata.cpp
    include/unrar/consio.cpp
    include/unrar/crc.cpp
    include/unrar/crypt.cpp
    include/unrar/dll.cpp
    include/unrar/encname.cpp
    include/unrar/errhnd.cpp
    include/unrar/extinfo.cpp
    include/unrar/extract.cpp
    include/unrar/filcreat.cpp
    include/unrar/file.cpp
    include/unrar/filefn.cpp
    include/unrar/filestr.cpp
    include/unrar/find.cpp
    include/unrar/getbits.cpp
    include/unrar/global.cpp
    include/unrar/hash.cpp
    include/unrar/headers.cpp
    include/unrar/isnt.cpp
    include/unrar/largepage.cpp
    include/unrar/list.cpp
    include/unrar/match.cpp
    include/unrar/options.cpp
    include/unrar/pathfn.cpp
    include/unrar/qopen.cpp
    include/unrar/rarvm.cpp
    include/unrar/rawread.cpp
    include/unrar/rdwrfn.cpp
    include/unrar/recvol.cpp
    include/unrar/rijndael.cpp
    include/unrar/rs.cpp
    include/unrar/rs16.cpp
    include/unrar/scantree.cpp
    include/unrar/secpassword.cpp
    include/unrar/sha1.cpp
    include/unrar/sha256.cpp
    include/unrar/smallfn.cpp
    include/unrar/strfn.cpp
    include/unrar/strlist.cpp
    include/unrar/system.cpp
    include/unrar/threadpool.cpp
    include/unrar/timefn.cpp
    include/unrar/ui.cpp
    include/unrar/unicode.cpp
    include/unrar/unpack.cpp
    include/unrar/volume.cpp
)
target_compile_definitions(openmpt-unrar PRIVATE _UNIX _APPLE SILENT RARDLL UNRAR RAR_NOCRYPT NOVOLUME)
target_include_directories(openmpt-unrar PUBLIC include/unrar)

# 11. rtaudio
add_library(openmpt-rtaudio STATIC include/rtaudio/RtAudio.cpp)
target_compile_definitions(openmpt-rtaudio PUBLIC __MACOSX_CORE__)
target_include_directories(openmpt-rtaudio PUBLIC include/rtaudio)

# 12. rtmidi
add_library(openmpt-rtmidi STATIC include/rtmidi/RtMidi.cpp)
target_compile_definitions(openmpt-rtmidi PUBLIC __MACOSX_CORE__ RTMIDI_DO_NOT_ENSURE_UNIQUE_PORTNAMES)
target_include_directories(openmpt-rtmidi PUBLIC include/rtmidi)

# ==============================================================================
# Executable Target: OpenMPT (macOS Native App Bundle)
# ==============================================================================

# Common Sources
file(GLOB COMMON_SOURCES common/*.cpp)

# Misc Sources
file(GLOB MISC_SOURCES misc/*.cpp)

# SoundDSP Sources
file(GLOB SOUNDDSP_SOURCES sounddsp/*.cpp)

# Tracklib Sources
file(GLOB TRACKLIB_SOURCES tracklib/*.cpp)

# Unarchiver Sources
file(GLOB UNARCHIVER_SOURCES unarchiver/*.cpp)

# Soundlib Sources
file(GLOB SOUNDLIB_SOURCES soundlib/*.cpp)
file(GLOB SOUNDLIB_PLUGINS_SOURCES soundlib/plugins/*.cpp)
file(GLOB SOUNDLIB_DMO_SOURCES soundlib/plugins/dmo/*.cpp)

# Src / SoundDevice / StreamEncoder Sources
set(SRCOPENMPT_SOURCES
    src/openmpt/soundfile_write/wav_write.cpp
    src/openmpt/streamencoder/StreamEncoder.cpp
    src/openmpt/streamencoder/StreamEncoderAU.cpp
    src/openmpt/streamencoder/StreamEncoderFLAC.cpp
    src/openmpt/streamencoder/StreamEncoderMP3.cpp
    src/openmpt/streamencoder/StreamEncoderOpus.cpp
    src/openmpt/streamencoder/StreamEncoderRAW.cpp
    src/openmpt/streamencoder/StreamEncoderVorbis.cpp
    src/openmpt/streamencoder/StreamEncoderWAV.cpp
    src/openmpt/sounddevice/SoundDevice.cpp
    src/openmpt/sounddevice/SoundDeviceBase.cpp
    src/openmpt/sounddevice/SoundDeviceManager.cpp
    src/openmpt/sounddevice/SoundDeviceRtAudio.cpp
    src/openmpt/sounddevice/SoundDeviceUtilities.cpp
)

# MPTrack Sources (excluding Windows/Wine-specific files)
file(GLOB MPTRACK_SOURCES mptrack/*.cpp)
list(FILTER MPTRACK_SOURCES EXCLUDE REGEX ".*MPTrackWine\\.cpp$")
list(FILTER MPTRACK_SOURCES EXCLUDE REGEX ".*MPTrackUtilWine\\.cpp$")
list(FILTER MPTRACK_SOURCES EXCLUDE REGEX ".*WineSoundDeviceStub\\.cpp$")
list(FILTER MPTRACK_SOURCES EXCLUDE REGEX ".*ExceptionHandler\\.cpp$")

# MPTrack Plugins
file(GLOB MPTRACK_PLUGINS_SOURCES mptrack/plugins/*.cpp)

# Native macOS Win32/MFC Shims
set(MAC_SHIMS_SOURCES
    mptrack/mac/MacWin32Afx.mm
    mptrack/mac/MacGDI.mm
    mptrack/mac/MacResources.mm
    mptrack/mac/MacWin32Api.mm
    mptrack/mac/MacControls.mm
    mptrack/mac/MacListTree.mm
    mptrack/mac/WineStub.cpp
    mptrack/mac/ExceptionHandlerMac.cpp
    mptrack/mac/BridgeWrapperMac.cpp
)

# Bundle Resources
file(GLOB_RECURSE RES_FILES "mptrack/res/*")
set(APP_RESOURCE_FILES
    mptrack/mptrack.rc
    mptrack/resource.h
    mptrack/mac/include/afxres.h
    mptrack/mac/AppIcon.icns
    ${RES_FILES}
)
set_source_files_properties(${APP_RESOURCE_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

# Target
add_executable(OpenMPT MACOSX_BUNDLE
    ${COMMON_SOURCES}
    ${MISC_SOURCES}
    ${SOUNDDSP_SOURCES}
    ${TRACKLIB_SOURCES}
    ${UNARCHIVER_SOURCES}
    ${SOUNDLIB_SOURCES}
    ${SOUNDLIB_PLUGINS_SOURCES}
    ${SOUNDLIB_DMO_SOURCES}
    ${SRCOPENMPT_SOURCES}
    ${MPTRACK_SOURCES}
    ${MPTRACK_PLUGINS_SOURCES}
    ${MAC_SHIMS_SOURCES}
    ${APP_RESOURCE_FILES}
)

set_target_properties(OpenMPT PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME "OpenMPT"
    MACOSX_BUNDLE_GUI_IDENTIFIER "org.openmpt.OpenMPT"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.33.00.25"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.33"
    MACOSX_BUNDLE_ICON_FILE "AppIcon"
)

target_link_libraries(OpenMPT PRIVATE
    openmpt-zlib
    openmpt-minizip
    openmpt-ogg
    openmpt-vorbis
    openmpt-mpg123
    openmpt-flac
    openmpt-lame
    openmpt-lhasa
    openmpt-ancient
    openmpt-unrar
    openmpt-rtaudio
    openmpt-rtmidi
    "-framework Cocoa"
    "-framework CoreGraphics"
    "-framework CoreText"
    "-framework CoreAudio"
    "-framework AudioToolbox"
    "-framework AudioUnit"
    "-framework CoreMIDI"
    "-framework ImageIO"
    "-framework UniformTypeIdentifiers"
)
