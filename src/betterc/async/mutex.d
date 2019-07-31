module betterc.async.mutex;

@nogc:
nothrow:

private import betterc.all;
private import core.sys.windows.windows;

struct Mutex {
@nogc:
nothrow:
private:
	HANDLE handle;
public:
	this() @disable;
    static Mutex* make() {
		auto m = heapAlloc!Mutex;
        m.handle = CreateMutex(null, false, null);
		return m;
    }
	void destroy() {
		if(handle) {
			CloseHandle(handle);
			handle = null;
		}
		free(&this);
	}
    /**
     * Lock the mutex. Returns true if the mutex was successfully locked.
     */
	bool lock(uint millis=INFINITE) {
		assert(handle);
		uint r = WaitForSingleObject(handle, millis);
		return r == WAIT_OBJECT_0;
	}
	void unlock() {
		assert(handle);
		assert(ReleaseMutex(handle));
	}
}