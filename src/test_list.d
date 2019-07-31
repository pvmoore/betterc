module test_list;

import betterc;

extern(C):
@nogc:
nothrow:

void testList() {
    printf("Testing List ...\n");

    {
        auto l0 = List!int();
        assert(l0.capacity==0 && l0.isEmpty && l0.length==0);

        auto l = List!int(10);
        scope(exit) l.destroy();

        assert(l.capacity==10);
        assert(l.isEmpty);
        assert(l.length==0);

        // add(value)
        l.add(3);
        assert(!l.isEmpty);
        assert(l.length==1);

        l.add(4);
        assert(l.length==2);

        // add(values)
        l.add(5,6);
        assert(l.length==4);

        // getAt
        assert(l.getAt(0) == 3);
        assert(l.getAt(1) == 4);
        assert(l.getAt(2) == 5);
        assert(l.getAt(3) == 6);

        // getPtrAt
        assert(*l.getPtrAt(0) == 3);

        // count
        l.add(4);

        // [3,4,5,6,4]

        assert(l.count(200)==0);
        assert(l.count(3)==1);
        assert(l.count(4)==2);

        // removeAll
        assert(0 == l.removeAll(200));
        assert(1 == l.removeAll(3));

        // [4,5,6,4]

        assert(l.length==4);
        assert(l.getAt(0)==4);
        assert(l.getAt(1)==5);
        assert(l.getAt(2)==6);
        assert(l.getAt(3)==4);

        // removeAt
        assert(l.removeAt(3)==4 && l.length==3);
        assert(l.removeAt(1)==5 && l.length==2);
        assert(l.removeAt(0)==4 && l.length==1);
        assert(l.getAt(0) == 6);

        // clear
        l.clear();
        assert(l.isEmpty && l.length==0);

        // copy
        l.add(1,2,3,4);
        assert(l.length==4);

        auto l2 = l.copy();
        scope(exit) l2.destroy();

        assert(l2.length==4);
        assert(l2.getAt(0) == 1);
        assert(l2.getAt(1) == 2);
        assert(l2.getAt(2) == 3);
        assert(l2.getAt(3) == 4);
        assert(l.getPtrAt(0) != l2.getPtrAt(0));


        // opEquals
        auto l3 = l.copy();
        scope(exit) l3.destroy();

        l3.removeAt(1);
        assert(l == l2);
        assert(l != l3);

        // static make
        auto l4 = List!int.make(5,6,7);
        assert(l4.length==3);
        assert(l4.getAt(0) == 5);
        assert(l4.getAt(1) == 6);
        assert(l4.getAt(2) == 7);

        // add(List)

        // [1,2,3,4]
        l.add(List!int.make(5,6,7));
        assert(l.length==7);
        assert(l == List!int.make(1,2,3,4,5,6,7));
    }
    {
        auto l = List!int();

        // removeLast
        l.add(1,2,3);
        assert(3==l.removeLast());
        assert(l.length==2);
        assert(l.getAt(0)==1);
        assert(l.getAt(1)==2);
    }
    {
        // indexOf
        auto l = List!int();
        l.add(1,2,3,4,5,6,7);
        assert(l.indexOf(0) == -1);
        assert(l.indexOf(1) == 0);
        assert(l.indexOf(7) == 6);
        assert(l.indexOf(4) == 3);

        // contains
        assert(l.contains(3)==true);
        assert(l.contains(10)==false);
    }
    printf("List OK\n");
}