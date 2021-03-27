

# Source vs Destination &mdash; Observations on Argument Ordering

Many functions / operations involve moving something (bytes, file, ...) somewhere.


I propose the following terms to clarify the relationship between the two objects in question:

**Master:** The object that will not be changed.

**Copy:** The object that will be changed (or created).


### Order: Master, Copy

1. **Unix Shell:** Bash (and sh) commands `ln`, `mv`, `cp` all take the form of `progname <master1> [... <masterN>] <copy>`.
2. **`string.h`:** C standard library string functions `memcpy`, `memmove`, `strcpy` all take the form `funcname(<copy-ptr>, <master-ptr>, [...])`.
3. **File System:** `dup2(fd, newfd)` duplicates file descriptor `fd` and associates the given `newfd` with the same file.

### Order: Copy, Master

1. **Intel x86 assembly language:** `mov rax, rdx` puts the contents of register `rdx` into register `rax`.
2. **Sendfile:** `sendfile(outfd, infd, ...)` writes everything from `infd` to `outfd`.

link() syscall
ln command
mv <i1> <i2> ... <iN> out
cp <a> ... <z> out

memcpy, strcpy, memmove

sendfile
dup2



<!--| Operation | Example | Explanation | Ordering |
|-----------|---------|-------------|----------|
| `link` syscall | `int link(const char *path1, const char *path2);` | Creates new file named `path2` that is a new name for the contents of file `path1` | Master, Copy |
| `ln`/`link` shell | `ln -s /bin/ls ~/bin/myls` | Creats symbolic link from second argument to first argument | Master, Copy |
| -->
