#!/bin/sh

#. test/runners/set_tmp_env.sh

# export TREETOP_DSN='treetop'
# export BACKUPS_DSN='backups'
# # zelta version for pool names will include the remote
# export SOURCE="${ZELTA_SRC_POOL}/${TREETOP_DSN}"
# export TARGET="${ZELTA_TGT_POOL}/${BACKUPS_DSN}/${TREETOP_DSN}"

test/runners/set_tmp_env.sh


#export SANDBOX_ZELTA_SRC_REMOTE=dever@fzfsdev
export SANDBOX_ZELTA_TGT_REMOTE=dever@zfsdev
export SANDBOX_ZELTA_SRC_POOL=apool
export SANDBOX_ZELTA_TGT_POOL=bpool
export SANDBOX_ZELTA_SRC_DS=treetop
export SANDBOX_ZELTA_TGT_DS=backups


#shellspec test/00_install_spec.sh test/01_no_op_spec.sh:@1-1-1
#shellspec
#shellspec test/00_install_spec.sh test/02_setup_spec.sh:@1-1-1
shellspec test/02_setup_spec.sh:@1-1
shellspec test/02_setup_spec.sh:@1-2

. test/test_helper.sh

set -x
make_src_pool
set +x

#shellspec test/02_setup_spec.sh:@2-1
#shellspec test/02_setup_spec.sh:@2-2
#shellspec test/02_setup_spec.sh:@3-1
#shellspec test/02_setup_spec.sh:@4-1


