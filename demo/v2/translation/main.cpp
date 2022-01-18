#include "translate.h"
#include <cstdio>

auto main () -> int
{
    std::printf(TR_("Hello, World!\n"));
    std::printf(TRn_("%d day left\n", "%d days left\n", 0), 0);
    std::printf(TRn_("%d day left\n", "%d days left\n", 1), 1);
    std::printf(TRn_("%d day left\n", "%d days left\n", 2), 2);
    std::printf(TRn_("%d day left\n", "%d days left\n", 5), 5);
    std::printf(TRn_("%d day left\n", "%d days left\n", 42), 42);
    return 0;
}
