# shellcheck shell=sh

Describe 'Zelta installation'
    It 'runs installer without errors'
        When run ./install.sh
        The status should be success
        The output should include 'installing'
    End
    
    It 'installs zelta binary'
        When run test -x "$ZELTA_BIN/zelta"
        The status should be success
    End
    
    It 'installs share files'
        When run test -f "$ZELTA_SHARE/zelta-common.awk"
        The status should be success
    End
    
    It 'installs man pages'
        When run test -f "$ZELTA_DOC/man8/zelta.8"
        The status should be success
    End
    
    It 'creates config examples'
        When run test -f "$ZELTA_ETC/zelta.conf.example"
        The status should be success
    End
End
