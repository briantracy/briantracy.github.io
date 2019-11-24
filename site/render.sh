#!/usr/bin/env bash

for file in ./markdown/*; do
    printf "rendering $file\n"

    base=$(basename $file)
    title=${base%%.md}

    pandoc -t html5 \
           --template=./templates/template.html \
           --include-in-header=./templates/styles.css \
           --metadata title="Brian Tracy - $title" \
           "$file" \
           -o "../${title}.html"
done

