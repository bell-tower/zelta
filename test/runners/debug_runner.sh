#!/bin/sh

. ./test/runners/helpers.sh


manual_make() {
    #run_it nuke_tgt_pool
    #run_id nuke_src_pool
    run_it make_tgt_pool
    run_it make_src_pool
    run_it make_divergent_tree
}

run_specs_to_021() {
    set +x
    SPEC_OPTIONS="--xtrace --shell bash"
    #shellspec $SPEC_OPTIONS --pattern "test/00*_spec.sh|test/01*_spec.sh|test/021*_spec.sh|test/99_cleanup_spec.sh"
    shellspec $SPEC_OPTIONS --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/99_cleanup_spec.sh"
}

setup_env ""
#setup_env "1"
run_specs_to_021
#manual_make

# current spec list
#shellspec test/00_install_spec.sh:@1-1
#shellspec test/00_install_spec.sh:@1-2
#shellspec test/01_no_op_spec.sh:@1-1-1
#shellspec test/01_no_op_spec.sh:@1-1-2
#shellspec test/01_no_op_spec.sh:@1-1-3
#shellspec test/01_no_op_spec.sh:@1-1-4
#shellspec test/01_no_op_spec.sh:@1-2-1
#shellspec test/01_no_op_spec.sh:@1-2-2
#shellspec test/01_no_op_spec.sh:@1-2-3
#shellspec test/01_no_op_spec.sh:@1-2-4
#shellspec test/021_setup_pools_spec.sh:@1-1
#shellspec test/021_setup_pools_spec.sh:@1-2
#shellspec test/021_setup_pools_spec.sh:@2-1
#shellspec test/021_setup_pools_spec.sh:@2-2
