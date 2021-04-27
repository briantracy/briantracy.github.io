
# btar &mdash; Bad tar Clone

This writeup will walk through how to create a clone (ish) of the classic UNIX `tar`
command, with one additional feature.

### Motivation

Consider the following quote from the Wikipedia page for `tar`:

*The tar format was designed without a centralized index or table of contents for
files and their properties for streaming to tape backup devices. The archive must
be read sequentially to list or extract files. For large tar archives, this causes
a performance penalty, making tar archives unsuitable for situations that often
require random access to individual files.*

I read this and thought, "wow that seems like an oversight", and then, with the hubris
of a recent college graduate, I thought "I can do better".

### `tar` Overview

`tar` converts a set of files into a single file. This new file, known as an "archive"
(hence the name **t**ape **ar**chive) can later be converted back into the original
set of files.

One of the great things about files is that they are just bytes, so to amalgamate
a set of files, all you really have to do is concatenate their contents. Add in
some metadata about which file starts where, and this is pretty much it.

### Design Overview

Random access was the one feature I wanted to add, so I had this in mind when beginning
the design process. To get random access to a given file in the archive, I would have
to know where all the files are without reading the entire archive.

We can model this information with a method that is extremely similar to the concept
of [Extents](https://en.wikipedia.org/wiki/Extent_(file_systems)) in file systems.
Essentially, each file is identified in the archive by a tuple of `(offset, length)`,
and all of these tuples are stored at the head of the file.

All you need now is a way to associate a file name with a single tuple, and the
archive is complete.

### File Names

Most of the `tar` implementations I have read about have all had fixed length
requirements for file names. The benefit to having a maximum file length is that
it simplifies the layout of metadata. The downside is that you now have an upper
bound on the name of a file, which is normally much smaller than the real upper
bound provided by the OS. In addition, fixed length file name fields lead to
wasted space when the majority of your files have short names.

`btar` stores file names separately from extent metadata. Much like how a compiler
will separate code and data, the archive separates all fixed length and variable length
data. In both cases, it is not necessary, but makes things easier down the line.


### Archive Format

The `btar` archive is structured as follows:

1. **Archive Header:** The archive header contains a magic number that identifies
the file as a `btar` archive (the sequence of bytes `"\x9a\x00\xA1\xFC""btar"`).
In addition, it stores when the archive was created, how many files are in it,
and the total length of all metadata (that is, all data that is not actual file data).

2. **File Metadata Blocks:** After the archive header comes the list of
`(offset, length)` tuples for each file. The number tuples is known from the archive
header.

3. **File Names:** Next comes all of the file names. They are stored as consecutive
NULL terminated strings, and can be of any length.

4. **File Data:** Finally, the raw data of every file is concatenated together.
There is no separation between the bytes of two files (unlike `tar`) as the offsets
between them are known.


Here is a comment from the top of `btar.h` giving a visual description of the format.

```
/*
 *        BTAR ARCHIVE FORMAT
 * +-----------------------------------+
 * | +-------------------------------+ |
 * | | Magic Number (8 bytes)        | |
 * | | Creation Date (8 bytes)       | |   One master block
 * | | Number of Files (8 bytes)     | |
 * | | Total Header Length (8 bytes) | |
 * | +-------------------------------+ |
 * |                                   |
 * | +------------------------------+  |
 * | | +--------------------------+ |  |
 * | | | File Length (8 bytes)    | |  |   Many file metadata blocks
 * | | | Archive Offset (8 bytes) | |  |   (one per file in archive)
 * | | +--------------------------+ |  |
 * | |            ...               |  |
 * | |            ...               |  |
 * | |            ...               |  |
 * | +------------------------------+  |
 * |                                   |
 * | +---------------+                 |
 * | | "filename1"\0 |                 |   Null terminated file names
 * | | "filename2"\0 |                 |   (one per file in archive)
 * | |    ...        |                 |
 * | | "filenameN"\0 |                 |
 * | +---------------+                 |
 * |                                   |
 * |           (end of header)         |
 * |                                   |
 * | +-------------------------------+ |
 * | |                               | |  Bytes of files in archive
 * | |         Raw File Data         | |  (one extent per file)
 * | |                               | |  (indexed by metadata blocks)
 * | +-------------------------------+ |
 * +-----------------------------------+
 *
*/
```

### Implementation

Here is the process for extracting a file from the archive:

1. Open the file and read the first `sizeof(struct archive_header)` bytes.
2. Skip ahead `num_files * sizeof(struct file_metadata)` bytes to skip of the
extent tuples to get to the file names.
3. Read all of the file names into memory (we know the total length of all the
file names from the archive header).
4. Search for the given file name to extract. Because all the file names are are
NULL terminated, it is easy to figure out the index of a given file name.
5. With the index of the desired file, look into the extent list and find the offset
and length of the file.
6. Seek to the proper offset, read the correct number of bytes, and write them to a file.

To create an archive from a set of files:

1. Open all the files first to make sure they exist and are readable.
2. Compute how large the archive metadata will be based off of the length of all
file names and how many files there are.
3. Seek past all the metadata and transfer all of the files contiguously into
the archive.
4. Seek to the beginning of the file and write the metadata.


### 2038 Problem


### Usage

Here is the API for `btar`

```
 $ ./btar
btar -- usage

o To create an archive from a set of files:
  > btar pack archive [file1 ... fileN]

o To extract all (or certain) files from an archive:
  > btar unpack archive [file1 ... fileN]

o To view the contents of an archive:
  > btar list archive
```