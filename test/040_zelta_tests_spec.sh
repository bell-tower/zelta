# Auto-generated ShellSpec test file
# Generated at: 2026-02-05 22:35:37 -0500
# Source: 040_zelta_tests_spec
# WARNING: This file was automatically generated. Manual edits may be lost.

output_for_match_after_divergence() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO "|\
        "[treetop] @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1/child @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub2 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub2/orphan @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub3 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub3/space name @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub4 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub4/encrypted @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub4/zvol @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "10 up-to-date")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

Describe 'Run zelta commands on divergent tree'
  It 'show divergence - zelta match $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP'
    When call zelta match $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP
    The output should satisfy output_for_match_after_divergence
    The status should equal 0
  End

End
