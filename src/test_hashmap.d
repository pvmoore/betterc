module test_hashmap;

import betterc;

extern(C):
@nogc:
nothrow:

void testHashMap() {
    printf("Testing HashMap ...\n");

    {
        auto m = HashMap!(int,int)(10);


    }
}