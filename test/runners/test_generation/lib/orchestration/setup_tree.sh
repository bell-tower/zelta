# helper to setup the test zfs pools and datasets in the
# state needed for creating/generating a new test and
# for testing the same.

REPO_ROOT=${REPO_ROOT:=$(git rev-parse --show-toplevel)}
echo "REPO ROOT: $REPO_ROOT"

setup_tree() {
    pattern_specs=$1
    selector_specs=$2
    trace_options=$3

    cd "$REPO_ROOT" || exit 1
    . ./test/test_helper.sh
    . ./test/runners/env/helpers.sh
    setup_env "1"      # setup debug environment
    clean_ds_and_pools # reset tree

    cmd1=()
    if [ -n "$pattern_specs" ]; then
        cmd1=(shellspec)
        if [ -n "$trace_options" ]; then
            cmd1+=("$trace_options")
        fi
        cmd1+=(--pattern "$pattern_specs")
    fi

    cmd2=()
    if [ -n "$selector_specs" ]; then
        cmd2=(shellspec)
        if [ -n "$trace_options" ]; then
            cmd2+=("$trace_options")
        fi
        cmd2+=("$selector_specs")
    fi

    set -x
    if [ ${#cmd1[@]} -gt 0 ] && ! "${cmd1[@]}"; then
        printf "\n ❌ setup failed for command: %s\n" "${cmd1[*]}"
        set +x
        return 1
    fi

    if [ ${#cmd2[@]} -gt 0 ] && ! "${cmd2[@]}"; then
        printf "\n ❌ setup failed for command: %s\n" "${cmd2[*]}"
        set +x
        return 1
    fi
    set +x

    printf "\n ✅ setup succeeded\n"

}
