# hateTransfer

_A fork of the hateTransfer-script which makes the script actully usable_

![Example use](https://github.com/id101010/hateTransfer/blob/master/doc/screen.png)

A little skript which helps you to convert and upload lossless music to your android phone in one single step!

## Synopsis
Got a lossless music collection? Ever wanted to upload mp3 versions of your music to your phone due to limited storage? Thanks to [mp3fs](https://khenriks.github.io/mp3fs/) (check it out, awesome project!) theres a solution without keeping two separated music libraries.
If you're wondering about the name, it's kind of intendet to get death metal on my phone, if you don't like it, change it. I don't care. ;)

## Main Features
You're not sure if you already uploaded something? Nevermind, the script will handle it!
The needed space on the phone will be calculatet before uploading aswell, so there are no bad surprises during the upload.

## Usage
Basically just throw a bunch of folders in there and the script will handle the rest. 

e.g.: $ hateTransfer "Six Feet Under" Aborted Acranius "God Dethroned"

## Requirements
Android phone
* busybox

Computer
* adb
* mp3fs
