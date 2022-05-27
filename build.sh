#!/usr/bin/env bash

# Secret Variable for CI
# LLVM_NAME | Your desired Toolchain Name
# TG_TOKEN | Your Telegram Bot Token
# TG_CHAT_ID | Your Telegram Channel / Group Chat ID
# GH_USERNAME | Your Github Username
# GH_EMAIL | Your Github Email
# GH_TOKEN | Your Github Token ( repo & repo_hook )
# GL_TOKEN | Your GitLab Token 
# GH_PUSH_REPO_URL | Your GitHub Repository for store compiled Toolchain ( without https:// or www. ) ex. github.com/xyz-prjkt/xRageTC.git
# GL_PUSH_REPO_URL | Your GitLab Repository

# Function to show an informational message

# Use tcbuild build script as LLVM Build Script.
# https://raw.githubusercontent.com/cbendot/tcbuild/llvm-tc/build-tc.sh