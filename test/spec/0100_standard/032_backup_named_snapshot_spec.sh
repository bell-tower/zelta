# Test backups that end at a named source snapshot

named_snap_init() {
	NamedSnapSuffix="/named-snapshot"
	NamedSnapSrcDS="${SANDBOX_ZELTA_SRC_DS}${NamedSnapSuffix}"
	NamedSnapTgtDS="${SANDBOX_ZELTA_TGT_DS}${NamedSnapSuffix}"

	if [ -n "$SANDBOX_ZELTA_SRC_REMOTE" ]; then
		NamedSnapSrcEP="${SANDBOX_ZELTA_SRC_REMOTE}:${NamedSnapSrcDS}"
	else
		NamedSnapSrcEP="$NamedSnapSrcDS"
	fi

	if [ -n "$SANDBOX_ZELTA_TGT_REMOTE" ]; then
		NamedSnapTgtEP="${SANDBOX_ZELTA_TGT_REMOTE}:${NamedSnapTgtDS}"
	else
		NamedSnapTgtEP="$NamedSnapTgtDS"
	fi
}

named_snap_cleanup() {
	named_snap_init
	tgt_exec zfs destroy -r "$NamedSnapTgtDS" >/dev/null 2>&1 || :
	src_exec zfs destroy -r "$NamedSnapSrcDS" >/dev/null 2>&1 || :
	return 0
}

named_snap_setup() {
	named_snap_init
	named_snap_cleanup || return 1
	src_exec zfs create -u "$NamedSnapSrcDS" || return 1
	src_exec zfs snapshot "$NamedSnapSrcDS@one" || return 1
	src_exec zfs snapshot "$NamedSnapSrcDS@two" || return 1
	src_exec zfs snapshot "$NamedSnapSrcDS@three" || return 1
	return 0
}

named_snap_backup() {
	named_snap_init
	zelta backup --log-level 4 --no-snapshot "$NamedSnapSrcEP@$1" "$NamedSnapTgtEP" 2>&1
}

Describe 'Backup to a named source snapshot' standard:32
	Skip if 'SANDBOX_ZELTA_SRC_DS undefined' test -z "$SANDBOX_ZELTA_SRC_DS"
	Skip if 'SANDBOX_ZELTA_TGT_DS undefined' test -z "$SANDBOX_ZELTA_TGT_DS"

	It 'creates a source with three snapshots'
		When call named_snap_setup
		The status should be success
	End

	It 'stops a full backup at the named snapshot'
		When call named_snap_backup one
		The status should be success
		The output should include 'syncing 1 datasets'
		The output should not include '@two'
		The output should not include 'error:'
	End

	It 'stops an incremental backup at the named snapshot'
		When call named_snap_backup two
		The status should be success
		The output should include 'incremental stream received'
		The output should not include '@three'
		The output should not include 'error:'
	End

	It 'reports up-to-date when the target has the named snapshot'
		When call named_snap_backup two
		The status should be success
		The output should include 'up-to-date'
		The output should not include 'zfs send'
	End

	It 'cleans up the named snapshot datasets'
		When call named_snap_cleanup
		The status should be success
	End
End
