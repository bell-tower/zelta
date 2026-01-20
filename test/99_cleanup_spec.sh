Describe 'Pool cleanup'
    It 'destroy source'
        Skip if 'no pools defined' skip_pools
        When call nuke_src_pool
        The status should be success
    End
    It 'destroy target'
        Skip if 'no pools defined' skip_pools
        When call nuke_tgt_pool
        The status should be success
    End
End
