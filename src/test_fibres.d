module test_fibres;

import betterc.async.fibres;

import core.sys.windows.windows;

extern(C):
@nogc:
nothrow:

void testFibres() {
    printf("Testing Fibres ...\n");

    auto threadId = GetCurrentThreadId();
    printf("Test - Main thread id = %d\n", threadId);

    Fibres.start();
    scope(exit) Fibres.shutDown();

    // UserFibreFunc bar = (Fibre* fibre) {
    //     printf("bar\n");
    // };

    printf("Test - Current fibre = %s\n", Fibres.getCurrentFibre().getName());

    //generatorExample();
    asyncExample();

    //callExample();
    //callWithArgsExample();
    //runFibreFromFibre();
    //pauseExample();

    Fibres.dumpStats();

    printf("main finished OK\n");
}
void generatorExample() {
    printf("##########################################################\n");
    printf("generatorExample\n");
    printf("##########################################################\n");

    auto gen = Fibres.makeGenerator!int( () {
        auto fibre = Fibres.getCurrentFibre();
        printf("%s Running in fibre\n", fibre.getName());

        Fibres.yield(10);
        Fibres.yield(20);

        return 30;
    });

    int r = gen.call();
    printf("generated %d\n", r);
    r = gen.call();
    printf("generated %d\n", r);

    r = gen.call();
    printf("generated %d\n", r);
}
void asyncExample() {
    printf("##########################################################\n");
    printf("asyncExample\n");
    printf("##########################################################\n");

    auto pending = Fibres.async!int( () {
        auto fibre = Fibres.getCurrentFibre();
        printf("%s async calculating result ...\n", fibre.getName());

        return 7;
    });

    // Wait for the result
    int r = pending.await!int();
    printf("r=%d\n", r);

    // This should return immediately
    r = pending.await!int();
    printf("r=%d\n", r);
}
// void callExample() {
//     printf("##########################################################\n");
//     printf("callExample\n");
//     printf("##########################################################\n");

//     auto f = Fibres.createFibre(cast(UserFibreFunc)() {
//            auto fibre = Fibres.getCurrentFibre();
//         printf("[%s] Running in fibre\n", fibre.getName());
//     });

//     printf("[callExample] before call status = %s\n", f.getStatusString().ptr);

//     // Run the fibre
//     f.call();

//     printf("[callExample] after call status = %s\n", f.getStatusString().ptr);

//     // Fibre is finished. Should do nothing
//     f.call();
//     f.call();
// }
// void callWithArgsExample() {
//     printf("##########################################################\n");
//     printf("callWithArgsExample\n");
//     printf("##########################################################\n");

//     auto f = Fibres.createFibre(cast(UserFibreFunc)() {
//         printf("[%s] callWithArgsExample test\n", fibre.getName());

//         auto args = fibre.getArgs().as!(int*);
//         printf("args = %u\n", *args);
//     });

//     // Run the fibre with args
//     int args = 99;
//     f.call(&args);
// }
// void runFibreFromFibre() {
//     printf("##########################################################\n");
//     printf("runFibreFromFibre\n");
//     printf("##########################################################\n");

//     auto f = Fibres.createFibre(cast(UserFibreFunc)() {
//         printf("[%s] runFibreFromFibre test\n", fibre.getName());

//         auto f2 = Fibres.createFibre(cast(UserFibreFunc)() {
//             printf("[%s] \n", fibre.getName());


//         });

//         f2.call();
//     });

//     f.call();
// }
// void pauseExample() {
//     printf("##########################################################\n");
//     printf("pauseExample\n");
//     printf("##########################################################\n");

//      auto f = Fibres.createFibre(cast(UserFibreFunc)() {

//         printf("pausing ...\n");
//         //fibre.pause();
//         printf("after pause ...\n");
//     });

//     f.call();

// }

void fibreFunc1() {
    printf("foo\n");
}
void generator() {
    printf("generator\n");

    auto threadId = GetCurrentThreadId();
    printf("generator - thread id = %d\n", threadId);

    printf("generator - yielding 1\n");
    Fibres.yield(1);
    printf("generator - yielding 2\n");
    Fibres.yield(2);
    printf("generator - yielding 3\n");
    Fibres.yield(3);
}