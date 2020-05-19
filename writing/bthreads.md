
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


### Setup

I wanted the following three features in `bthreads`:

1. The ability to create threads
2. The ability to synchronize these threads via mutexes
3. The ability to join these threads 

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


### Implementing Mutexes


### Joining Threads


