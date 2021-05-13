
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

Remembering this, I thought that maybe the current implementation (which definitely did not use executable code on the stack) might still have access to the user's stack through the stack pointer. If I could get access to the saved registers of the interrupted process inside of an interrupt handler, I could track the instruction pointer.

Unfortunately, it appears that in modern versions of Linux, signal handlers are executed in a separate region of the stack and I could not find a way to reliably gain access to the "main" stack. In addition, it seems that upon interrupt, registers are spilled to a separate kernel stack that would be totally inaccessible to the interrupt handler.

### Man Page Hunting

After I verified via `gdb` that I could not partially "unwind" the interrupt stack to get to the interrupted function, I let the project go for a few weeks. Eventually, after much searching, I ran across a stack overflow post that had a very interesting code example that made everything possible.


### Mapping %rip -> symbol


### Keeping Track (async-signal-safely)