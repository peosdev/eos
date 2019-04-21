#!/usr/bin/env bash
set -eio pipefail
VERSION=3.0 # Build script version (change this to re-build the CICD image)
##########################################################################
# This is the EOSIO automated install script for Linux and Mac OS.
# This file was downloaded from https://github.com/EOSIO/eos
#
# Copyright (c) 2017, Respective Authors all rights reserved.
#
# After June 1, 2018 this software is available under the following terms:
#
# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# https://github.com/EOSIO/eos/blob/master/LICENSE
##########################################################################

function usage() {
   printf "Usage: $0 OPTION...
  -o TYPE     Build <Debug|Release|RelWithDebInfo|MinSizeRel> (default: Release)
  -s NAME     Core Symbol Name <1-7 characters> (default: SYS)
  -b DIR      Use pre-built boost in DIR
  -i DIR      Directory to use for dependencies & EOS install (default: $HOME)
  -y          Noninteractive mode (answers yes to every prompt)
  -c          Enable Code Coverage
  -d          Generate Doxygen
   \\n" "$0" 1>&2
   exit 1
}

TIME_BEGIN=$( date -u +%s )
if [ $# -ne 0 ]; then
   while getopts "o:s:b:i:ycdh" opt; do
      case "${opt}" in
         o )
            options=( "Debug" "Release" "RelWithDebInfo" "MinSizeRel" )
            if [[ "${options[*]}" =~ "${OPTARG}" ]]; then
               CMAKE_BUILD_TYPE=$OPTARG
            else
               echo  "Invalid argument: ${OPTARG}" 1>&2
               usage
            fi
         ;;
         s)
            if [ "${#OPTARG}" -gt 7 ] || [ -z "${#OPTARG}" ]; then
               echo "Invalid argument: ${OPTARG}" 1>&2
               usage
            else
               CORE_SYMBOL_NAME=$OPTARG
            fi
         ;;
         b)
            BOOST_LOCATION=$OPTARG
         ;;
         i)
            INSTALL_LOCATION=$OPTARG
         ;;
         y)
            NONINTERACTIVE=true
            PROCEED=true
         ;;
         c )
            ENABLE_COVERAGE_TESTING=true
         ;;
         d )
            DOXYGEN=true
         ;;
         h)
            usage
         ;;
         ? )
            echo "Invalid Option!" 1>&2
            usage
         ;;
         : )
            echo "Invalid Option: -${OPTARG} requires an argument." 1>&2
            usage
         ;;
         * )
            usage
         ;;
      esac
   done
fi

# Load eosio specific helper functions
. ./scripts/lib/eosio.bash

# [[ -d ${EOSIO_HOME} ]] && echo "EOSIO has already been installed into ${EOSIO_HOME}... It's suggested that you eosio_uninstall.bash before re-running this script... Proceeding anyway in 10 seconds..." && sleep 10

# Setup directories and envs we need
setup
# Setup tmp directory; handle if noexec exists
setup-tmp
# Prevent a non-git clone from running
ensure-git-clone

execute cd $REPO_ROOT

# Submodules need to be up to date
ensure-submodules-up-to-date

echo "Beginning build version: ${VERSION}"
echo "$( date -u )"
CURRENT_USER=${CURRENT_USER:-$(whoami)}
echo "User: ${CURRENT_USER}"
# echo "git head id: %s" "$( cat .git/refs/heads/master )"
echo "Current branch: $( execute git rev-parse --abbrev-ref HEAD 2>/dev/null )"

# Use existing cmake on system (either global or specific to eosio)
export CMAKE=${CMAKE:-${EOSIO_HOME}/bin/cmake}
( [[ -z "${CMAKE}" ]] && [[ ! -z $(command -v cmake 2>/dev/null) ]] ) && export CMAKE=$(command -v cmake 2>/dev/null)

# Setup based on architecture
echo "Architecture: ${ARCH}"
if [ "$ARCH" == "Linux" ]; then
   [[ $CURRENT_USER == "root" ]] || ensure-sudo
   OPENSSL_ROOT_DIR=/usr/include/openssl
   case $NAME in
      "Amazon Linux AMI" | "Amazon Linux")
         FILE="${REPO_ROOT}/scripts/eosio_build_amazonlinux.bash"
         CXX_COMPILER=g++
         C_COMPILER=gcc
      ;;
      "CentOS Linux")
         FILE="${REPO_ROOT}/scripts/eosio_build_centos7.bash"
         CXX_COMPILER=g++
         C_COMPILER=gcc
      ;;
      "Ubuntu")
         FILE="${REPO_ROOT}/scripts/eosio_build_ubuntu.bash"
         CXX_COMPILER=clang++-4.0
         C_COMPILER=clang-4.0
      ;;
      *) echo " - Unsupported Linux Distribution." && exit 1;;
   esac
fi

if [ "$ARCH" == "Darwin" ]; then
   # opt/gettext: cleos requires Intl, which requires gettext; it's keg only though and we don't want to force linking: https://github.com/EOSIO/eos/issues/2240#issuecomment-396309884
   # EOSIO_HOME/lib/cmake: mongo_db_plugin.cpp:25:10: fatal error: 'bsoncxx/builder/basic/kvp.hpp' file not found
   LOCAL_CMAKE_FLAGS="-DCMAKE_PREFIX_PATH=/usr/local/opt/gettext;$EOSIO_HOME/lib/cmake ${LOCAL_CMAKE_FLAGS}" 
   FILE="${SCRIPT_DIR}/eosio_build_darwin.bash"
   CXX_COMPILER=clang++
   C_COMPILER=clang
   OPENSSL_ROOT_DIR=/usr/local/opt/openssl
fi

echo "${COLOR_CYAN}====================================================================================="
echo "======================= ${COLOR_WHITE}Starting EOSIO Dependency Install${COLOR_CYAN} ===========================${COLOR_NC}"
execute pushd $SRC_LOCATION 1>/dev/null
. $FILE # Execute OS specific build file
execute popd 1>/dev/null
echo ""
echo "${COLOR_CYAN}========================================================================"
echo "======================= ${COLOR_WHITE}Starting EOSIO Build${COLOR_CYAN} ===========================${COLOR_NC}"
execute mkdir -p $BUILD_DIR
execute pushd $BUILD_DIR 1>/dev/null
execute $CMAKE -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
   -DCMAKE_CXX_COMPILER="${CXX_COMPILER}" \
   -DCMAKE_C_COMPILER="${C_COMPILER}" \
   -DCORE_SYMBOL_NAME="${CORE_SYMBOL_NAME}" \
   -DOPENSSL_ROOT_DIR="${OPENSSL_ROOT_DIR}" \
   -DBUILD_MONGO_DB_PLUGIN=true \
   -DENABLE_COVERAGE_TESTING="${ENABLE_COVERAGE_TESTING}" \
   -DBUILD_DOXYGEN="${DOXYGEN}" \
   -DCMAKE_PREFIX_PATH=$INSTALL_LOCATION \
   -DCMAKE_INSTALL_PREFIX="${OPT_LOCATION}/eosio" \
   ${LOCAL_CMAKE_FLAGS} \
   "${REPO_ROOT}"
execute make -j"${JOBS}"
execute popd $REPO_ROOT 1>/dev/null

TIME_END=$(( $(date -u +%s) - $TIME_BEGIN ))

echo "${COLOR_RED}_______  _______  _______ _________ _______"
echo '(  ____ \(  ___  )(  ____ \\\\__   __/(  ___  )'
echo "| (    \/| (   ) || (    \/   ) (   | (   ) |"
echo "| (__    | |   | || (_____    | |   | |   | |"
echo "|  __)   | |   | |(_____  )   | |   | |   | |"
echo "| (      | |   | |      ) |   | |   | |   | |"
echo "| (____/\| (___) |/\____) |___) (___| (___) |"
echo "(_______/(_______)\_______)\_______/(_______)"
echo "=============================================${COLOR_NC}"

echo "${COLOR_GREEN}EOSIO has been successfully built. $(($TIME_END/3600)):$(($TIME_END%3600/60)):$(($TIME_END%60))"
echo "${COLOR_GREEN}You can now install using: ./scripts/eosio_install.bash${COLOR_NC}"
echo "${COLOR_YELLOW}Uninstall with: ./scripts/eosio_uninstall.bash${COLOR_NC}"

echo ""
echo "${COLOR_CYAN}If you wish to perform tests to ensure functional code:${COLOR_NC}"
print_instructions
echo "1. Start Mongo: ${BIN_LOCATION}/mongod --dbpath ${MONGODB_DATA_LOCATION} -f ${MONGODB_CONF} --logpath ${MONGODB_LOG_LOCATION}/mongod.log &"
echo "2. Run Tests: cd ./build && PATH=\$PATH:$EOSIO_HOME/opt/mongodb/bin make test" # PATH is set as currently 'mongo' binary is required for the mongodb test
echo ""
resources
