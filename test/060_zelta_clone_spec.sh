# Auto-generated ShellSpec test file
# Generated at: 2026-02-08 16:45:43 -0500
# Source: 060_zelta_clone_spec
# WARNING: This file was automatically generated. Manual edits may be lost.

output_for_clone() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "cloned 2/2 datasets to ${SANDBOX_ZELTA_SRC_DS}/copy_of_sub2")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

Describe 'Test clone'
  Skip if 'SANDBOX_ZELTA_SRC_DS undefined' test -z "$SANDBOX_ZELTA_SRC_DS"

  It "zelta clone sub2 - zelta clone \"$SANDBOX_ZELTA_SRC_EP/sub2\" \"$SANDBOX_ZELTA_SRC_EP/copy_of_sub2\""
    When call zelta clone "$SANDBOX_ZELTA_SRC_EP/sub2" "$SANDBOX_ZELTA_SRC_EP/copy_of_sub2"
    The output should satisfy output_for_clone
    The error should equal "warning: unexpected 'zfs clone' output: filesystem successfully created, but it may only be mounted by root
warning: unexpected 'zfs clone' output: filesystem successfully created, but it may only be mounted by root"
    The status should be success
  End

End
