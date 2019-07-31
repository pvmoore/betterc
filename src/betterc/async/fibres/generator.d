module betterc.async.fibres.generator;

@nogc:
nothrow:

private import betterc.async.fibres.all;

struct Generator(R) {
@nogc:
nothrow:
private:
    Fibre* fibre;
    FibreThread* fibreThread;
public:
    this(Fibre* fibre, FibreThread* fibreThread) {
        this.fibre       = fibre;
        this.fibreThread = fibreThread;
    }
    R call() {
        /* Allocate some space for the yielded result */
        R value;

        fibre.setResultPtr(&value);

        // Continue the fibre
        fibreThread.resumed(fibre);

        return value;
    }
}