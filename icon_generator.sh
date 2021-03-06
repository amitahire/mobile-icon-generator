#!/bin/bash

usage() {
    echo
    echo Usage: icon_generator.sh -i image file -p platform -t icon type [-d directory] [-c color] [-w] [-m]
    echo
    echo "  -i The original image file."
    echo "  -p The icon's platform. Valid options:"
    echo "     ios"
    echo "     android"
    echo "  -t Most iOS and Anroid icons are supported. Valid options:"
    echo "     toolbar (iOS) (1x = 22x22)"
    echo "     tabbar (iOS) (1x = 25x25)"
    echo "     tableviewcell (iOS) (1x = 25x25)"
    echo "     app (iOS)"
    echo "     action (Android)"
    echo "     notification (Android)"
    echo "     small (Android)"
    echo "  -d The directory the images will be saved to. Default is the current directory."
    echo "     On iOS, icons, along with a Contents.json file, are saved in a .imageset file."
    echo "     On Android, a new directory for each density is created, if it doesn't already exist."
    echo "  -c Optional. A color used to mask the original image. Example: blue, \"#929292\"." 
    echo "     Default keeps the original color." 
    echo "     This flag does not apply to -type app."
    echo "  -w Optional. Removes whitespace around the original image."
    echo "     Default keeps the original whitespace." 
    echo "     This flag does not apply to -type app."
    echo "  -m Optional. Enables Google Material Design icon sizes (slightly smaller than normal)."
    echo "     This flag only applies to Android."
    echo
    echo ./icon_generator.sh -i ic_trash.png -p ios -t toolbar -d ~/icons/ -c red
    echo
    echo This script requires ImageMagick for image manipulation.
    echo https://www.imagemagick.org/script/index.php
    echo 
}

TRIM=0
COLORIZE=0
MATERIAL=0
while getopts "i:p:t:d:c:wm" OPTION
do
    case $OPTION in
    i)
        IMG=$OPTARG
        ;;
    p)
        PLATFORM=$OPTARG
        ;;
    t)
        TYPE=$OPTARG
        ;;
    d)
        DIR=$OPTARG
        ;;
    c)
        COLORIZE=1
        COLOR=$OPTARG
        ;;
    w)
        TRIM=1
        ;;
    m)
        MATERIAL=1
        ;;
    esac
done

# Argument validation.

if [ -z $IMG ]; then
    echo ERROR: Image file missing.
    usage
    exit 1
fi

if [ -z $PLATFORM ]; then
    echo ERROR: Platform missing.
    usage
    exit 1
fi

if [ -z $TYPE ]; then
    echo ERROR: Icon type not supplied.
    usage
    exit 1
fi

# File extension of the input image.
EXT=.${IMG##*.}

# File name of the input image, sans extension.
FILE_NAME=${IMG%.*}
ORIGINAL_FILE_NAME=$FILE_NAME

# iOS app icon
if [ $PLATFORM = ios -a $TYPE = app ]; then
    convert $IMG -resize 20x20 $DIR$FILE_NAME"_20"$EXT
    convert $IMG -resize 29x29 $DIR$FILE_NAME"_29"$EXT
    convert $IMG -resize 40x40 $DIR$FILE_NAME"_40"$EXT
    convert $IMG -resize 60x60 $DIR$FILE_NAME"_60"$EXT
    convert $IMG -resize 58x58 $DIR$FILE_NAME"_58"$EXT
    convert $IMG -resize 76x76 $DIR$FILE_NAME"_76"$EXT
    convert $IMG -resize 87x87 $DIR$FILE_NAME"_87"$EXT
    convert $IMG -resize 80x80 $DIR$FILE_NAME"_80"$EXT
    convert $IMG -resize 120x120 $DIR$FILE_NAME"_120"$EXT
    convert $IMG -resize 152x152 $DIR$FILE_NAME"_152"$EXT
    convert $IMG -resize 167x167 $DIR$FILE_NAME"_167"$EXT
    convert $IMG -resize 180x180 $DIR$FILE_NAME"_180"$EXT

    exit 1
fi

# System icons

# Create a colorized copy of the original file, if needed.
if [ $COLORIZE -ne 0 ]; then
    FILE_NAME_COLORIZED=$FILE_NAME"_colorized"
    convert $IMG -alpha off -fill $COLOR -colorize 100% -alpha on $FILE_NAME_COLORIZED$EXT
    FILE_NAME=$FILE_NAME_COLORIZED
fi

# Trim whitespace if needed, otherwise copy the file.
FILE_COPY=$FILE_NAME"_copy"$EXT
FILE=$FILE_NAME$EXT
if [ $TRIM -ne 0 ]; then
    convert $FILE -trim $FILE_COPY
else
    cp $FILE $FILE_COPY
fi

# Creates a given directory if it doesn't already exist.
makeDir() {
    if [ ! -d "$1" ]; then
        mkdir $1
    fi
}

MDPI=$DIR"drawable-mdpi"
HDPI=$DIR"drawable-hdpi"
XHDPI=$DIR"drawable-xhdpi"
XXHDPI=$DIR"drawable-xxhdpi"
XXXHDPI=$DIR"drawable-xxxhdpi"

gen_android() {
    convert $FILE_COPY -resize $1 $MDPI/$IMG
    convert $FILE_COPY -resize $2 $HDPI/$IMG
    convert $FILE_COPY -resize $3 $XHDPI/$IMG
    convert $FILE_COPY -resize $4 $XXHDPI/$IMG
    convert $FILE_COPY -resize $5 $XXXHDPI/$IMG
}

handle_android() {
    makeDir $MDPI
    makeDir $HDPI
    makeDir $XHDPI
    makeDir $XXHDPI
    makeDir $XXXHDPI

    # Material Action, Notification
    if [ $TYPE = action -a $MATERIAL -ne 0 -o $TYPE = notification ]; then
        gen_android 24x24 36x36 48x48 72x72 96x96
    fi

    # Normal Action
    if [ $TYPE = action -a $MATERIAL = 0 ]; then
        gen_android 32x32 48x48 64x64 96x96 128x128
    fi

    # Small
    if [ $TYPE = small ]; then
        gen_android 16x16 24x24 32x32 48x48 64x64
    fi
}

gen_ios_icon() {
    FILE_1X=$ORIGINAL_FILE_NAME"_1x"$EXT
    FILE_2X=$ORIGINAL_FILE_NAME"_2x"$EXT
    FILE_3X=$ORIGINAL_FILE_NAME"_3x"$EXT

    convert $FILE_COPY -resize $2 $1/$FILE_1X
    convert $FILE_COPY -resize $3 $1/$FILE_2X
    convert $FILE_COPY -resize $4 $1/$FILE_3X
}

handle_ios() {
    # Create .imageset directory.
    DIR=$DIR$ORIGINAL_FILE_NAME".imageset"
    makeDir $DIR

    # TabBar
    if [ $TYPE = tabbar ]; then
        gen_ios_icon $DIR 25x25 50x50 75x75
    fi

    # Toolbar
    if [ $TYPE = toolbar ]; then
        gen_ios_icon $DIR 22x22 44x44 66x66
    fi

    # UITableViewCell
    if [ $TYPE = tableviewcell ]; then
        gen_ios_icon $DIR 25x25 50x50 75x75
    fi

    # Create Contents.json file.
    cat << EOF > $DIR/Contents.json
{
    "images" : [
        {
            "idiom" : "universal",
            "filename" : "$FILE_1X",
            "scale" : "1x"
        },
        {
            "idiom" : "universal",
            "filename" : "$FILE_2X",
            "scale" : "2x"
        },
        {
            "idiom" : "universal",
            "filename" : "$FILE_3X",
            "scale" : "3x"
        }
    ],
    "info" : {
        "version" : 1,
        "author" : "ios_icon_set"
    }
} 
EOF
}

if [ $PLATFORM = android ]; then
    handle_android
fi

if [ $PLATFORM = ios ]; then
    handle_ios
fi

# Delete temporary files
rm $FILE_COPY
if [ $COLORIZE -ne 0 ]; then
    rm $FILE_NAME_COLORIZED$EXT
fi