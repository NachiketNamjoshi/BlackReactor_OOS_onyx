#!/bin/bash

##################################################
##################################################
# 												 #
# 	  Copyright (c) 2016, Nachiket.Namjoshi		 #
# 			 All rights reserved.				 #
# 												 #
# 	BlackReactor Kernel Build Script beta - v0.1 #
# 												 #
##################################################
##################################################

#For Time Calculation
BUILD_START=$(date +"%s")

# Housekeeping
blue='\033[0;34m'
cyan='\033[0;36m'
green='\033[1;32m'
red='\033[0;31m'
nocol='\033[0m'

# 
# Configure following according to your system
# 

# Directories
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/arch/arm/boot/zImage-dtb
OUT_DIR=$KERNEL_DIR/zipping/onyx
REACTOR_VERSION="OOS-beta-112"
MODULES_DIR=$KERNEL_DIR/zipping/common
STRIP="ccache /home/nachiket/Android/onyx/kernel/toolchains/4.9/bin/arm-linux-androideabi-strip"
# Device Spceifics
export ARCH=arm
export CROSS_COMPILE="ccache /home/nachiket/Android/onyx/kernel/toolchains/4.9/bin/arm-linux-androideabi-"
export KBUILD_BUILD_USER="nachiket"
export KBUILD_BUILD_HOST="reactor"


########################
## Start Build Script ##
########################

# Remove Last builds
rm -rf $OUT_DIR/*.zip
rm -rf $OUT_DIR/zImage
rm -rf $OUT_DIR/dtb.img
rm -rf $OUT_DIR/modules/*

compile_kernel ()
{
echo -e "$green ********************************************************************************************** $nocol"
echo "                    "
echo "                                   Compiling BlackReactor-Kernel                    "
echo "                    "
echo -e "$green ********************************************************************************************** $nocol"
make onyx_mm-perf_defconfig
make -j64
if ! [ -a $KERN_IMG ];
then
echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
exit 1
fi
strip_modules
zipping
}

strip_modules ()
{
echo "Copying modules"
rm $MODULES_DIR/*
find . -name '*.ko' -exec cp {} $MODULES_DIR/ \;
cd $MODULES_DIR
echo "Stripping modules for size"
$STRIP --strip-unneeded *.ko
zip -9 modules *
cd $KERNEL_DIR
}


zipping() {

# make new zip
cp $KERN_IMG $OUT_DIR/zImage
cp $MODULES_DIR/*.ko $OUT_DIR/modules/
cd $OUT_DIR
zip -r -9 BlackReactor-onyx-$REACTOR_VERSION-$(date +"%Y%m%d")-$(date +"%H%M%S").zip *

}

get_md5() {
TARGET_ZIP_NAME=$(ls $OUT_DIR | grep -i "black")
TARGET_ZIP="$OUT_DIR/$TARGET_ZIP_NAME"
echo -e " OUT: $(md5sum $TARGET_ZIP | awk '{print $1}') $(basename $TARGET_ZIP)" > $PRODUCT_INFO
}

compile_kernel
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$blue Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo -e "$red zImage size (bytes): $(stat -c%s $KERN_IMG) $nocol"
notify-send "Compilation Has Finished!"