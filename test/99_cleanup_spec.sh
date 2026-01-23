Describe 'Cleanup'
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

    Describe 'Installation cleanup'
        It 'uninstall script'
            Skip if 'avoid systemwide uninstall' skip_if_root
            When run sh uninstall.sh
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
