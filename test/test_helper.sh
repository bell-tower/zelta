# shellcheck shell=sh

# Zelta Test Helper
#
# Environment variables:
#   SANDBOX_ZELTA_SRC_POOL    - Source pool
#   SANDBOX_ZELTA_TGT_POOL    - Target pool
#   SANDBOX_ZELTA_SRC_REMOTE  - Source [user@]host for remote tests
#   SANDBOX_ZELTA_TGT_REMOTE  - Target [user@]host for remote tests
#   SANDBOX_ZELTA_SRC_DS      - Source dataset
#   SANDBOX_ZELTA_TGT_DS      - Target dataset
#
# If pools/hosts are not configured, only basic sanity tests run.

## Use repo's zelta
REPO_ROOT="$SHELLSPEC_PROJECT_ROOT"
export PATH="$REPO_ROOT/bin:$PATH"
export ZELTA_SHARE="$REPO_ROOT/share/zelta"

## Build endpoints
if [ -n "$SANDBOX_ZELTA_SRC_REMOTE" ]; then
    SANDBOX_ZELTA_SRC_EP="${SANDBOX_ZELTA_SRC_REMOTE}:${SANDBOX_ZELTA_SRC_DS}"
    SANDBOX_ZELTA_SRC_CMD="ssh ${SANDBOX_ZELTA_SRC_REMOTE} "
else
    SANDBOX_ZELTA_SRC_EP="$SANDBOX_ZELTA_SRC_DS"
fi

if [ -n "$SANDBOX_ZELTA_TGT_REMOTE" ]; then
    SANDBOX_ZELTA_TGT_EP="${SANDBOX_ZELTA_TGT_REMOTE}:${SANDBOX_ZELTA_TGT_DS}"
    SANDBOX_ZELTA_SRC_CMD="ssh ${SANDBOX_ZELTA_SRC_REMOTE} "
else
    SANDBOX_ZELTA_TGT_EP="$SANDBOX_ZELTA_TGT_DS"
fi

# We should determine if sudo is actually needed
SANDBOX_ZELTA_SRC_CMD="${SANDBOX_ZELTA_SRC_CMD}sudo "
SANDBOX_ZELTA_TGT_CMD="${SANDBOX_ZELTA_TGT_CMD}sudo "

# Consider using unique tests
# SANDBOX_ZELTA_SRC_DS="${SANDBOX_ZELTA_SRC_DS}/zelta_test_src_$$"
# SANDBOX_ZELTA_TGT_DS="${SANDBOX_ZELTA_TGT_DS}/zelta_test_tgt_$$"

export SANDBOX_ZELTA_SRC_POOL SANDBOX_ZELTA_TGT_POOL
export SANDBOX_ZELTA_SRC_DS SANDBOX_ZELTA_TGT_DS
export SANDBOX_ZELTA_SRC_EP SANDBOX_ZELTA_TGT_EP
export SANDBOX_ZELTA_SRC_CMD SANDBOX_ZELTA_TGT_CMD


## Helpers
##########

pools_defined() {
    [ -z "$SANDBOX_ZELTA_SRC_POOL$SANDBOX_ZELTA_TGT_POOL" ]
    
}
