module betterc.HashMap;

extern(C):
@nogc:
nothrow:

/**
 * K must be one of:
 *   - primitive type
 *   - struct with size_t toHash() method
 *
 * TODO - This is currently unstable in that the addresses of values can change 
 * TODO - Benchmark
 * TODO - Add hash quality graph
 * TODO - Implement remove()
 * TODO - Fix clear(), destroy()
 * TODO - Use a List of Arenas which use a FreeList for
 *        storing the KeyValues
 */
struct HashMap(K,V)
    if(isPrimitiveType!K || hasMethod!(K,"toHash", size_t))
{ @nogc: nothrow:
    int length() const   { return _length; }
    bool isEmpty() const { return _length == 0; }
    auto keys() { return KeyIterator!(K,V)(Iterator!(K,V)(buckets)); }
    auto values() { return ValueIterator!(K,V)(Iterator!(K,V)(buckets)); }
    auto byKeyValue() { return KeyValueIterator!(K,V)(Iterator!(K,V)(buckets)); }

    this(int expectedCapacity) {
        expect(expectedCapacity >= 0);
        int cap = 1 << (bsr(expectedCapacity) + 1);
        expect(isPowerOf2(cap));

        this._length = 0;
        this.buckets = List!(Bucket!(K,V))(cap);
        this.buckets.length(cap);
    }
    void destroy() {
        // TODO - free all allocated KeyValues
        buckets.destroy();
    }
    auto add(K key, V value) {
        ulong hash = getHash(key);
        printf("add() hash = %llu\n", hash);

        auto b = getBucket(hash);
        if(b.length == 0) {
            b.length = 1;
            b.single = KeyValue!(K,V)(key, value);
            _length++;
        } else if(b.length == 1) {

            // If we already have this Key, just replace the value and leave the map size unchanged
            if(b.single.key == key) {
                b.single.value = value;
                return this;
            }

            // This is a new Key

            // Note that this is rubbish
            auto ptr = cast(KeyValue!(K,V)*)malloc(KeyValue!(K,V).sizeof * 2);
            ptr[0] = b.single;
            ptr[1] = KeyValue!(K,V)(key, value);

            b.ptr = ptr;
            _length++;
            b.length = 2;
        } else {
            // Check if this Key exists in the map
            foreach(i; 0..b.length) {
                if(b.ptr[i].key == key) {
                    b.ptr[i].value = value;
                    return this;
                }
            }

            // This is a new Key

            // Note that this is rubbish
            b.ptr = realloc(b.ptr, KeyValue!(K,V).sizeof * (b.length+1)).as!(KeyValue!(K,V)*);
            b.ptr[b.length] = KeyValue!(K,V)(key, value);

            _length++;
            b.length++;
        }
        return this;
    }
    V get(K key) {
        V* ptr = getPtr(key);
        if(ptr) return *ptr;
        return V.init;
    }
    V* getPtr(K key) {
        ulong hash = getHash(key);
        printf("get() hash = %llu\n", hash);
        auto b = getBucket(hash);

        if(b.length == 1) {
            if(b.single.key == key) {
                return &b.single.value;
            }
        } else {
            foreach(i; 0..b.length) {
                if(b.ptr[i].key == key) {
                    return &b.ptr[i].value;
                }
            }
        }
        // We don't have this Key
        return null;
    }

    // For testing
    int peekNumBuckets() {
        return buckets.capacity();
    }
    // For testing
    uint peekBucketIndexFor(K key) {
        ulong hash = getHash(key);
        ulong and = buckets.capacity()-1;
        return (hash & and).as!uint;
    }

    V remove(K key) {
        return V.init;
    }
    void clear() {
        // TODO - free allocs
        buckets.clear();
    }
    bool containsKey(K key) {
        auto b = getBucket(getHash(key));
        //printf("length = %d\n", b.length);
        //printf("single = (%u = %u)\n", b.single.key, b.single.value);
        if(b.length == 0) return false;
        if(b.length == 1) return b.single.key == key;

        foreach(i; 0..b.length) {
            if(b.ptr[i].key == key) return true;
        }
        return false;
    }

private:
    uint _length = 0;
    List!(Bucket!(K,V)) buckets;

    void ensureBucketsAreInitialised() {
        if(buckets.isEmpty()) {
            this.buckets = List!(Bucket!(K,V))(DEFAULT_CAPACITY);
            this.buckets.length(DEFAULT_CAPACITY);
        }
    }

    auto getBucket(size_t hash) {
        // This is rubbish
        ensureBucketsAreInitialised();

        ulong and = buckets.capacity()-1;
        uint b = (hash & and).as!uint;
        printf("  bucket = %u\n", b);
        return buckets.getPtrAt(b);
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
            ulong h = *p2;
        } else {
            // K must be some sort of primitive type
            ulong h = cast(size_t)key;
        }
        h = (h ^ (h >> 30)) * 0xbf58476d1ce4e5b9L;
        h = (h ^ (h >> 27)) * 0x94d049bb133111ebL;
        h = h ^ (h >> 31);
        return h;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

import betterc.all;
import core.bitop : bsr;

enum DEFAULT_CAPACITY = 16;

/**
 * Simple Bucket that holds a length plus either a single value or a ptr to a list of values
 */
struct Bucket(K,V) { align(1):
    // length == 0 --> Empty,
    // length == 1 --> single contains the value
    // length  > 1 --> ptr points to an array of length values (on the heap)
    uint length;
    union {
        KeyValue!(K,V) single;
        KeyValue!(K,V)* ptr;
    }
}
struct KeyValue(K,V) {
    K key;
    V value;
}
struct Arena(K,V) {
    FreeList freeList;
    KeyValue!(K,V)* ptr;
}
struct KeyValueIterator(K,V) {
    this(Iterator!(K,V) iter) {
        this.iter = iter;
    }
    extern(D)
    int opApply(int delegate(KeyValue!(K,V)*) @nogc nothrow dg) {
        int result = 0;
        while(iter.hasNext()) {
            result = dg(iter.next()); 
            if(result) break;
        }
        return result;
    }
private:
    Iterator!(K,V) iter;    
}
struct KeyIterator(K,V) {
    this(Iterator!(K,V) iter) {
        this.iter = iter;
    }
    extern(D)
    int opApply(int delegate(ref K) @nogc nothrow dg) {
        int result = 0;
        while(iter.hasNext()) {
            result = dg(iter.next().key); 
            if(result) break;
        }
        return result;
    }
private:
    Iterator!(K,V) iter;
}
struct ValueIterator(K,V) {
    this(Iterator!(K,V) iter) {
        this.iter = iter;
    }
    extern(D)
    int opApply(int delegate(ref V) @nogc nothrow dg) {
        int result = 0;
        while(iter.hasNext()) {
            result = dg(iter.next().value); 
            if(result) break;
        }
        return result;
    }
private:
    Iterator!(K,V) iter;
}
struct Iterator(K,V) {
    this(List!(Bucket!(K,V)) buckets) {
        this.buckets = buckets;
        this.bucket = nextPopulatedBucket();
    }
    bool hasNext() {
        return bucket !is null;
    }
    auto next() {
        if(bucket.length == 1) {
            auto v = &bucket.single;
            bucket = nextPopulatedBucket();
            return v;    
        } 
        auto v = &bucket.ptr[sub];
        if(++sub==bucket.length) {
            bucket = nextPopulatedBucket();
            sub = 0;
        }
        return v;
    }
private:
    List!(Bucket!(K,V)) buckets;
    int bucketIndex = 0;
    int sub = 0;
    Bucket!(K,V)* bucket;

    auto nextPopulatedBucket() {
        Bucket!(K,V)* b = null;
        while(bucketIndex < buckets.length()) {
            b = buckets.getPtrAt(bucketIndex++);
            if(b.length != 0) return b;
        }
        return null;
    }    
}