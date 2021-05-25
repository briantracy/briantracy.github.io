
# Endianness (Byte Order) Is Real!


As a student, I learned about the concept of [endianness / byte order](https://en.wikipedia.org/wiki/Endianness) at a very high level. Due to the fact that x86 is a little endian ISA and ARM ISAs are by default little endian (and the new Apple chips), big endian systems simply did not exist to me. In fact, unless I was to do some low level networking, I was confident in the fact that I would never need to use a big endian byte ordering at any point.

Well it turns out that big endian systems do exist, and code that I write one day may have to run on such systems. Knowing this, I wanted to prove to myself that there really was something fundamentally different, and potentially dangerous, about naively targeting these platforms. To do so, I cooked up a sample application and ran it on both a little endian x86 system, and a big endian (emulated via QEMU) MIPS system.

---

The application is a fake database type thing where the user inputs some information about themselves that can be read back at a later date.

```
$ ./users
usage: ./users create <file> <name> <id> <weight>
usage: ./users fetch <file>
```

The `create` operation puts the user supplied values into a structure, then writes the bytes of the structure to the given file.

The `fetch` operation populates a structure directly from the bytes of the given file.

Here is the user structure:

```
struct user {
    char name[8];   // 8 bytes
    uint64_t id;    // 8 bytes
    double weight;  // 8 bytes
};
```

Essentially, the `create` operation is:

```
struct user new_user = { /* (name, id, weight) from user input */ };
write(fd, &new_user, sizeof(struct user));
```

And the `fetch` operation is:

```
struct user existing_user;
read(fd, &existing_user, sizeof(struct user));
```

The goal is to demonstrate how this code, while seemingly "portable" (in the sense that all we are doing is reading/writing from/to a file), will in fact be laid low by the byte order of the underlying hardware.

---

The setup is that there are two different systems, one little endian and one big. In addition, on the little endian system, both a 32 and 64 bit version of the program is compiled. We will see that due to the `struct user` definition, there will be no difference between the 32 and 64 bit programs (due to the members being of fixed width), but there will be a difference between the two systems.


For the little endian system, I am running a virtual x64 machine on my personal computer (via vagrant + Virtual Box):
```
vagrant@ubuntu-focal:~ $ uname -a
Linux ubuntu-focal 5.4.0-73-generic #82-Ubuntu SMP
Wed Apr 14 17:39:42 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```

For the big endian system, I am running QEMU to emulate MIPS Debian, all from within the above virtual machine:
```
root@ubuntu-focalqemu:~ # uname -a
Linux ubuntu-focalqemu 4.19.0-16-4kc-malta #1 SMP Debian 4.19.181-1
(2021-03-19) mips GNU/Linux
```

Here is an example of the program running normally. We create a new users named "brimips" with id "12345" and weight "987.654". The binary representation of these values are then written to file. Next, we read the user in that file and get the correct values out.

```
root@ubuntu-focalqemu:/test# ./mips_users create mips.data brimips 12345 987.654
creating user {'brimips', id=12345, weight=987.654000} in file mips.data
root@ubuntu-focalqemu:/test# ./mips_users fetch mips.data
found user {'brimips', id=12345, weight=987.654000} in file mips.data
```

Simultaneously, on the little endian machine, we run the same program to create two new data files. Again, everything on the same machine works perfectly.

Finally, mis-matching the data files and attempting to read them from the system the were not created on will yield garbage results. Here we have the MIPS program attempting to read the x86/64 data file.
```
root@ubuntu-focalqemu:/test# ./mips_users fetch x86.data
found user {'brix86', id=4120793659044003840, weight=-0.000000} in file x86.data
root@ubuntu-focalqemu:/test# ./mips_users fetch x64.data
found user {'brix64', id=4120793659044003840, weight=-0.000000} in file x64.data
```

Likewise, on the x86/64 platform, we get incorrect values when attempting to read from the big endian MIPS data.
```
vagrant@ubuntu-focal:/vagrant/mips$ ./x86_users fetch mips.data
found user {'brimips', id=4120793659044003840, weight=-0.000000} in file mips.data
vagrant@ubuntu-focal:/vagrant/mips$ ./x64_users fetch mips.data
found user {'brimips', id=4120793659044003840, weight=-0.000000} in file mips.data
```

Here are the three compilations of the same source program. The MIPS target was compiled on the emulated MIPS host (I could not figure out how to get GCC to cross compile).

```
(x64)  $ gcc ${CFLAGS} users.c -o x64_users
(x86)  $ gcc ${CFLAGS} -m32 users.c -o x86_users
(mips) $ gcc ${CFLAGS} users.c -o mips_users
```

Where `CFLAGS='-Wall -Wextra -Wpedantic -std=c11'`. Here are the resulting executables.

```
$ file mips_users
ELF 32-bit MSB pie executable, MIPS, MIPS32 rel2 version 1 (SYSV)

$ file x86_users
ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV)

$ file x64_users
ELF 64-bit LSB shared object, x86-64, version 1 (SYSV)
```

To understand what is going wrong, take a look at the data files generated by each program. The crux of the issues is that the `struct user` is being serialized in a platform dependent manner (the dependence being the byte order of the `uint64_t` and the `double` fields).

```
$ xxd -c8 mips.data
00000000: 6272 696d 6970 7300  brimips.     char name[8]  ("brimips\0")
00000008: 0000 0000 0000 3039  ......09     uint64_t id   (12345)
00000010: 408e dd3b 645a 1cac  @..;dZ..     double weight (987.654)
$ xxd -c8 x86.data
00000000: 6272 6978 3836 0000  brix86..     char name[8]  ("brix86\0\0")
00000008: 3930 0000 0000 0000  90......     uint64_t id   (12345)
00000010: ac1c 5a64 3bdd 8e40  ..Zd;..@     double weight
$ xxd -c8 x64.data
00000000: 6272 6978 3634 0000  brix64..     char name[8]  ("brix64\0\0")
00000008: 3930 0000 0000 0000  90......     uint64_t id   (12345)
00000010: ac1c 5a64 3bdd 8e40  ..Zd;..@     double weight (987.654)
```

### Conclusions

It is unwise to serialize and de-serialize without thought. Obviously, ELF knows how to do this (I believe the ELF header is a structure that gets read out of the executable at load time), but special care is put into that.

In addition, even if the serialization code is endianness-aware, your use case might not always need to have such a compact on-disk format. The benefits of directly writing a structure are space and complexity (of a naive solution) savings, but you also sacrifice human readability and portability. I would guess that this is one of the reasons behind the rise of human readable protocols/exchange formats like HTTP and JSON. If you can afford the price of transforming through JSON, you might save yourself some rather insidious bugs.

Finally, strange machines do exist! Granted, my test machines were not extra-strange (like ternary systems or systems where `CHAR_BIT != 8`), but it is good to know that the world is not run solely on x86.
