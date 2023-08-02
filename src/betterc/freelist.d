module betterc.FreeList;

private import betterc.all;

alias HeapFreeList              = FreeList_T!(uint, 0);
alias StaticFreeList(uint SIZE) = FreeList_T!(uint, SIZE);

/**
 * Keep track of slot index usage.
 * Allows for fast reuse of slots.
 *
 * If SIZE == 0 then - Heap memory will be used to store the indexes
 *                   - initialise() must be called before use
 * If SIZE != 0 then - The indexes will be stored inline (length = SIZE)
 *                   - this(T) constructor is removed
 *                   - destroy() is removed
 */
struct FreeList_T(T, T SIZE = 0)
    if(isInteger!T && isUnsigned!T)
{ @nogc:nothrow:
private:
    enum ON_HEAP = (SIZE == 0);
    T next = T.max;
    T _numUsed;
    static if(ON_HEAP) {
        T length;
        T* ptr;
    } else {
        enum length = SIZE;
        T[SIZE] ptr;
    }
public:
    T numUsed() { return _numUsed; }
    T numFree() { return length - _numUsed; }

    static if(ON_HEAP) {
    this(T length) {
        this.length = length;
        this.ptr = malloc(length * T.sizeof).as!(T*);
        initialise();
    }
    ~this() {
        free(ptr);
        ptr = null;
        length = 0;
        _numUsed = 0;
    }
    } // ON_HEAP
    void initialise() {
        next = 0;
        _numUsed = 0;
        foreach(i; 0..length) {
            ptr[i] = (i.as!T) + 1;
        }
    }
    T acquire() {
        expectMsg(next != T.max, "initialise() has not been called");
        expectMsg(length != 0, "use after free");
        expect(_numUsed < length);
        auto index = next;
        next = ptr[next];
        _numUsed++;
        return index;
    }
    void release(T index) {
        ptr[index] = next;
        next = index;
        _numUsed--;
    }
}

