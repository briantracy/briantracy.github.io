

# Heading Level 1

Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
lather on which a mirror and a razor lay crossed. A yellow dressinggown,
ungirdled, was sustained gently behind him on the mild morning air. He
held the bowl aloft and intoned:

Here is some `monospaced text for you`

Break Incoming

---

That was the break

## Heading Level 2

Solemnly he came forward and mounted the round gunrest. He faced about
and blessed gravely thrice the tower, the surrounding land and the
awaking mountains. Then, catching sight of Stephen Dedalus, he bent
towards him and made rapid crosses in the air, gurgling in his throat
and shaking his head. Stephen Dedalus, displeased and sleepy, leaned
his arms on the top of the staircase and looked coldly at the shaking
gurgling face that blessed him, equine in its length, and at the light
untonsured hair, grained and hued like pale oak.

1. --My name is absurd too: Malachi Mulligan, two dactyls. But it has a

2. Hellenic ring, hasn't it? Tripping and sunny like the buck himself.

3. We must go to Athens. Will you come if I can get the aunt to fork out

4. twenty quid?



### Heading Level 3

He peered sideways up and gave a long slow whistle of call, then paused
awhile in rapt attention, his even white teeth glistening here and there
with gold points. Chrysostomos. Two strong shrill whistles answered
through the calm.

- --A woful lunatic! Mulligan said. Were you in a funk?

- --I was, Stephen said with energy and growing fear. Out here in the dark

- with a man I I don't know raving and moaning to himself about shooting a

- black panther. You saved men from drowning. I'm not a hero, however. If

- he stays on here I am off.


#### Heading Level 4

He skipped off the gunrest and looked gravely at his watcher, gathering
about his legs the loose folds of his gown. The plump shadowed face and
sullen oval jowl recalled a prelate, patron of arts in the middle ages.
A pleasant smile broke quietly over his lips.


##### Heading Level 5

He pointed his finger in friendly jest and went over to the parapet,
laughing to himself. Stephen Dedalus stepped up, followed him wearily
halfway and sat down on the edge of the gunrest, watching him still as
he propped his mirror on the parapet, dipped the brush in the bowl and
lathered cheeks and neck.


```
static void calculate_refcounts(int *counts, vnode_t *vnode) {
    long ret;

    size_t pos = 0;
    dirent_t dirent;
    vnode_t *child;

    while ((ret = s5fs_readdir(vnode, pos, &dirent)) > 0) {
        counts[dirent.d_ino]++;
        dbg(DBG_S5FS, "incrementing count of inode %d to %d\n", dirent.d_ino, counts[dirent.d_ino]);
        if (counts[dirent.d_ino] == 1) {
            child = vget_second(vnode, dirent.d_ino);
            if (S_ISDIR(child->vn_mode)) {
                calculate_refcounts(counts, child);
            }
            vput_second(vnode, &child);
        }
        pos += ret;
    }

    KASSERT(!ret);
}
```
