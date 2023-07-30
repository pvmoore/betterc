module betterc.async.fibres.all;

public:
@nogc:
nothrow:
extern(C):

import betterc.all;
import betterc.async.all;
import betterc.async.fibres;

private import core.sys.windows.windows;

extern(Windows) {
    LPVOID ConvertThreadToFiberEx(
        LPVOID lpParameter,
        DWORD  dwFlags
    );
}
