# Auto-generated ShellSpec test file
# Generated at: 2026-03-10 03:12:05 -0400
# Source: 080_zelta_policy_spec
# WARNING: This file was automatically generated. Manual edits may be lost.

output_for_policy_check() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "[BACKUP_SITE: ${SANDBOX_ZELTA_TGT_EP}/zelta_policy_backup_2026-03-10_07.11.59] ${SANDBOX_ZELTA_SRC_EP}: syncing 12 datasets"|\
        "[BACKUP_SITE: ${SANDBOX_ZELTA_TGT_EP}/zelta_policy_backup_2026-03-10_07.11.59] ${SANDBOX_ZELTA_SRC_EP}: * sent, 22 streams received in * seconds")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

Describe 'Test zelta policy'
  Skip if 'SANDBOX_ZELTA_SRC_DS undefined' test -z "$SANDBOX_ZELTA_SRC_DS"
  Skip if 'SANDBOX_ZELTA_TGT_DS undefined' test -z "$SANDBOX_ZELTA_TGT_DS"
  Skip if 'SANDBOX_ZELTA_SRC_REMOTE undefined' test -z "$SANDBOX_ZELTA_SRC_REMOTE"
  Skip if 'SANDBOX_ZELTA_TGT_REMOTE undefined' test -z "$SANDBOX_ZELTA_TGT_REMOTE"

  It "test zelta policy - zelta policy -C ./test/runners/test_generation/config/zelta_test_policy.conf"
    When call zelta policy -C ./test/runners/test_generation/config/zelta_test_policy.conf
    The output should satisfy output_for_policy_check
    The status should be success
  End

End
