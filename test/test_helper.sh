# shellcheck shell=sh

# Zelta Test Helper
#
# Environment variables:
#   ZELTA_TEST_SRC_POOL  - Source pool (default: zelta-source)
#   ZELTA_TEST_TGT_POOL  - Target pool (default: zelta-target)
#   ZELTA_TEST_SRC_HOST  - Source host for remote tests (optional)
#   ZELTA_TEST_TGT_HOST  - Target host for remote tests (optional)
#
# If pools/hosts are not configured, only basic sanity tests run.

## Test namespace defaults (designed to never collide)
: "${ZELTA_TEST_SRC_POOL:=zelta-source}"
: "${ZELTA_TEST_TGT_POOL:=zelta-target}"
: "${ZELTA_TEST_SRC_DS:=zelta-source/test-data}"
: "${ZELTA_TEST_TGT_DS:=zelta-target/test-backups}"

## Use repo's zelta by default
REPO_ROOT="$SHELLSPEC_PROJECT_ROOT"
export PATH="$REPO_ROOT/bin:$PATH"
export ZELTA_SHARE="$REPO_ROOT/share/zelta"

## Build endpoints
if [ -n "$ZELTA_TEST_SRC_HOST" ]; then
    ZELTA_TEST_SRC_EP="${ZELTA_TEST_SRC_HOST}:${ZELTA_TEST_SRC_DS}"
else
    ZELTA_TEST_SRC_EP="$ZELTA_TEST_SRC_DS"
fi

if [ -n "$ZELTA_TEST_TGT_HOST" ]; then
    ZELTA_TEST_TGT_EP="${ZELTA_TEST_TGT_HOST}:${ZELTA_TEST_TGT_DS}"
else
    ZELTA_TEST_TGT_EP="$ZELTA_TEST_TGT_DS"
fi

export ZELTA_TEST_SRC_POOL ZELTA_TEST_TGT_POOL
export ZELTA_TEST_SRC_DS ZELTA_TEST_TGT_DS
export ZELTA_TEST_SRC_EP ZELTA_TEST_TGT_EP

## Helper: check if test pools exist
zelta_test_pools_exist() {
    zfs list -H -o name "$ZELTA_TEST_SRC_POOL" >/dev/null 2>&1 &&
    zfs list -H -o name "$ZELTA_TEST_TGT_POOL" >/dev/null 2>&1
}

## Helper: check if remote hosts are reachable
zelta_test_remote_available() {
    [ -n "$ZELTA_TEST_SRC_HOST" ] && [ -n "$ZELTA_TEST_TGT_HOST" ]
}

spec_helper_precheck() {
    : minimum_version "0.28.1"
    info "Zelta test environment:"
    info "  ZELTA_SHARE: $ZELTA_SHARE"
    info "  Source: $ZELTA_TEST_SRC_EP"
    info "  Target: $ZELTA_TEST_TGT_EP"
    if zelta_test_remote_available; then
        info "  Remote tests: enabled"
    else
        info "  Remote tests: disabled (set ZELTA_TEST_SRC_HOST and ZELTA_TEST_TGT_HOST)"
    fi
}

spec_helper_loaded() {
    :
}

spec_helper_configure() {
    : import 'support/custom_matcher'
}
