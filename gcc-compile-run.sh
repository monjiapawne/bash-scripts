#!/bin/bash
#####################################################
# purpose: compile and run c scripts
# usage: ./gcc-compile-run.sh "cool_script.c"
#####################################################

file="$1"
fullpath="$PWD/$file"
filetype=".c"

function main() {
    if [[ $file == *$filetype && -f $fullpath ]]; then
        if command -v gcc >/dev/null 2>&1; then
            compiledFile=${file%.*}
            gcc "$fullpath" -o $compiledFile
            ./$compiledFile
        else
            echo 'gcc is not installed'
        fi
    else
        echo 'verify file format and location.'
        echo "file: $fullpath"
    fi
}

main
