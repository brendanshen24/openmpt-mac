/*
 * ExceptionHandlerMac.cpp
 * -----------------------
 * Purpose: macOS native implementation of OpenMPT ExceptionHandler.
 */

#include "stdafx.h"
#include "ExceptionHandler.h"

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

void ExceptionHandler::Register() {}
void ExceptionHandler::ConfigureSystemHandler() {}
void ExceptionHandler::UnconfigureSystemHandler() {}
void ExceptionHandler::Unregister() {}

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

void ExceptionHandler::UnhandledMFCException(CException* e, const MSG* pMsg) {
    (void)e;
    (void)pMsg;
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
