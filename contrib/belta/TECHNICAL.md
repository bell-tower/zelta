# Technical Deep Dive

This document covers the technical implementation details, edge cases, and design decisions in Belta.

## Table of Contents

1. [Command Translation Architecture](#command-translation-architecture)
2. [UUID to GUID Conversion](#uuid-to-guid-conversion)
3. [Received UUID for Matching](#received-uuid-for-matching)
4. [Sorting by Creation Time](#sorting-by-creation-time)
5. [Path Handling and ds_length](#path-handling-and-ds_length)
6. [FS_TREE Detection](#fs_tree-detection)
7. [Send/Recv Flag Mapping](#sendrecv-flag-mapping)
8. [AWK Regex Compatibility](#awk-regex-compatibility)
9. [Stream Output Formatting](#stream-output-formatting)
10. [Environment Variable Flow](#environment-variable-flow)

## Command Translation Architecture

### How Zelta Builds Commands

Zelta uses a data-driven approach. The `build_command()` function in `zelta-common.awk` reads from TSV files:

```awk
# From zelta-common.awk
function build_command(action, cmd_arr,    _cmd, _line, _f) {
    # Reads zelta-cmds.tsv
    # Replaces placeholders like {ds}, {flags} with values from cmd_arr
}
```

The TSV format:
```
ACTION  REMOTE  COMMAND  ARGUMENTS  VARIABLES
LIST    DEFAULT belta list      ds
```

**Key insight**: By changing `COMMAND` from `zfs` to `belta list`, we intercept the command without modifying the AWK core.

### Command Flow

```
zelta backup /src /dst
    │
    ▼
zelta-args.awk → sets ZELTA_* environment vars
    │
    ▼
zelta-backup.awk → builds commands via build_command()
    │
    ▼
zelta-cmds.tsv → "belta list" (instead of "zfs list")
    │
    ▼
belta list → btrfs subvolume list → format output
```

## UUID to GUID Conversion

### The Problem

Zelta's AWK core validates GUIDs with a regex expecting numeric values:

```awk
# From zelta-match.awk (line ~102)
$2 ~ /^[0-9]+$/
```

Btrfs uses hex UUIDs like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`.

### The Solution

Belta's `belta_uuid_to_guid()` function:

```bash
belta_uuid_to_guid() {
    _uuid="$1"
    if [ -z "$_uuid" ] || [ "$_uuid" = "-" ]; then
        echo "0"
        return
    fi
    # 1. Strip hyphens: a1b2c3d4e5f67890abcdef1234567890
    _hex=$(echo "$_uuid" | tr -d '-')
    # 2. Take first 15 hex chars: a1b2c3d4e5f6789
    _hex=$(echo "$_hex" | cut -c1-15)
    # 3. Convert to decimal: 454278588155752105
    printf '%d\n' "0x${_hex}"
}
```

### Why 15 Hex Chars?

- 16 hex chars = 64 bits
- `printf '%d'` on some shells overflows at >63 bits
- 15 hex chars = 60 bits, safely within limits
- Collisions are astronomically unlikely in practice

## Received UUID for Matching

### The Problem

When btrfs receives a snapshot, it generates a new UUID for the received subvolume. This breaks Zelta's matching logic which expects snapshot GUIDs to be preserved across send/receive (as they are in ZFS).

```
Source snapshot:      UUID=9c37dbe8-8c88-4046-88ad-9acd59a9f1b2
Target (received):    UUID=ef9587c6-5409-d94c-8dd4-515a5d24c5b4
                      Received UUID=9c37dbe8-8c88-4046-88ad-9acd59a9f1b2
```

If belta reports the target's UUID (`ef9587c6...`), Zelta won't find a match because the source has a different UUID.

### The Solution

Belta checks for `Received UUID` field and uses that for matching when available:

```bash
_received_uuid=$(echo "$_show" | awk '/^\tReceived UUID:/{print $3}')
_uuid=$(echo "$_show" | awk '/^\tUUID:/{print $2}')
if [ -n "$_received_uuid" ] && [ "$_received_uuid" != "-" ]; then
    _uuid="$_received_uuid"
fi
```

**Note:** The awk pattern uses `$3` because "Received UUID" contains a space, so awk splits it into separate fields.

### Result

Both source and target now report the same GUID for received snapshots, enabling:
- Proper matching for incremental backups
- Correct "up-to-date" detection

## Sorting by Creation Time

### The Problem

ZFS `zfs list -S createtxg` returns snapshots sorted by creation time in reverse order (newest first). Zelta's match logic expects this ordering - it treats the first snapshot in the list as the "latest".

Btrfs `btrfs subvolume list` returns subvolumes in an undefined order (by default, by subvolume ID). This caused Zelta to identify the wrong snapshot as "latest".

### The Solution

Belta sorts output by timestamp in reverse order:

```bash
# Collect output and sort by column 4 (timestamp) numerically reverse
... | sort -t'\t' -k4,4nr -k1,1 > "$_tmpfile"
```

The `sort` command:
- `-t'\t'` - uses tab as delimiter
- `-k4,4nr` - sorts by column 4 (timestamp) numerically in reverse
- `-k1,1` - secondary sort by name for consistent ordering

### Result

Snapshots are now listed newest-first, matching ZFS behavior:

```
/belta1/data@20260401044337    1086772453432731476    0    1775018617  <- newest
/belta1/data@20260401044116    889011214805418516     0    1775018476
/belta1/data@20260401043541    703544224092029956     0    1775018141
/belta1/data                   391807275165398372     0    1775017859
```

## Path Handling and ds_length

### The Critical Bug

Early versions output paths without leading slashes:
```
# WRONG
belta1/data@2024-01-01    1234567890    0    1711843200
```

Zelta's match logic calculates:
```awk
# From zelta-match.awk (line ~151)
_ds_length = length(DS) + 1
_ds_suffix = substr(name, _ds_length)
```

For DS=`/belta1`, ds_length=8:
- With `/belta1/data`: substr("/belta1/data", 8) = `/data` ✅
- With `belta1/data`: substr("belta1/data", 8) = `ta` ❌

### The Fix

All output paths must include the leading `/`:
```bash
# CORRECT output format
/belta1/data@2024-01-01    1234567890    0    1711843200
```

This ensures `ds_suffix` extraction works correctly for:
- Dataset matching
- Snapshot identification
- Incremental send parent selection

## FS_TREE Detection

### The Problem

When listing from a mount point root:
```bash
btrfs subvolume list -a /belta1
# ID 256 gen 10 top level 5 path <FS_TREE>/data
```

The `<FS_TREE>` pseudo-name represents the btrfs filesystem root, not an actual subvolume.

### The Impact

If `belta get` accepts `<FS_TREE>`:
1. Zelta thinks the target exists
2. Backup logic skips dataset creation
3. `btrfs receive` fails because the path doesn't exist as a subvolume

### The Solution

`belta get` explicitly rejects FS_TREE:

```bash
belta_get() {
    _show=$(btrfs subvolume show "$_ds" 2>/dev/null)
    if [ -z "$_show" ]; then
        return 1
    fi
    # Check if it's the root FS_TREE (not an actual subvolume)
    if echo "$_show" | grep -q "^\s*Name:\s*<FS_TREE>"; then
        return 1
    fi
    # ... output properties
}
```

This forces Zelta to create the target subvolume properly.

## Send/Recv Flag Mapping

### ZFS to Btrfs Flag Translation

| ZFS Flag | Btrfs Equivalent | Belta Action |
|----------|------------------|--------------|
| `-I` (intermediate) | `-p` (parent) | Map to parent |
| `-i` (incremental) | `-p` (parent) | Map to parent |
| `-P` (parsable) | N/A | Strip |
| `-L` (large block) | N/A | Strip |
| `-c` (compressed) | N/A | Strip |
| `-e` (embed) | N/A | Strip |
| `-w` (raw) | N/A | Strip |

### Implementation

```sh
belta_send() {
    _parent=""
    _snap=""

    while [ $# -gt 0 ]; do
        case "$1" in
        -I|-i)
            shift
            _parent="$1"
            shift ;;
        -*)
            shift ;;  # Strip all other flags (unsupported by btrfs)
        *)
            _snap="$1"
            shift ;;
        esac
    done

    if [ -n "$_parent" ]; then
        btrfs send -p "$_parent" "$_snap"
    else
        btrfs send "$_snap"
    fi
}
```

### Receive Flags

Btrfs receive has fewer options than ZFS. Belta strips:
- `-o` (origin)
- `-x` (exclude property)
- `-e` (embedded)
- `-F` (force)
- `-u` (unmount)
- `-M` (manual mount)

## AWK Regex Compatibility

### The Bug

The `glob_to_regex()` function in `zelta-common.awk` used:
```awk
gsub(/[\\^$.|()[\]{}+]/, "\\\\&", glob)
```

This fails on mawk because `{}` is interpreted as an interval expression (e.g., `{1,3}`).

### The Fix

Move `{}` to the start of the character class:
```awk
gsub(/[{}\\^$.|()\[\]+]/, "\\\\&", glob)
```

Character classes in AWK regex treat `{}` literally at the start, but as interval delimiters elsewhere. The replacement `"\\\\&"` produces a literal backslash followed by the matched character in AWK's string escape rules.

### Testing

```bash
# Test with different AWK implementations
export ZELTA_AWK=mawk   # or gawk, awk
zelta match /src /dst
```

## Stream Output Formatting

### ZFS recv Output

Zelta's AWK core parses `zfs recv` output to count streams:

```awk
# From zelta-backup.awk (line ~768)
else if ($1 == "received") {
    _streams++
    _time += $5
    Summary["replicationStreamsReceived"]++
}
```

Expected format: `received <size> stream in <seconds> seconds`

### Btrfs receive Output

Btrfs receive outputs:
```
# Nothing on success, or error on failure
```

### The Solution

`belta recv` fakes ZFS-style output:

```sh
belta_recv() {
    # ... flag parsing sets _dest ...
    _parent=$(dirname "$_dest")
    mkdir -p "$_parent"

    _start=$(date +%s)
    btrfs receive "$_parent"
    _end=$(date +%s)
    _elapsed=$(( _end - _start ))

    # Fake ZFS recv success output for AWK stream counting
    echo "receiving full stream"
    echo "received 0 stream in ${_elapsed} seconds"
}
```

This satisfies the AWK parsing logic.

## Environment Variable Flow

### How Arguments Flow

1. **CLI Args** → `zelta` shell script
2. **`zelta-args.awk`** → Parses into `ZELTA_*` environment variables
3. **`zelta-backup.awk`** → Reads `ENVIRON[]` array
4. **`build_command()`** → Uses variables to construct commands

### Example Flow

```bash
zelta backup --incremental /src /dst
```

1. `zelta-args.awk` sets:
   - `ZELTA_SEND_INTR=INTERMEDIATE`
   - `ZELTA_SRC_DS=/src`
   - `ZELTA_TGT_DS=/dst`

2. `zelta-backup.awk` reads:
   ```awk
   Opt["SEND_INTR"] = ENVIRON["ZELTA_SEND_INTR"]
   ```

3. `get_send_command_flags()` uses it:
   ```awk
   if (Opt["SEND_INTR"])
       _flag_list[++_f] = "-I"  # or maps to btrfs -p
   ```

4. `build_command("SEND", ...)` produces:
   ```
   belta send -P -I '/src@snap1' '/src@snap2'
   ```

### MATCH Command Exception

The `MATCH` command is special—it runs `zelta ipc-run match` which expects environment variables, not CLI arguments:

```
# In zelta-cmds.tsv
MATCH		zelta ipc-run match	--time --log-mode=text -Hpo relname,match,srcnext,srclast,tgtlast	flags
```

This is why `zelta match` works: it sets up the environment, then spawns a subprocess.

## Design Decisions

### Why Not Modify AWK?

The goal was to prove Zelta's architecture is flexible. By only modifying TSV files and creating a translator, we demonstrate that:

1. The AWK core is truly backend-agnostic
2. New filesystems can be supported without core changes
3. The TSV configuration system is powerful

One exception was made: the mawk compatibility fix for `glob_to_regex()` was upstreamed into `zelta-common.awk`. Belta picks this up via the symlink — no local modification is needed.

### Why Shell Instead of AWK?

Belta is written in shell because:
1. It's consistent with Zelta's shell wrapper approach
2. Easier to call external binaries (`btrfs`, `date`)
3. Simpler argument parsing for this use case

### Why Flat Structure?

Btrfs subvolumes can be nested, but Belta assumes flat structure for simplicity:
- Snapshots live alongside parents: `data` and `data@2024-01-01`
- No recursive child enumeration
- Matches typical backup use case

Full recursion support would require:
- Parsing `btrfs subvolume list -R` for parent relationships
- Building a tree structure
- More complex path calculations

## Debugging Tips

### Enable Debug Logging

```bash
export ZELTA_LOG_LEVEL=4  # DEBUG
zelta backup /src /dst 2>&1
```

### Trace Commands

```bash
export ZELTA_DRYRUN=1
zelta backup /src /dst  # Shows commands without executing
```

### Check UUID Conversion

```bash
# Manual test
belta list /btrfs_mount | head -5
# Should show: /path<TAB>numeric_guid<TAB>0<TAB>timestamp
```

### Verify FS_TREE Handling

```bash
# Should fail (FS_TREE not a real subvolume)
belta get /btrfs_mount_root

# Should succeed
belta get /btrfs_mount_root/data
```

## Future Enhancements

1. **Recursive Support** - Parse `btrfs subvolume list -R` for nested subvolumes
2. **Compression** - Map ZFS compression properties to btrfs compression
3. **Quotas** - Translate ZFS quota properties to btrfs qgroups
4. **Send/Receive Filters** - Support btrfs send's `-c` (clone sources)
5. **Rotation** - Implement `belta rotate` using btrfs subvolume deletion

## References

- [Zelta Match Logic](../../share/zelta/zelta-match.awk)
- [Zelta Backup Logic](../../share/zelta/zelta-backup.awk)
- [Btrfs Subvolume Documentation](https://btrfs.readthedocs.io/en/latest/Subvolumes.html)
- [Btrfs Send/Receive](https://btrfs.readthedocs.io/en/latest/Send-receive.html)
