#!/bin/sh
# dot.sh
file=$1
filename=${file%.*}
extension=${file##*.}
outfile=${filename}.png
dot -T png $file -o $outfile
#show generate image file
#eog $outfile &