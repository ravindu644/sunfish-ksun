#!/bin/bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/download_toolchain.sh
mkdir -p ${SCRIPT_DIR}/dist

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

# Localversion
if [ -z "$BUILD_KERNEL_VERSION" ]; then
    export BUILD_KERNEL_VERSION="dev"
fi
echo -e "CONFIG_LOCALVERSION_AUTO=n\nCONFIG_LOCALVERSION=\"-ravindu644-${BUILD_KERNEL_VERSION}\"\n" > "${SCRIPT_DIR}/custom_defconfigs/version_defconfig"

# Build options
export KBUILD_BUILD_USER="@ravindu644"
export MERGE_CONFIG="${SCRIPT_DIR}/private/msm-google/scripts/kconfig/merge_config.sh"

set -x 

export GKI_KERNEL_BUILD_OPTIONS="
    SKIP_MRPROPER=1 \
    BUILD_CONFIG=private/msm-google/build.config.sunfish_no-cfi \
    KMI_SYMBOL_LIST_STRICT_MODE=0 \
    ABI_DEFINITION= \
    BUILD_BOOT_IMG=1 \
    MKBOOTIMG_PATH=${SCRIPT_DIR}/mkbootimg/mkbootimg.py \
    GKI_RAMDISK_PREBUILT_BINARY=ramdisk.gz \
    KERNEL_BINARY=Image.lz4 \
    BOOT_IMAGE_HEADER_VERSION=2 \
    PAGE_SIZE=4096 \
    SKIP_VENDOR_BOOT=1
"
export KERNEL_CMDLINE="console=ttyMSM0,115200n8 androidboot.console=ttyMSM0 printk.devkmsg=on msm_rtb.filter=0x237 ehci-hcd.park=3 service_locator.enable=1 androidboot.memcg=1 cgroup.memory=nokmem lpm_levels.sleep_disabled=1 usbcore.autosuspend=7 loop.max_part=7 loop.hw_queue_depth=31 androidboot.usbcontroller=a600000.dwc3 swiotlb=1 androidboot.boot_devices=soc/1d84000.ufshc cgroup_disable=pressure buildvariant=user"

export MKBOOTIMG_EXTRA_ARGS="
    --base=0x00000000 \
    --os_version 13.0.0 \
    --os_patch_level 2023-06-00
"

# Run menuconfig only if you want to.
# It's better to use MAKE_MENUCONFIG=0 when everything is already properly enabled, disabled, or configured.
export MAKE_MENUCONFIG=1

# Funciton to cook the kernel
build_kernel(){
    env ${GKI_KERNEL_BUILD_OPTIONS} build/build.sh "$@" && \
        cp "${SCRIPT_DIR}/out/android-msm-pixel-4.14/dist/boot.img" "${SCRIPT_DIR}/dist"
}

# Funciton to sign the build boot image
sign_boot(){
    local AVBTOOL="${SCRIPT_DIR}/mkbootimg/avbtool.py"   
    echo -e "\n[INFO] Signing the boot.img...\n"

    ${AVBTOOL} \
        add_hash_footer \
        --partition_name "boot" \
        --partition_size "67108864" \
        --image "${SCRIPT_DIR}/dist/boot.img" \
        --algorithm "SHA256_RSA2048" \
        --key "${SCRIPT_DIR}/mkbootimg/tests/data/testkey_rsa2048.pem"  

}

# Funciton to make a zip out of the built boot image
build_zip(){
    if [ -f "${SCRIPT_DIR}/dist/boot.img" ]; then
        cd "${SCRIPT_DIR}/dist" && \
        zip -9 "Kernel-Pixel-4a-${BUILD_KERNEL_VERSION}" boot.img && \
        rm -f boot.img
        cd "${SCRIPT_DIR}"
    fi
}

# Main build process
( build_kernel
sign_boot ) || exit 1

build_zip
