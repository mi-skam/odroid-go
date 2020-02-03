#!/usr/bin/env bash 

# SETUP

LOGO=launcher_logo.png
NEEDED_PROGRAMS=( git make ffmpeg getopts )
BIN_DIR=~/.local/bin
TMP_DIR="/tmp/odroidfw_$(date +%Y%M%d-%s)"

while getopts f: option
        do
        case "${option}"
        in
        f) FIRMWARE=${OPTARG};;
        esac
        done

if [ ! -f "$FIRMWARE" ]
then
    echo >&2 "Error: ${FIRMWARE:-<empty>} is not an existing path. Use -f example.ino.bin "; exit 1;
fi

mkdir -p $TMP_DIR

# HELPER
check_programs(){
    for i in "${NEEDED_PROGRAMS[@]}"
    do
        command -v "$i" >/dev/null 2>&1 || { echo >&2 "Error: I require $i but it's not installed.  Aborting."; exit 1; }
    done
}

get_requirements(){    
    # mkspiffs
    git clone https://github.com/igrr/mkspiffs.git $TMP_DIR/mkspiffs
    cd $TMP_DIR/mkspiffs
    git submodule update --init
    make dist
    chmod +x ./mkspiffs
    cp ./mkspiffs $BIN_DIR/
    
    # mkfw
    git clone https://github.com/othercrashoverride/odroid-go-firmware.git -b factory $TMP_DIR/mkfw
    cd $TMP_DIR/mkfw/tools/mkfw
    make
    chmod +x ./mkfw
    cp ./mkfw $BIN_DIR/
}

convert_logo(){
    ffmpeg -i "$LOGO" -f rawvideo -pix_fmt rgb565 launcher_logo.raw
}

make_firmware(){
    $BIN_DIR/mkfw test launcher_logo.raw 0 16 1048576 app "$FIRMWARE"
}


# MAIN

check_programs
get_requirements
convert_logo
make_firmware

# TEAR DOWN
rm -rf $TMP_DIR