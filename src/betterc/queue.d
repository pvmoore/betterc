module betterc.queue;

private import betterc.all;
/**
 * Simple queue using malloc/free for each Node.
 * Not thread safe.
 *
 * Could improve this by caching unused Nodes and reusing them.
 */
struct Queue(T){
@nogc:
nothrow:
private:
    struct Node {
        Node* next;
        Node* prev;
        T value;
    }
    Node* head; // take from here
    Node* tail; // add to here
    uint _length;
public:
    uint length() const  { return _length; }
    bool isEmpty() const { return _length==0; }

    /**
     * Iterate from head of the queue to the tail.
     */
    extern(D)
    int opApply(int delegate(ref T) @nogc nothrow dg) {
        int result = 0;
        auto n = head;
        for(auto i=0; i<_length; i++) {
            result = dg(n.value);
            if(result) break;
            n = n.prev;
        }
        return result;
    }
    /**
     * Iterate from head of the queue to the tail.
     */
    extern(D)
    int opApply(int delegate(uint,ref T) @nogc nothrow dg) {
        int result = 0;
        auto n = head;
        for(auto i=0; i<_length; i++) {
            result = dg(i,n.value);
            if(result) break;
            n = n.prev;
        }
        return result;
    }
    /**
     * Add to the back of the queue.
     */
    void add(T value) {
        auto n = newNode(value);
        if(!tail) {
            tail = head = n;
        } else {
            n.next = tail;
            tail.prev = n;
            tail = n;
        }
        _length++;
    }
    /**
     * Add to the front of the queue.
     */
    void addToFront(T value) {
        auto n = newNode(value);
        if(!head) {
            tail = head = n;
        } else {
            n.prev = head;
            head.next = n;
            head = n;
        }
        _length++;
    }
    /**
     * Take from the front of the queue.
     */
    T take() {
        assert(_length>0);

        auto value   = head.value;
        auto oldHead = head;

        if(_length==1) {
            head = tail = null;
        } else {
            head = head.prev;
        }
        free(oldHead);
        _length--;
        return value;
    }
    /**
     * Look at the item at_ index_ from the head of the queue.
     */
    T peek(int index) {
        assert(_length>index);
        return getAtIndex(index).value;
    }
    /**
     * Look at the item at _index_ from the head of the queue if there is one otherwise returns defaultValue.
     */
    T peekOrElse(int index, T defaultValue) {
        if(index>=_length) return defaultValue;
        return getAtIndex(index).value;
    }
    /**
     * Remove the first instance of value from the queue and return true if it was removed.
     */
    bool remove(T value) {
        Node* n = find(value);
        if(n) {
            auto prev = n.prev;
            auto next = n.next;
            if(prev) {
                prev.next = next;
            } else {
                // we removed the tail
                tail = next;
            }
            if(next)  {
                next.prev = prev;
            } else {
                // we removed the head
                head = prev;
            }
            _length--;
            free(n);
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
            take();
        }
    }
private:
    Node* newNode(T value) {
        auto n = heapAlloc!Node;
        n.value = value;
        return n;
    }
    Node* find(T value) {
        Node* n = head;
        while(n) {
           if(n.value==value) return n;
           n = n.prev;
        }
        return null;
    }
    Node* getAtIndex(int index) {
        Node* n = head;
        while(n && --index>=0) {
           n = n.prev;
        }
        return n;
    }
}