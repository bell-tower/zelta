#!/bin/sh

. ./test/runners/helpers.sh

manual_make() {
    clean_ds_and_pools
    run_it make_tgt_pool
    run_it make_src_pool
    run_it make_divergent_tree
}


manual_backup() {
    clean_ds_and_pools
    run_it make_tgt_pool
    run_it make_src_pool
    run_it make_initial_tree
    #run_it make_target_dataset
    zelta backup --snap-name @start $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP
    #run_it "zelta backup"
}


run_specs_to_040() {
    # NOTE: to get an execution trace on macOS need homebrew bash shell
    #SPEC_OPTIONS='--xtrace --shell /opt/homebrew/bin/bash'
    #shellspec "$SPEC_OPTIONS" --pattern "test/00*_spec.sh|test/01*_spec.sh|test/021*_spec.sh|test/99_cleanup_spec.sh"
    #shellspec "$SPEC_OPTIONS" --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/99_cleanup_spec.sh"
    #shellspec --xtrace --shell /opt/homebrew/bin/bash  --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_zelta_spec.sh"
    shellspec --xtrace --shell /opt/homebrew/bin/bash  --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh"
}

manual_run() {
    #setup_env "1"
    #echo $PATH
    #manual_make
    #echo "SANDBOX_ZELTA_SRC_EP: {$SANDBOX_ZELTA_SRC_EP}"
    #echo "SANDBOX_ZELTA_TGT_EP: {$SANDBOX_ZELTA_TGT_EP}"
    manual_backup
}

spec_run() {
    # NOTE: setup_env 1  - will create a debug environment
    #       setup_env "" - creates a standard environment
    if setup_env ""; then
      run_specs_to_040
    fi
}

spec_run


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
