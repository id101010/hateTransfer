#!/bin/bash
#
# Convert and transfer your FLAC music to an android phone in one single step!
#
# The script assumes that you have a music library of the following form:
# $(MUSIC_DIR)/Interpret/Album
#
# Example: hateTransfer "Swallow the Sun" "Spawn of Possession" ...
#
# TODO: Helpfile

# Some options
QUALITY="-b 320 --quality=0"
MP3LIB="/home/${USER}/mp3fs/"
FLACLIB="/home/${USER}/Music/"
ANDROIDLIB="/mnt/sdcard/Music/"

# Some useful variables
NOT_PRESENT="List of devices attached"
ADB_FOUND=$(adb devices | tail -2 | head -1 | cut -f 1 | sed 's/ *$//g')

# functions ------------------------------------------------------------------------
die(){
    # Cleanup
    kill `pgrep mp3fs`
    kill `pgrep adb`

    # Exit with error
    exit 1
}

cleanup(){
    # Cleanup
    kill `pgrep mp3fs`
    kill `pgrep adb`

    # Exit with error
    exit 1
}

# Create mp3fs mountpoint if it isn't already there ---------------------------------
if [ ! -d ${MP3LIB} ]
then
    mkdir ${MP3LIB}
fi

# Check if mp3fs is running ---------------------------------------------------------
if [ -z "$(pgrep mp3fs)" ]
then
    echo -e "[\033[32m:)\033[m] starting mp3fs."
    mp3fs ${QUALITY} ${FLACLIB} ${MP3LIB}
else
    echo -e "[\033[32m:)\033[m] mp3fs is running."
fi

# Check if adb is running -----------------------------------------------------------
if [ -z "$(pgrep adb)" ]
then
    adb start-server
else
    echo -e "[\033[32m:)\033[m] adb server is running."
fi

# Check if any android device is connected ------------------------------------------
if [ "${ADB_FOUND}" == "${NOT_PRESENT}" ] 
then
	echo -e "[\033[31m:(\033[m] Android device seems to be missing."
	die
else
	echo -e "[\033[32m:)\033[m] Android device ${ADB_FOUND} found."
fi

# Check if each folder exists in your library ----------------------------------------
for arg in "$@"
do
    if [ -d "${MP3LIB}${arg}" ]
    then
        echo -e "[\033[32m:)\033[m] Folder \033[93m${arg}\033[m exists in your library."
    else
        echo -e "[\033[31m:(\033[m] Folder \033[93m${arg}\033[m doesn't exist in your library!"
        die
    fi
done

# Check if there is enough space on the device --------------------------------------
cd ${MP3LIB}
NEED=$(du -hcs "${@}" | tail -1 | awk '{print $1}' | sed 's/[^0-9]*//g')
FREE=$(adb shell busybox df -m | tail -1 | awk '{print $4}')

if [ "$FREE" \> "$NEED" ]
then
    echo -e "[\033[32m:)\033[m] Enough Space on the device. Free=$FREE[MB] Needed=$NEED[MB]."
else
    echo -e "[\033[31m:(\033[m] Not enough space left. Free=$FREE[MB] Needed=$NEED[MB]."
    die
fi

# For each given folder check if its already on the phone
# If not, upload it
for arg in "$@"
do
    # Assemble paths and escape the android path for the sh shell
    CURR_FILE_AND="${ANDROIDLIB}${arg}"
    CURR_FILE_LIB="${MP3LIB}${arg}"
    FILE="$(echo ${CURR_FILE_AND} | sed 's/ /\\ /g')"
    CHECK=$(adb shell "if [ -e "${FILE}" ]; then echo -n "err"; else echo -n  "ok"; fi")

    # Only opload if the folder doesn't exist
    if [ ${CHECK} == "err" ] 
    then
        echo -e "[\033[31m:(\033[m] \033[93m${arg}\033[m Already uploaded, skipping!"
    else
        echo -e "[\033[32m:)\033[m] \033[93m${arg}\033[m Doesn't exist on phone!"
        echo -e "[\033[32m:)\033[m] Uploading \033[94m${CURR_FILE_LIB}\033[m to \033[94m${CURR_FILE_AND}\033[m"
        echo -e "\033[94m"
        adb push "${CURR_FILE_LIB}" "${CURR_FILE_AND}"
        echo -e "\033[m"
    fi
done

cleanup
