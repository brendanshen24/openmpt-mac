/*
 * ExceptionHandlerMac.cpp
 * -----------------------
 * Purpose: macOS native implementation of OpenMPT ExceptionHandler.
 */

#include "stdafx.h"
#include "ExceptionHandler.h"
#include "Moddoc.h"
#include "Mptrack.h"
#include "Reporting.h"
#include "../soundlib/mod_specifications.h"

#include <atomic>
#include <csignal>
#include <ctime>
#include <exception>
#include <filesystem>

OPENMPT_NAMESPACE_BEGIN

bool ExceptionHandler::fullMemDump = false;
bool ExceptionHandler::stopSoundDeviceOnCrash = false;
bool ExceptionHandler::stopSoundDeviceBeforeDump = false;
bool ExceptionHandler::delegateToWindowsHandler = false;
bool ExceptionHandler::debugExceptionHandler = false;

bool ExceptionHandler::useAnyCrashHandler = false;
bool ExceptionHandler::useImplicitFallbackSEH = false;
bool ExceptionHandler::useExplicitSEH = false;
bool ExceptionHandler::handleStdTerminate = false;
bool ExceptionHandler::handleStdUnexpected = false;
bool ExceptionHandler::handleMfcExceptions = false;

static thread_local ExceptionHandler::Context* s_currentContext = nullptr;

static constexpr int kCrashSignals[] = {SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT};
static std::atomic<bool> s_rescueStarted{false};
static std::terminate_handler s_originalTerminate = nullptr;
static std::vector<char> s_signalStack;

// Saves every modified module to "<config folder>/Crash Files/<time>/", as the Windows crash handler does.
// Returns the folder, or an empty path when nothing needed saving.
static mpt::PathString RescueFiles(int &numFiles)
{
    numFiles = 0;
    char stamp[32] = {};
    const std::time_t now = std::time(nullptr);
    std::strftime(stamp, sizeof(stamp), "%Y-%m-%d %H.%M.%S", std::localtime(&now));
    const mpt::PathString dir = theApp.GetConfigPath() + P_("Crash Files/") + mpt::PathString::FromUnicode(mpt::ToUnicode(mpt::Charset::ASCII, stamp)) + P_("/");
    for(CModDoc *modDoc : theApp.GetOpenDocuments())
    {
        if(!modDoc->IsModified())
            continue;
        if(numFiles == 0)
        {
            std::error_code ec;
            std::filesystem::create_directories(mpt::ToCharset(mpt::Charset::UTF8, dir.ToUnicode()), ec);
        }
        const mpt::PathString filename = dir + mpt::PathString::FromUnicode(mpt::ufmt::val(++numFiles)) + P_("_")
            + mpt::PathString::FromCString(modDoc->GetTitle()).AsSanitizedComponent() + P_(".")
            + mpt::PathString::FromUnicode(modDoc->GetSoundFile().GetModSpecifications().GetFileExtension());
        try
        {
            modDoc->OnSaveDocument(filename);
        } catch(...)
        {
        }
    }
    return numFiles ? dir : mpt::PathString();
}

// Runs once per process: a second crash while rescuing goes straight to the system crash report.
static void RescueOnCrash(const char *what)
{
    if(s_rescueStarted.exchange(true))
        return;
    for(int sig : kCrashSignals)
        std::signal(sig, SIG_DFL);
    std::fprintf(stderr, "OpenMPT crashed (%s), saving modified modules...\n", what);
    int numFiles = 0;
    const mpt::PathString dir = RescueFiles(numFiles);
    if(numFiles)
        std::fprintf(stderr, "OpenMPT saved %d modified module(s) to %s\n", numFiles, mpt::ToCharset(mpt::Charset::UTF8, dir.ToUnicode()).c_str());
}

// shortcut: saving from a signal handler is not async-signal-safe; like the Windows handler it is a best effort before the process dies anyway.
static void CrashSignalHandler(int sig)
{
    RescueOnCrash(strsignal(sig));
    std::signal(sig, SIG_DFL);
    std::raise(sig);  // let macOS write its crash report
}

static void TerminateHandler()
{
    RescueOnCrash("std::terminate");
    if(s_originalTerminate)
        s_originalTerminate();
    std::abort();
}

void ExceptionHandler::Register()
{
    if(useImplicitFallbackSEH)
    {
        // An alternate stack, so a stack overflow can still run the handler.
        s_signalStack.resize(std::max<size_t>(SIGSTKSZ, 256 * 1024));
        stack_t ss{};
        ss.ss_sp = s_signalStack.data();
        ss.ss_size = s_signalStack.size();
        sigaltstack(&ss, nullptr);
        struct sigaction sa{};
        sa.sa_handler = &CrashSignalHandler;
        sa.sa_flags = SA_ONSTACK;
        sigemptyset(&sa.sa_mask);
        for(int sig : kCrashSignals)
            sigaction(sig, &sa, nullptr);
    }
    if(handleStdTerminate)
        s_originalTerminate = std::set_terminate(&TerminateHandler);
}

void ExceptionHandler::ConfigureSystemHandler() {}
void ExceptionHandler::UnconfigureSystemHandler() {}

void ExceptionHandler::Unregister()
{
    if(handleStdTerminate)
    {
        std::set_terminate(s_originalTerminate);
        s_originalTerminate = nullptr;
    }
    if(useImplicitFallbackSEH)
    {
        for(int sig : kCrashSignals)
            std::signal(sig, SIG_DFL);
    }
}

void ExceptionHandler::TaintProcess(TaintReason reason) {
    (void)reason;
}

ExceptionHandler::Context* ExceptionHandler::SetContext(Context* newContext) noexcept {
    Context* old = s_currentContext;
    s_currentContext = newContext;
    return old;
}

LONG WINAPI ExceptionHandler::UnhandledExceptionFilterContinue(_EXCEPTION_POINTERS* pExceptionInfo) {
    (void)pExceptionInfo;
    return 0; // EXCEPTION_CONTINUE_SEARCH
}

LONG WINAPI ExceptionHandler::ExceptionFilter(_EXCEPTION_POINTERS* pExceptionInfo) {
    (void)pExceptionInfo;
    return 0; // EXCEPTION_CONTINUE_SEARCH
}

// The app keeps running after an MFC exception, as on Windows, so rescue files and say where they went.
void ExceptionHandler::UnhandledMFCException(CException* e, const MSG* pMsg) {
    (void)e;
    std::fprintf(stderr, "OpenMPT: unhandled MFC exception while processing window message %u\n", pMsg ? pMsg->message : 0u);
    int numFiles = 0;
    const mpt::PathString dir = RescueFiles(numFiles);
    mpt::ustring text = MPT_UFORMAT("An unhandled exception occurred while processing window message {}.")(pMsg ? pMsg->message : 0u);
    if(numFiles)
        text += MPT_UFORMAT("\n\n{} modified module(s) were saved to:\n{}")(numFiles, dir.ToUnicode());
    Reporting::Error(text, "OpenMPT");
}

void DebugInjectCrash() {
    volatile int* p = nullptr;
    *p = 42;
}

void DebugTraceDump() {}

// No crash reporter on macOS yet: log failed assertions and keep running, like a release build.
MPT_ATTR_NOINLINE MPT_DECL_NOINLINE void AssertHandler(const mpt::source_location &loc, const char *expr, const char *msg)
{
    std::fprintf(stderr, "OpenMPT ASSERT(%s) failed at %s(%u) in [%s]%s%s\n",
        expr ? expr : "", loc.file_name() ? loc.file_name() : "", static_cast<unsigned>(loc.line()),
        loc.function_name() ? loc.function_name() : "", msg ? ": " : "", msg ? msg : "");
}

OPENMPT_NAMESPACE_END
