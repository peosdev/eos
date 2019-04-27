#!/bin/bash
set -eo pipefail
# prepare environment
PATH=$PATH:~/opt/mongodb/bin
echo "[Extracting build directory]"
[[ -z "${1}" ]] && tar -zxf build.tar.gz || tar -xzf $1
echo "[Starting MongoDB]"
mongod --fork --dbpath ~/data/mongodb -f ~/etc/mongod.conf --logpath "$(pwd)"/mongod.log
cd ./build
# run tests
echo "[Running tests]"
ctest -L nonparallelizable_tests --output-on-failure -T Test

mv $(pwd)/Testing/$(ls $(pwd)/Testing/ | grep '20' | tail -n 1)/Test.xml test-results.xml