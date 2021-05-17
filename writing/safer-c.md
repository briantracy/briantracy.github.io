
# Writing Safer C Code

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
