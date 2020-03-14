#!/bin/bash

# input files
FILES="files"
TEMP="temp"

# command line argument for output name
PDFNAME=$1

# reduction size
MAXSIZE=2048

if [ -z "$1" ]
    then
        echo "No output file given, exporting to output.pdf"
        echo "To specify the name of the output, pass a name as follows: ./clear.sh <name>.pdf"
        PDFNAME="output.pdf"
fi

# This is the blur radius, as a fraction of the total image size.
# This normalizes the blur radius to the page size.

# Fractions smaller than 1/10 (BLUR = 10) are very slow and may not be fine enough
# to keep the background consistent.

# Fractions larger than 1/100 (BLUR = 100) are fast, but may result in issues where
# blurring is local and doesn't lighten dark blocks of text enough
BLUR=15

rm -rf "${TEMP}${FILES}"
mkdir "${TEMP}${FILES}"


for f in ${FILES}/*; do
    tempfile=$TEMP$f
    convert $f -resize ${MAXSIZE}x${MAXSIZE}\> $tempfile
done

for f in ${TEMP}${FILES}/*; do
    width=`identify -format "%w" $f`
    height=`identify -format "%h" $f`

    #notify user if the image is in landscape mode (pages are usually portrait)
    if [ "$width" -gt "$height" ]
        then
            echo "Image $f is in landscape orientation."
    fi

    blurradius=$((width / BLUR))
    outfile=$f
    echo "$f -> $outfile with blur of $blurradius px"

    #imagemagick convert file with blur 0x(blursize) and divide with the blur
    convert $f \( +clone -blur 0x$blurradius \) -compose Divide_Src -composite $outfile
done

#loop through finished files
total=""
for f in $TEMP${FILES}/*; do
    total="${total} $f"
done

echo "$total -> $1"
convert $total -quality 80 -units PixelsPerInch -density 72x72 $PDFNAME
echo "$PDFNAME created"
