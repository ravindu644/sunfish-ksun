#!/bin/bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/download_toolchain.sh

# Install the requirements for building the kernel when running the script for the first time
if [ ! -f ".requirements" ]; then
    echo -e "\n[INFO]: INSTALLING REQUIREMENTS..!\n"
    {
        sudo apt update
        sudo apt install -y rsync p7zip-full
    } && touch .requirements
fi

# Check if the Toolchain exists
if [[ ! -d "${SCRIPT_DIR}/prebuilts" ]]; then
    download_ndk
    cd "${SCRIPT_DIR}"
fi
