#!/bin/bash

set -x
set -e

echo "--- Env"
# Use the compiler as a frontend for the linker
export LD=${CC}

echo "--- Configure"
pushd src

echo "--- Build"
make

echo "--- Install"
mkdir -p $PREFIX/bin
cp DAlphaBall.gcc $PREFIX/bin/dalphaball

echo "--- Done"
popd
