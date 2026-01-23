Describe 'Cleanup'
    Describe 'Pool cleanup'
        It 'destroy source'
            Skip if 'SANDBOX_ZELTA_SRC_POOL undefined' [ -z "$SANDBOX_ZELTA_SRC_POOL" ]
            When call nuke_src_pool
            The status should be success
        End
        It 'destroy target'
            Skip if 'SANDBOX_ZELTA_TGT_POOL undefined' [ -z "$SANDBOX_ZELTA_TGT_POOL" ]
            When call nuke_tgt_pool
            The status should be success
        End
    End
    Describe 'Installation cleanup'
        It 'uninstall script'
            When run sh uninstall.sh env
            The status should be success
            The output should include 'removing'
        End
        It 'remove temporary installation'
            When call cleanup_temp_install
            The status should be success
            The output should include '2'
        End
    End
End
