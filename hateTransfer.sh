#!/bin/bash
#
# Convert and transfer your FLAC music to an android phone in one single step!
#
# The script assumes that you have a music library of the following form:
# $(MP3LIB)/Interpret/Album
#
# Example: hateTransfer "Swallow the Sun" "Spawn of Possession" ...
#
# TODO: Helpfile

# Some options
DEBUG=${DEBUG-false}
QUALITY=${QUALITY-"-b 320 --quality=0"}
MP3LIB=${MP3LIB-"${HOME}/mp3fs/"}
FLACLIB=${FLACLIB-"${HOME}/Music/"}
ANDROIDLIB=${ANDROIDLIB-"/mnt/sdcard/Music/"}

# Some useful variables
ADB_FOUND=$(adb devices | sed -nre 's/^([^\s]+)\s+device.*/\1/pg')

#Colors 
RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'

usage() {
cat << EOF
    Usage: $0 [list]
    This script helps you convert and upload lossless music to your android phone in one single step.

    ENVIRONMENT:
        DEBUG       : set to true for debug output [${DEBUG}]
        QUALITY     : quality options [${QUALITY}]
        MP3LIB      : path to your mp3fs [${MP3LIB}]
        FLACLIB     : path to yoru flac library [${FLACLIB}]
        ANDROIDLIB  : path to your mounted andorid [${ANDROIDLIB}]
    
EOF
}

cleanup() {
    # Cleanup
    pkill mp3fs
    pkill adb
}

debug() {
    if ${DEBUG}; then
        echo -e "${YELLOW}$*${RESTORE}"
    fi
}

error() {
    echo -e "${RED}$*${RESTORE}"
    cleanup
    exit 1
}

null() {
    "$@" &>/dev/null
}

# Check if there are any arguments given
if (( ${#} == 0 )); then
    usage
    error "invalid argument count: ${#}"
fi

# Create environment
mkdir -p "${MP3LIB}" "${FLACLIB}"

# Check if mp3fs is running
if ! null pgrep mp3fs; then
    debug "starting mp3fs"
    mp3fs ${QUALITY} ${FLACLIB} ${MP3LIB}
fi

# Check@if adb is running
if ! null pgrep adb; then
    debug "starting adb server"
    adb start-server
fi

# Check if any android device is connected
if [ ! "${ADB_FOUND}" ]; then
    error "android device seems to be missing"
else
    debug "android device ${ADB_FOUND} found"
fi

# Transfer
for arg in "$@"; do
    src="${MP3LIB}/${arg}"
    dst="${ANDROIDLIB}/${arg}"
    if [ ! -d "${src}" ]; then
        error "folder: ${src} doesn't exist"
    fi
    need=$(du -hcs "${src}" | tail -1 | awk '{print $1}' | sed -nre 's/^([0-9]+).*/\1/pg')
    free=$(adb shell busybox df -m | tail -1 | awk '{print $4}')
    if (( $need >= $free )); then
        error "not enough space left free: ${free} MiB needed: ${need} MiB"
    fi
    exists_on_dst=$(adb shell "if [ -e '${dst}' ]; then echo exists; fi")

    # Only opload if the folder doesn't exist
    if [ ${exists_on_dst} ]; then
        debug "${arg} already uploaded, skipping"
    else
        debug "uploading ${src} to ${dst}"
        adb push "${src}" "${dst}"
    fi
done

cleanup
