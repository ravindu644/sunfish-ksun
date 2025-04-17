#!/bin/bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/download_toolchain.sh

# Install the requirements for building the kernel when running the script for the first time
if [ ! -f ".requirements" ]; then
    echo -e "\n[INFO]: INSTALLING REQUIREMENTS..!\n"
    {

    sudo apt update
    sudo apt install -y rsync p7zip-full git device-tree-compiler lz4 xz-utils zlib1g-dev openjdk-17-jdk gcc g++ python3 python-is-python3 android-sdk-libsparse-utils erofs-utils \
    default-jdk git gnupg flex bison gperf build-essential zip curl libc6-dev libncurses-dev libx11-dev libreadline-dev libgl1 libgl1-mesa-dev \
    python3 make sudo gcc g++ bc grep tofrodos python3-markdown libxml2-utils xsltproc zlib1g-dev python-is-python3 libc6-dev libtinfo6 \
    make repo cpio kmod openssl libelf-dev pahole libssl-dev libarchive-tools zstd --fix-missing

    } && touch .requirements
fi

# Check if the Toolchain exists
if [[ ! -d "${SCRIPT_DIR}/prebuilts" ]]; then
    download_ndk
    cd "${SCRIPT_DIR}"
fi

BUILD_CONFIG=private/msm-google/build.config.sunfish_no-cfi build/build.sh "$@"
