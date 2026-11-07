# A forced snapshot that fails must not fall back to an older snapshot.

# Exercise the real CLI with a fake ZFS tree; never touch a host's pools.
run_backup_snapshot() {
	_case=$1
	shift
	_fakebin="$SHELLSPEC_TMPBASE/backup-snapshot-bin"
	mkdir -p "$_fakebin"
	cat > "$_fakebin/zfs" <<'EOF'
#!/bin/sh
_command=$1
for _arg do
	_dataset=$_arg
done
case "$_command $_dataset" in
'get apool/source')
	printf 'apool/source\ttype\tfilesystem\n'
	printf 'apool/source\twritten\t4096\n'
	;;
'list apool/source')
	printf 'apool/source@old\t2\n'
	printf 'apool/source\t1\n'
	;;
get*|list*)
	printf "cannot open '%s': dataset does not exist\n" "$_dataset" >&2
	exit 1
	;;
snapshot*)
	printf "cannot create snapshot '%s': dataset already exists\n" "$_dataset" >&2
	exit 1
	;;
send*)
	printf '%s\n' "$*" >> "$BACKUP_SENDS"
	;;
recv*)
	cat > /dev/null
	printf 'received 1K stream in 1 seconds (1K/sec)\n'
	;;
create*) ;;
*) exit 1 ;;
esac
EOF
	chmod +x "$_fakebin/zfs"
	_repo="${REPO_ROOT:-$SHELLSPEC_PROJECT_ROOT}"
	env PATH="$_fakebin:$_repo/bin:$PATH" ZELTA_SHARE="$_repo/share/zelta" \
		ZELTA_ENV=/dev/null \
		BACKUP_SENDS="$SHELLSPEC_TMPBASE/backup-sends-$_case" "$@"
}

Describe 'Backup snapshot failures' standard:31
	It 'stops when a forced snapshot fails'
		When call run_backup_snapshot forced zelta backup -qq --snapshot --snap-name new apool/source bpool/backups/source
		The status should be failure
		The error should eq "error: error creating snapshot 'apool/source@new'"
		The path "$SHELLSPEC_TMPBASE/backup-sends-forced" should not be exist
	End

	It 'falls back to the latest snapshot without --snapshot'
		When call run_backup_snapshot fallback zelta backup -qq --snap-name new apool/source bpool/backups/source
		The status should be success
		The contents of file "$SHELLSPEC_TMPBASE/backup-sends-fallback" should eq 'send -P -L -c -e apool/source@old'
	End
End
