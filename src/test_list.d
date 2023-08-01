module test_list;

import betterc;

extern(C):
@nogc:
nothrow:

void testList() {
    printf("Testing List ...\n");

    {
        List!int l;
        assert(l.capacity==0 && l.isEmpty() && l.length()==0);
    }
    {
        auto l = List!int();
        assert(l.capacity==0 && l.isEmpty() && l.length()==0);
    }
    {
        auto l = List!int(3);
        assert(l.capacity==3 && l.isEmpty() && l.length()==0);
    }
    {
        struct S { @nogc: nothrow:
            List!int l;

            this(int s) {
                l = List!int(s);
            }
        }
        S s;
        S s2 = S(2);
        assert(s.l.capacity==0 && s.l.isEmpty() && s.l.length()==0);
        assert(s2.l.capacity==2 && s2.l.isEmpty() && s2.l.length()==0);
    }

    {
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
        auto l4 = List!int(5,6,7);
        assert(l4.length==3);
        assert(l4.getAt(0) == 5);
        assert(l4.getAt(1) == 6);
        assert(l4.getAt(2) == 7);

        // add(List)

        // [1,2,3,4]
        l.add(List!int(5,6,7));
        assert(l.length==7);
        assert(l == List!int(1,2,3,4,5,6,7));
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
    {   // set length()
        auto l = List!int(5);
        expect(0, l.length());
        expect(5, l.capacity());

        l.add(7);
        expect(1, l.length());
        expect(5, l.capacity());

        // Expand to length = 10
        l.length(10);
        expect(10, l.length());
        expect(10, l.capacity());
        expect(7, l.getAt(0));
        expect(0, l.getAt(1));
        expect(0, l.getAt(2));
        expect(0, l.getAt(3));
        expect(0, l.getAt(4));
        expect(0, l.getAt(5));
        expect(0, l.getAt(6));
        expect(0, l.getAt(7));
        expect(0, l.getAt(8));
        expect(0, l.getAt(9));

        // Shrink to length = 8
        l.length(8);
        expect(8, l.length());
        expect(10, l.capacity());
        expect(7, l.getAt(0));
        expect(0, l.getAt(1));
        expect(0, l.getAt(2));
        expect(0, l.getAt(3));
        expect(0, l.getAt(4));
        expect(0, l.getAt(5));
        expect(0, l.getAt(6));
        expect(0, l.getAt(7));
    }
    {
        auto l = List!int(5);
        l.length(5);

        l.setAt(1, 5);
        l.setAt(4, 9);
        expect(0, l.getAt(0));
        expect(5, l.getAt(1));
        expect(0, l.getAt(2));
        expect(0, l.getAt(3));
        expect(9, l.getAt(4));
    }
    printf("List OK\n");
}