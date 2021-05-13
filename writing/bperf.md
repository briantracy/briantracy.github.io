
# bperf &mdash; Bad Performance Profiler


This writeup will walk through the implementation of a basic performance profiler for C programs.

### Motivation

One of the more interesting topics I learned about in school is Linux's dynamic loader (`ld.so`). Symbol resolution (the act of converting a symbols textual name to its address) seemed especially fascinating and I wanted to make use of it in a project. By combining the dynamic loader with frequent interrupts, I thought I could gauge the performance of a program by periodically determining which function was currently executing.

### Goals

Ideally I would be able to modify a program minimally (just add a call to `perf_start()` and `perf_stop()`), run it, then see a nice output telling me what parts of the program were running for the longest.

### Sampling Theory

The theory behind a sampling profiler is fairly straightforward: if you want to know what a program is spending its time doing, all you have to do is ask! If you check in on the program periodically and mark down which function is currently executing, you will be able to paint a picture of which functions are "on the CPU" most often.


```
                       (---> Time --->)

samples: a  a  a  b  a  a  b  b  b  c  c  a  a  a  a  a
         |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
         v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
        +-------+---+---+--------+-----+--------+-------+
        |   a   | b | a |    b   |  c  |    a   |   a   |
        +-------+---+---+--------+-----+--------+-------+
                        (Function on CPU)


Results:
    a - 10 ticks
    b - 4  ticks
    c - 2  ticks
```


If you notice that you interrupted function `A` 5 times as often as function `B`, it follows that function `A` was being executed roughly for 5 times as long as function `B`

*Aside: It is worth noting that the sampling rate is critical to the accuracy of the final metrics. Consider a program that has two functions, `F` and `J`. `F` runs for 9ms, then `J` runs for 1ms. If you are sampling the program every 10ms and get "unlucky", you could interrupt the program only when `J` is running, and conclude that is was running 100% of the time. If you sampled once per 1ms, this error goes away.*


To make this idea concrete, we can use software interrupts to "check in" on a program periodically, and instruction pointer tracking to see what program is being interrupted.

The high level algorithm looks like this:

```
profile($program):
    map<function,int> samples
    every 10 ms:
        interrupt $program
        fn = $program->last_executed_function
        samples[fn]++
        resume $program
```

### First Attempt

The first problem I wanted to solve was determining what function was interrupted while executing inside a signal handler.

I recalled hearing an anecdote from my operating systems professor about how the adoption of Non-eXecutable Memory (often referred to as NX) broke some operating systems due to the way they were handling signals. The design was that whenever a signal had to be sent to a process that did not have a user defined handler, the code of the default handler would literally be pushed on to the userspace stack and then executed.

Remembering this, I thought that maybe the current implementation (which definitely did not use executable code on the stack) might still have access to the user's stack through the base pointer (stack unwinding). If I could get access to the saved registers of the interrupted process inside of an interrupt handler, I could track the instruction pointer.

Unfortunately, it appears that in modern versions of Linux, signal handlers are executed in a separate region of the stack and I could not find a way to reliably gain access to the "main" stack. In addition, it seems that upon interrupt, registers are spilled to a separate kernel stack that would be totally inaccessible to the interrupt handler.

### Man Page Hunting

After I verified via `gdb` that I could not partially "unwind" the interrupt stack to get to the interrupted function, I let the project go for a few weeks. Eventually, after much searching, I ran across a stack overflow post that had a very interesting code example that made everything possible.

It turns out that the `sigaction` structure that is passed into the `sigaction` syscall (to install an interrupt handler) can receive a flag of `SA_SIGINFO` that tells the kernel to pass the context of the interrupted process into the signal handler. The man page for `sigaction` has great information on this.


### Accessing the Instruction Pointer

With the correct flag to `sigaction`, our interrupt handler is now a three argument function whose final arg can be cast to a magical `ucontext_t *`.

After implementing a tiny OS as an assignment in school, I was positive that such a structure should exist. The first instructions of the kernel's hardware interrupt handler looked like `push %reg1; ... ; push %regN`, so all the data I was after had to be somewhere. Finding this data though took 95% of the total project time.


Here is the syntax for poking into the `ucontext_t` structure.

```
void handler(int signum, siginfo_t *info, void *ctx) {
    // lol @ "greg"
    greg_t const rip = ((ucontext_t *)ctx)->uc_mcontext.gregs[REG_RIP];
    ...
```

### Mapping %rip -> symbol (`ld.so`)

Now that I could determine the instruction pointer just prior to the interrupt, I had to convert this to a function name. This is where the dynamic loader comes into play. The `dladdr` function (not POSIX, GNU specific) asks the dynamic loader to find the closest symbol **below** the given address. While we are executing a function, this "closest symbol below" will be the name of the function.

```
Dl_info info;
int const s = dladdr((void *)rip, &info);
const char *const function_name = info.dli_sname;
```

*Aside: `dladdr` returns 1 on success and 0 on failure. Yikes*


### Keeping Track (async-signal-safely)

Now that we have the name of the function currently on the CPU at every interrupt, we need to keep track of this data.

Originally, I was thinking of rolling my own hash map implementation (as an exercise) to map the `const char *` of a function's name to the `int` number of times it has been called. This started out fine, but then I realized that all bookkeeping code was being executed inside of a signal handler, which meant that the number of library functions I could call was extremely limited.

For example, I was planning on using `malloc` to create the hash entries, but you can't call that function as it is not signal safe. To get around this, I took the easy way out and statically allocated space for 100 entries and got on with it. The performance is bad (to record a call, you have to iterate through all the existing entries), but it works.


### API

Now that the data collection is done, here is the public API for `bperf`:

```
void bperf_start();   // install signal handler, start timer
void bperf_stop();    // uninstall signal handler
void bperf_display(); // prints output / graphs
```

### Benchmark

With the profiler in a working state, I needed a benchmark program to run it on. It needed to be CPU bound and have obviously bottlenecked functions, so I came up with the following scheme.

Create four functions called `tinywork`, `leastwork`, `middlework`, `mostwork`, each of which is essentially a busy CPU loop where a counter is incremented to a large number. `tinywork` runs for `1<<20` iterations, `leastwork` for 8x as many (`1<<23`), `middlework` for twice as many as `leastwork`, and `mostwork` for twice as many as `middlework`. Finally, there is `in_kernel` which just reads a huge number of bytes from `/dev/urandom`.

Each of these functions are called 10 times while the program is being profiled. We expect to see nearly linear scaling in CPU time between the `*work` functions as they are all doing the same thing, just for different amounts of time.

### Output

```
$ ./bench
bperf tracked 5 functions with 679 total samples
      name  | #calls | %calls | graphic
   tinywork   11       1.62    [          ]
  leastwork   89       13.11   [#         ]
 middlework   180      26.51   [##        ]
   mostwork   366      53.90   [#####     ]
     __read   33       4.86    [          ]
```

Wow! The resulting percentages are almost exactly in the series that was expected: 8x, 2x, 2x, 2x!

Also, note the precision of the measurements. `bperf` can pick up a wide range from over 50% all the way down to 1%, so we are not "losing" anything to the noise.

### Frequency of Interrupts