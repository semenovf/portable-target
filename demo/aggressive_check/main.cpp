#include <algorithm>
#include <iostream>
#include <vector>
#include <cstdio>
#include <cstring>

auto main () -> int
{
    // FIXME No any alert
    {
        printf("{%c}\n", 1024); // output {}
    }

    // FIXME No any alert
    {
        printf("[%lf]\n", 1.0); // output [1.000000]
    }

    // At runtime
    //      gcc Error: elements in iterator range [__first, __last) are not partitioned by
    //              the value __val.
    {
        int arr[] = { 3, 1, 2 };
        std::cout << std::binary_search(arr, arr + 3, 2) << std::endl;
    }

    // At compile time:
    //      gcc warning: ‘void* __builtin___memcpy_chk(void*, const void*, long unsigned int, long unsigned int)’ writing 10 bytes into a region of size 9 overflows the destination [-Wstringop-overflow=]
    // At runtime:
    //      gcc *** buffer overflow detected ***: ./aggressive_check terminated
    {
        char s[9];
        strcpy(s, "too large");
        std::cout << s << std::endl;
    }

    // At runtime:
    //      gcc runtime error: index 3 out of bounds for type 'int [3]'
    {
        int arr[3];

        for (int i = 0; i <= 3; i++) {
            arr[i] = i;
            std::cout << arr[i] << " ";
        }

        std::cout << std::endl;
    }

    // Here will be output in runtime:
    // Error: attempt to subscript container with out-of-bounds index 7, but
    // container only holds 3 elements.
    {
        std::vector<int> v(3);
        std::cout << v[7] << std::endl;
    }

    // At compile time:
    //      gcc warning: ‘p’ may be used uninitialized in this function [-Wmaybe-uninitialized]
    // At runtime:
    //      gcc runtime error: load of null pointer of type 'int'
    {
        int * p;
        std::cout << *p << std::endl;
    }

    // Check duplicate condition
    {
        auto n = 1;

        if (n == 1)
            std::cout << "Hello, World!\n";
        else if (n == 1) // <-- g++ warning: duplicated ‘if’ condition [-Wduplicated-cond]
            std::cout << "Hello, World!\n";
    }

    return 0;
}
