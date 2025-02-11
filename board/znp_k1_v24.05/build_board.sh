#!/bin/bash

#拉取指定分支代码
function board_pull_source {
    check_armbian_source "v24.05"
}

#将配置和patch应用到源码
function board_patch {
    rsync -av --progress board/$BOARD  build/
}

#编译
function board_armbian_compile {
    cd build/
    ./compile.sh build BOARD=makego BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=bookworm
    cd -
}