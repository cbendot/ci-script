#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#
echo "Downloading few Dependecies . . ."
git clone --depth=1 https://github.com/cbendot/elastics-toolchain llvm
git clone --depth=1 https://github.com/cbendot/kernel_asus_sdm660 hard

# Main
KERNEL_ROOTDIR=$(pwd)/hard # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_DEFCONFIG=ElasticsPerf_defconfig # IMPORTANT ! Declare your kernel source defconfig file here.
CLANG_ROOTDIR=$(pwd)/llvm # IMPORTANT! Put your clang directory here.
export KBUILD_BUILD_USER=ben863 # Change with your own name or else.
export KBUILD_BUILD_HOST=LiteSpeed-CloudLinux # Change with your own hostname.

# Main Declaration
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
IMAGE=$(pwd)/hard/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date "+%B %-d, %Y")
START=$(date +"%s")

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo Kernel Compiler Started!
echo version : rev1.5 - gaspoll modified
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo TOOLCHAIN_VERSION = ${KBUILD_COMPILER_STRING}
echo CLANG_ROOTDIR = ${CLANG_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Compiler
function compile() {

   curl -s -X POST "https://api.telegram.org/bot${token}/sendSticker" \
        -d sticker="CAACAgUAAxkBAAEChbdg3-SJAabmOMYa5Pax18UWLnLBVAACpgIAApk4AAFXSahPNJ_y_k0gBA" \
        -d chat_id="${chat_id}"

# Private CI
   curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>🔨 Building Kernel Started!</b>%0ABuilder Name: <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host: <code>${KBUILD_BUILD_HOST}</code>%0ABuild Date: <code>$DATE</code>%0ABuild started on: <code>Drone CI</code>%0AClang Rootdir : <code>${CLANG_ROOTDIR}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>%0ACompiler Info:%0A<code>${KBUILD_COMPILER_STRING}</code>%0A%0A1:00 ●━━━━━━─────── 2:00 ⇆ㅤㅤㅤ ㅤ◁ㅤㅤ❚❚ㅤㅤ▷ㅤㅤㅤㅤ↻"

  cd ${KERNEL_ROOTDIR}
  make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
  make -j$(nproc) ARCH=arm64 O=out \
  	CC=${CLANG_ROOTDIR}/bin/clang \
	AR=${CLANG_ROOTDIR}/bin/llvm-ar \
	NM=${CLANG_ROOTDIR}/bin/llvm-nm \
	OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
	OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
	STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
	CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
        git clone --depth=1 https://github.com/cbendot/AnyKernel3 AnyKernel
	cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot${token}/sendDocument" \
        -F chat_id="${chat_id}" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ <code>$(($DIFF / 60)) minute(s) $(($DIFF % 60)) second(s)</code>  <code>$DATE</code>"
}
        
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Build throw an error(s)%0A%0A<code>$(($DIFF / 60)) minute(s) $(($DIFF % 60)) second(s) </code>"

    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 ElasticsPerf-HMP-${DATE}.zip *
    cd ..
}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
