#!/bin/bash

# Update the "last updated" part of homepage
# Remove last three lines, then update them

gsed -i '$d' index.html
gsed -i '$d' index.html
gsed -i '$d' index.html

echo "        <i>Last updated on `date`</i>" >> index.html
echo "    </body>" >> index.html
echo "</html>" >> index.html

# Compress all images in the images folder into the compressed folder
# This is expensive, so only compress new images or ones that have been modified
for img in $(git ls-files -mo | grep -E 'jpg|png'); do
    [ -e "$img" ] || continue
    echo "Compressing $img"
    convert -resize 33% "$img" "images/`basename $img`"
done

if [ "$?" -ne 0 ]; then
    echo "something went wrong with image compression"
    exit 1
fi

# publish 

git add . 
git commit -m "`date`"
git push