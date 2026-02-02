
# in use
output_for_match_after_backup() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO"|\
        "[treetop] @start @start @start up-to-date"|\
        "/sub1 @start @start @start up-to-date"|\
        "/sub1/child - - - syncable (full)"|\
        "/sub1/kid - - - no source (target only)"|\
        "/sub2 - @two @two blocked sync: target diverged"|\
        "/sub2/orphan @start @start @start up-to-date"|\
        "/sub3 @start @two @start syncable (incremental)"|\
        "/sub3/space name @start @start @blocker blocked sync: target diverged"|\
        "/sub4 @start @start @start up-to-date"|\
        "/sub4/encrypted @start @start @start up-to-date"|\
        "/sub4/zvol - @start - blocked sync: no target snapshots"|\
        "5 up-to-date, 2 syncable, 4 blocked")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

output_from_rotate() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "source is written; snapshotting: @zelta_"*""|\
        "warning: insufficient snapshots; performing full backup for 3 datasets"|\
        "renaming '${SANDBOX_ZELTA_TGT_DS}' to '${SANDBOX_ZELTA_TGT_DS}_start'"|\
        "to ensure target is up-to-date, run: zelta backup $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP"|\
        "warning: missing \`zfs allow\` permissions: readonly,mountpoint"|\
        "no source: ${SANDBOX_ZELTA_TGT_DS}/sub1/kid"|\
        "* sent, 10 streams received in * seconds")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}


output_for_match_after_rotate() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO"|\
        "[treetop] @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1/child @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub2 @two @zelta_"*" @two syncable (incremental)"|\
        "/sub2/orphan @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub3 @two @zelta_"*" @two syncable (incremental)"|\
        "/sub3/space name @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub4 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub4/encrypted @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub4/zvol @start @zelta_"*" @start syncable (incremental)"|\
        "7 up-to-date, 3 syncable"|\
        "10 total datasets compared")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

# (in specfile test/040_zelta_spec.sh, line 44-56, WARNING)
# When call zelta rotate dever@zfsdev:apool/treetop dever@zfsdev:bpool/backups
# There was output to stdout but not found expectation
#
# WIP notes
#    zelta backup $_options_all $_options_backup "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"

Describe 'Divergent tree zelta tests'
    Skip if 'SANDBOX_ZELTA_SRC_EP and SANDBOX_ZELTA_TGT_EP are undefined' test -z "$SANDBOX_ZELTA_SRC_EP" -a -z "$SANDBOX_ZELTA_TGT_EP"

    It "zelta match $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP"
        When call zelta match "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"
        The output should satisfy output_for_match_after_backup
    End

    It "zelta rotate $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP"
       When call zelta rotate "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"
       The error should include "warning: insufficient snapshots; performing full backup for 3 datasets"
       The output should satisfy output_from_rotate
       The status should equal 0
    End

    It "match $SOURCE and $TARGET after divergent rotate"
        When call zelta match "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"
        The output should be present
        The output should satisfy output_for_match_after_rotate
        The status should equal 0
    End
End


Describe 'ignored tests'
    Skip if "wip test conversion" true

    Describe 'Divergent match, rotate, match'
        It "shows current match for divergent $SOURCE and $TARGET"
           When call zelta match $SOURCE $TARGET
           The output should satisfy match_after_divergent_snapshots_output
        End

        It "rotate divergent $SOURCE and $TARGET"
           When call zelta rotate $SOURCE $TARGET
           The output should satisfy match_rotate_output
           The stderr should equal "warning: insufficient snapshots; performing full backup for 2 datasets"
           The status should equal 0
        End

        It "match $SOURCE and $TARGET after divergent rotate"
           When call zelta match $SOURCE $TARGET
           The output should satisfy match_after_rotate_output
           The status should equal 0
        End
    End


    Describe 'Divergent backup, then match'
        It "backup divergent $SOURCE to $TARGET"
           When call zelta backup $SOURCE $TARGET
           The output line 1 should equal "syncing 8 datasets"
           The output line 2 should equal "8 datasets up-to-date"
           The output line 3 should match pattern "* sent, 5 streams received in * seconds"
           The status should equal 0
        End

        It "match after backup"
           When call zelta backup $SOURCE $TARGET
           The output should satisfy zelta_match_after_backup_output
           The status should equal 0
        End
    End
End

