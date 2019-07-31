module test_threads;

import betterc;
import betterc.async;

import core.sys.windows.windows;

@nogc:
nothrow:

void testThread() {
    printf("\n########### Testing Thread ...\n");

    const foo = cast(ThreadFunc)(void* args) {
        uint argsValue = *cast(uint*)args;
        printf("foo running ...\n");
        printf("args = %u\n", argsValue);

        printf("foo threadId = %u\n", Thread.currentThreadId());
        printf("foo sleeping ...\n");
        Thread.sleep(250);
        printf("foo sleeping ...\n");
        Thread.sleep(250);

        printf("foo finished\n");
        return 0;
    };

    uint args = 77;

    printf("threadId = %u\n", Thread.currentThreadId());

    Thread* t = Thread.make("t1", foo, &args);
    t.start();
    t.join();

    printf("priority = %d\n", t.getPriority());
    printf("exit code was = %d\n", t.getExitCode());
    printf("isFinished = %d\n", t.isFinished());
    printf("cycles used = %llu\n", t.getCyclesUsed());

    t.destroy();

    testAtomics();

    testSemaphore();
}
void testAtomics() {
    printf("\n########### Testing atomics ...\n");
    enum NUM_THREADS    = 8;
    enum NUM_ITERATIONS = 100;

    uint counter = 0;

    List!(Thread*) threads;

    printf("Starting %u threads...\n", NUM_THREADS);

    for(auto i=0; i<NUM_THREADS; i++) {
        auto t = Thread.make("name", cast(ThreadFunc)(void* argsPtr) {
            auto args = cast(uint*)argsPtr;

            for(auto i=0;i<NUM_ITERATIONS;i++) {
                 atomicAdd32(args, 1);
                 Thread.sleep(20);
            }

            return 0;

        }, &counter);

        threads.add(t);
    }

    foreach(t; threads) {
        t.start();
    }
    foreach(t; threads) {
        t.join();
    }
    foreach(t; threads) {
        t.destroy();
    }
    threads.destroy();

    //mfence();
    printf("Counter should be %u\n", NUM_THREADS*NUM_ITERATIONS);
    printf("Counter is ...... %u\n", counter);

    assert(counter == NUM_THREADS*NUM_ITERATIONS);
}
void testSemaphore() {
    printf("\n########### Testing semaphore ...\n");

    auto s = Semaphore.make(0, 10);

    auto t = Thread.make("name", cast(ThreadFunc)(void* argsPtr) {
            auto sem = cast(Semaphore*)argsPtr;

            for(auto i=0; i<10; i++) {
                printf("waiting...\n");
                sem.wait();
                printf("released...\n");
            }

            return 0;

        }, s);

    t.start();

    Thread.sleep(500);
    printf("Num waiting = %u\n", s.getNumWaiting());

    printf("%u\n", s.notify());
    printf("%u\n", s.notify());

    printf("notifying all ...\n");
    s.notifyAll();

    Thread.sleep(500);
    printf("Num waiting = %u\n", s.getNumWaiting());

    t.join();
}