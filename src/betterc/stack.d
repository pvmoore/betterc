module betterc.stack;

private import betterc.all;
/**
 * A Queue implementation using a composed List instance.
 * Not thread safe.
 *
 * Could improve this by caching unused Nodes and reusing them.
 */
struct Stack(T) {
@nogc:
nothrow:
private:
    List!T list;
public:
    uint length()   { return list.length; }
    bool isEmpty() { return list.isEmpty; }

    void push(T value) {
        list.add(value);
    }
    T pop() {
        return list.removeLast();
    }
    void clear() {
        list.clear();
    }
}