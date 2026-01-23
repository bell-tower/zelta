# Check remotes and create pools and datasets

Describe 'Remote check'
    It 'source accessible'
        Skip if 'SANDBOX_ZELTA_SRC_REMOTE undefined' [ -z "$SANDBOX_ZELTA_SRC_REMOTE" ]
        When run ssh -n "$SANDBOX_ZELTA_SRC_REMOTE" true
        The status should be success
    End
    It 'target accessible'
        Skip if 'SANDBOX_ZELTA_TGT_REMOTE undefined' [ -z "$SANDBOX_ZELTA_TGT_REMOTE" ]
        When run ssh -n "$SANDBOX_ZELTA_TGT_REMOTE" true
        The status should be success
    End
End

Describe 'Pool setup'
    It 'create source'
        Skip if 'SANDBOX_ZELTA_SRC_POOL undefined' [ -z "$SANDBOX_ZELTA_SRC_POOL" ]
        When call make_src_pool
        The status should be success
    End
    It 'create target'
        Skip if 'SANDBOX_ZELTA_TGT_POOL undefined' [ -z "$SANDBOX_ZELTA_TGT_POOL" ]
        When call make_tgt_pool
        The status should be success
    End
End

Describe 'Divergent tree setup'
    It 'creates divergent tree on source'
        Skip if 'SANDBOX_ZELTA_SRC_DS undefined' test -z "$SANDBOX_ZELTA_SRC_DS" -a -z "$SANDBOX_ZELTA_TGT_DS"
        When call make_divergent_tree
        The status should be success
        The output should include 'syncing 9 datasets'
        The error should not include 'error:'
    End
End

Describe 'Divergent tree match'
    It 'shows expected divergence types'
        Skip if 'SANDBOX_ZELTA_TGT_DS undefined' test -z "$SANDBOX_ZELTA_TGT_DS"
        When run zelta match "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"
        The status should be success
        The output should include 'up-to-date'
        The output should include 'syncable (full)'
        The output should include 'syncable (incremental)'
        The output should include 'blocked sync: target diverged'
        The output should include 'blocked sync: no target snapshots'
        The output should include '11 total datasets compared'
    End
End
