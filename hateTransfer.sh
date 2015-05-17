#!/bin/bash
#
# Transfers all your finest death metal to your phone!;-)
#
# Usage: hateTransfer [List of Music]
#

# Some options
QUALITY='-b 320 --quality=0'
MP3LIB="/home/${USER}/mp3fs/"
FLACLIB="/home/${USER}/Music/"
ANDROIDLIB='/mnt/sdcard/Music/'

# Create mp3fs mountpoint if not exists
if [ ! -d ${MP3LIB} ]
then
    mkdir ${MP3LIB}
fi

# Check if mp3fs is running.
if [ -z "$(pgrep mp3fs)" ]
then
    mp3fs ${QUALITY} ${FLACLIB} ${MP3LIB}
else
    echo "[DEBUG]: mp3fs is running."
fi

# Check if adb is running.
if [ -z "$(pgrep adb)" ]
then
    adb start-server
else
    echo "[DEBUG]: adb server is running."
fi

# Perform some error checks and upload the music to the phone
for arg in "$@"
do
    FILE="${ANDROIDLIB}$(echo ${arg}| sed 's/ /\\ /g')/"

    if [ -d "${MP3LIB}${arg}" ]
    then
        
        CHECK="$(adb shell "if [ -d ${FILE} ]; then echo -n "err"; fi")"

        if [ -z "${CHECK}" ]
        then

            FREE=$(adb shell busybox df     | tail -1 | awk '{print $4}')
            NEED=$(du "${MP3LIB}${arg}"   | tail -1 | awk '{print $1}')
        
            if [ "$FREE" -gt "$NEED" ]
            then
                echo "[DEBUG]: Uploading [${arg}] to [${FILE}]"
                adb push "${MP3LIB}${arg}" "${FILE}"
            else 
                echo "[ERROR]: Not enough space available on your device!"
            fi
        else
            echo "[ERROR]: [${arg}] already uploaded!"
        fi
    else
        echo "[ERROR]: No such folder in your library! [${MP3LIB}${arg}]"
    fi
done
