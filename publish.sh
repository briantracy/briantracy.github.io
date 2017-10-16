#!/bin/bash

# Update the "last updated" part of homepage
# It is always the last line of index.html

sed -i '' '$d' index.html
echo "Last updated on `date`" >> index.html



# Add, commit, and push all files

git add . 
git commit -m "`date`"
git push
