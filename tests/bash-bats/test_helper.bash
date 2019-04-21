# You can add `load test_helper` to the .bats files you create to include anything in this file.
# DO NOT REMOVE
export DRYRUN=true
export VERBOSE=true
export CURRENT_USER=$(whoami)

export HOME="$BATS_TMPDIR/bats-eosio-user-home" # Ensure $HOME is available for all scripts
mkdir -p $HOME

# Obtain dependency versions and paths
. ./scripts/lib/eosio.bash

# Setup directories; useful for uninstall.bash
mkdir -p $SRC_LOCATION
mkdir -p $OPT_LOCATION
mkdir -p $VAR_LOCATION
mkdir -p $BIN_LOCATION
mkdir -p $VAR_LOCATION/log
mkdir -p $ETC_LOCATION
mkdir -p $LIB_LOCATION
mkdir -p $MONGODB_LOG_LOCATION
mkdir -p $MONGODB_DATA_LOCATION

# Ensure we're in the root directory to execute
if [[ ! -d "tests" ]] && [[ ! -f "README.md" ]]; then
  echo "You must navigate into the root directory to execute tests..." >&3
  exit 1
fi

debug() {
  printf " ---------\\n STATUS: ${status}\\n${output}\\n ---------\\n\\n" >&3
}

trap teardown EXIT
teardown() { # teardown is run once after each test, even if it fails
  # echo -e "\n-- CLEANUP --" >&3
  [[ -d "$HOME" ]] && rm -rf "$HOME"
  # echo -e "-- END CLEANUP --\n" >&3
}