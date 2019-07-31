module betterc.async.fibres.pending_result;

@nogc:
nothrow:

private import betterc.async.fibres.all;

struct PendingResult {
@nogc:
nothrow:
private:
    void* resultPtr;    // Points to R
    bool resultReady;
    Mutex* mutex;
    List!(Fibre*) waiting;
public:
    static PendingResult* make(R)() {
        auto instance        = heapAlloc!PendingResult;
        instance.resultPtr   = heapAlloc!R;
        instance.resultReady = false;
        instance.mutex       = Mutex.make();

        return instance;
    }
    static void destroy(PendingResult* pr) {
        if(pr) {
            if(pr.resultPtr) {
                free(pr.resultPtr);
            }
            pr.mutex.destroy();
            free(pr);
        }
    }
    @Async
    R await(R)() {

        auto fibre = Fibres.getCurrentFibre();

        if(mutex.lock()) {
            scope(exit) mutex.unlock();

            /* Return the result immediately if it is already done */
            if(resultReady) {
                return *cast(R*)resultPtr;
            }

            /* Result is still pending */
            waiting.add(fibre);
        }
        /* Pause until we are notified by the resultIsReady() call */
        fibre.waitForPendingResult();

        /* When we get here the result must be ready */

        return *cast(R*)resultPtr;
    }
    @Async
    void setResult(R)(R value) {
        printf("%s setResult()\n", Fibres.getCurrentFibre().getName());
        if(mutex.lock()) {
            scope(exit) mutex.unlock();

            *cast(R*)resultPtr = value;
            resultReady = true;

            /* Inform waiting fibres that they can now proceed */
            foreach(w; waiting) {
                w.pendingResultReady();
            }

            /* We don't need this any more */
            waiting.destroy();
        }
    }
}