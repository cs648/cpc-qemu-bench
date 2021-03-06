#!/bin/sh -e

# Use DONTCLEAN=1 ./build_host.sh to avoid rebuilding everything

ROOTDIR="$(pwd)"

CONFIGOPTS="--disable-werror --target-list=x86_64-softmmu"
CILOPTS="--save-temps --noMakeStaticGlobal --useLogicalOperators \
  --useCaseRange"
GCCOPTS="-U__SSE2__ -Wno-unused-variable -Wno-redundant-decls \
  -Wno-deprecated-declarations -Dcoroutine_fn='__attribute__((cps))' -w"
COROOPTS="--load=$ROOTDIR/corocheck/_build/corocheck.cma \
  --doCoroCheck --coopAttr=cps --blockAttr=nocps"

CILBIN="$ROOTDIR/cil/bin/cilly"
CPCBIN="$ROOTDIR/cpc/bin/cpc"

# Make CIL
cd cil
if [ -z "$DONTCLEAN" ]; then
  git clean -fdx
fi
git checkout develop
git pull
./configure
make

cd ..

# Make CoroCheck
cd corocheck
if [ -z "$DONTCLEAN" ]; then
  git clean -fdx
fi
git checkout master
git pull
# Force clean: fast to build, make sure its consistent with latest CIL
make clean all OCAMLPATH=$ROOTDIR/cil/lib

cd ..

# Make CPC
cd cpc
if [ -z "$DONTCLEAN" ]; then
  git clean -fdx
fi
git checkout develop
git pull
./configure
make

cd ..

# Prepare QEMU
cd qemu
if [ -z "$DONTCLEAN" ]; then
  git clean -fdx
fi
mkdir -p bin/gcc-ucontext
mkdir -p bin/cil-ucontext
mkdir -p bin/cpc-ucontext
mkdir -p bin/cpc-cpc

# Build gcc-ucontext QEMU

# We want to use the same code for all four binaries
git checkout convert-block-part2
git pull

cd bin/gcc-ucontext
../../configure $CONFIGOPTS \
    --with-coroutine=ucontext    \
    --extra-cflags="$GCCOPTS"
make -j8

cd ../..

# Build cil-ucontext QEMU (with CoroCheck)

cd bin/cil-ucontext
../../configure $CONFIGOPTS \
    --with-coroutine=ucontext    \
    --cc="$CILBIN" \
    --extra-cflags="$GCCOPTS $CILOPTS $COROOPTS" 
make -j8

cd ../..

# Build  cpc-ucontext QEMU

cd bin/cpc-ucontext
../../configure $CONFIGOPTS \
    --with-coroutine=ucontext    \
    --cc="$CPCBIN" \
    --extra-cflags="--dontcpc $GCCOPTS $CILOPTS"
make -j8

cd ../..

# Build CPC QEMU

cd bin/cpc-cpc
../../configure $CONFIGOPTS \
    --with-coroutine=cpc    \
    --cc="$CPCBIN" \
    --extra-cflags="$GCCOPTS $CILOPTS"
make -j8

cd ../..
