# shellcheck shell=sh

Describe 'Zelta sanity checks'
    Describe 'zelta command'
        It 'is executable'
            When run command command -v zelta
            The status should be success
            The output should include 'zelta'
        End
        It 'shows help with no arguments'
            When run command zelta
            The status should be failure
            The error should include 'usage'
        End

        It 'shows version'
            When run command zelta version
            The status should be success
            The output should include 'Zelta'
        End
    End
    Describe 'zelta match'
    	It 'shows zfs list commands for one operand'
    		When run command zelta match --dryrun "$ZELTA_TEST_SRC_DS"
    		The status should be success
    		The output should include '+ zfs list'
    	End
    	It 'shows zfs list commands for two operands'
    		When run command zelta match --dryrun zelta-nonexistent-pool/nonexistent
    		The status should be success
    		The output should include '+ zfs list'
    	End

    	It 'respects depth parameter'
    		When run command zelta match --dryrun --depth 69 zelta-nonexistent-pool/nonexistent
    		The status should be success
    		The output should include '69'
    	End
    End
End
