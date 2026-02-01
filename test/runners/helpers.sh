setup_env() {
    DEBUG_MODE=$1
    if [ -n "$DEBUG_MODE" ]; then
        printf "\n*\n* Running in DEBUG MODE, sourcing setup files\n*\n"
        . test/runners/set_reuse_tmp_env.sh
        . test/test_helper.sh
    else
        printf '%s\n' "--> Normal shellspec Run"
    fi
    . test/runners/test_env.sh
}

run_it() {
    _func=$1
    if (eval set -x; "$_func";); then
        printf "✅ %s\n\n" "$_func"
    else
        printf "❌ %s\n\n" "$_func"
    fi
}