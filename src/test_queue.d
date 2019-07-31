module test_queue;

import betterc;

extern(C):
@nogc:
nothrow:

void testQueue() {
    printf("Testing Queue ...\n");

    {
        auto q = Queue!int();
        assert(q.isEmpty);
        assert(q.length==0);

        q.add(1);
        assert(!q.isEmpty);
        assert(q.length==1);

        q.add(2);
        assert(q.length==2);

        auto item = q.take();
        assert(item==1);
        assert(q.length==1);

        auto item2 = q.take();
        assert(q.isEmpty);
        assert(q.length==0);
        assert(item2 == 2);

        q.add(3);
        q.add(4);
        q.add(5);

        foreach(i, v; q) {
            if(i==0) assert(v==3);
            if(i==1) assert(v==4);
            if(i==2) assert(v==5);
            assert(i<3);
        }
    }
    {
        // remove
        auto q = Queue!int();
        q.add(7);
        q.add(9);
        q.add(11);
        q.add(13);
        assert(q.length==4);

        // [13, 11, 9, 7] front
        assert(q.peek(0)==7 && q.peek(1)==9 && q.peek(2)==11 && q.peek(3)==13);

        // remove non-existing element
        assert(!q.remove(10));
        assert(q.peek(0)==7 && q.peek(1)==9 && q.peek(2)==11 && q.peek(3)==13);

        // remove end of the queue
        assert(q.remove(13));
        // [11, 9, 7] front
        assert(q.length==3 && q.peek(0)==7 && q.peek(1)==9 && q.peek(2)==11);

        // remove middle element
        assert(q.remove(9));
        // [11, 7] front
        assert(q.length==2 && q.peek(0)==7 && q.peek(1)==11);

        // remove head of the queue
        assert(q.remove(7));
        // [11]
        assert(q.length==1 && q.peek(0)==11);

        // remove only element
        assert(q.remove(11));
        assert(q.isEmpty && q.length==0);

        q.add(1);
        q.add(2);
        q.add(3);

        // [3, 2, 1] front
        printf("%d\n", q.peek(0));
        assert(q.peek(0)==1 && q.peek(1)==2 && q.peek(2)==3);
    }
    {
        // contains
        auto q = Queue!int();
        q.add(5);
        q.add(9);

        assert(!q.contains(10));
        assert(q.contains(5));

        // peekOrElse
        assert(q.peekOrElse(0, 0)==5);
        q.take();
        assert(q.peekOrElse(0, 0)==9);
        q.take();
        assert(q.peekOrElse(0, 0)==0);
        assert(q.isEmpty);

        q.add(5);
        q.add(6);
        q.add(7);

        // [7, 6, 5] front
        assert(q.peekOrElse(0, 0) == 5);
        assert(q.peekOrElse(1, 0) == 6);
        assert(q.peekOrElse(2, 0) == 7);

        // clear
        q.clear();
        assert(q.isEmpty && q.length==0);

        // addToFront
        q.add(1);
        q.addToFront(10);
        assert(q.peekOrElse(0, 0)==10);

        q.add(2);
        assert(q.length==3);

        // [2, 1, 10] front

        assert(q.take() == 10);
        assert(q.take() == 1);
        assert(q.take() == 2);
    }
    {
        // peek(int)
        auto q = Queue!int();
        q.add(1);
        q.add(2);
        q.add(3);

        // [3, 2, 1] front

        assert(q.peek(0)==1);
        assert(q.peek(1)==2);
        assert(q.peek(2)==3);
    }
    printf("Queue OK\n");
}