#!/bin/sh

# Debug environment setup
#   To facilitate creating and manually shellspec tests, and debugging existing tests
#   use the last spec installed zelta version

# find the last installed version of zelta installed by shellspec
last_tmp_installed_zelta_ver=$(ls -1d /tmp/zelta* | tail -1)

# exit if no previous install found
if [ -z "$last_tmp_installed_zelta_ver" ]; then
   echo "No previous zelta installs found in /tmp/zelta* "
   exit 1
fi

# extract the process number used when zelta install wsa created
last_tmp_process_number=$(echo "$last_tmp_installed_zelta_ver" | grep -o '[0-9]\+$')


printf "\n***\n*** %s\n***\n", "using zelta $last_tmp_installed_zelta_ver with process number $last_tmp_process_number"

set -x
# use discovered zelta dir
export SANDBOX_ZELTA_TMP_DIR="$last_tmp_installed_zelta_ver"

# use discovered process number
export SANDBOX_ZELTA_PROCNUM="$last_tmp_process_number"

export ZELTA_BIN="$SANDBOX_ZELTA_TMP_DIR/bin"
export ZELTA_SHARE="$SANDBOX_ZELTA_TMP_DIR/share"
export ZELTA_ETC="$SANDBOX_ZELTA_TMP_DIR/etc"
export ZELTA_DOC="$SANDBOX_ZELTA_TMP_DIR/man"
export PATH="$ZELTA_BIN:$PATH"
export SHELLSPEC_TMPBASE=~/tmp/dbg_shellspecs
mkdir -p $SHELLSPEC_TMPBASE

echo "NOTE: SHELLSPEC_PROJECT_ROOT is not set"

set +x
