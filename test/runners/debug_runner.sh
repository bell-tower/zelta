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
    ##shellspec "$SPEC_OPTIONS" --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/99_cleanup_spec.sh"
    shellspec --xtrace --shell /opt/homebrew/bin/bash  --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_zelta_tests_spec.sh"
    #shellspec --xtrace --shell /opt/homebrew/bin/bash  --pattern "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh"
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
#rlogwood@lumacp zelta % shellspec --list examples
#test/00_install_spec.sh:@1-1
#test/00_install_spec.sh:@1-2
#test/01_no_op_spec.sh:@1-1-1
#test/01_no_op_spec.sh:@1-1-2
#test/01_no_op_spec.sh:@1-1-3
#test/01_no_op_spec.sh:@1-1-4
#test/01_no_op_spec.sh:@1-2-1
#test/01_no_op_spec.sh:@1-2-2
#test/01_no_op_spec.sh:@1-2-3
#test/01_no_op_spec.sh:@1-2-4
#test/021_setup_pools_spec.sh:@1-1
#test/021_setup_pools_spec.sh:@1-2
#test/021_setup_pools_spec.sh:@2-1
#test/021_setup_pools_spec.sh:@2-2
#test/022_setup_tree_spec.sh:@1-1-1
#test/022_setup_tree_spec.sh:@1-1-2
#test/022_setup_tree_spec.sh:@1-1-3
#test/022_setup_tree_spec.sh:@1-2-1
#test/03_backup_spec.sh:@1-1
#test/03_backup_spec.sh:@1-2
#test/040_zelta_tests_spec.sh:@1-1
#test/040_zelta_tests_spec.sh:@1-2
#test/040_zelta_tests_spec.sh:@1-3
#test/040_zelta_tests_spec.sh:@1-4
#test/99_cleanup_spec.sh:@1-1-1
#test/99_cleanup_spec.sh:@1-1-2
#test/99_cleanup_spec.sh:@1-2-1
#test/99_cleanup_spec.sh:@1-2-2
#test/99_cleanup_spec.sh:@1-3-1
#test/99_cleanup_spec.sh:@1-3-2
