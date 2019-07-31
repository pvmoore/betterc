module betterc.async.fibres.fibre;

@nogc:
nothrow:

private import betterc.async.fibres.all;
private import core.stdc.stdlib : malloc, free;
private import core.sys.windows.windows;

enum FibreStatus {
    NOT_CREATED = 0,

    RUNNABLE,
    FINISHED
}

struct Fibre {
@nogc:
nothrow:
private:
    WinFibreHandle handle;
    FibreThread* fibreThread;
    char[32] name;
    FibreStatus status;
    bool _isMainFibre;

    void* args;             // may be null
    void* resultPtr;        // may be null
    void* params;           // may not be used

    PendingResult* pendingResult;   // may be null
public:

    auto getHandle()        { return handle; }
    auto getStatus()        { return status; }
    char* getName()         { return name.ptr; }
    auto getFibreThread()   { return fibreThread; }
    auto getResultPtr()     { return resultPtr; }
    auto getArgs()          { return args; }
    auto isMainFibre()      { return _isMainFibre; }

    void setStatus(FibreStatus status) { this.status = status; }
    void setResultPtr(void* addr)      { this.resultPtr = addr; }

    string getStatusString() {
        final switch(status) with(FibreStatus) {
            case NOT_CREATED: return "NOT_CREATED";
            case RUNNABLE: return "RUNNABLE";
            case FINISHED: return "FINISHED";
        }
    }
    /**
     * Create a Fibre to represent the main fibre of a thread.
     * This is currently executing and doesn't have a user function.
     */
    static Fibre* makeMainFibre(FibreThread* fibreThread, uint threadId) {
        auto f = heapAlloc!Fibre;

        f.fibreThread  = fibreThread;
        f.handle       = ConvertThreadToFiberEx(null, 0);
        f.status       = FibreStatus.RUNNABLE;
        f._isMainFibre = true;

        f.setName();

        if(!f.handle) panic("ConvertThreadToFiber");

        return f;
    }
    static Fibre* makeSubFibre(R)(FibreThread* fibreThread, UserFibreFunc!R userFunc, PendingResult* pending, uint index) {
        auto f = heapAlloc!Fibre;

        f.fibreThread   = fibreThread;
        f.pendingResult = pending;

        // Set wrapper params
        f.params = heapAlloc!(Params!R);

        Params!R* p = cast(Params!R*)f.params;
        p.userFunc = userFunc;
        p.fibrePtr = f;

        f.handle = CreateFiberEx(0, 0, 0, &fibreFunctionWrapper!R, p);
        if(!f.handle) panic("Fibre - CreateFiberEx");

        f.status = FibreStatus.RUNNABLE;

        f.setName(index);

        return f;
    }
    void destroy() {
        if(handle) {
            status = FibreStatus.NOT_CREATED;
            DeleteFiber(handle);
            handle = null;
        }
        if(params) {
            free(params);
            params = null;
        }
        free(&this);
    }
    /**
     * The PendingResult is now ready. Called by async thread.
     */
    @Async
    void pendingResultReady() {
        printf("%s Result ready\n", Fibres.getCurrentFibre().getName());
        fibreThread.setAsRunnable(&this);
    }
    /**
     * This fibre is waiting for a PendingResult
     */
    void waitForPendingResult() {
        fibreThread.setAsWaiting(&this);
    }
private:
    void finished() {
        assert(status == FibreStatus.RUNNABLE);
        fibreThread.finished(&this);
    }
    void setName(uint index = 0) {
        char[32] temp;
        auto len = snprintf(temp.ptr, temp.length, "%s", fibreThread.isMainThread() ? "Main".ptr : "Pool".ptr);

        if(!fibreThread.isMainThread()) {
             snprintf(temp.ptr+len, temp.length-len, "%u", fibreThread.getThreadIndex()-1);
        }

        snprintf(name.ptr, this.name.length, "[Fibre %s/F%u]", temp.ptr, index);

    }
}

//##########################################################################################################

private:

struct Params(R) {
    Fibre* fibrePtr;
    UserFibreFunc!R userFunc;
}

extern(Windows)
void fibreFunctionWrapper(R)(void* arg) {
    auto args = cast(Params!R*)arg;
    //printf("[%s] FibreWrapper - Running\n", args.fibrePtr.getName());

    /* Run the user code */
    static if(is(R==void)) {
        args.userFunc();
    } else {
        R r = args.userFunc();

        /* Set PendingResult if it exists */
        if(args.fibrePtr.pendingResult) {
            args.fibrePtr.pendingResult.setResult(r);
        } else {
            // Must be a generator
            R* addr = cast(R*)args.fibrePtr.resultPtr;
            assert(addr);

            *addr = r;
        }
    }

    //printf("[%s] FibreWrapper - exiting\n", args.fibrePtr.getName());
    args.fibrePtr.finished();
}
