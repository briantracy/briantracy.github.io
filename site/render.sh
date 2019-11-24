#!/usr/bin/env bash


gsed ':a;N;$!ba;s/\n//g;s/: /:/g;s/ {  /{/g;s/;  /;/g;s/;}/}/g' \
         ./templates/styles.css > ./templates/styles.min.css

for file in $(git ls-files -m markdown); do
    printf "rendering $file\n"

    base=$(basename $file)
    title=${base%%.md}

    pandoc -t html5 \
           --template=./templates/template.html \
           --include-in-header=./templates/styles.min.css \
           --metadata title="Brian Tracy - $title" \
           --metadata date="$(date)" \
           "$file" |
           gsed ':a;N;$!ba;s|>\s*<|><|g' \
           > "../${title}.html"
done

