module betterc.util;

/*──────────────────────────────────────────────────────────────────────────────────────────────────
  Template utilities
────────────────────────────────────────────────────────────────────────────────────────────────────

isArray
isBoolean
isFloatingPoint
isInteger
isPointer
isSigned
isString
isStruct
isUnsigned

hasMethod
hasMethodWithName

as
heapAlloc
isPowerOf2

──────────────────────────────────────────────────────────────────────────────────────────────────*/

public:

import std.traits : isArray,
                    isBoolean,
                    isFloatingPoint,
                    isPointer,
                    isSigned,
                    isUnsigned;

T as(T,I)(I o) {
    return cast(T)o;
}

T* heapAlloc(T)() {
    return cast(T*)calloc(1, T.sizeof);
}

bool isPowerOf2(T)(T v)
    if(isInteger!T)
{
   return !(v & (v - 1)) && v;
}

template isStruct(T) {
	const bool isStruct = is(T==struct);
}
template isPrimitiveType(T) {
    const bool isPrimitiveType =
        is(T==bool)  ||
        is(T==byte)  || is(T==ubyte) ||
        is(T==short) || is(T==ushort) ||
        is(T==int)   || is(T==uint) ||
        is(T==long)  || is(T==ulong) ||
        is(T==float) || is(T==double) || is(T==real);
}
template isInteger(T) {
    const bool isInteger =
        is(T==byte)  || is(T==ubyte) ||
        is(T==short) || is(T==ushort) ||
        is(T==int)   || is(T==uint) ||
        is(T==long)  || is(T==ulong) ||

        is(T==const(int));
}
template isString(T) {
    const bool isString = isSomeString!T;
}

/**
 * Returns true if the type has a method with the given name regardless of return type or parameters.
 *
 * assert(hasMethodWithName!(A,"bar"));
 */
bool hasMethodWithName(T,string M)()
    if(isStruct!T)
{
    static if(__traits(hasMember, T, M)) {
        return isSomeFunction!(__traits(getMember, T, M));
    } else {
        return false;
    }
}

/**
 * Returns true only if the type has a method with the given name and the given return type and parameters.
 * Note that the types do not have to explicitly match if they can be converted to the required types.
 *
 * assert(hasMethod!(A,"bar", void, float, bool));
 */
bool hasMethod(T, string NAME, RET_TYPE, PARAMS...)() {
    bool result = false;
    bool temp;
    static if(isStruct!T && hasMethodWithName!(T,NAME)) {

        /* Look at all overloads */
        static foreach(func; __traits(getOverloads, T, NAME)) {

            static if(is(ReturnType!func : RET_TYPE)) {
                static if(PARAMS.length == Parameters!func.length) {
                    temp = true;

                    static foreach(i, p; Parameters!func) {
                        static if(!is(p : PARAMS[i])) {
                            temp = false;
                        }
                    }
                    result |= temp;
                }
            }
        }
    }
    return result;
}

/**
 * obj.let
 */
// alias LET_FUNC(T) = extern(C) void function(T arg) @nogc nothrow;
// void let(T)(T arg, LET_FUNC!T d) if(isPointer!T) {
//     if(arg) {
//         d(arg);
//     }
// }

private:

import std.traits : isSomeFunction,
                    isSomeString,
                    Parameters,
                    ReturnType;
import betterc.all;