#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Needed Secret Variable
# KERNEL_NAME | Your kernel name
# KERNEL_SOURCE | Your kernel link source
# KERNEL_BRANCH  | Your needed kernel branch if needed with -b. eg -b eleven_eas
# DEVICE_CODENAME | Your device codename
# DEVICE_DEFCONFIG | Your device defconfig eg. lavender_defconfig
# ANYKERNEL | Your Anykernel link repository
# TG_TOKEN | Your telegram bot token
# TG_CHAT_ID | Your telegram private ci chat id
# BUILD_USER | Your username
# BUILD_HOST | Your hostname

echo "|| Downloading few Dependecies . . .||"
# Kernel Sources
git clone --depth=1 $KERNEL_SOURCE $KERNEL_BRANCH $DEVICE_CODENAME
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-master gcc64 # gcc64 set as Default
git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git -b gcc-master gcc32 # gcc32 set as Default

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/$DEVICE_CODENAME # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_DEFCONFIG=$DEVICE_DEFCONFIG # IMPORTANT ! Declare your kernel source defconfig file here.
GCC64_ROOTDIR=$(pwd)/gcc64 # IMPORTANT! Put your GCC directory here.
GCC32_ROOTDIR=$(pwd)/gcc32 # IMPORTANT! Put your GCC directory here.
export KBUILD_BUILD_USER=$BUILD_USER # Change with your own name or else.
export KBUILD_BUILD_HOST=$BUILD_HOST # Change with your own hostname.

# Main Declaration
KBUILD_COMPILER_STRING=$("$GCC64_ROOTDIR"/bin/aarch64-elf-gcc --version | head -n 1 )
PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
export KBUILD_COMPILER_STRING
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date "+%B %-d, %Y")
ZIP_DATE=$(date +"%Y%m%d")
START=$(date +"%s")

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo xKernelCompiler
echo version : rev1.5 - gaspoll modified
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo TOOLCHAIN_VERSION = ${KBUILD_COMPILER_STRING}
echo GCC64_ROOTDIR = ${GCC64_ROOTDIR}
echo GCC32_ROOTDIR = ${GCC32_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}

# Post Main Information
tg_post_msg "<b>🔨 Building Kernel Started!</b>%0A<b>Builder Name: </b><code>${KBUILD_BUILD_USER}</code>%0A<b>Builder Host: </b><code>${KBUILD_BUILD_HOST}</code>%0A<b>Build For: </b><code>$DEVICE_CODENAME</code>%0A<b>Build Date: </b><code>$DATE</code>%0A<b>Build started on: </b><code>CircleCI</code>%0A<b>GCC Rootdir : </b><code>${GCC64_ROOTDIR}</code>%0A<code>${GCC32_ROOTDIR}</code>%0A<b>Kernel Rootdir : </b><code>${KERNEL_ROOTDIR}</code>%0A<b>Compiler Info:</b>%0A<code>${KBUILD_COMPILER_STRING}</code>%0A%0A1:00 ●━━━━━━─────── 2:00 ⇆ㅤㅤㅤ ㅤ◁ㅤㅤ❚❚ㅤㅤ▷ㅤㅤㅤㅤ↻"

# Compile
compile(){
tg_post_msg "<b>xKernelCompiler:</b><code>Compilation has started"
cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
make -j$(nproc) ARCH=arm64 O=out \
    AR=aarch64-elf-ar \
    OBJDUMP=aarch64-elf-objdump \
    OBJCOPY=aarch64-elf-objcopy \
    STRIP=aarch64-elf-strip \
    NM=aarch64-elf-nm \
    LD=aarch64-elf-ld.lld \
    CROSS_COMPILE=${GCC64_ROOTDIR}/bin/aarch64-elf- \
    CROSS_COMPILE_ARM32=${GCC32_ROOTDIR}/bin/arm-eabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi

  git clone --depth=1 $ANYKERNEL AnyKernel
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)"
}

# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [LV][OC]$KERNEL_NAME-EAS-${ZIP_DATE}.zip *
    cd ..

}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
