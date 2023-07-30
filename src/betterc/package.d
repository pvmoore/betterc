module betterc;
/**
 *  https://dlang.org/spec/betterc.html
 */

/**
 *  Unavailable features:
 *
 *  - Garbage Collection
 *  - TypeInfo and ModuleInfo
 *  - Classes
 *  - Built-in threading (e.g. core.thread)
 *  - Dynamic arrays (though slices of static arrays work) and associative arrays
 *  - Exceptions
 *  - synchronized and core.sync
 *  - Static module constructors or destructors
 */

public:

version(D_BetterC)          {} else static assert(false, "enable -betterC");
version(D_InlineAsm_X86_64) {} else static assert(false, "Supports x86_64 only");

extern(C):
@nogc:
nothrow:

import betterc.array;
import betterc.freelist;
import betterc.HashMap;
import betterc.linkedlist;
import betterc.list;
import betterc.queue;
import betterc.stack;
import betterc.stream;
import betterc.util;

//int printf(immutable(char)* format, ...);
import core.stdc.stdio  : printf, snprintf;
import core.stdc.stdlib : calloc, malloc, realloc, free;
import core.stdc.string : memset, memmove, memcpy, memcmp;

// void log(A...)(string fmt, A args) nothrow {
//         try{
//     	    doLog(format(fmt, args));
//     	}catch(Exception e) {}
//     }

void panic(string msg) {
    printf("PANIC!!! ");
    printf(msg.ptr);
    printf("\n");

    import core.stdc.stdlib : exit;
    exit(-1);
}
