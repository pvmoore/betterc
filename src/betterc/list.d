module betterc.list;

public:
extern(C):
@nogc:
nothrow:

private import betterc.all;

/**
 *  A dynamic array list using malloc, realloc and free.
 */
struct List(T) {
@nogc:
nothrow:
private:
    T* _ptr = null;
    int _length = 0;
    int _capacity = 0;
public:
    this(int capacity) {
        if(capacity>0) {
            this._capacity = capacity;
            this._ptr      = cast(T*)malloc(this._capacity*T.sizeof);
        }
    }
    static auto make(T[] values...) {
        auto list = List!T(values.length.as!uint);
        list.add(values);
        return list;
    }
    void destroy() {
        free(_ptr);
        _ptr = null;
        _length = 0;
        _capacity = 0;
    }

    int length() const   { return _length; }
    int capacity() const { return _capacity; }
    bool isEmpty() const { return _length==0; }

    extern(D)
    int opApply(int delegate(ref T) @nogc nothrow dg) {
        int result = 0;
        for(auto i=0; i<_length; i++) {
            result = dg(_ptr[i]);
            if(result) break;
        }
        return result;
    }
    extern(D)
    int opApply(int delegate(uint,ref T) @nogc nothrow dg) {
        int result = 0;
        for(auto i=0; i<_length; i++) {
            result = dg(i,_ptr[i]);
            if(result) break;
        }
        return result;
    }
    bool opEquals(inout List!T other) const {
        if(_length!=other._length) return false;
        return 0==memcmp(_ptr, other._ptr, _length*T.sizeof);
    }
    uint toHash() const {
        uint hash = 7;
        uint* p = cast(uint*)_ptr;
        for(auto i=0; i<_length; i++) {
            hash = hash*31 + p[i];
        }
        return hash;
    }

    void clear() {
        _length = 0;
    }
    List!T copy() {
        auto temp = List!T(_length);
        memcpy(temp._ptr, _ptr, _length*T.sizeof);
        temp._length = _length;
        return temp;
    }

    auto add(T value) {
        grow(1);
        _ptr[_length++] = value;
        return this;
    }
    auto add(T[] values...) {
        grow(values.length.as!uint);
        for(auto i=0; i<values.length; i++) {
            _ptr[_length++] = values[i];
        }
        return this;
    }
    auto add(List!T values) {
        if(values.length>0) {
            grow(values.length);

            memcpy(_ptr+_length, values._ptr, values._length*T.sizeof);
            this._length += values._length;
        }
        return this;
    }
    T getAt(uint index) {
        assert(index<_length);
        return _ptr[index];
    }
    T* getPtrAt(uint index) {
        assert(index<_length);
        return &_ptr[index];
    }
    T removeLast() {
        assert(!isEmpty);
        T val = _ptr[_length-1];
        _length--;
        return val;
    }
    // naive
    uint removeAll(T value) {
        int dest = 0;
        int count = 0;
        for(auto i=0; i<_length; i++) {
            if(_ptr[i]==value) {
                // skip
                count++;
            } else {
                _ptr[dest++] = _ptr[i];
            }
        }
        _length = dest;
        return count;
    }
    T removeAt(uint index) {
        T val = _ptr[index];
	    _length--;

        memmove(_ptr+index,                 // dest
                _ptr+index+1,               // src
                (_length-index)*T.sizeof);  // num bytes
        return val;
    }
    int count(T value) {
        int c = 0;
        for(auto i = 0; i<_length; i++) {
            if(_ptr[i]==value) c++;
        }
        return c;
    }
    bool contains(T value) {
        return indexOf(value) != -1;
    }
    int indexOf(T value) {
        for(auto i=0; i<_length; i++) {
            if(_ptr[i] == value) return i;
        }
        return -1;
    }
    /**
     *  list.each((v) { });
     */
    // void each(void delegate(T v) nothrow @nogc functor) {
    //     for(auto i = 0; i<_length; i++) {
    //         functor(_ptr[i]);
    //     }
    // }
    // /**
    //  *  list.each((v,i) { });
    //  */
    // void each(void delegate(T v, int index) nothrow @nogc functor) {
    //     for(auto i = 0; i<_length; i++) {
    //         functor(i, _ptr[i]);
    //     }
    // }
    // /**
    //  *  list.filter(v=>v<5) // ==> returns new List!T
    //  *      .each((v,i){});
    //  */
    // auto filter(bool delegate(T v) nothrow @nogc functor) {
    //     auto temp = List!T(_length);
    //     for(auto i = 0; i<_length; i++) {
    //         if(functor(_ptr[i])) {
    //             temp.add(_ptr[i]);
    //         }
    //     }
    //     return temp;
    // }
    // /**
    //  *  list.map(v=>return v*2f);
    //  */
    // auto map(K)(K delegate(T v) nothrow @nogc functor) {
    //     auto temp = List!K(_length);
    //     for(auto i = 0; i<_length; i++) {
    //         auto v = functor(_ptr[i]);
    //         temp.add(v);
    //     }
    //     return temp;
    // }
private:
    void grow(uint count) {
        if(count==0) {
            // do nothing
        } else if(_ptr is null) {
            _capacity = count+4;
            _ptr      = cast(T*)malloc(_capacity*T.sizeof);
        } else if(_length+count > _capacity) {
            _capacity = (_capacity + count)*2;
            _ptr      = cast(T*)realloc(_ptr, _capacity*T.sizeof);
        }
    }
}
