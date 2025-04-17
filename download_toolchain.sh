#!/bin/bash

# Download the Toolchain from the Github releases
download_ndk(){

    NDK_SPLIT_LINKS=(
        "https://github.com/ravindu644/sunfish-ksun/releases/download/NDK/pixel4a-prebuilds.tar.gz.z01"
        "https://github.com/ravindu644/sunfish-ksun/releases/download/NDK/pixel4a-prebuilds.tar.gz.z02"
        "https://github.com/ravindu644/sunfish-ksun/releases/download/NDK/pixel4a-prebuilds.tar.gz.zip"
    )

    for LINK in ${NDK_SPLIT_LINKS[@]}; do
        echo -e "\n[INFO] Downloading: $(basename $LINK)\n"
        curl -LO "$LINK"
    done

    echo -e "\n[INFO] Extracting...\n"

    7z x pixel4a-prebuilds.tar.gz.zip && \
        rm -rf pixel4a-prebuilds.tar.gz.z*

    tar -xf pixel4a-prebuilds.tar.gz && \
        rm -rf pixel4a-prebuilds.tar.gz
}
