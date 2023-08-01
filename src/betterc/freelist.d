module betterc.freelist;

private import betterc.all;

alias FreeList = FreeList_T!uint;

/**
 * Keep track of slot index usage.
 * Allows for fast reuse of slots.
 */
struct FreeList_T(T) 
    if(isInteger!T && isUnsigned!T) 
{ @nogc:nothrow:
private:
    T length;
    T* ptr;
    T next;
    T _numUsed;
public:
    T numUsed() { return _numUsed; }
    T numFree() { return length - _numUsed; }

    this(T length) {
        initialise(length);
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