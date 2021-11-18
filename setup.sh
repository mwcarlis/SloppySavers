#!/bin/bash

# Bash script to copy source files into my Addon Directory.

# If you save this file in windows, it will use Windows style
#   newline characters, and then fail to work in bash.
# If you have windows newline characters run "dos2unix setup.py" to fix.

if [ -z "$CLASSIC_ADDONDIR" ]; then
    echo "User Must 'export CLASSIC_ADDONDIR=<your Interface/Addons>' Directory"
    exit 1
fi

set -x

cp SloppySavers.lua /media/sf__classic_/Interface/AddOns/SloppySavers
cp SloppySavers.toc /media/sf__classic_/Interface/AddOns/SloppySavers

