module betterc.async.fibres.fibre_thread;

@nogc:
nothrow:
private import betterc.async.fibres.all;
private import core.sys.windows.windows : GetCurrentThreadId, SwitchToFiber;

struct FibreThread {
private:
    __gshared uint threadsCreated = 0;
    __gshared uint fibresCreated  = 1;

    Fibre* mainFibre;
    Fibre* currentlyRunning;
    Mutex* mutex;
    char[128] name;
    char[8] logPrefix;

    /* Thread props */
    uint threadId;
    uint threadIndex;
    bool _isMainThread;
    Thread* thread;         /* null if this is the main thread */
    ThreadArgs threadArgs;
    Semaphore* semaphore;   /* The thread wait semaphore */
    bool isShuttingDown;
    bool threadIsOnSemaphore;

    /* Queues */
    LinkedList!(Fibre*)* runnableFibres;
    LinkedList!(Fibre*)* waitingFibres;   /* fibres waiting for an async result */
@nogc:
nothrow:
public:
    uint getThreadId()        { return threadId; }
    uint getThreadIndex()     { return threadIndex; }
    Fibre* getCurrentFibre()  { return currentlyRunning; }
    bool isMainThread()       { return _isMainThread; }
    bool isPoolThread()       { return !_isMainThread; }
    char* getName()           { return name.ptr; }
    int getNumQueuedFibres()  { return runnableFibres.length; }
    Semaphore* getSemaphore() { return semaphore; }

    static FibreThread* makeMainThread(uint threadId) {
        auto tf           = heapAlloc!FibreThread;
        tf.runnableFibres = LinkedList!(Fibre*).make();
        tf.waitingFibres  = LinkedList!(Fibre*).make();
        tf.threadId       = threadId;
        tf.threadIndex    = threadsCreated++;
        tf._isMainThread  = true;
        tf.semaphore      = Semaphore.make(0);
        tf.mutex          = Mutex.make();
        tf.thread         = null;
        tf.logPrefix[0]   = '\t';
        tf.logPrefix[1]   = 'M';
        tf.logPrefix[2]   = '|';

        printf("%s Initialising ...\n", tf.logPrefix.ptr);

        tf.setName();

        /* Create a Fibre to represent the main Fibre on this thread.
           This is the currently executing one */
        tf.mainFibre        = Fibre.makeMainFibre(tf, threadId);
        tf.currentlyRunning = tf.mainFibre;

        /* The main fibre is not added to the runnable queue */
        printf("%s Ready\n", tf.logPrefix.ptr);

        return tf;
    }
    static FibreThread* makePoolThread() {
        auto tf           = heapAlloc!FibreThread;
        tf.runnableFibres = LinkedList!(Fibre*).make();
        tf.waitingFibres  = LinkedList!(Fibre*).make();
        tf.threadIndex    = threadsCreated++;
        tf._isMainThread  = false;
        tf.semaphore      = Semaphore.make(0);
        tf.mutex          = Mutex.make();
        tf.logPrefix[0]   = '\t';
        tf.logPrefix[1]   = '\t';
        tf.logPrefix[2]   = 'P';
        tf.logPrefix[3]   = cast(char)('0'+tf.threadIndex-1);
        tf.logPrefix[4]   = '|';

        printf("%s Initialising ...\n", tf.logPrefix.ptr);

        tf.setName();

        tf.threadArgs.shouldExit  = false;
        tf.threadArgs.fibreThread = tf;
        tf.threadArgs.startupSemaphore = Semaphore.make(0, 1);
        mfence();

        tf.thread   = Thread.make("Pool-Thread", &threadFunc, &tf.threadArgs);
        tf.threadId = tf.thread.start();

        /* Wait for the thread to start up and convert itself into a fibre */
        tf.threadArgs.startupSemaphore.wait();

        //tf.threadArgs.startupSemaphore.destroy();
        //tf.threadArgs.startupSemaphore = null;

        /* Create a Fibre to represent the main Fibre on this thread.
           This is the currently executing one */
        tf.mainFibre        = tf.threadArgs.mainFibre;
        tf.currentlyRunning = tf.mainFibre;

        /* The main fibre is not added to the runnable queue */
        printf("%s Ready\n", tf.logPrefix.ptr);

        /* Tell the thread we are initialised */
        tf.threadArgs.startupSemaphore.notify();

        return tf;
    }
    void destroy() {
        /* todo - free all fibres */
        printf("%s Destroy\n", logPrefix.ptr);

        // foreach(f; waitingForAsyncResult) {
        //     if(isMainThread() && f.isMainFibre()) continue;
        //     f.destroy();
        // }
        // foreach(f; executableFibres) {
        //     if(isMainThread() && f.isMainFibre()) continue;
        //     f.destroy();
        // }
        isShuttingDown = true;

        atomicSetBool(&threadArgs.shouldExit, true);
        mfence();

        semaphore.notify();
        if(semaphore.getNumWaiting()>0) {

        }
        if(thread) {
            thread.join();
            thread.destroy();
        }
        semaphore.destroy();
        mutex.destroy();

        //threadArgs.startupSemaphore.destroy();

        runnableFibres.destroy();
        waitingFibres.destroy();

        free(&this);
    }
    Fibre* createFibre(R)(UserFibreFunc!R userFunc, PendingResult* pending = null) {

        auto fibre = Fibre.makeSubFibre!R(&this, userFunc, pending, fibresCreated++);

        printf("%s Created new fibre %s\n", logPrefix.ptr, fibre.getName());

        /* Add to the queue */
        setAsRunnable(fibre);

        return fibre;
    }

    void resumed(Fibre* fibre) {
        /* Just return if the fibre is finished */
        if(fibre.getStatus()==FibreStatus.FINISHED) return;

        //printf("\t| fibre [%s] started or resumed\n", fibre.getName());
        //printf("\t| currentlyRunning = [%s]\n", currentlyRunning.getName());

        if(fibre != mainFibre && !runnableFibres.contains(fibre)) {
            setAsRunnable(fibre);
        }

        switchToNext();
    }
    void pause(Fibre* fibre) {
        printf("%s Pausing %s\n", logPrefix.ptr, currentlyRunning.getName());
        switchToNext();
    }
    /* A new fibre has been created or a pending result has become ready */
    @Async
    void setAsRunnable(Fibre* fibre) {
        assert(fibre.getStatus() != FibreStatus.FINISHED);

        printf("%s Setting %s to runnable\n", logPrefix.ptr, Fibres.getCurrentFibre().getName());

        if(isPoolThread()) assert(fibre != mainFibre);

        if(mutex.lock()) {
            scope(exit) mutex.unlock();

            if(fibre!=mainFibre) {
                assert(!runnableFibres.contains(fibre));
                runnableFibres.add(fibre);
            }
            waitingFibres.remove(fibre);

             /* Notify the thread if it is waiting on the semaphore */
            if(threadIsOnSemaphore) {
                 printf("%s Notifying thread on semaphore ... \n", Fibres.getCurrentFibre().getName());
                 semaphore.notify();
            }

        }
    }
    /* Fibre is waiting for a pending result */
    void setAsWaiting(Fibre* fibre) {
        assert(fibre.getStatus() != FibreStatus.FINISHED);

        printf("%s Setting %s to waiting\n", logPrefix.ptr, fibre.getName());

        if(isPoolThread()) assert(fibre != mainFibre);

        if(mutex.lock()) {
            scope(exit) mutex.unlock();

            runnableFibres.remove(fibre);

            assert(!waitingFibres.contains(fibre));
            waitingFibres.add(fibre);
        }

        switchToNext();
    }
    void finished(Fibre* fibre) {
        fibre.setStatus(FibreStatus.FINISHED);
        runnableFibres.remove(fibre);

        printf("%s %s finished\n", logPrefix.ptr, fibre.getName());

        /* todo - who destroys fibre? */

        switchToNext();
    }
private:
    void switchToNext() {

        Fibre* fibre;

        spin:while(true) {
            if(isShuttingDown) return;

            printf("%s %s Spin loop\n", logPrefix.ptr, currentlyRunning.getName());

            /* If there is nothing in the runnable queue then switch back to the main fibre */
            if(runnableFibres.length==0) {

                if(currentlyRunning != mainFibre) {
                    /* Switch to main fibre */
                    fibre = mainFibre;
                    break spin;
                } else {
                    /* currently running on the main fibre */

                    bool shouldSpin = !isShuttingDown && (isPoolThread() || waitingFibres.contains(mainFibre));

                    if(shouldSpin) {
                        printf("%s %s waiting on semaphore -->|\n", logPrefix.ptr, currentlyRunning.getName());
                        threadIsOnSemaphore = true;
                        semaphore.wait();
                        threadIsOnSemaphore = false;
                        printf("%s %s <-- woken from semaphore\n", logPrefix.ptr, currentlyRunning.getName());
                    } else {
                        /* Continue main thread */
                        printf("%s %s Continuing the main thread ...\n", logPrefix.ptr, currentlyRunning.getName());
                        return;
                    }
                    printf("%s %s Continuing pool thread...\n", logPrefix.ptr, currentlyRunning.getName());
                }
            } else {
                /*
                    Pick one that isn't currently running (nearest to the front of the queue)
                */
                foreach_reverse(f; *runnableFibres) {
                    /* Skip the currently running fibre */

                    printf("%s %s? running=%s\n", logPrefix.ptr, f.getName(), currentlyRunning.getName());

                    if(f == currentlyRunning) continue;

                    fibre = f;
                    break spin;
                }

                /* The other fibre was running so switch back to the main fibre */
                fibre = mainFibre;
                break spin;
            }
        }

        /* Continuing on the current fibre */
        if(currentlyRunning == fibre) {
            return;
        }

        printf("%s Switching from %s to %s\n", logPrefix.ptr, currentlyRunning.getName(), fibre.getName());

        currentlyRunning = fibre;

        SwitchToFiber(currentlyRunning.getHandle());
    }
    void setName() {
        char[32] temp;
        auto len = snprintf(temp.ptr, temp.length, "%s", isMainThread ? "Main".ptr : "Pool".ptr);

        if(isPoolThread()) {
            snprintf(temp.ptr+len, temp.length-len, "%u", threadIndex-1);
        }

        snprintf(name.ptr, name.length, "[FibreThread on %s/%u]", temp.ptr, threadId);
    }
    void dumpQueueInfo() {
        printf("%s\t    %u Runnable:\n", logPrefix.ptr, runnableFibres.length);
        foreach(i, f; *runnableFibres) {
            printf("%s\t      [%u] %s\n", logPrefix.ptr, i, f.getName());
        }
        printf("%s\t    %u Waiting:\n", logPrefix.ptr, waitingFibres.length);
        foreach(i, f; *waitingFibres) {
            printf("%s\t      [%u] %s\n", logPrefix.ptr, i, f.getName());
        }
    }
}

//#################################################################################################
private:

struct ThreadArgs {
    bool shouldExit = false;
    FibreThread* fibreThread;
    Semaphore* startupSemaphore;
    Fibre* mainFibre;
}

/* Pool thread wrapper function */
uint threadFunc(void* argptr) {
    auto args        = cast(ThreadArgs*)argptr;
    auto fibreThread = args.fibreThread;

    /* Register this thread with Fibres.threadManagers and convert to a Fibre */
    auto threadId  = GetCurrentThreadId();
    auto fibre     = Fibre.makeMainFibre(fibreThread, threadId);
    args.mainFibre = fibre;
    mfence();

    /* Tell fibreThread that we are now a fibre thread */
    args.startupSemaphore.notify();

    /* Wait for fibreThread to complete initialisation */
    args.startupSemaphore.wait();

    /* Start working */
    fibreThread.switchToNext();

    /* We are no longer required */
    printf("%s %s exiting\n", fibreThread.logPrefix.ptr, fibre.getName());
    return 0;
}