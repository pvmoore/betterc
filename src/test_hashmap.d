module test_hashmap;

import betterc;

extern(C):
@nogc:
nothrow:

void testHashMap() {
    printf("Testing HashMap ...\n");
    {
        auto m = HashMap!(int,int)();
        cassert(m.length() == 0);
        cassert(m.isEmpty());
        cassert(m.numBuckets() == 0);
    }
    {
        auto m = HashMap!(int,int)(1);
        cassert(m.length() == 0);
        cassert(m.isEmpty());
        cassert(m.numBuckets() == 2);
    }
    {
        auto m = HashMap!(int,int)(10);
        cassert(m.length() == 0);
        cassert(m.isEmpty());
        cassert(m.numBuckets() == 16);
    }
}