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

enum ANSI_RED_BOLD = "\u001b[31;1m".ptr;
enum ANSI_RESET    = "\u001b[0m".ptr;

void panic(string msg) {
    printf("PANIC!!! ");
    printf(msg.ptr);
    printf("\n");

    import core.stdc.stdlib : exit;
    exit(-1);
}
void cassert(bool expectedBool, 
             string msg = null, 
             string file = __FILE__,
             int line = __LINE__) {
    if(!expectedBool) {
        import core.stdc.stdlib : exit;
        printf(ANSI_RED_BOLD);
        printf("\n!!! Assertion failed -->");
        printf(ANSI_RESET);
        printf(" %s:%d", file.ptr, line);
        printf("\u001b[0m");
        if(msg) {
            printf(": '%s'\n", msg.ptr);
        } else {
            printf("\n");
        }
        printf("\n");
        exit(-1);
    }
}