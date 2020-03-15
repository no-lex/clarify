#!/bin/bash

#simple script using ImageMagick to convert a series of input photographs to a
#PDF after self divsion to normalize the background to white

# takes a single argument for the PDF name, which should include the .pdf extension.

#note: as of v6.9.7, imagemagick blacklists ghostscript due to a security bug which
# has been resolved as of 9.26 (default for 18.04) but still needs to be enabled in
# imagemagick settings (located at /etc/ImageMagick-6/policy.yml in 18.04)

# ==== Settings ====

# input files
FILES="files"
TEMP="temp"

# command line argument for output name
PDFNAME=$1

# reduction size
MAXSIZE=2048

# quality of pdf output from 1 to 100
QUALITY=80

# This is the blur radius, as a fraction of the total image size.
# This normalizes the blur radius to the page size.

# Fractions smaller than 1/10 (BLUR = 10) are very slow and may not be fine enough
# to keep the background consistent.

# Fractions larger than 1/100 (BLUR = 100) are fast, but may result in issues where
# blurring is local and doesn't lighten dark blocks of text enough
BLUR=15

# ==== End of Settings ====

if [ -z "$1" ]
    then
        echo "No output file given, exporting to output.pdf"
        echo "To specify the name of the output, pass a name as follows: ./clear.sh <name>.pdf"
        PDFNAME="output.pdf"
fi

rm -rf "${TEMP}${FILES}"
mkdir "${TEMP}${FILES}"

# This resizes the files and places them in the tempfile directory.
for f in ${FILES}/*; do
    tempfile=$TEMP$f
    convert $f -resize ${MAXSIZE}x${MAXSIZE}\> $tempfile
done

# This identifies the files which are in landscape mode and warns the user
# then proceeds to blur and divide.
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

# converts the files created in $TEMP$FILES to a PDF
convert $total -quality 80 -units PixelsPerInch -density 72x72 $PDFNAME
echo "$PDFNAME created"
