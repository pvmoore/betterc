module betterc.asserts;

@nogc:
nothrow:

import betterc.all;

void expect(bool actual, string file = __FILE__, int line = __LINE__) {
    version(assert)
    if(!actual) {
        expectCommon("Expected true but was false".ptr, file, line);
    }
}
void expectFalse(bool actual, string file = __FILE__, int line = __LINE__) {
    version(assert)
    if(actual) {
        expectCommon("Expected false but was true".ptr, file, line);
    }
}
void expect(bool expected, bool actual, string file = __FILE__, int line = __LINE__) {
    version(assert)
    if(actual != expected) {
        if(expected) {
            expectCommon("Expected true but was false".ptr, file, line);
        } else {
            expectCommon("Expected false but was true".ptr, file, line);
        }
    }
}
void expect(T)(T expected, T actual, string file = __FILE__, int line = __LINE__)
    if(isPrimitiveType!T && !is(T==bool))
{
    version(assert)
    if(actual != expected) {
        static char[1024] temp;
        static if(isFloatingPoint!T) string fmt = "Expected %f but was %f";
        else static if(is(T==long)) string fmt = "Expected %lld but was %lld";
        else static if(is(T==ulong)) string fmt = "Expected %llu but was %llu";
        else static if(is(T : int)) string fmt = "Expected %d but was %d";
        else static if(is(T : uint)) string fmt = "Expected %u but was %u";
        else static assert(false);

        snprintf(&temp[0], temp.length, fmt.ptr, expected, actual);
        expectCommon(&temp[0], file, line);
    }
}
void checkBounds(T)(T value, T min, T maxExclusive, string file = __FILE__, int line = __LINE__)
    if(is(T==int) || is(T==uint) || is(T==long) || is(T==ulong))
{
    version(assert)
    if(value < min || value >= maxExclusive) {
        static char[1024] temp;
        static if(is(T==long)) string fmt = "%lld is not in the range [%lld to %lld)";
        else static if(is(T==ulong)) string fmt = "%llu is not in the range [%llu to %llu)";
        else static if(is(T==int)) string fmt = "%d is not in the range [%d to %d)";
        else static if(is(T==uint)) string fmt = "%u is not in the range [%u to %u)";
        else static assert(false);

        snprintf(&temp[0], temp.length, fmt.ptr, value, min, maxExclusive);
        expectCommon(&temp[0], file, line);
    }
}
private void expectCommon(inout char* msg, string file = __FILE__, int line = __LINE__) {
    version(assert) {
        import core.stdc.stdlib : exit;

        printf(ANSI_RED_BOLD);
        printf("\n!!! Assertion failed -->");
        printf(ANSI_RESET);
        printf(" %s:%d", file.ptr, line);
        printf("\u001b[0m");
        if(msg) {
            printf(": '%s'\n", msg);
        } else {
            printf("\n");
        }
        printf("\n");
        exit(-1);
    }
}
