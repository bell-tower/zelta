setup_env() {
    DEBUG_MODE=$1
    if [ -n "$DEBUG_MODE" ]; then
        printf "\n*\n* Running in DEBUG MODE, sourcing setup files\n*\n"
        . test/runners/set_reuse_tmp_env.sh
        . test/runners/test_env.sh
        . test/test_helper.sh
    else
        printf '%s\n' "--> Normal shellspec Run"
        . test/runners/test_env.sh
    fi
}

run_it() {
    _func=$1
    if (eval set -x; "$_func";); then
        printf "✅ %s\n\n" "$_func"
    else
        printf "❌ %s\n\n" "$_func"
        exit 1
    fi
}

clean_ds_and_pools() {
    echo "cleaning up, datasets and pools"
    run_it clean_src_ds
    run_it clean_tgt_ds
    run_it nuke_tgt_pool
    run_it nuke_src_pool
}
