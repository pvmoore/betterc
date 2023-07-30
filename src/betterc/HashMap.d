module betterc.HashMap;

public:
extern(C):
@nogc:
nothrow:

import betterc.all;
import core.bitop : bsr;

static assert(HashMap!(int,int).sizeof == 16);

/**
 * K must be one of:
 *   - primitive type
 *   - struct with size_t toHash() method
 *
 */
struct HashMap(K,V)
    if(isPrimitiveType!K || hasMethod!(K,"toHash", size_t))
{ @nogc: nothrow: 
    int length() const   { return 0; }
    bool isEmpty() const { return length() == 0; }
    int numBuckets() const { return buckets.capacity(); }
    V[] values()   { return null; }

    this(int expectedCapacity) {
        assert(expectedCapacity >= 0);
        auto cap = 1 << (bsr(expectedCapacity) + 1);
        this.buckets = ListOfBuckets(cap);
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
        buckets.clear();
    }
    bool containsKey(K key) {
        return false;
    }

private:
    alias BucketType = Bucket!(K,V);
    alias ListOfBuckets = List!BucketType;
    ListOfBuckets buckets;

    BucketType* findBucket(K key) {
        if(buckets.isEmpty()) {
            
        }
        auto bucket = getHash(key) % buckets.length();

        return null;
    }
    size_t getHash(K key) {
        static if(isString!K) {
            // Probably the most common map key type
            size_t hash = 5381;
            foreach(i; 0..key.length) {
                hash = ((hash << 5) + hash) + key[i];
            }
            return hash;
        }
        static if(isStruct!K) {
            return key.toHash();
        }
        static if(is(K==double)) {
            double* p1 = &key;
            size_t* p2 = cast(size_t*)p1;
            return *p2;
        }
        // K must be some sort of primitive type
        return cast(size_t)key;
    }
}

private:

struct Bucket(K,V) { @nogc:nothrow:
    static assert(Bucket!(K,V).sizeof == 16);
    union {
        V value;
        V[] values;
    }
}
