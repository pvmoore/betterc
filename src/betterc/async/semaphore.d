module betterc.async.semaphore;

@nogc:
nothrow:
extern(C):

private import betterc.all;
private import betterc.async.all;
private import core.sys.windows.windows;

struct Semaphore {
@nogc:
nothrow:

private:
	HANDLE handle;
	int maxCount;
	int currentCount;
	int numWaiting;
public:
	int getCurrentCount() { return atomicGet32(&currentCount); }
	int getNumWaiting()   { return atomicGet32(&numWaiting);}

	this() @disable;
	static Semaphore* make(int initialCount, int maxCount = int.max) {
		auto s 		   = heapAlloc!Semaphore;
		s.handle 	   = CreateSemaphoreW(null, initialCount, maxCount, null);
		s.maxCount 	   = maxCount;
		s.currentCount = 0;
		s.numWaiting   = 0;
		if(!s.handle) {
			uint err = GetLastError();
			printf("err = %u\n", err);
			assert(false);
		}
		return s;
	}
    void destroy() {
        if(handle) {
			CloseHandle(handle);
			handle = null;
		}
		free(&this);
    }
	/**
	 * Reduce the semaphore count by 1 and return. If the count
	 * is 0 then wait for it to be notified or timeout.
	 * @return true if we have been signalled.
	 */
	bool wait(uint millis = INFINITE) {
		atomicAdd32(&numWaiting, 1);
		auto r = WaitForSingleObject(handle, millis);
		atomicAdd32(&numWaiting, -1);

		if(r == WAIT_OBJECT_0) {
			/* We took a slot */
			atomicAdd32(&currentCount, -1);
			return true;
		}
		return false;
	}
	/**
     * Increase the semaphore count by 1, signalling any waiting threads.
	 * @return true on success.
	 */
	bool notify() {
		if(ReleaseSemaphore(handle, 1, null) !=0) {
			atomicAdd32(&currentCount, 1);
		}
		return false;
	}
	/**
	 *	Set semaphore count to max value to release all threads.
	 */
	void notifyAll() {
		int count = maxCount-getCurrentCount();
		ReleaseSemaphore(handle, count, null);
	}
}
