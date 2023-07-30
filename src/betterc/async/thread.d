module betterc.async.thread;

@nogc:
nothrow:

private import betterc.all;
private import betterc.async.all;
private import core.sys.windows.windows;

alias ThreadFunc = uint function(void*) @nogc nothrow;

struct Thread {
@nogc:
nothrow:
public:
	enum Status : uint { NOT_STARTED, RUNNING, FINISHED }
	struct WrapperArgs {
		Thread* t;
		ThreadFunc func;
		void* args;
	};
private:
	HANDLE handle = null;
	int status = Status.NOT_STARTED;
	WrapperArgs wrapperArgs;
public:
	uint  id = 0;
	string name;

	void* getArgs() { return wrapperArgs.args; }

	//=====================================================================================
	// Disable constructors
	this() @disable;
	this(ref return scope Thread other) @disable;

	static Thread* make(string name, ThreadFunc func, void* functionArgs) {
		auto t 		  = heapAlloc!Thread;
		t.name        = name;
        t.wrapperArgs = WrapperArgs(t, func, functionArgs);
		return t;
	}
	static void destroy(Thread* t) {
		if(t) {
			if(t.handle) {
				// this might throw an exception if _endthread has been called
				CloseHandle(t.handle);
				t.handle = null;
			}
			t.setStatus(Status.FINISHED);

			free(t);
		}
	}
	void destroy() {
		if(handle) {
			// this might throw an exception if _endthread has been called
			CloseHandle(handle);
			handle = null;
		}
		setStatus(Status.FINISHED);
		Thread.destroy(&this);
	}
	//=====================================================================================

	Status getStatus() {
		return cast(Status)atomicGet32(&status);
    }
	void setStatus(Status s) {
		atomicSet32(&status, s);
    }
	string getStatusString() {
		final switch(getStatus()) with(Status) {
			case NOT_STARTED: return "NOT_STARTED";
			case RUNNING: return "RUNNING";
			case FINISHED: return "FINISHED";
		}
		assert(false);
	}

	uint start() {
		if(getStatus() == Status.NOT_STARTED) {
			handle = CreateThread(null, 0, &wrapperFunction, &wrapperArgs, 0, &id);
			setStatus(Status.RUNNING);
		}
		return id;
	}
	/*
	 * THREAD_PRIORITY_HIGHEST		= 2
	 * THREAD_PRIORITY_ABOVE_NORMAL = 1
	 * THREAD_PRIORITY_NORMAL		= 0
	 * THREAD_PRIORITY_BELOW_NORMAL = -1
	 * THREAD_PRIORITY_LOWEST		= -2
	 */
	int getPriority() {
		return GetThreadPriority(handle);
	}
	void setPriority(int p) {
		BOOL result = SetThreadPriority(handle, p);
	}
	bool isFinished() {
		return getStatus() == Status.FINISHED;
	}
	DWORD getExitCode() {
		if(getStatus() != Status.FINISHED) return STILL_ACTIVE;

		DWORD exitCode;
		GetExitCodeThread(handle, &exitCode);
		return exitCode;
	}
	void join(DWORD millis=INFINITE) {
		if(getStatus() == Status.RUNNING) {
			auto result = WaitForSingleObject(handle, millis);
		}
	}
	/// Suspends the thread
	// void suspend() {
	// 	auto result = SuspendThread(handle);
	// }
	// /// Resumes from suspension
	// void resume() {
	// 	auto result = ResumeThread(handle);
	// }
	ulong getCyclesUsed() {
		ulong ticks;
		QueryThreadCycleTime(handle, &ticks);
		return ticks;
	}

	//================================================  statics

	/// Park current thread for millis ms. Switches to another thread
	static void sleep(uint millis) {
		Sleep(millis);
	}
	/// Allow another thread on the same processor to run
	/// if available, otherwise return immediately.
	static void yield() {
		SwitchToThread();
	}
	static uint currentThreadId() {
		return GetCurrentThreadId();
	}
}

private:

extern(Windows) uint wrapperFunction(void* argsPtr) {
	auto args = *cast(Thread.WrapperArgs*)argsPtr;

	// call the user function
	uint exitCode = args.func(args.args);

	// this thread is now exiting
	args.t.setStatus(Thread.Status.FINISHED);

	return exitCode;
}
