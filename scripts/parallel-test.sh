#!/bin/bash
set -eo pipefail
echo "[Extracting build directory]"
[[ -z "${1}" ]] && tar -zxf build.tar.gz || tar -xzf $1
echo "[Running tests]"
cd ./build
ctest -j $(getconf _NPROCESSORS_ONLN) -LE _tests --output-on-failure -T Test
# Prepare tests for artifact upload
mv $(pwd)/Testing/$(ls $(pwd)/Testing/ | grep '20' | tail -n 1)/Test.xml test-results.xml