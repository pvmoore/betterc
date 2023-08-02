module betterc.FreeList;

private import betterc.all;

alias HeapFreeList          = FreeList_T!(uint, 0);
alias StaticFreeList(SIZE)  = FreeList_T!(uint, SIZE);

/**
 * Keep track of slot index usage.
 * Allows for fast reuse of slots.
 *
 * If SIZE == 0 then - Heap memory will be used to store the indexes
 *
 * If SIZE != 0 then - The indexes will be stored inline (length = SIZE)
 *                   - this(T) constructor is removed
 *                   - destroy() does nothing
 */
struct FreeList_T(T, uint SIZE = 0)
    if(isInteger!T && isUnsigned!T)
{ @nogc:nothrow:
private:
    T length;
    T next;
    T _numUsed;
    static if(SIZE == 0) {
        T* ptr;
    } else {
        T[SIZE] ptr;
    }
public:
    T numUsed() { return _numUsed; }
    T numFree() { return length - _numUsed; }

    static if(SIZE == 0) {
    this(T length) {
        initialise(length);
    }
    }
    void destroy() {
        free(ptr);
        ptr = null;
        length = 0;
        _numUsed = 0;
    }
    void initialise(T length) {
        this.length = length;
        this.ptr = malloc(length * T.sizeof).as!(T*);
        next = 0;
        _numUsed = 0;
        foreach(i; 0..length) {
            ptr[i] = (i.as!T) + 1;
        }
    }
    T acquire() {
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