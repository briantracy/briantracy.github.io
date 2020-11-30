
# Identity

How does one prove their identity on the internet?

One approach would be to write "I am Brian Tracy and I own briantracy.xyz". The problem with this approach is that anyone could have bought this domain and made that statement.

Attempt two would be to record a video of me saying "I am Brian Tracy and I own briantracy.xyz". This is better, but there is no way to verify that the person you see speaking is actually me. A **trusted third party** needs to verify that the person with my face is Brian Tracy, and then in turn, that Brian Tracy owns briantracy.xyz

For some definitions of "trusted", the most trusted third party possible would be the US Government. Conveniently, the government issues a bidirectional mapping from face to legal name in the form of [Photo IDs](https://en.wikipedia.org/wiki/Photo_identification).

So by presenting a photo id issued by a trusted government, we build a chain of trust from the government to my domain. Once we have this, anything hosted on my domain could be considered legitimately from me.

With the sophistication of modern image manipulation software, a picture with my face, a photo id, and then the text "I own briantracy.xyz" is not enough. Fortunately, we do not yet have the technology (available to everybody) to doctor videos as convincingly.

So I offer the following: a video with my face, several forms of photo id issued by a trusted government, and a claim of ownership of briantracy.xyz

Augmented with a GPG key, this creates a robust chain of trust.

```
US Government -> my face / my name -> my domain -> my GPG key -> ???
```




