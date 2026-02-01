#!/bin/sh

. ./test/runners/helpers.sh

#test_it() {
#    ls /tmp/apool.img
#    return 0
#}

setup_env "1"
echo "cleaning up"
#run_it test_it

run_it clean_src_ds
run_it clean_tgt_ds
run_it nuke_tgt_pool
run_it nuke_src_pool

