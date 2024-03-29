module test_freelist;

import betterc;

extern(C):
@nogc:
nothrow:

void testFreeList() {
    printf("Testing FreeList ...\n");

    testHeapFreeList();
    testStaticFreeList();
}
private:

void testHeapFreeList() {
    printf("Testing HeapFreeList ...\n");
    {
        HeapFreeList l;
        expect(0, l.numUsed());
        expect(0, l.numFree());
    }
    {
        auto l = HeapFreeList(5);
        expect(0, l.numUsed());
        expect(5, l.numFree());

        uint[5] a = [
            l.acquire(),
            l.acquire(),
            l.acquire(),
            l.acquire(),
            l.acquire()
        ];
        expect(5, l.numUsed());
        expect(0, l.numFree());

        printf("a = %u,%u,%u,%u,%u\n", a[0], a[1], a[2], a[3], a[4]);

        expect(a == [0,1,2,3,4]);
    }
    {
        auto l = HeapFreeList(5);
        uint[5] a = [
            l.acquire(),
            l.acquire(),
            l.acquire(),
            0,
            0
        ];
        expect(a == [0,1,2, 0,0]);

        // release 2
        l.release(2);

        // next acquire should be 2 again
        expect(2, l.acquire());

        // release 0
        l.release(0);

        // next acquire should b 0
        expect(0, l.acquire());
    }
    {
        auto l = HeapFreeList(10);
        {
            scope(exit) l.destroy();
            expect(0, l.numUsed());
            expect(10, l.numFree());
            l.acquire();
        }
        // should be deallocated
        expect(0, l.numUsed());
        expect(0, l.numFree());
    }
}
void testStaticFreeList() {
    printf("Testing StaticFreeList ...\n");
    {
        StaticFreeList!5 l;
        l.initialise();
        
        expect(0, l.numUsed());
        expect(5, l.numFree());

        uint[5] a = [
            l.acquire(),
            l.acquire(),
            l.acquire(),
            l.acquire(),
            l.acquire()
        ];
        expect(5, l.numUsed());
        expect(0, l.numFree());

        printf("a = %u,%u,%u,%u,%u\n", a[0], a[1], a[2], a[3], a[4]);

        expect(a == [0,1,2,3,4]);
    }
    {
        StaticFreeList!5 l;
        l.initialise();

        uint[5] a = [
            l.acquire(),
            l.acquire(),
            l.acquire(),
            0,
            0
        ];
        expect(a == [0,1,2, 0,0]);

        // release 2
        l.release(2);

        // next acquire should be 2 again
        expect(2, l.acquire());

        // release 0
        l.release(0);

        // next acquire should b 0
        expect(0, l.acquire());
    }
}