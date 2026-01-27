#!/bin/sh
set -x
# to facilitate creating shellspec tests, use the last spec installed zelta version
last_tmp_installed_zelta_ver=$(ls -ld /tmp/zelta* | tail -1 | cut -d ' ' -f 9)
last_tmp_process_number=$(echo "$last_tmp_installed_zelta_ver" | grep -o '[0-9]\+$')
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
set +x
