
# Adventure 3 - Smart Numbers

Let's take the CAS number for my favorite substance benzene: `71-43-2`

```
71-43-2
-------
3*1 + 4*2 + 1*3 + 7*4 =
3   + 8   + 3   + 28  = 42
                      = 2 (mod 10)
```

Let's say that we discover a vial of a clear substance that has a CAS number
scrawled on it, but one of the numbers is missing. Because of the check number, the missing digit can be recovered.

```
71-X3-2   (X is lost digit)
-------
3*1 + X*2 + 1*3 + 7*4 =
3   + 2*X + 3   + 28  = 34 + 2*X
                      = 2 (mod 10)