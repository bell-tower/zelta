setup_env() {
    DEBUG_MODE=$1

    if [ -n "$DEBUG_MODE" ]; then
        . test/runners/setup_debug_env.sh
    else
        printf '%s\n' "--> Normal shellspec Run"
        . test/runners/reset_env.sh   # reset the env, use test_helper.sh version
        . test/runners/test_env.sh    # set dataset, pools and remote env vars
        # on normal run shellspec will automatically run test/test_helper.sh
    fi
}

run_it() {
    _func=$1
    #if (eval set -x; "$_func";); then
    if (eval "$_func";); then
        printf " ✅ %s\n\n" "$_func"
    else
        printf " ❌ %s\n\n" "$_func"
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
