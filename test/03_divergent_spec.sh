Describe 'Divergent tree setup'
    It 'creates divergent tree on source'
        Skip if 'source dataset not configured' test -z "$SANDBOX_ZELTA_SRC_DS"
        When call make_divergent_tree
        The status should be success
        The output should include 'snapshotting'
        The output should include 'syncing 9 datasets'
        The error should not include 'error:'
    End
End

Describe 'Divergent tree match'
    It 'shows expected divergence types'
        Skip if 'source dataset not configured' test -z "$SANDBOX_ZELTA_SRC_DS"
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
