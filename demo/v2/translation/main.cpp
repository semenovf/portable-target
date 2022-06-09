#include <string>
#include <libintl.h>
#include <cstdio>
#include <clocale>
#include <cstdarg>
#include <cstdlib>

//
// `xgettext` can recognizes keywords in format `NS::keyword` ignoring namespace
// name `NS`. So this feature can be used in the way implemented in this demo.
//

namespace tr {

inline char * _ (char const * msgid)
{
    auto x = gettext(msgid);
    return x;
}

inline char * n_ (char const * msgid, char const * plural, unsigned long int n)
{
    return ngettext(msgid, plural, n);
}

inline char * f_ (char const * msgid, ...)
{
    static char __buf[256];

    va_list args;
    vsprintf(__buf, gettext(msgid), args);
    va_end(args);

    return __buf;
}

constexpr char const * noop_ (char const * msgid) { return msgid; }

}

static char const * static_string = tr::noop_("Demo");

int main ()
{
    auto domaindir = std::string{getenv("PWD")} + "/locale";

    // NOTE! LC_ALL gives success result instead of LC_MESSAGES
    //auto loc = std::setlocale(LC_MESSAGES, "");

    auto loc = std::setlocale(LC_ALL, "");
    //auto loc = std::setlocale(LC_ALL, "ru_RU.UTF-8");
    //auto loc = std::setlocale(LC_ALL, "ru_RU.utf8");

    //                  ------------------ Basename for mo-file
    //                  |          ------- Better use absolute path for dirname
    //                  |          |
    //                  v          v
    bindtextdomain("translation", domaindir.c_str());
    auto tdom = textdomain("translation");

    std::printf("Locale: %s\n", loc);
    std::printf("Domain dir: %s\n", bindtextdomain("translation", nullptr));
    std::printf("Text domain: %s\n", tdom);

    std::printf("%s\n", tr::_(static_string));
    std::printf("%s\n", tr::_("Hello, World!"));
    std::printf(tr::n_("%d day left\n", "%d days left\n", 0), 0);
    std::printf(tr::n_("%d day left\n", "%d days left\n", 1), 1);
    std::printf(tr::n_("%d day left\n", "%d days left\n", 2), 2);
    std::printf(tr::n_("%d day left\n", "%d days left\n", 5), 5);
    std::printf(tr::n_("%d day left\n", "%d days left\n", 42), 42);

    // FIXME Segmentation fault (core dumped)
//     std::printf("%s\n", tr::f_("Hello, %s!", "Vladislav"));

    return 0;
}
