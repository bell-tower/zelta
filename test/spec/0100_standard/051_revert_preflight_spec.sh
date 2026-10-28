# Exercise the real CLI with a fake ZFS tree; never touch a host's pools.
run_revert_preflight() {
	_case=$1
	shift
	_fakebin="$SHELLSPEC_TMPBASE/revert-preflight-bin"
	mkdir -p "$_fakebin"
	cat > "$_fakebin/zfs" <<'EOF'
#!/bin/sh
_command=$1
shift
case $_command in
get)
	for _ds in apool/source 'apool/source/child with space'; do
		printf '%s\ttype\tfilesystem\n' "$_ds"
		printf '%s\treadonly\toff\n' "$_ds"
	done
	;;
list)
	_props=
	_prev=
	for _arg do
		[ "$_prev" != -o ] || _props=$_arg
		_prev=$_arg
	done
	if [ "$_props" = name ]; then
		[ "$REVERT_CASE" != list-failure ] || exit 1
		printf '%s\n' apool/source apool/source@old 'apool/source/child with space'
		case $REVERT_CASE in
		coherent*) printf '%s\n' 'apool/source/child with space@old' ;;
		no-snapshot) ;;
		*) printf '%s\n' 'apool/source/child with space@new' ;;
		esac
	else
		printf 'apool/source@old\t2\n'
		printf 'apool/source\t1\n'
		case $REVERT_CASE in
		coherent*) printf 'apool/source/child with space@old\t4\n' ;;
		no-snapshot) ;;
		*) printf 'apool/source/child with space@new\t5\n' ;;
		esac
		printf 'apool/source/child with space\t3\n'
	fi
	;;
rename|clone|snapshot)
	printf '%s\n' "$_command $*" >> "$REVERT_MUTATIONS"
	case "$_command $*" in
	*'child with space@old'*)
		case $REVERT_CASE in coherent*) exit 0 ;; esac
		printf '%s\n' 'cannot open snapshot: dataset does not exist' >&2
		exit 1
		;;
	esac
	;;
*) exit 1 ;;
esac
EOF
	chmod +x "$_fakebin/zfs"
	_repo="${REPO_ROOT:-$SHELLSPEC_PROJECT_ROOT}"
	env PATH="$_fakebin:$_repo/bin:$PATH" ZELTA_SHARE="$_repo/share/zelta" \
		ZELTA_ENV=/dev/null REVERT_CASE="$_case" \
		REVERT_MUTATIONS="$SHELLSPEC_TMPBASE/revert-mutations-$_case" "$@"
}

revert_pipe_status_unavailable() {
	"${ZELTA_AWK:-awk}" 'BEGIN { cmd = "exit 1"; cmd | getline; exit(close(cmd) != 0) }'
}

Describe 'Revert whole-tree preflight' standard:51
	It 'rejects a missing child snapshot before any mutation'
		When call run_revert_preflight missing zelta revert -qq apool/source@old
		The status should be failure
		The error should eq "error: cannot revert tree: missing snapshot 'apool/source/child with space@old'; revert eligible children individually"
		The path "$SHELLSPEC_TMPBASE/revert-mutations-missing" should not be exist
	End

	It 'rejects children with no snapshots before any mutation'
		When call run_revert_preflight no-snapshot zelta revert -qq apool/source@old
		The status should be failure
		The error should include 'cannot revert tree:'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-no-snapshot" should not be exist
	End

	It 'also rejects incomplete dry-run plans'
		When call run_revert_preflight dryrun zelta revert -qqn apool/source@old
		The status should be failure
		The error should include 'missing snapshot'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-dryrun" should not be exist
	End

	It 'fails closed if the whole-tree listing fails'
		When call run_revert_preflight list-failure zelta revert -qq apool/source@old
		The status should be failure
		The error should eq 'error: cannot validate revert tree; no datasets renamed'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-list-failure" should not be exist
	End

	It 'permits a coherent recursive dry run'
		When call run_revert_preflight coherent zelta revert -qqn apool/source@old
		The status should be success
		The path "$SHELLSPEC_TMPBASE/revert-mutations-coherent" should not be exist
	End

	It 'rejects a depth limit that would strand children under the preserved path'
		When call run_revert_preflight coherent zelta revert -qqn -d 1 apool/source@old
		The status should be failure
		The error should include 'unselected dataset'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-coherent" should not be exist
	End

	It 'rejects a child without snapshots when no snapshot name is given'
		When call run_revert_preflight no-snapshot zelta revert -qq apool/source
		The status should be failure
		The error should include 'no snapshot for'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-no-snapshot" should not be exist
	End

	It 'rejects a filter that would strand a child under the preserved path'
		When call run_revert_preflight coherent zelta revert -qqn --exclude='*/child*' apool/source@old
		The status should be failure
		The error should include 'unselected dataset'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-coherent" should not be exist
	End

	It 'executes a coherent recursive revert after validation'
		When call run_revert_preflight coherent-real zelta revert -qq apool/source@old
		The status should be success
		The path "$SHELLSPEC_TMPBASE/revert-mutations-coherent-real" should be exist
	End

	Parameters
		--force force-long
		-f force-short
	End
	It "permits the old incomplete clone plan with $1"
		When call run_revert_preflight "$2" zelta revert -n "$1" apool/source@old
		The status should be success
		The output should include "'apool/source_old/child with space@old'"
		The error should include 'skipping revert preflight'
		The path "$SHELLSPEC_TMPBASE/revert-mutations-$2" should not be exist
	End

	It "preserves the original clone failure status with $1"
		Skip if 'AWK does not report pipeline exit status' revert_pipe_status_unavailable
		When call run_revert_preflight "failure-$2" zelta revert -qq "$1" apool/source@old
		The status should be failure
		The error should eq "error: error creating clone 'apool/source/child with space'"
		The path "$SHELLSPEC_TMPBASE/revert-mutations-failure-$2" should be exist
	End
End
