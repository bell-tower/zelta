#. spec/bin/divergent_test/divergent_test_env.sh

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

###########

# Custom validation functions
zelta_match_after_backup_output() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO"|\
        "[treetop] @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1/child @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub2 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub2/orphan @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub3 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub3/space name @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/vol1 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "8 up-to-date")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

match_after_rotate_output() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO"|\
        "[treetop] @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1 @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub1/child @zelta_"*" @zelta_"*" @zelta_"*" up-to-date"|\
        "/sub2 @two @zelta_"*" @two syncable (incremental)"|\
        "/sub2/orphan @two @zelta_"*" @two syncable (incremental)"|\
        "/sub3 @two @zelta_"*" @two syncable (incremental)"|\
        "/sub3/space name @two @zelta_"*" @two syncable (incremental)"|\
        "/vol1 @go @zelta_"*" @go syncable (incremental)"|\
        "3 up-to-date, 5 syncable"|\
        "8 total datasets compared")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}


match_rotate_output() {
  while IFS= read -r line; do
      # normalize whitespace, remove leading/trailing spaces
     normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
     case "$normalized" in
       "source is written; snapshotting: @zelta_"*|\
       "renaming '"*"/treetop' to '"*"/treetop_go'"|\
       "warning: insufficient snapshots; performing full backup for 2 datasets"|\
       "to ensure target is up-to-date, run: zelta backup "*" "*"/treetop"|\
       "no source: "*"/treetop/sub1/kid"|\
       *"K sent, 8 streams received in "*" seconds")
         ;;
       *)
         printf "Unexpected line format: %s\n" "$line" >&2
         return 1
         ;;
     esac
  done
  return 0
}

match_after_first_backup_output() {
  while IFS= read -r line; do
      # normalize whitespace, remove leading/trailing spaces
      normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')

        case "${normalized}" in
            "source is written; snapshotting: @zelta_"*)
                # New snapshot created on source
                ;;
            "syncing 9 datasets")
                # Starting sync operation
                ;;
            "no source: $TGT_TREE/sub1/kid")
                # Dataset exists on target but not on source
                ;;
            "target snapshots beyond the source match: $TGT_TREE/sub2")
                # Target has snapshots newer than source's latest matching snapshot
                ;;
            "target snapshots beyond the source match: $TGT_TREE/sub2/orphan")
                # Target has snapshots newer than source's latest matching snapshot
                ;;
            "target snapshots beyond the source match: $TGT_TREE/sub3/space name")
                # Target has snapshots newer than source's latest matching snapshot
                ;;
            "no snapshot; target diverged: $TGT_TREE/vol1")
                # No common snapshot found; target has diverged from source
                ;;
            "15K sent, 5 streams received in 0.09 seconds")
                # Summary statistics
                ;;
           *)
             echo "Unexpected line format: $line" >&2
             return 1
             ;;
     esac
  done
}


match_after_divergent_snapshots_output() {
  while IFS= read -r line; do
      # normalize whitespace, remove leading/trailing spaces
      normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')

     case "$normalized" in
       "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO"|\
       "[treetop] @go @go @go up-to-date"|\
       "/sub1 @go @go @go up-to-date"|\
       "/sub1/child - - - syncable (full)"|\
       "/sub1/kid - - - no source (target only)"|\
       "/sub2 @go @two @two blocked sync: target diverged"|\
       "/sub2/orphan @go @two @two blocked sync: target diverged"|\
       "/sub3 @go @two @go syncable (incremental)"|\
       "/sub3/space name @go @two @blocker blocked sync: target diverged"|\
       "/vol1 - @go - blocked sync: no target snapshots"|\
       "2 up-to-date, 2 syncable, 5 blocked"|\
       "9 total datasets compared")
         # Pattern matches
         ;;
       *)
         echo "Unexpected line format: $line" >&2
         return 1
         ;;
     esac
  done
}



divergent_initial_match_output() {
  while IFS= read -r line; do
      # normalize whitespace, remove leading/trailing spaces
      normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')

      case "$normalized" in
        "DS_SUFFIX MATCH SRC_LAST TGT_LAST INFO"|\
        "[treetop] @go @go @go up-to-date"|\
        "/sub1 @go @go @go up-to-date"|\
        "/sub1/child - - - syncable (full)"|\
        "/sub1/kid - - - no source (target only)"|\
        "/sub2 @go @go @go up-to-date"|\
        "/sub2/orphan @go @go @go up-to-date"|\
        "/sub3 @go @go @go up-to-date"|\
        "/sub3/space name @go @go @blocker blocked sync: target diverged"|\
        "/vol1 - @go - blocked sync: no target snapshots"|\
        "5 up-to-date, 1 syncable, 3 blocked"|\
        "9 total datasets compared")
          # Pattern matches
          ;;
        *)
          echo "Unexpected line format: $line" >&2
          return 1
          ;;
      esac
  done
}



validate_divergent_snap_tree_zfs_output() {
  while IFS= read -r line; do
    # Skip header line
    #[ "$line" = "NAME                             USED  AVAIL  REFER  MOUNTPOINT" ] && continue
    #[[ "$line" = "NAME"*"USED"*"AVAIL"*"REFER"*"MOUNTPOINT" ]] && continue

    # Pattern: NAME * * * MOUNTPOINT
    case "$line" in
      "NAME"*"USED"*"AVAIL"*"REFER"*"MOUNTPOINT") continue ;;
      apool*"/apool"|\
      $SRC_TREE*"/$SRC_TREE"|\
      $SRC_TREE/sub1*"/$SRC_TREE/sub1"|\
      $SRC_TREE/sub1/child*"/$SRC_TREE/sub1/child"|\
      $SRC_TREE/sub2*"/$SRC_TREE/sub2"|\
      $SRC_TREE/sub2/orphan*"/$SRC_TREE/sub2/orphan"|\
      $SRC_TREE/sub3*"/$SRC_TREE/sub3"|\
      $SRC_TREE/sub3/space\ name*"/$SRC_TREE/sub3/space name"|\
      $SRC_TREE/vol1*"-"|\
      bpool*"/bpool"|\
      bpool/backups*"/bpool/backups"|\
      $TGT_TREE*"/$TGT_TREE"|\
      $TGT_TREE/sub1*"/$TGT_TREE/sub1"|\
      $TGT_TREE/sub1/kid*"/$TGT_TREE/sub1/kid"|\
      $TGT_TREE/sub2*"/$TGT_TREE/sub2"|\
      $TGT_TREE/sub2/orphan*"/$TGT_TREE/sub2/orphan"|\
      $TGT_TREE/sub3*"/$TGT_TREE/sub3"|\
      $TGT_TREE/sub3/space\ name*"/$TGT_TREE/sub3/space name"|\
      $TGT_TREE/vol1*"-"|\
      $TGT_SETUP*"/$TGT_SETUP"|\
      $TGT_SETUP/sub1*"/$TGT_SETUP/sub1"|\
      $TGT_SETUP/sub2*"/$TGT_SETUP/sub2"|\
      $TGT_SETUP/sub2/orphan*"/$TGT_SETUP/sub2/orphan"|\
      $TGT_SETUP/sub3*"/$TGT_SETUP/sub3"|\
      $TGT_SETUP/sub3/space\ name*"/$TGT_SETUP/sub3/space name"|\
      $TGT_SETUP/vol1*"-"|\
      ${TGT_SETUP}_set*"/${TGT_SETUP}_set"|\
      ${TGT_SETUP}_set/sub1*"/${TGT_SETUP}_set/sub1"|\
      ${TGT_SETUP}_set/sub2*"/${TGT_SETUP}_set/sub2"|\
      ${TGT_SETUP}_set/sub2/orphan*"/${TGT_SETUP}_set/sub2/orphan"|\
      ${TGT_SETUP}_set/sub3*"/${TGT_SETUP}_set/sub3"|\
      ${TGT_SETUP}_set/sub3/space\ name*"${TGT_SETUP}_set/sub3/space name"|\
      ${TGT_SETUP}_set/vol1*"-")
        # Pattern matches
        ;;
      *)
        echo "Unexpected line format: $line" >&2
        return 1
        ;;
    esac
  done
}

# WIP notes
#    zelta backup $_options_all $_options_backup "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"

Describe 'Confirm divergent tree setup'
    Skip if 'SANDBOX_ZELTA_SRC_EP and SANDBOX_ZELTA_TGT_EP are undefined' test -z "$SANDBOX_ZELTA_SRC_EP" -a -z "$SANDBOX_ZELTA_TGT_EP"

    It "check zelta match output"
        When call zelta match "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"
        The output should satisfy output_for_match_after_backup
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

