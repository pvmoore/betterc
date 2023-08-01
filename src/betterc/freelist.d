module betterc.freelist;

private import betterc.all;

/**
 * Keep track of index usage.
 * Allows for fast reuse of slots.
 */
struct FreeList { @nogc:nothrow:
private:
    uint[] list;
    uint next;
    uint _numUsed;
public:
    uint numUsed() { return _numUsed; }
    uint numFree() { return list.length.as!uint - _numUsed; }

    this(uint length) {
        list.length = length;
        reset();
    }
    uint acquire() {
        expect(_numUsed < list.length);
        auto index = next;
        next = list[next];
        _numUsed++;
        return index;
    }
    void release(uint index) {
        list[index] = next;
        next = index;
        _numUsed--;
    }
    void reset() {
        foreach(i; 0..list.length) {
            list[i] = i.as!int+1;
        }
        next = 0;
        _numUsed = 0;
    }
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
struct FreeList2(T) {
@nogc:
nothrow:
private:
    T* values;
    uint* freeList;
    uint head;
    uint _capacity;
    uint _numUsed;
public:
    uint capacity() const { return _capacity; }
    uint numUsed() const { return _numUsed; }

    this(uint capacity) {
        grow(capacity);
    }
    /**
     *  Free all allocated memory and resize the list to zero.
     */
    void free() {
        .free(freeList); freeList = null;
        .free(values); values = null;
        head = 0;
        _numUsed = 0;
        _capacity = 0;
    }
    /**
     *  Empty the list and reset all indexes.
     */
    void clear() {
        head = 0;
        _numUsed = 0;
        for(auto i=0; i<_capacity; i++) {
            freeList[i] = i+1;
        }
    }
    /**
     *  Add new value and return the index in the list.
     */
    uint add(ref T value) {
        if(_numUsed==_capacity) grow(_capacity*2);
        auto index = head;
        head = freeList[head];
        values[index] = value;
        _numUsed++;
        return index;
    }
    /**
     *  Remove element at position _index_.
     */
    T removeAt(uint index) {
        freeList[index] = head;
        head = index;
        _numUsed--;
        return values[index];
    }
private:
    void grow(uint capacity) {
        if(capacity==0) capacity = 16;

        this.freeList = cast(uint*)realloc(freeList, capacity*int.sizeof);
        this.values = cast(T*)realloc(values, capacity*T.sizeof);

        for(auto i=_capacity; i<capacity; i++) {
            freeList[i] = i+1;
        }
        this._capacity = capacity;
    }
}