module betterc.async;

version(D_BetterC)          {} else static assert(false, "enable -betterC");
version(D_InlineAsm_X86_64) {} else static assert(false, "Supports x86_64 only");

public:
extern(C):
@nogc:
nothrow:

import betterc;

import betterc.async.mutex;
import betterc.async.semaphore;
import betterc.async.thread;

/**
 * Win64 calling convention:
 * https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention?view=vs-2019
 *
 * [1 param]  RCX                     | XMM0
 * [2 params] RCX, RDX                | XMM0, XMM1
 * [3 params] RCX, RDX, R8            | XMM0, XMM1, XMM2
 * [4 params] RCX, RDX, R8, R9        | XMM0, XMM1, XMM2, XMM3
 * [5 params] RCX, RDX, R8, R9, stack | XMM0, XMM1, XMM2, XMM3, stack
 *
 * Clobbered:
 * RAX, RCX, RDX, R8, R9, R10, R11
 * XMM0-XMM5, upper YMM0-YMM15, upper ZMM0-ZMM15
 * AVX512: ZMM16-ZMM31, YMM16-YMM31, XMM16-XMM31
 */

/**
 * If [ptr] == expected then [ptr] = value else don't update.
 * Returns the old value.
 */
uint cas32(void* ptr, uint expected, uint newValue) {
	asm pure nothrow @nogc {
        // RCX = ptr
        // EDX = expected
        // R8D = newValue
		naked;
		mov EAX, EDX;
		lock; cmpxchg [RCX], R8D;
        // return original value in EAX
		ret;
	}
}
/**
 * Set newValue at [ptr].
 * Returns the old value.
 */
bool atomicSetBool(void* ptr, bool newValue) {
    asm pure nothrow @nogc {
        // RCX = ptr
        // DL = newValue
        naked;
        xchg [RCX], DL;    // implicit lock
        movzx EAX, DL;
        ret;
    }
}
bool atomicGetBool(void* ptr) {
    asm pure nothrow @nogc {
        // RCX = ptr
        naked;
        movzx EAX, byte ptr [RCX];
        ret;
    }
}
/**
 * Set newValue at [ptr].
 * Returns the old value.
 */
uint atomicSet32(void* ptr, uint newValue) {
    asm pure nothrow @nogc {
        // RCX = ptr
        // EDX = newValue
        naked;

        //mov [RCX], EDX;
        //mfence;

        xchg [RCX], EDX;    // implicit lock
        mov EAX, EDX;
        ret;
    }
}
void atomicAdd32(void* ptr, uint add) {
    asm pure nothrow @nogc {
        // RCX = ptr
        // EDX = add
        naked;
        lock; xadd [RCX], EDX;
        ret;
    }
}
/**
 * Assumes atomicSet32 was used to set the value.
 * Does not use a fence as it assumes the sfence used when setting is enough to make
 * the current value visible to reads. Thus the fence cost is spent on the write,
 * speculating that there are more reads than writes.
 * This may not be correct - check.
 */
uint atomicGet32(void* ptr) {
    asm pure nothrow @nogc {
        // RCX = ptr
        naked;
        mov EAX, [RCX];
        ret;
    }
}

void mfence() {
    asm pure nothrow @nogc { naked; mfence; ret; }
}
void lfence() {
    asm pure nothrow @nogc { naked; lfence; ret; }
}
void sfence() {
    asm pure nothrow @nogc { naked; sfence; ret; }
}

interface Async {

}

extern(Windows) {
    private import core.sys.windows.windows : LONG, LPLONG, BOOL, HANDLE, PULONG64;
    @nogc:
    nothrow:

    BOOL QueryThreadCycleTime(
        HANDLE   ThreadHandle,
        PULONG64 CycleTime
    );
}