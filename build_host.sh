#!/bin/sh -e

ROOTDIR=$(pwd)

# Make CPC
cd cpc
./configure
make

cd ..

# Prepare QEMU
cd qemu
mkdir -p bin/master
mkdir -p bin/cpc

# Build vanilla QEMU
git checkout master
cd bin/master
../../configure --disable-werror \
    --with-coroutine=ucontext    \
    --target-list=x86_64-softmmu \
    --cc="$ROOTDIR/cpc/bin/cpc" \
    --extra-cflags="--dontcpc -U__SSE2__ --save-temps -Wno-unused-variable -Wno-redundant-decls -Wno-deprecated-declarations"
make -j8

# CPC QEMU does not work yet
exit 0

# Build CPC QEMU
cd ..
git checkout cpc
cd bin/cpc
../../configure --disable-werror \
    --with-coroutine=cpc         \
    --target-list=x86_64-softmmu \
    --cc="$ROOTDIR/cpc/bin/cpc" \
    --extra-cflags="-U__SSE2__ --save-temps -Wno-unused-variable -Wno-redundant-decls -Wno-deprecated-declarations"
make -j8
