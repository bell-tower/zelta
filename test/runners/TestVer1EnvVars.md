# Env Vars from 1st version of shellspec

Temporary documentation to help with migration to version 2, refactored tests

```shell
export SRC_POOL="apool"
export TGT_POOL="bpool"


export TREETOP_DSN='treetop'
export BACKUPS_DSN='backups'

# zelta version for pool names will include the remote
export SOURCE="${ZELTA_SRC_POOL}/${TREETOP_DSN}"
export TARGET="${ZELTA_TGT_POOL}/${BACKUPS_DSN}/${TREETOP_DSN}"

# zfs versions for pool names do not include th remote
export SRC_TREE="$SRC_POOL/$TREETOP_DSN"
export TGT_TREE="$TGT_POOL/$BACKUPS_DSN/$TREETOP_DSN"

# Zelta supports remote commands, by default SRC and TGT servers are the current host
export SRC_SVR="${SRC_SVR:-}"
export TGT_SVR="${TGT_SVR:-}"


if [ -z "$SRC_SVR" ]; then
    export ZELTA_SRC_POOL="${SRC_POOL}"
else
    export ZELTA_SRC_POOL="${SRC_SVR}:${SRC_POOL}"
fi

if [ -z "$TGT_SVR" ]; then
    export ZELTA_TGT_POOL="${TGT_POOL}"
else
    export ZELTA_TGT_POOL="${TGT_SVR}:${TGT_POOL}"
fi

# zelta version for pool names will include the remote
export SOURCE="${ZELTA_SRC_POOL}/${TREETOP_DSN}"
export TARGET="${ZELTA_TGT_POOL}/${BACKUPS_DSN}/${TREETOP_DSN}"

# zfs versions for pool names do not include th remote
export SRC_TREE="$SRC_POOL/$TREETOP_DSN"
export TGT_TREE="$TGT_POOL/$BACKUPS_DSN/$TREETOP_DSN"



```