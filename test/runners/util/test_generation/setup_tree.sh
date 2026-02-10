REPO_ROOT=${REPO_ROOT:=$(git rev-parse --show-toplevel)}
echo "REPO ROOT: $REPO_ROOT"

setup_tree() {
   setup_specs=$1
   trace_options=$2

   cd "$REPO_ROOT" || exit 1
   . ./test/test_helper.sh
   . ./test/runners/helpers.sh
   setup_env "1"
   clean_ds_and_pools

    if shellspec $trace_options --pattern "$setup_specs"; then
        printf "\n ✅ setup succeeded for specs: %s\n" "$SPECS"
    else
        printf "\n ❌ setup failed for specs: %s\n" "$SPECS"
        exit 1
    fi
}
