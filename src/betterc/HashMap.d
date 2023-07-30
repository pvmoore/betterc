module betterc.HashMap;

public:
extern(C):
@nogc:
nothrow:

import betterc.all;

/**
 * K must be one of:
 *   - primitive type
 *   - struct with size_t toHash() method
 *
 */
struct HashMap(K,V)
    if(isPrimitiveType!K || hasMethod!(K,"toHash", size_t))
{ @nogc: nothrow: static assert(HashMap!(int,int).sizeof == 16);
    int length() const   { return 0; }
    bool isEmpty() const { return length() == 0; }
    K[] keys()     { return null; }
    V[] values()   { return null; }

    this(int expectedCapacity) {
        this.buckets = ListOfBuckets(expectedCapacity);
    }
    void destroy() {
        buckets.destroy();
    }

    void add(K key, V value) {

    }
    V remove(K key) {
        return V.init;
    }
    void clear() {

    }
    bool containsKey(K key) {
        return false;
    }

private:
    alias BucketType = Bucket!(K,V);
    alias ListOfBuckets = List!BucketType;
    ListOfBuckets buckets;

    BucketType* findBucket(K key) {
        //size_t hash = key.toHash();

        return null;
    }
}

private:

struct Bucket(K,V) { @nogc:nothrow:
    union {
        V value;
        V[] values;
    }
}
