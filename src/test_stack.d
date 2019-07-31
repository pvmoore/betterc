module test_stack;

import betterc;

extern(C):
@nogc:
nothrow:

void testStack() {
    printf("Testing Stack ...\n");

    {
        // push, pop, isEmpty and length
        auto s = Stack!int();
        assert(s.isEmpty);
        assert(s.length==0);

        s.push(4);
        assert(!s.isEmpty);
        assert(s.length==1);

        s.push(6);
        assert(s.length==2);

        s.push(8);
        assert(s.length==3);

        assert(s.pop()==8);
        assert(s.length==2);

        assert(s.pop()==6);
        assert(s.length==1);

        assert(s.pop()==4);
        assert(s.length==0);
        assert(s.isEmpty);

        // clear
        s.push(10);
        s.clear();
        assert(s.isEmpty);
        assert(s.length==0);
    }
    printf("Stack OK\n");
}