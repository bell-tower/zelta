REPO_ROOT=$(git rev-parse --show-toplevel)
RUNNERS_DIR="$REPO_ROOT/test/runners"
UTIL_DIR="$REPO_ROOT/test/runners/util"
TEST_GEN_DIR="$REPO_ROOT/test/runners/util/test_generation"
. "$TEST_GEN_DIR/setup_tree.sh"

SPECS="test/01*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_*_spec.sh"

if setup_tree "$SPECS"; then
    printf "\n ✅ initial tree setup succeeded for specs: %s\n" "$SPECS"
else
    printf "\n ❌ Goodbye, initial tree setup failed for specs: %s\n" "$SPECS"
    exit 1
fi

. "$RUNNERS_DIR/setup_debug_env.sh"
TRACE_OPTIONS="--xtrace --shell /opt/homebrew/bin/bash"
#TRACE_OPTIONS="--xtrace-only --shell /bin/sh"
#unset TRACE_OPTIONS

new_spec="$UTIL_DIR/tmp/050_zelta_revert_spec.sh"
echo "confirming new spec: {$new_spec}"

if shellspec $TRACE_OPTIONS "$new_spec"; then
    printf "\n ✅ confirmation test succeeded for new spec: %s\n" "$new_spec"
else
    printf "\n ❌ confirmation test failed for new spec: %s\n" "$new_spec"
    exit 1
fi
