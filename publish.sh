#!/bin/bash

# Update the "last updated" part of homepage
# Remove last three lines, then update them

gsed -i '$d' index.html
gsed -i '$d' index.html
gsed -i '$d' index.html

echo "<i>Last updated on `date`</i>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html


# Add, commit, and push all files

git add . 
git commit -m "`date`"
git push
