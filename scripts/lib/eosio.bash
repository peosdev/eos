# Obtain dependency versions; Must come first in the script
. ./scripts/.environment
# Load general helpers
. ./scripts/lib/helpers.bash

# Checks for Arch and OS + Support for tests setting them manually
## Necessary for linux exclusion while running bats tests/bash-bats/*.bash
[[ -z "${ARCH}" ]] && export ARCH=$( uname )
if [[ -z "${NAME}" ]]; then
    if [[ $ARCH == "Linux" ]]; then 
        [[ ! -e /etc/os-release ]] && echo "${COLOR_RED} - /etc/os-release not found! It seems you're attempting to use an unsupported Linux distribution.${COLOR_NC}" && exit 1
        # Obtain OS NAME, and VERSION
        . /etc/os-release
    elif [[ $ARCH == "Darwin" ]]; then export NAME=$(sw_vers -productName)
    else echo " ${COLOR_RED}- EOSIO is not supported for your Architecture!${COLOR_NC}" && exit 1
    fi
fi

function setup() {
    if $VERBOSE; then
        echo "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}"
        echo "CORE_SYMBOL_NAME: ${CORE_SYMBOL_NAME}"
        echo "BOOST_LOCATION: ${BOOST_LOCATION}"
        echo "INSTALL_LOCATION: ${INSTALL_LOCATION}"
        echo "EOSIO_HOME: ${EOSIO_HOME}"
        echo "NONINTERACTIVE: ${NONINTERACTIVE}"
        echo "PROCEED: ${PROCEED}"
        echo "ENABLE_COVERAGE_TESTING: ${ENABLE_COVERAGE_TESTING}"
        echo "DOXYGEN: ${DOXYGEN}"
    fi
    [[ -d ./build ]] && execute rm -rf ./build # cleanup old build directory
    execute mkdir -p $SRC_LOCATION
    execute mkdir -p $OPT_LOCATION
    execute mkdir -p $VAR_LOCATION
    execute mkdir -p $BIN_LOCATION
    execute mkdir -p $VAR_LOCATION/log
    execute mkdir -p $ETC_LOCATION
    execute mkdir -p $LIB_LOCATION
    execute mkdir -p $MONGODB_LOG_LOCATION
    execute mkdir -p $MONGODB_DATA_LOCATION
}

function resources() {
    echo "${COLOR_CYAN}EOSIO website:${COLOR_NC} https://eos.io"
    echo "${COLOR_CYAN}EOSIO Telegram channel:${COLOR_NC} https://t.me/EOSProject"
    echo "${COLOR_CYAN}EOSIO resources:${COLOR_NC} https://eos.io/resources/"
    echo "${COLOR_CYAN}EOSIO Stack Exchange:${COLOR_NC} https://eosio.stackexchange.com"
}