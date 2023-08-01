module test_freelist;

import betterc;

extern(C):
@nogc:
nothrow:

void testFreeList() {
    printf("Testing FreeList ...\n");

    {
        FreeList l;
        expect(0, l.numUsed());
        expect(0, l.numFree());

    }
}