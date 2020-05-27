
# bthreads &mdash; Bad Threading Library

This writeup will walk through how to make an extremely barebones threading
library for programs running on Linux, without support from `pthreads` or the
`futex` syscall. 


### Motivation

This year in school, I was exposed to many different "flavors" of systems
programming (OS, formal methods of verification, databases, networks, ...). By far the most interesting was the topic of how a uni/multi processor system can support multiple threads of execution. Particularly, the concept of mutual exclusion was intriguing, and I thought it would be a cool project to try to implement my own mutex using commonly available hardware features.

Of course, a mutex isn't very interesting if you don't have multiple threads of
control competing for it, so in order to test the mutexes I was creating,
I also needed a way to create threads. This inspired the rest of the "library".

Code snippets presented in this writeup are distilled versions of the full library. They capture the critical points, but if you want to follow along in full, [you can view the source here](https://github.com/briantracy/bthread).


### Setup

I wanted the following three features in `bthreads`:

1. The ability to create threads
2. The ability to join these threads 
3. The ability to synchronize these threads via mutexes

This pretty much dictates the public API of `bthreads` as follows:

```
int  bthread_create(int (*thread_func)(void *), void *thread_arg);
void bthread_collect();

void bthread_mutex_lock(bthread_mutex *mtx);
void bthread_mutex_unlock(bthread_mutex *mtx);
```

For the sake of simplicity, joining threads is done all at once in
`bthread_collect`, which should be called by the main thread before it exits.


### Creating Threads

A goal of threads is to have multiple concurrent instruction streams, all
with the capability of accessing a shared piece of memory. One method for accomplishing this would be to use `fork` to create a new process
for each thread, then use `mmap` to map in a shared memory region into each
process' address space.

This approach felt a little clunky as the shared memory regions would have to be explicitly "named" by client programs (i.e: please create a new process, and map *these* chunks of my address space into the child). 

Instead of manually performing mappings for memory that the threads would like to share, we can ask the kernel to place the threads inside of the parent's address space via the `clone` system call.

*Aside: The concept of "clone" throws a wrench in the traditional distinction between threads and processes students are initially introduced to. For example, the objects created by clone have their own distinct process ids, yet they can all be running within the same address space! One explanation I have read is that the process vs thread distinction is really a user space abstraction, and that the kernel sees both types of objects as simply "tasks". This thread/process duality is used below with respect to creation/joining.*

With `clone`, thread creation distills down to a single call of the following
form:

```
int child_pid = clone(
    thread_func, (void *)stack_top,
    CLONE_VM | SIGCHLD,
    thread_arg
);
```

`thread_func` is the function the user would like to run in the new thread,
`stack_top` points to a region of the address space that was previously
allocated for this thread to run inside of, and the flags passed in are as follows:

1. `CLONE_VM`: Tells the kernel to run this thread in the same address space as the one in which it was created. This follows the classical "thread-like" model.
2. `SIGCHLD` tells the kernel to ensure that when the newly created thread exits, `SIGCHLD` should be sent to the parent. This allows the parent to `wait` upon the child as if we were using the classical "process-like" model.

`bthread_create` is just a wrapper around `clone` that creates the stack and passes in the right flags.

So now we have the capability to fracture one address space into many stacks,
have a thread running on each stack, and have all the threads access the same
shared memory.

*Aside: At this point (no synchronization), our little library is quite dangerous as the client has no way to prevent data races between all that shared memory.*

### Joining Threads

Before the main thread (the one that spawned all the others via `btrhread_create`) exits, we would like all of the children to terminate. The
common description of this action would be to say that we want to have the parent thread "join with" the child threads (see `pthread_join`).

Due to the thread/process duality that is a result of `clone`, we can leverage
the standard `wait` family of system calls to simulate joining with threads.

Assuming we have a list of the pids from all of the `clone` calls (`thread_ids` below), as well as the total number of threads created (`next_tid` below), we
can repeatedly call `wait` to collect all of them.

```
for (int i = 0; i < next_tid; i++) {
    int status;
    if (waitpid(thread_ids[i], &status, 0) == -1) {
        fprintf(stderr, "... failed to join with thread %d\n", i);
    }
    fprintf(stderr, "... thread %i exited with value %d\n", i, WEXITSTATUS(status));
}
```

*Aside: Technically, the call to `WEXITSTATUS` has no meaning unless the process cleanly exited (as apposed to being killed by a signal), but this is
glossed over for simplicity's sake. In fact, most things about this "library"
completely ignore best practices in favor of greater readability.*

Now that our threads can be spawned, and then reigned in when they are done working, we can move on to synchronizing the threads during their execution.


### Implementing Mutexes (Overview)

To implement a mutex, we need some help from the hardware (*Note: this is false in certain situations: <https://en.wikipedia.org/wiki/Peterson%27s_algorithm>*). x86 provides the `lock` prefix for instructions, which allows for atomic memory access. This is essential because to properly
implement a synchronization object, there needs to be a way to impose an order
on the otherwise chaotic nature of multi processor memory access. The following
scenario needs to be avoided at all costs:

1. Thread 1 arrives at the beginning of the critical section and sees that the mutex is unlocked.
2. Thread 1 claims the mutex, and says to everyone else "this is now locked".
3. Before Thread 2 hears the proclamation that "this is now locked", it approaches the critical section and sees that it is open.
4. Thread 2 claims the mutex and joins Thread 1 in the critical section.

The crux of the issue is that the act of noticing that the mutex is unlocked, and then proceeding to lock it (steps 1 and 2 above), is not instantaneous. In the short window between these actions, another thread may also see that the mutex is unlocked and enter the critical section.

The solution is to combine these two steps into one **atomic** action (or at least a sequence of actions that appear to be atomic).

### Compare and Exchange (mnemonic `cmpxchg`)

The `cmpxchg %reg, dest` instruction compares the current value of the accumulator to the value in `dest` (either another register or a location in memory). If the two are equal, the value in `%reg` (any general purpose register) is stored into `dest`. If they are not equal, the value in `dest` is loaded into the accumulator.

Note that the value in the accumulator after the execution of a `cmpxchg` will always be equal to the value that was in `dest` before the instruction (in one case, they were already equal. In the other, `dest` is put into the accumulator). In addition, the contents of `%reg` are never changed. 

*Aside: The AT&amp;T style syntax is used*

Here are two examples showing the two possible execution paths of a compare and exchange (one where the accumulator is equal to the destination, and one where they differ). In both examples, we will use three registers to demonstrate:

1. The "test subject", whose value we are interested in.
2. The "test value", a number we want to compare with the test subject.
3. The "new value", a number that will replace the test subject if the comparison succeeds.

**Example 1:** Test Value &ne; Test Subject 
```
mov     $0x1,%eax     ; eax = 1  (test value)
mov     $0x7,%ebx     ; ebx = 7  (new value)
mov     $0x9,%ecx     ; ecx = 9  (test subject)
cmpxchg %ebx,%ecx     ; bang

; *** NEW VALUES ***
; eax = 9  (changed!!)
; ebx = 7  (unchanged)
; ecx = 9  (unchanged)

```

**Example 2:** Test Value = Test Subject 
```
mov    $0x1,%eax      ; eax = 1 (test value)
mov    $0x7,%ebx      ; ebx = 7 (new value)
mov    $0x1,%ecx      ; ecx = 1 (test subject)
cmpxchg %ebx,%ecx     ; bang

; *** NEW VALUES ***
; eax = 1 (unchanged)
; ebx = 7 (unchanged)
; ecx = 7 (changed!!)
```

### Lock State

If we represent the lock state of a mutex as a number (0 = unlocked, 1 = locked), then the act of checking if a mutex is locked, and then subsequently locking it, can be done via a compare and exchange.

```
mov $0, %eax         ; 0 = unlocked (comparing mtx state with this)
mov $1, %ebx         ; 1 = locked   (hopefully set mtx state to this)
                     ; given: %ecx holds the location
                     ; of the mutex state
cmpxchg %ebx, (%ecx)

; %eax now holds the value of the previous mtx state
; so if we compare it with 0 (unlocked), this means that
; the mutex was unlocked, and that we successfully locked it
cmp %eax, $0
je .got_mutex
; if %eax is 1, this means that the mutex was locked
; when we checked it.
```

### Implementation in C

An easy way to have the compiler emit a `cmpxchg` instruction is to manually direct it to do so with an in-line assembly block. Assuming that the lock
state of our mutex is located in the variable `mtx->locked`, the following
code will attempt to lock the mutex one time.

```
int existing_value = -1;
asm volatile (
    "movl $0, %%eax;"
    "movl $1, %%edx;"
    "lock cmpxchg %%edx, %0;"
    "movl %%eax, %1;"
    : "=m" (mtx->locked), "=r" (existing_value)
    :
    : "eax"
);
// previous lock state now in existing_value
```

This construct currently only tries once for the mutex. This would not be useful in the most general case (*for the non general case, see `pthread_mutex_trylock`*), but provides the core of what will become a spin lock.

To force a thread to wait until it acquires the mutex, we can simply wrap the
above construct in an infinite loop, halting the threads process until it acquires the mutex.
```
void spin_lock(mutex *mtx) {
    while (1) {
        int existing_value;
        <... inline asm from above ...>
        if (existing_value == 0) {
            // got the mutex
            return;
        }
    }
}
```

That is roughly the entirety of `bthreads`: a call to `clone`, a call to `wait`, and one `cmpxchg` instruction.


### Sample Program

Here is a sample program (`client.c`) that uses all three features of the `bthreads` library.

*Aside: The `print` function used below is not included for brevity's sake*

```
// Will automatically be initialized to have its
// locks state set to 0 (unlocked).
bthread_mutex mtx;
// This variable will be modified by all threads
int protect_me = 12;
// Total number of times a thread enters the critical
// section. Used to make sure all the threads actually
// get a chance to modify the shared memory.
int critical_section_count = 0;

int thread_fun(void *arg) {
    print("hello", (char *)arg);
    for (int i = 0; i < ITERS; i++) {
        bthread_mutex_lock(&mtx);
        critical_section_count++;
        assert(protect_me == 12);
        protect_me++;
        assert(protect_me == 13);
        protect_me--;
        assert(protect_me == 12);
        bthread_mutex_unlock(&mtx);
    }
    print("goodbye", (char *)arg);
    exit(0);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s [threadname1] ... [threadnameN]\n", argv[0]);
        return 1;
    }
    const int nthreads = argc - 1;

    printf("I am the parent, my pid is %d\n", getpid());

    for (int i = 0; i < nthreads; i++) {
        int s = bthread_create(&thread_fun, argv[i + 1]);
        if (s == -1) {
            fprintf(stderr, "thread creation failed\n");
            bthread_collect();
            exit(1);
        }
    }
    
    bthread_collect();
    assert(critical_section_count == nthreads * ITERS);
}
```

When run, we get the following output.

```
$ gcc client.c bthread.c -o client
$ ./client a b c d e f g
I am the parent, my pid is 2991
collecting threads ...
hello from pid 2998, name=g
hello from pid 2994, name=c
hello from pid 2995, name=d
hello from pid 2997, name=f
hello from pid 2996, name=e
hello from pid 2992, name=a
hello from pid 2993, name=b
goodbye from pid 2996, name=e
goodbye from pid 2995, name=d
goodbye from pid 2993, name=b
goodbye from pid 2992, name=a
goodbye from pid 2994, name=c
... thread 0 exited with value 0
... thread 1 exited with value 0
... thread 2 exited with value 0
... thread 3 exited with value 0
... thread 4 exited with value 0
goodbye from pid 2998, name=g
goodbye from pid 2997, name=f
... thread 5 exited with value 0
... thread 6 exited with value 0
... bye
```

For some semblance of proof that the mutex is actually working, when the line that locks the mutex is commented out, this is the output.

*Aside: I think this is technically undefined behavior (unprotected read/writes to shared memory from multiple threads), see the end for more on that.*

```
I am the parent, my pid is 3024
collecting threads ...
hello from pid 3025, name=a
hello from pid 3026, name=b
hello from pid 3027, name=c
hello from pid 3028, name=d
client: client.c:38: thread_fun: Assertion `protect_me == 12' failed.
hello from pid 3029, name=e
hello from pid 3030, name=f
hello from pid 3031, name=g
Aborted
```


This is the end of the informative section of the writeup. I will now move
on to the explorative (read: I don't know what's happening, so I can't speak with any confidence) section. If you see anything suspect, please let me know as I want to get to the bottom of this.

---


### Measuring Performance

What does it mean for a spin lock to be "fast"? When a thread is blocked on a spin lock, it is not making any progress, so it is not clear how one could talk about speed in this context.

How long a thread waits at the edge of a critical section is a function of what other threads are doing inside, so that is not really up to the implementation of the mutex.

One way to measure performance of a spin lock could be to see how the overall system is impacted by threads waiting at a spin lock. The only thing the `bthread_mutex_lock` function does is repeatedly execute a `lock cmpxchg`, so if a bottleneck exists, it will be here.


### Lock Prefix and Atomic Memory Access

Without a deep knowledge of how the processor implements `lock`ed instructions, it feels safe to assume that instructions that modify memory atomically are "slower" than those that modify memory non-atomically.

*Aside: My weak argument for this claim is that if atomic memory access were just as fast as non-atomic access, it would be the default. In addition, my basic understanding of caching layers tells me that wrangling the caches on a set of processors in such a way that we don't write to the same location simultaneously is a non trivial task.*

Additionally, atomically modifying memory might not only be slower for the executing thread, but it might slow down the rest of the threads on the system 

*Aside: An argument for this claim would be that other threads attempting to access the same memory need to be prevented from doing so until the "atomic thread" has done its work.*

So an initial optimization might be to reduce the number of atomic memory accesses a given thread is performing while waiting at a spin lock.

Keeping in mind that the worst case scenario for a mutex is a false positive (a thread thinks the mutex is open and enters prematurely) and that a false negative scenario (a thread believes the mutex is locked, when in reality, it is unlocked), we can relax the constraints on mutex acquisition logic to favor a false negative.

If allowing more false negatives (but never relaxing our intolerance of false positives) improves performance, this would be a fair tradeoff. To do this, we can perform normal, non-atomic memory accesses in our spin loop, and only when they say that the mutex is unlocked do we perform an atomic memory access to verify.

```
// Un-optimized
while (1) {
    ...
    // perform an atomic cmpxchg every iteration
}

// optimized
while (1) {
    if (mtx->locked != 0) {
        // regular memory access tells us that the
        // mutex is locked. Instead of atomically
        // verifying this assumption (which is most likely true)
        // just wait a few more cycles.
        continue;
    }
    // regular memory access tells us that the mutex
    // is unlocked! We are hopeful at this point, but
    // need to atomically verify.
    ...
    // perform an atomic cmpxchg
}

```

This reduces the number of atomic operations that are performed, without jeopardizing the strict no-false-positive semantics.

### Benchmark

To see if this optimization makes a difference, I cooked up a benchmark where while in the critical section, each thread performs a huge number of reads and writes. The memory operations are structured such that the order is completely random (to reduce predictive caching) and the search space (`ARRAY_SIZE`) is large enough to prevent locality based caching.

The goal here is to "slam the memory bus" to aggravate any adverse side effects that performing a `lock`ed instruction might have on the rest of the system.

```
int massive_array[ARRAY_SIZE];
static unsigned long total = 0;
void slam_bus() {
    // Perform lots of writes and reads to memory
    // Try to avoid hitting caches.
    int idx = rand() % ARRAY_SIZE;
    for (int i = 0; i < BUS_SLAM_ROUNDS; i++) {
        int next_idx = massive_array[idx];
        // next thread that comes here will go somewhere totally different
        massive_array[idx] = (ARRAY_SIZE - 1) - massive_array[idx];
        idx = next_idx;
        total += idx;
    }
}

bthread_mutex mtx;
int protect_me = 12;

int thread_fun(void *arg) {
    (void)arg;
    for (int i = 0; i < THREAD_FUNC_REPS; i++) {
        bthread_mutex_lock(&mtx);
        assert(protect_me == 12);
        protect_me++;
        assert(protect_me == 13);
        protect_me--;
        assert(protect_me == 12);

        slam_bus();

        bthread_mutex_unlock(&mtx);
    }
    exit(0);
}
```

To see the results, I compile one benchmark with the optimization and one without.

```
$ diff bthread-with-opt.c bthread-without-opt.c 
141c141
<         if (mtx->locked != 0) { continue; }
---
>         //if (mtx->locked != 0) { continue; }

$ gcc benchmark.c bthread-with-opt.c && time ./a.out
            <output trimmed>
... bye
total = 1638299986875

real    0m17.612s
user    0m35.155s
sys 0m0.021s

$ gcc benchmark.c bthread-without-opt.c && time ./a.out
            <output trimmed>
... bye
total = 1638299986875

real    0m30.714s
user    1m1.370s
sys 0m0.025s
```

So the optimized version is definitely faster. How much faster is a function of what we are doing in the critical section, and how many threads are spinning in wait.


This is the end of the explorative section. Moving forward, I will be discussing the things that I can't make any sense out of.

---


### Optimization

All of the examples shown have been compiled without optimizations. Applying even `-O1` breaks the programs, but not because of an issue with the mutex functions (the optimizations `gcc` makes are really readable. It almost looks hand written):

```
$ gcc -c -O1 bthread.c && objdump -d bthread.o | less
0000000000000218 <bthread_mutex_lock>:
 218:   8b 07           mov    (%rdi),%eax
 21a:   85 c0           test   %eax,%eax
 21c:   75 fc           jne    21a <bthread_mutex_lock+0x2>
 21e:   b8 00 00 00 00  mov    $0x0,%eax
 223:   ba 01 00 00 00  mov    $0x1,%edx
 228:   f0 0f b1 17     lock cmpxchg %edx,(%rdi)
 22c:   89 c2           mov    %eax,%edx
 22e:   85 d2           test   %edx,%edx
 230:   75 e6           jne    218 <bthread_mutex_lock>
 232:   f3 c3           repz retq 
```

Both the client program and the benchmark invariable hang while waiting for
one of the threads to exit. I don't know why, but optimization does not seem to agree with my amalgamation of clone and wait.

*Aside: I am almost positive that this is not an issue with clone and wait. These are extremely well tested functions that were written by RealProgrammers&trade;. The issue is probably some undefined behavior I am invoking in the way `bthreads` is setup.*

### Conclusion

This writeup was made in an attempt to codify what I think I learned while digging deeper into multi threaded programming on Linux. Please feel free to reach out and correct my mistakes. Thanks for reading.

Here are some cool resources.

<https://www.felixcloutier.com/x86/cmpxchg>

<https://eli.thegreenplace.net/2018/launching-linux-threads-and-processes-with-clone/>


