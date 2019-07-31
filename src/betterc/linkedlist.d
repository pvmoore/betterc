module betterc.linkedlist;

private import betterc.all;

struct LinkedList(T) {
@nogc:
nothrow:
private:
    struct Node {
        Node* next;
        Node* prev;
        T value;
    }
    Node* head;
    Node* tail;
    uint _length;
public:
    uint length() const  { return _length; }
    bool isEmpty() const { return _length==0; }

    this() @disable;
    this(ref return scope LinkedList!T) @disable;

    static LinkedList* make() {
        return heapAlloc!LinkedList;
    }
    void destroy() {
        clear();
        free(&this);
    }
    extern(D)
    int opApply(scope int delegate(ref T) @nogc nothrow dg) {
        int result = 0;
        auto n = tail;
        for(auto i=0; i<_length; i++) {
            result = dg(n.value);
            if(result) break;
            n = n.next;
        }
        return result;
    }
    extern(D)
    int opApplyReverse(scope int delegate(ref T) @nogc nothrow dg) {
        int result = 0;
        auto n = head;
        for(int i=_length-1; i>=0; i--) {
            result = dg(n.value);
            if(result) break;
            n = n.prev;
        }
        return result;
    }
    extern(D)
    int opApply(scope int delegate(uint,ref T) @nogc nothrow dg) {
        int result = 0;
        auto n = tail;
        for(auto i=0; i<_length; i++) {
            result = dg(i, n.value);
            if(result) break;
            n = n.next;
        }
        return result;
    }
    extern(D)
    int opApplyReverse(scope int delegate(uint,ref T) @nogc nothrow dg) {
        int result = 0;
        auto n = head;
        for(int i=_length-1; i>=0; i--) {
            result = dg(i, n.value);
            if(result) break;
            n = n.prev;
        }
        return result;
    }
    T getAt(uint index) {
        assert(index<_length);
        return getAtIndex(index).value;
    }
    T* getPtrAt(uint index) {
        assert(index<_length);
        auto n = getAtIndex(index);
        return &n.value;
    }
    T first() {
        assert(!isEmpty);
        return tail.value;
    }
    T last() {
        assert(!isEmpty);
        return head.value;
    }

    void add(T value) {
        auto n = newNode(value);
        if(!head) {
            tail = head = n;
        } else {
            n.prev    = head;
            head.next = n;
            head      = n;
        }
        _length++;
    }
    void add(T[] values...) {
        for(auto i=0; i<values.length; i++) {
            add(values[i]);
        }
    }
    void insertAt(uint index, T value) {
        assert(_length>=index);

        if(!tail) {
            add(value);
        } else {
            auto i  = newNode(value);
            Node* n = getAtIndex(index);

            /* insert before n */
            if(n==tail) {
                i.next    = tail;
                tail.prev = i;
                tail      = i;
            } else if(n is null) {
                i.prev    = head;
                head.next = i;
                head      = i;
            } else {
                 i.prev    = n.prev;
                 i.next    = n;

                 n.prev.next = i;
                 n.prev    = i;
            }
            _length++;
        }
    }
    void insertAt(uint index, T[] values...) {
        assert(_length>=index);

        if(values.length==1) {
            insertAt(index, values[0]);
            return;
        }

        assert(false, "todo");

        // for(auto i=0; i<values.length; i++) {

        // }
    }
    T removeAt(uint index) {
        assert(_length>index);

        Node* n   = getAtIndex(index);
        auto value = n.value;
        removeNode(n);

        return value;
    }
    /**
     * Remove the first instance of value from the list and return true if it was removed.
     */
    bool remove(T value) {
        Node* n = find(value);
        if(n) {
            removeNode(n);
            return true;
        }
        return false;
    }
    bool contains(T value) {
        return find(value) !is null;
    }
    void clear() {
        // free each node individually
        while(head) {
            removeAt(0);
        }
    }
private:
    Node* newNode(T value) {
        auto n = heapAlloc!Node;
        n.value = value;
        return n;
    }
    Node* find(T value) {
        Node* n = tail;
        while(n) {
           if(n.value==value) return n;
           n = n.next;
        }
        return null;
    }
    Node* getAtIndex(int index) {
        Node* n = tail;
        while(n && --index>=0) {
           n = n.next;
        }
        return n;
    }
    void removeNode(Node* n) {
        assert(n);

        if(_length==1) {
            head = tail = null;
        } else {
            auto next = n.next;
            auto prev = n.prev;
            if(next) next.prev = n.prev; else head = n.prev;
            if(prev) prev.next = n.next; else tail = n.next;
        }
        free(n);
        _length--;
    }
}