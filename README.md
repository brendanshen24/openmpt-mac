
README
======


OpenMPT and libopenmpt
======================

This repository contains OpenMPT, a free Windows/Wine-based
[tracker](https://en.wikipedia.org/wiki/Music_tracker) (plus a native macOS
build, see [below](#openmpt-for-macos-native)) and libopenmpt,
a library to render tracker music (MOD, XM, S3M, IT MPTM and dozens of other
legacy formats) to a PCM audio stream. libopenmpt is directly based on OpenMPT,
offering the same playback quality and format support, and development of the
two happens in parallel.


License
-------

The OpenMPT/libopenmpt project is distributed under the *BSD-3-Clause* License.
See [LICENSE](LICENSE) for the full license text.

Files below the `include/` (external projects) and `contrib/` (related assets
not directly considered integral part of the project) folders may be subject to
other licenses. See the respective subfolders for license information. These
folders are not distributed in all source packages, and in particular they are
not distributed in the Autotools packages.


How to compile
--------------


### OpenMPT

 -  Supported Visual Studio versions:

     -  Visual Studio 2019, and 2022 Community/Professional/Enterprise

        To compile the project, open `build/vsVERSIONwin7/OpenMPT.sln` (VERSION
        being 2019, or 2022) and hit the compile button. Other target systems
        can be found in the `vs2019*`, and `vs2022*` sibling folders.

        Note that you have to build the `PluginBridge` and `PluginBridgeLegacy`
        projects manually for architectures other than the one you are building
        OpenMPT for, as Visual Studio only builds one architecture configuration
        at a time.

        Please note that we do not support building with a later Visual Studio
        installation with an earlier compiler version. This is because, while
        later Visual Studio versions allow installing earlier compilers to be
        available via the later version's environment, in this configuration,
        the earlier compiler will still use the later C and C++ runtime's
        headers and implementation, which significantly increases the matrix of
        possible configurations to test.

     -  Visual Studio 2017 XP targeting toolset

 -  OpenMPT requires the compile host system to be Windows 8.1 (or later) on
    amd64 for VS2019 and VS2017, Windows 10 (or later) on amd64 for VS2022, or
    Windows 11 (or later) ARM64.

 -  In order to build OpenMPT for Windows XP, the Visual Studio 2017 XP 
    targeting toolset as well as the Windows 8.1 SDK need to be installed. The
    SDK is optionally included with Visual Studio 2017.

 -  Microsoft Foundation Classes (MFC) are required to build OpenMPT.


### OpenMPT for macOS (native)

This fork builds the real OpenMPT user interface (`mptrack`) as a native macOS
app. The Win32/MFC code is unchanged in spirit; a compatibility layer in
`mptrack/mac/` implements the Win32, GDI and MFC APIs it uses on top of AppKit
and CoreGraphics, and dialogs and menus are read from `mptrack/mptrack.rc` at
run time. Audio goes through RtAudio/CoreAudio and follows the system output
device ("Default Device" in Setup > Sound Card).

 -  Requirements: macOS 13 or later, Xcode command line tools, CMake 3.20+.

 -  Development build:

        cmake -S . -B build-mac -DCMAKE_BUILD_TYPE=RelWithDebInfo
        cmake --build build-mac -j
        open build-mac/OpenMPT.app

 -  Release packages (`dist/OpenMPT-<version>-macOS-<arch>.zip` and `.dmg`):

        mptrack/mac/make-release.sh

    The app is ad-hoc signed, not notarized: on first launch, right-click it
    and choose Open (or run `xattr -dr com.apple.quarantine OpenMPT.app`).

 -  Keyboard: OpenMPT's shortcuts work with Command or Control standing in for
    Ctrl. Shortcuts that macOS reserves (e.g. Cmd+Space for Spotlight, used by
    "Enable Recording") must use the Control key instead (Control+Space).

 -  Known gaps: no drawn scroll bars (scrolling works with the
    wheel/trackpad), Tab navigation between dialog controls, and some dialogs
    may still differ from Windows. Third-party VST plugins are untested.

 -  Debug aids: `MPT_SNAPSHOT_DIR=<dir>` writes PNGs of every window and dumps
    the window tree to stderr after startup; `MPT_SNAPSHOT_COMMAND=<id>` sends
    a menu command first (e.g. 32782 = View > Patterns).


### libopenmpt and openmpt123

See [Dependencies](doc/libopenmpt/dependencies.md) and
[Getting Started](doc/libopenmpt/gettingstarted.md).


Contributing to OpenMPT/libopenmpt
----------------------------------


See [contributing](doc/contributing.md).

