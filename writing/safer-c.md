
# `CFLAGS` &mdash; Greatest Hits

Consider the following C program. Also consider the fact that by default,
it compiles and runs without warning (`gcc -O2`).

```
#include <stdio.h>

int main(void) {
    int x[10] = { 0 };
    printf("%d\n", x[100]);
}

```

As the saying goes, 


https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html


```
#  What language version are we using?
CFLAGS += -std=gnu17

#  These are the basics that cover mostly everything
CFLAGS += -Wall -Wextra -Wpedantic

#  More opinionated, but warnings should not be ignored
CFLAGS += -Werror

## Now we get into the bulk of the warnings
```
