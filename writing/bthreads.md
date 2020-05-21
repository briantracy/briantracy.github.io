
# bthreads &mdash; Bad Threading Library

This writeup will walk through how to make an extremely barebones threading
library for programs running on Linux, without support from `pthreads` or the
`futex` syscall. 


### Motivation

It appears to me that implementing something badly is the first step towards
implementing something well, and since I want to learn more about systems
programming, I thought I would give this a shot. Mutexes are very interesting
and while I have experience using them, I have only briefly considered how to
create them myself.

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

The goal of threads is to have multiple concurrent instruction streams, all
with the capability of accessing a shared piece of memory. One method for accomplishing this would be to use `fork` to create a new process
for each thread, then use `mmap` to map in a shared memory region into each
process' address space.

Instead of doing this ourselves, we can utilize the
`clone` system call (more precisely, the glibc wrapper) and let the kernel
handle the process creation and memory sharing.

*Aside: I have read that the process vs thread distinction is really a user space abstraction,
and that the kernel sees both types of objects as simply "tasks". Assuming this
is true, allowing the kernel to manage thread creation sees like a much better
idea than a hacky `fork`+`mmap` approach*

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

1. `CLONE_VM`: Tells the kernel to run this thread in the same address space as the one in which it was created. This is where the classical thread vs process distinction is made.
2. `SIGCHLD` tells the kernel to ensure that when the newly created thread exits, `SIGCHLD` should be sent to the parent. This allows the parent to `wait` upon the child as if it were a process.

So now we have the capability to fracture one address space into many stacks,
have a thread running on each stack, and have all the threads access the same
shared memory.

### Joining Threads

Before the main thread (the one that spawned all the others via `btrhread_create`) exits, we would like all of the children to terminate. A
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
completely ignore best practices for greater readability.*

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

The crux of the issue is that the act of noticing that the mutex is unlocked, and then proceeding to lock it, is not instantaneous. The amount of time between these two steps is not 0, and in this short window, another thread may also see that the mutex is unlocked and enter the critical section.

The solution is to combine these two steps into one **atomic** action.

### Compare and Exchange (mnemonic `cmpxchg`)

The `cmpxchg %reg, dest` instruction compares the current value of the accumulator (`%rax`, `%eax`, ...) to the value in `dest` (either another register or a location in memory). If the two are equal, the value in `%reg` (any general purpose register) is stored into `dest`. If they are not equal, the value in `dest` is loaded into the accumulator.

Note that the value in the accumulator after the execution of a `cmpxchg` will always be equal to the value that was in `dest` before the instruction. In addition, the contents of `%reg` are never changed. 

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

Due to the simplicity of our lock state (one integer), a thread can release the
mutex by non atomically setting the lock state to the "unlocked" value.  

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

void spin_unlock(mutex *mtx) {
    mtx->locked = 0;
}
```

That is roughly the entirety of `bthreads`: a call to `clone`, a call to `wait`, and one `cmpxchg` instruction.

### Sample Program

### Performance


### Resources

https://eli.thegreenplace.net/2018/launching-linux-threads-and-processes-with-clone/


