Describe 'Pool setup'
    It 'create'
        Skip if 'source not defined' skip_src_pool
        When call make_src_pool
        The status should be success
    End
    It 'create'
        Skip if 'target not defined' skip_tgt_pool
        When call make_tgt_pool
        The status should be success
    End
End
