#!/usr/bin/env bash
# Use tcbuild build script as LLVM Build Script.
git clone https://github.com/cbendot/tcbuild -b llvm-tc && cd tcbuild
bash build-tc.sh
