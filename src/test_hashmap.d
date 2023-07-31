module test_hashmap;

import betterc;

@nogc:
nothrow:

void testHashMap() {
    printf("Testing HashMap ...\n");
    {
        auto m = HashMap!(int,int)();
        expect(0, m.length());
        expect(m.isEmpty());
        expect(0, m.peekNumBuckets());
    }
    {
        auto m = HashMap!(int,int)(1);
        expect(0, m.length());
        expect(m.isEmpty());
        expect(2, m.peekNumBuckets());
    }
    {
        auto m = HashMap!(int,int)(10);
        expect(0, m.length());
        expect(m.isEmpty());
        expect(16, m.peekNumBuckets());
    }
    {
        auto m = HashMap!(int,int)();
        expect(!m.containsKey(7));
        expect(0, m.get(7));

        // Add a new Key, Value; bucket = 4
        m.add(7, 70);
        expect(1, m.length());
        expect(!m.isEmpty());

        expect(m.containsKey(7));
        expect(70, m.get(7));

        // Replace an existing Key; bucket = 4
        m.add(7, 71);
        expect(1, m.length());
        expect(!m.isEmpty());
        expect(m.containsKey(7));
        expect(71, m.get(7));

        // Add a new Key, Value; bucket = 7
        m.add(9, 90);
        expect(2, m.length());

        expect(m.containsKey(7));
        expect(m.containsKey(9));
        expect(71, m.get(7));
        expect(90, m.get(9));

        // Add a new Key, Value; bucket = 9
        m.add(10, 100);
        expect(3, m.length());

        expect(m.containsKey(7));
        expect(m.containsKey(9));
        expect(m.containsKey(10));
    }
}