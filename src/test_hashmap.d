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

        // Add a new Key (7), Value; bucket = 4
        m.add(7, 70);
        expect(1, m.length());
        expect(!m.isEmpty());

        expect(m.containsKey(7));
        expect(70, m.get(7));

        // Replace an existing Key (7); bucket = 4
        m.add(7, 71);
        expect(1, m.length());
        expect(!m.isEmpty());
        expect(m.containsKey(7));
        expect(71, m.get(7));

        // Add a new Key (9); bucket = 7
        m.add(9, 90);
        expect(2, m.length());

        expect(m.containsKey(7));
        expect(m.containsKey(9));
        expect(71, m.get(7));
        expect(90, m.get(9));

        // Add a new Key (10); bucket = 9 (Now 1 in this bucket)
        m.add(10, 100);
        expect(3, m.length());
        expect(m.containsKey(10));

        // Add a new Key (1); bucket = 5
        m.add(1, 10);
        expect(4, m.length());
        expect(m.containsKey(1));

        // Add a new Key (11); bucket = 13
        m.add(11, 110);
        expect(5, m.length());
        expect(m.containsKey(11));

        // Add a new Key (15); bucket = 9 (Now 2 in this bucket)
        m.add(15, 150);
        expect(6, m.length());
        expect(m.containsKey(15));

        // Add a new Key (51); bucket = 9 (Now 3 in this bucket)
        m.add(51, 220);
        expect(7, m.length());

        expect(m.containsKey(1));
        expect(m.containsKey(7));
        expect(m.containsKey(9));
        expect(m.containsKey(10));
        expect(m.containsKey(11));
        expect(m.containsKey(15));
        expect(m.containsKey(51));

        printf("Keys: ");
        foreach(k; m.keys()) {
            printf("%d ", k);
        }
        printf("\nValues: ");
        foreach(v; m.values()) {
            printf("%d ", v);
        }
        printf("\nKeys and values {\n");
        foreach(e; m.byKeyValue()) {
            printf("  %d = %d\n", e.key, e.value);
        }
        printf("}");
    }
}