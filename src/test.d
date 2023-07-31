module test;


import test_fibres;
import test_hashmap;
import test_list;
import test_linkedlist;
import test_queue;
import test_stack;
import test_threads;

import betterc;

extern(C):
@nogc:
nothrow:

void main(int argv, char** args) {

    // testQueue();
    //testList();
    // testStack();
    // testLinkedList();

    // testThread();
    // testFibres();

    testHashMap();
}
