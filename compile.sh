#!/bin/bash

java -jar TypstEscape.jar . --once --allow gradle --allow java --ask-each

shopt -s globstar nullglob  # Enable recursive globbing and nullglob option

for file in ./**/*.typ; do
    # Perform desired operation on $file
    typst c "${file}" --root .
done

rm common/escape.pdf
rm common/java-kotlin-launch.pdf

for file in ./**/*.typesc; do
    rm "${file}"
done
