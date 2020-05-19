
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
glossed over for simplicity's sake*

Now our threads can be spawned, and then reigned in when they are done working.
We can now move on to synchronizing the threads during their execution.


### Implementing Mutexes

To implement a mutex, we need some help from the hardware (*Note: this is false in certain situations: <https://en.wikipedia.org/wiki/Peterson%27s_algorithm>*). x86 provides the `lock` prefix for instructions, which allows atomic memory access. 


### Sample Program

### Performance


### Resources

https://eli.thegreenplace.net/2018/launching-linux-threads-and-processes-with-clone/


