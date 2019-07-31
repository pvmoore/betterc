module betterc.async.fibres.fibres;

@nogc:
nothrow:

private import betterc.async.fibres.all;
private import core.sys.windows.windows : GetCurrentThreadId;

enum MAX_THREADS = 4;
enum MAX_FIBRES  = 5;

alias UserFibreFunc(R) = R function() @nogc nothrow;
alias WinFibreHandle   = void*;

struct Fibres {
@nogc:
nothrow:
private:
    enum Status : uint { NOT_STARTED, ACCEPTING_WORK, SHUTTING_DOWN }
    __gshared Status status = Status.NOT_STARTED;
    __gshared Mutex* mutex;
    __gshared List!(FibreThread*) fibreThreads;
    __gshared uint mainThreadId;

    static Status getStatus()       { return cast(Status)atomicGet32(&status); }
	static void setStatus(Status s) { atomicSet32(&status, s); }
public:
    this() @disable;

    static void start() {
        assert(getStatus() == Status.NOT_STARTED);

        mutex        = Mutex.make();
        mainThreadId = GetCurrentThreadId();

        /* Create a ThreadFibres for the main thread */
        createMainFibreThread(mainThreadId);

        /* Create a ThreadFibres for async tasks */
        createPoolFibreThread();

        setStatus(Status.ACCEPTING_WORK);
    }
    @Async
    static void shutDown() {
        if(getStatus() != Status.SHUTTING_DOWN) {
            printf("[pool] shutting down\n");
            setStatus(Status.SHUTTING_DOWN);

            foreach(ft; fibreThreads) {
                ft.destroy();
            }

            mutex.destroy();
        }
    }
    /**
     * Return the currently running fibre on the current thread.
     */
    @Async
    static Fibre* getCurrentFibre() {
        auto threadId  = GetCurrentThreadId();
        auto threadMgr = getFibreThread(threadId);
        return threadMgr.getCurrentFibre();
    }
    // @Async
    // static ThreadFibres* getThreadFibres() {
    //     return getThreadManager(GetCurrentThreadId());
    // }
    @Async
    static void yield(R)(R value) {
        auto threadMgr = getFibreThread(GetCurrentThreadId());
        Fibre* f = threadMgr.getCurrentFibre();

        R* addr  = cast(R*)f.getResultPtr();
        assert(addr);

        *addr = value;

        threadMgr.pause(f);
    }
    @Async
    static void pause() {
        auto threadMgr = getFibreThread(GetCurrentThreadId());
        Fibre* f = threadMgr.getCurrentFibre();
        threadMgr.pause(f);
    }
    @Async
    static Generator!R makeGenerator(R)(UserFibreFunc!R userFunc) {
       assert(getStatus() == Status.ACCEPTING_WORK);

        auto threadId  = GetCurrentThreadId();
        auto threadMgr = getFibreThread(threadId);

        auto fibre = threadMgr.createFibre!R(userFunc);
        assert(fibre.getStatus() == FibreStatus.RUNNABLE);

        return Generator!R(fibre, threadMgr);
    }
    @Async
    static PendingResult* async(R)(UserFibreFunc!R userFunc, uint delayMillis = 0) {
        assert(getStatus() == Status.ACCEPTING_WORK);

        /* Select a different thread */
        auto threadId  = selectAsyncThread();

        // Create a fibre on the other thread
        auto threadMgr = getFibreThread(threadId);

         printf("async() %s, selected thread %s to run job\n\n", getCurrentFibre().getName(), threadMgr.getName());


        // Create the fibre but don't make it runnable yet
        auto pending = PendingResult.make!R();

        auto fibre = threadMgr.createFibre!R(userFunc, pending);

        return pending;
    }
    @Async
    static void dumpStats() {
        printf("Fibre Pool Stats:\n");
        foreach(tf; fibreThreads) {
            printf("     %s %u runnable fibres\n", tf.getName(), tf.getNumQueuedFibres());
        }
    }
private:
    static FibreThread* getFibreThread(uint threadId) {
        foreach(td; fibreThreads) {
            if(td.getThreadId() == threadId) return td;
        }
        assert(false);
    }
    static FibreThread* createMainFibreThread(uint threadId) {
        if(mutex.lock()) {
            scope(exit) mutex.unlock();

            auto threadMgr = FibreThread.makeMainThread(threadId);
            fibreThreads.add(threadMgr);

            return threadMgr;
        }
        assert(false);
    }
    @Async
    static FibreThread* createPoolFibreThread() {
        if(mutex.lock()) {
            scope(exit) mutex.unlock();

            auto threadMgr = FibreThread.makePoolThread();
            fibreThreads.add(threadMgr);

            return threadMgr;
        }
        assert(false);
    }
    static uint selectAsyncThread() {
        auto threadId  = GetCurrentThreadId();

        int minQueued      = int.max;
        FibreThread* minTm = null;

        foreach(tm; fibreThreads) {
            if(tm.getThreadId() == mainThreadId) continue;

            if(tm.getThreadId() != threadId) {

                int n = tm.getNumQueuedFibres();
                if(n<minQueued) {
                    minQueued = n;
                    minTm     = tm;
                }
            }
        }

        return minTm.getThreadId;
    }
}
