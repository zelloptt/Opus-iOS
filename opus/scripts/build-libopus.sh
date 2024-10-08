#!/bin/bash
#  Builds libopus for all three current iPhone targets: iPhoneSimulator-i386,
#  iPhoneOS-armv6, iPhoneOS-armv7.
#
#  Copyright 2012 Mike Tigas <mike@tig.as>
#
#  Based on work by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Choose your libopus version and your currently-installed iOS SDK version:
#
# libopus version
VERSION="1.5.2"
# iOS SDK version
SDKVERSION="$(xcrun --sdk iphoneos --show-sdk-version)"
# Minimum iOS deployment target
MINIOSVERSION="12.1"

#  This breaks linking in Xcode so keep it off for now
LTO="false"

###########################################################################
#
# Don't change anything under this line!
#
###########################################################################

# by default, we won't build for debugging purposes
if [ "${DEBUG}" == "true" ]; then
    echo "Compiling for debugging ..."
    OPT_CFLAGS="-O0 -fno-inline -g"
    OPT_LDFLAGS=""
    OPT_CONFIG_ARGS="--enable-assertions --disable-asm"
else
    if [ "${LTO}" == "true" ]; then 
	echo "Compiling with link time optimization (LTO)"
    	OPT_CFLAGS="-Ofast -flto -g"
    	OPT_LDFLAGS="-flto"
    else
    	OPT_ ="-Ofast -g"
    	OPT_LDFLAGS=""
    fi
    OPT_CONFIG_ARGS=""
fi


# No need to change this since xcode build will only compile in the
# necessary bits from the libraries we create
SIMULATOR_ARCHS="x86_64 arm64"
ARCHS="arm64"

DEVELOPER=`xcode-select -print-path`

cd "`dirname \"$0\"`"
BUILDROOT="${DERIVED_FILE_DIR}/libopus"

# Where we'll end up storing things in the end
OUTPUTDIR="${PROJECT_TEMP_DIR}/libopus"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib

HEADERDIR="${PROJECT_DIR}/../dependencies/include"

# where we will keep our sources and build from.
SRCDIR="${BUILDROOT}/src"
echo "Created build src directory: ${SRCDIR}"

mkdir -p "${SRCDIR}"
# where we will store intermediary builds
INTERDIR="${BUILDROOT}/built"
mkdir -p "${INTERDIR}"

########################################

cd "${SRCDIR}"

# Exit the script if an error happens
set -e

if [ ! -e "${SRCDIR}/opus-${VERSION}.tar.gz" ]; then
	echo "Downloading opus-${VERSION}.tar.gz"
	curl -LO http://downloads.xiph.org/releases/opus/opus-${VERSION}.tar.gz
fi
echo "Using opus-${VERSION}.tar.gz"

tar zxf opus-${VERSION}.tar.gz -C "${SRCDIR}"

cd "${SRCDIR}/opus-${VERSION}"

set +e # don't bail out of bash script if ccache doesn't exist
CCACHE=`which ccache`
if [ $? == "0" ]; then
	echo "Building with ccache: $CCACHE"
	CCACHE="${CCACHE} "
else
	echo "Building without ccache"
	CCACHE=""
fi
set -e # back to regular "bail out on error" mode

export ORIGINALPATH="${PATH}"

# Builds a single architecture of the libopus static library
build_slice () {
    mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

    local CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"

    ./configure --enable-float-approx --disable-asm --disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
		--prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
		LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -L${OUTPUTDIR}/lib" \
		CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \

    # Build the application and install it to the fake SDK intermediary dir
    # we have set up. Make sure to clean up afterward because we will re-use
    # this source tree to cross-compile other targets.
    make -j4
    make install
    make clean
}

# Simulator for x86
ARCH="x86_64"
PLATFORM="iPhoneSimulator"
EXTRA_CFLAGS="-arch ${ARCH}"
EXTRA_CONFIG="--host=x86_64-apple-darwin"
build_slice

# Simulator for Apple Silicon
ARCH="arm64"
PLATFORM="iPhoneSimulator"
EXTRA_CFLAGS="-arch ${ARCH} -target arm64-apple-ios${MINIOSVERSION}-simulator"
EXTRA_CONFIG="--host=arm-apple-darwin"
build_slice

# iOS device
ARCH="arm64"
PLATFORM="iPhoneOS"
EXTRA_CFLAGS="-arch ${ARCH} -fembed-bitcode"
EXTRA_CONFIG="--host=arm-apple-darwin"
build_slice

########################################

echo "Build library..."

# Creates a fat/universal static library file
# $1: output library filename
# $2: platform
# $3: list of architectures for the platform
create_fatlib () {
    local OUTPUT="$1"
    local PLATFORM="$2"
    local FATLIB_ARCHS="$3"

    local INPUT_LIBS=""
    for ARCH in ${FATLIB_ARCHS}; do
	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
	if [ -e $INPUT_ARCH_LIB ]; then
    	    INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
	fi
    done
    if [ -n "$INPUT_LIBS"  ]; then
	mkdir -p "${OUTPUTDIR}/${PLATFORM}/lib"
	lipo -create $INPUT_LIBS \
	     -output "${OUTPUTDIR}/${PLATFORM}/lib/${OUTPUT_LIB}"
    else
	echo "$OUTPUT_LIB does not exist, skipping (are the dependencies installed?)"
    fi
}

# These are the libs that comprise libopus.
OUTPUT_LIBS="libopus.a"
for OUTPUT_LIB in ${OUTPUT_LIBS}; do
    create_fatlib "$OUTPUT_LIB" "iPhoneSimulator" "$SIMULATOR_ARCHS"
    create_fatlib "$OUTPUT_LIB" "iPhoneOS" "$ARCHS"
done

# Copy headers
if [ ! -d "${HEADERDIR}" ]
then
  mkdir -p "${HEADERDIR}"
fi
for ARCH in ${ARCHS}; do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ];
    then
      PLATFORM="iPhoneSimulator"
    else
      PLATFORM="iPhoneOS"
    fi
    cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/* "${HEADERDIR}"
    if [ $? == "0" ]; then
	# We only need to copy the headers over once. (So break out of forloop
	# once we get first success.)
	echo "Successfully copied headers"
	break
    else
	echo "Failed to copy headers"
    fi
done


####################

echo "Building done."
echo "Cleaning up..."
rm -fr ${INTERDIR}
rm -fr "${SRCDIR}/opus-${VERSION}"
echo "Done."
