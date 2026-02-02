set -x
# pools
export SANDBOX_ZELTA_SRC_POOL=apool
export SANDBOX_ZELTA_TGT_POOL=bpool

# datasets
export SANDBOX_ZELTA_SRC_DS=apool/treetop
export SANDBOX_ZELTA_TGT_DS=bpool/backups

# remotes setup
#export SANDBOX_ZELTA_SRC_REMOTE=dever@zfsdev  # works from macOS
#export SANDBOX_ZELTA_SRC_REMOTE=localhost # works on Ubuntu

#TODO: confirm if FreeBSD works

export SANDBOX_ZELTA_SRC_REMOTE=dever@zfsdev
export SANDBOX_ZELTA_TGT_REMOTE=dever@zfsdev
#unset SANDBOX_ZELTA_SRC_REMOTE
#unset SANDBOX_ZELTA_TGT_REMOTE
set +x
