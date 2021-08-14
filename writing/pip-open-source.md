
# My First Open Source Contribution

I am a huge fan of open source software and one of my biggest goals is to one day contribute to the Linux kernel. I took my first step towards that goal by making a tiny contribution to a smaller open source project.

[pip](https://pypi.org/project/pip/) is the *de facto* python package manager. It is used to install pieces python code that other people wrote (called packages) so that programmers are not forced to "re-invent the wheel" (i.e.: re-implement common designs) any time they start a new project.

While working in my school's computer lab, I noticed that many students who were just learning about python had trouble interacting with the package manager. This difficulty would leave them feeling hopeless and uninspired ("I can't even set up my program's environment, how am I supposed to write the program itself?"). Often, they would get hung up on the very idiomatic step of installing packages listed in a file (using the `-r <file>` flag):

```
$ cat requirements.txt
package1
anotherPackage2
finalPackage3

$ pip install -r requirements.txt
```

Instead of the above (correct) invocation, they would often forget the `-r` flag and simply try:

```
$ pip install requirements.txt
ERROR: Could not find a version that satisfies the requirement requirements.txt (from versions: none)
ERROR: No matching distribution found for requirements.txt
```

This is an unfortunate error message for a beginner as they are unlikely to understand that "satisfies the requirement ..." means that `pip` was attempting to find a package named "requirements.txt" (and not, as intended, to install the packages **listed in** requirements.txt).

My contribution merely detects this common mistake and emits a helpful warning.

```
HINT: You are attempting to install a package literally named
"requirements.txt" (which cannot exist).
Consider using the '-r' flag to install the packages listed in requirements.txt
```

[My patch has been approved](https://github.com/pypa/pip/pull/9915) and is now live for millions of confused students around the world!