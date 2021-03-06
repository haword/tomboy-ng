#!/bin/bash
# copyright David Bannon, 2019, no license, use as you see fit.
# -------------------------------------------------------------
# A script to build tomboy-ng from source without using the Lazarus GUI
# You still need to get Lazarus LCL and various other parts of its package
# and the easy (only?) way to get that is to download lazarus source but
# you only need to build selected parts of it and don't need to activate 
# the GUI. As a prerequisite (for tomboy-ng) you need svn, fpc, lazarus source
# and kcontrols source. You might, for example -
#
# mkdir Pascal
# cd Pascal
# svn checkout http://svn.freepascal.org/svn/lazarus/tags/lazarus_2_0_0 Laz_Test
# wget https://bitbucket.org/tomkrysl/kcontrols/get/e826181ebbeb.zip 
# unzip e826181ebbeb.zip
# wget https://github.com/tomboy-notes/tomboy-ng/archive/v0.20.zip
# unzip v0.20.zip
# 
# And you are ready to go. NOTE - directory names above may NOT MATCH THE SCRIPT
# the names in the script are for my use and suit my installs - change them !

CPU="x86_64"
OS="linux"
PROJ="Tomboy_NG"
SOURCE_DIR="$HOME/Pascal/tomboy-ng/tomboy-ng"

TARGET="$CPU-$OS"
LAZ_FULL_DIR="$HOME/Pascal/Laz_Test"
K_DIR="$HOME/Pascal/tomkrysl-kcontrols-e826181ebbeb/packages/kcontrols/"
WIDGET="gtk2"
COMPILER="/usr/bin/fpc"
VERSION=`cat "$SOURCE_DIR/../package/version"`
TEMPCONFDIR=`mktemp -d`
# lazbuild writes, or worse might read a default .lazarus config file. We'll distract it later.

if [ "$1" == "full" ]; then

    echo "-------------- Building lazbuild -------------------"
    cd "$LAZ_FULL_DIR"
    make lazbuild

    echo "-------------- Building LCL (and friends) ----------"
    make lcl 1> somelog_2.txt

    echo "-------------- Compiling KControls -----------------"
    cd $K_DIR
    LAZBUILD="$LAZ_FULL_DIR/lazbuild  --pcp="$TEMPCONFDIR" --cpu=$CPU --widgetset=$WIDGET --lazarusdir=$LAZ_FULL_DIR kcontrolslaz.lpk"
    echo "Laz build command is $LAZBUILD"
    $LAZBUILD
    rm -Rf "$TEMPCONFDIR"
else
    if [ -n "$1" ]; then
        echo "usage : $0 [full]"
        echo "           full will also compile lazbuild, LCL and KControls if necessary"
        exit
    fi        
fi

cd $SOURCE_DIR

# DEBUG options -O1,   (!) -CX, -g, -gl, -vewnhibq

OPT1="-MObjFPC -Scghi -CX -Cg -O3 -XX -Xs -l -vewnibq -Fi$SOURCE_DIR/lib/$TARGET"

UNITS="$UNITS -Fu$K_DIR/lib/$TARGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/components/tdbf/lib/$TARGET/$WIDGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/components/printers/lib/$TARGET/$WIDGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/components/cairocanvas/lib/$TARGET/$WIDGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/components/lazcontrols/lib/$TARGET/$WIDGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/components/lazutils/lib/$TARGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/components/ideintf/units/$TARGET/$WIDGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/lcl/units/$TARGET/$WIDGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/lcl/units/$TARGET"
UNITS="$UNITS -Fu$LAZ_FULL_DIR/packager/units/$TARGET"

UNITS="$UNITS -Fu$SOURCE_DIR/"
UNITS="$UNITS -FU$SOURCE_DIR/lib/$TARGET/" 


OPTS2=" -FE$SOURCE_DIR/ -o$SOURCE_DIR/project1 -dLCL -dLCL$WIDGET"
DEFS="-dDisableLCLGIF -dDisableLCLJPEG -dDisableLCLPNM -dDisableLCLTIFF"
# reported to reduce binary size but made no difference for me
# http://wiki.lazarus.freepascal.org/Lazarus_2.0.0_release_notes#Compiler_defines_to_exclude_some_graphics_support


# We must force a clean compile, no make looking after us here.
# I have not found a way of telling the compiler to write its .o and .ppu files
# somewhere else so not to compete with Lazarus, but both this script and Lazarus
# is quite happy to write new ones whenever needed. So, flush it clean. 
if [ -d "lib/$TARGET" ]; then
    rm -Rf "lib/$TARGET"
fi
mkdir -p "lib/$TARGET"

if [ -f "$PROJ" ]; then
    rm "$PROJ"
fi

echo "----------------------- Building tomboy-ng ----------------"
RUNIT="$COMPILER $OPT1 $UNITS $OPT2 $DEFS $PROJ.lpr"
TOMBOY_NG_VER="$VERSION" $RUNIT
echo "OK, lets see how we got on "
ls -l "$PROJ"

