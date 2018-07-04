#!/bin/bash

# Update the "last updated" part of homepage
# Remove last three lines, then update them
#

gsed -i '$d' index.html
gsed -i '$d' index.html
gsed -i '$d' index.html

echo "<i>Last updated on `date`</i>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html

# Compress all images in the images folder into the compressed folder
for img in $(git ls-files -mo | grep ".jpg"); do
    [ -e "$img" ] || continue
    echo "Compressing $img"
    convert -resize 33% "$img" "compressed/`basename $img`"
done

# publish 

git add . 
git commit -m "`date`"
git push
