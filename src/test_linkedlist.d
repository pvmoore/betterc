module test_linkedlist;

import betterc;

extern(C):
@nogc:
nothrow:

void testLinkedList() {
    printf("Testing LinkedList ...\n");

    void assertList(LinkedList!int* list, int[] values...) {
        assert(list.length  == values.length);
        assert(list.isEmpty == (list.length==0));
        for(auto i=0; i<values.length; i++) {
            assert(list.getAt(i) == values[i]);
        }
    }

    {
        auto ll = LinkedList!int.make();
        scope(exit) ll.destroy();
        assert(ll.isEmpty && ll.length==0);

        // add
        ll.add(5);
        assert(!ll.isEmpty && ll.length==1);

        ll.add(10);
        assert(ll.length==2);

        ll.add(15);
        assert(ll.length==3);

        // getAt
        assert(ll.getAt(0)==5);
        assert(ll.getAt(1)==10);
        assert(ll.getAt(2)==15);

        // getPtrAt
        assert(*ll.getPtrAt(0)==5);
        assert(*ll.getPtrAt(1)==10);
        assert(*ll.getPtrAt(2)==15);

        // remove
        assert(ll.remove(10)==true && ll.length==2);
        assert(ll.remove(0)==false && ll.length==2);
        assert(ll.remove(15)==true && ll.length==1);
        assert(ll.remove(5)==true && ll.length==0 && ll.isEmpty);

        // add(...)
        ll.add(1,2,3,4,5);
        assertList(ll, 1,2,3,4,5);

        // contains
        assert(ll.contains(1));
        assert(ll.contains(5));
        assert(!ll.contains(0));

        // removeAt
        assert(ll.removeAt(0)==1 && ll.length==4);
        assert(ll.removeAt(3)==5 && ll.length==3);
        assert(ll.removeAt(1)==3 && ll.length==2);
        assert(ll.removeAt(1)==4 && ll.length==1);
        assert(ll.removeAt(0)==2 && ll.length==0 && ll.isEmpty);

        // clear
        ll.add(1,2,3);
        ll.clear();
        assert(ll.isEmpty && ll.length==0);

        // insertAt
        ll.add(1,2,3,4,5);
        ll.insertAt(0, 0);
        assertList(ll, 0,1,2,3,4,5);

        ll.insertAt(1, 90);
        assertList(ll, 0,90,1,2,3,4,5);

        ll.insertAt(6, 91);
        assertList(ll, 0,90,1,2,3,4,91,5);

        ll.insertAt(8, 92);
        assertList(ll, 0,90,1,2,3,4,91,5,92);

        // first last
        assert(ll.first()==0);
        assert(ll.last()==92);

        // opApply
        int i=0;
        foreach(v; *ll) {
            switch(i++) {
                case 0: assert(v==0); break;
                case 1: assert(v==90); break;
                case 2: assert(v==1); break;
                case 3: assert(v==2); break;
                case 4: assert(v==3); break;
                case 5: assert(v==4); break;
                case 6: assert(v==91); break;
                case 7: assert(v==5); break;
                case 8: assert(v==92); break;
                default: assert(false);
            }
        }
        assert(i==9);

        i=0;
        foreach(n, v; *ll) {
            assert(n==i);
            switch(i++) {
                case 0: assert(v==0); break;
                case 1: assert(v==90); break;
                case 2: assert(v==1); break;
                case 3: assert(v==2); break;
                case 4: assert(v==3); break;
                case 5: assert(v==4); break;
                case 6: assert(v==91); break;
                case 7: assert(v==5); break;
                case 8: assert(v==92); break;
                default: assert(false);
            }
        }
        assert(i==9);

        // opApplyReverse
        i=0;
        foreach_reverse(v; *ll) {
            switch(i++) {
                case 0: assert(v==92); break;
                case 1: assert(v==5); break;
                case 2: assert(v==91); break;
                case 3: assert(v==4); break;
                case 4: assert(v==3); break;
                case 5: assert(v==2); break;
                case 6: assert(v==1); break;
                case 7: assert(v==90); break;
                case 8: assert(v==0); break;
                default: assert(false);
            }
        }

        i=0;
        foreach_reverse(n, v; *ll) {
            //assert(n == 8-i);
            switch(i++) {
                case 0: assert(v==92); break;
                case 1: assert(v==5); break;
                case 2: assert(v==91); break;
                case 3: assert(v==4); break;
                case 4: assert(v==3); break;
                case 5: assert(v==2); break;
                case 6: assert(v==1); break;
                case 7: assert(v==90); break;
                case 8: assert(v==0); break;
                default: assert(false);
            }
        }

        // insertAt(...)
        // todo

    }
}