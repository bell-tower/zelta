#!/bin/sh

# to facilitate creating shellspec tests, use the last spec installed zelta version
#last_tmp_installed_zelta_ver=$(ls -ld /tmp/zelta* | tail -1 | cut -w -f 9)

last_tmp_installed_zelta_ver=$(ls -1d /tmp/zelta* | tail -1)

if [ -z "$last_tmp_installed_zelta_ver" ]; then
   echo "No previous zelta installs found in /tmp/zelta* "
   exit 1
fi

last_tmp_process_number=$(echo "$last_tmp_installed_zelta_ver" | grep -o '[0-9]\+$')
printf "\n***\n*** %s\n***\n", "using zelta $last_tmp_installed_zelta_ver with process number $last_tmp_process_number"

set -x
export SANDBOX_ZELTA_TMP_DIR="$last_tmp_installed_zelta_ver"
export SANDBOX_ZELTA_PROCNUM="$last_tmp_process_number"
export ZELTA_BIN="$SANDBOX_ZELTA_TMP_DIR/bin"
export ZELTA_SHARE="$SANDBOX_ZELTA_TMP_DIR/share"
export ZELTA_ETC="$SANDBOX_ZELTA_TMP_DIR/etc"
export ZELTA_DOC="$SANDBOX_ZELTA_TMP_DIR/man"
if [ -z "$USR_ORIG_PATH" ]; then
    export USR_ORIG_PATH=$PATH
fi
export PATH="$ZELTA_BIN:$PATH"
export SHELLSPEC_TMPBASE=~/tmp/dbg_shellspecs
mkdir -p $SHELLSPEC_TMPBASE
echo "NOTE: SHELLSPEC_PROJECT_ROOT is not set"

set +x
