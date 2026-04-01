# Belta - Btrfs-to-ZFS Command Translator

A compatibility layer that enables the [Zelta](https://zelta.space) ZFS backup suite to work with btrfs filesystems. Belta demonstrates that Zelta's TSV-based command architecture makes it effectively backend-agnostic.

## Overview

Belta translates ZFS-style commands into btrfs equivalents and transforms btrfs output back into the ZFS format that Zelta's AWK core expects. This proves that Zelta can back up more than just ZFS—with only minimal configuration changes.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Zelta Commands                           │
│                    (backup, match, policy...)                   │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Zelta AWK Core Scripts                       │
│           (zelta-backup.awk, zelta-match.awk, etc.)            │
│                   (COMPLETELY UNMODIFIED)                       │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Command Builder (TSV)                        │
│             zelta-cmds.tsv ──▶ belta <subcommand>               │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Belta Translator                        │
│     check│list│get│snap│create│send│recv│rename                │
│     └────┴────┴───┴────┴──────┴────┴────┴──────▶ btrfs commands │
└─────────────────────────────────────────────────────────────────┘
```

The key insight: Zelta's core AWK scripts are data-driven. They build shell commands using TSV configuration files (`zelta-cmds.tsv`, `zelta-opts.tsv`). By swapping these files and providing a translator, we can target any filesystem.

## Installation

```sh
# 1. Ensure zelta is installed and in your PATH
# 2. Copy/link belta to a directory in your PATH
# 3. Set ZELTA_SHARE to point to this directory:
cp .env.example .env
# Edit .env and set ZELTA_SHARE to the absolute path of contrib/belta
. /path/to/contrib/belta/.env
```

## Quick Start

```bash
# List subvolumes (equivalent to zfs list)
zelta list /btrfs_mount

# Match snapshots between source and target
zelta match /btrfs_source /btrfs_target

# Full backup to empty target
zelta backup /btrfs_source /btrfs_target

# Incremental backup (only sends missing snapshots)
zelta backup --incremental /btrfs_source /btrfs_target

# Create a snapshot with timestamp
zelta snapshot /btrfs_source
```

## Supported Commands

| Zelta Command | Status | Notes |
|---------------|--------|-------|
| `zelta list` | ✅ Working | Lists subvolumes and snapshots |
| `zelta match` | ✅ Working | Compares source/target snapshots |
| `zelta backup` | ✅ Working | Full and incremental backups |
| `zelta snapshot` | ✅ Working | Creates read-only snapshots |
| `zelta policy` | ⚠️ Partial | Basic policy support |
| `zelta rotate` | ❌ Not implemented | Would use rename |
| `zelta clone` | ❌ Not implemented | Stub returns error |

## Implementation Details

### UUID to GUID Translation

Zelta's AWK core expects numeric GUIDs for snapshot matching:

```awk
# From zelta-match.awk
$2 ~ /^[0-9]+$/   # GUID validation expects numeric
```

Btrfs uses hex UUIDs (`a1b2c3d4-e5f6-...`), so Belta converts them:

```bash
belta_uuid_to_guid() {
    # Strip hyphens
    _hex=$(echo "$1" | tr -d '-')
    # Take first 15 hex chars
    _hex=$(echo "$_hex" | cut -c1-15)
    # Convert hex to decimal
    printf '%d\n' "0x${_hex}"
}
```

### Path Handling

**Critical**: Output paths must include a leading slash. Zelta calculates `ds_length = length(DS) + 1` and uses `substr(name, ds_length)` to extract the relative path. Without the leading `/`, snapshots aren't recognized correctly.

```
# CORRECT output format from belta list:
/belta1/data    123456789012345    0    1711843200
/belta1/data@2024-01-01    123456789012346    0    1711843200
```

### FS_TREE Detection

When listing from a mount point root, btrfs reports `<FS_TREE>` as the name. `belta get` rejects this to prevent the backup logic from thinking a non-existent target exists:

```sh
if echo "$_show" | grep -q "^[[:space:]]*Name:[[:space:]]*<FS_TREE>"; then
    return 1  # Reject FS_TREE as invalid dataset
fi
```

## Subcommands

### `belta check`
Verifies a dataset path exists.

### `belta list`
Enumerates subvolumes and snapshots, outputs TSV with converted GUIDs.

### `belta get`
Returns stub ZFS properties (type=filesystem, encryption=off, etc.).

### `belta snap`
Creates a read-only snapshot: `btrfs subvolume snapshot -r`

### `belta create`
Creates a new subvolume: `btrfs subvolume create`

### `belta send`
Sends a snapshot stream. Translates ZFS flags:
- `-I`/`-i` → `-p` (parent for incremental)
- Strips ZFS-only flags: `-P`, `-L`, `-c`, `-e`, `-w`, etc.

### `belta recv`
Receives a snapshot stream. Fakes ZFS success output for AWK stream counting:
```
received 0 stream in 5 seconds
```

### `belta rename`
Renames subvolumes (used for rotation). Currently uses `mv`.

## Configuration

### TSV Files

**`zelta-cmds.tsv`** - Maps Zelta actions to belta subcommands:
```tsv
ACTION	REMOTE	COMMAND	ARGUMENTS	VARIABLES
CHECK	DEFAULT	belta check	-Ho name	ds
LIST	DEFAULT	belta list		ds
...
```

**`zelta-opts.tsv`** - Defines command-line options. Belta's version strips ZFS-specific passthrough flags.

## Limitations

### Flat Subvolume Structure Only
Belta assumes a flat structure: snapshots live alongside their parent subvolumes with `@timestamp` suffix. No recursive child enumeration.

### No Native Encryption
Btrfs doesn't have native encryption like ZFS. `belta get` reports `encryption=off` for all datasets.

### Read-Only Snapshots
Belta creates read-only snapshots (`-r` flag). Writable snapshots aren't supported.

### Limited Property Support
Only basic properties are emulated: `type`, `encryption`, `written`, `canmount`.

### Tested On
- Alpine Linux with btrfs-progs v6.8.1
- mawk (BusyBox awk has regex issues)

## Testing

```bash
# Basic functionality test
sudo zelta list /btrfs_mount

# Match test
sudo zelta match /btrfs_source /btrfs_target

# Full backup test
sudo zelta backup /btrfs_source /btrfs_target

# Incremental backup test (run twice, second should be instant)
sudo zelta backup --incremental /btrfs_source /btrfs_target
```

## Development

### Project Structure
```
contrib/belta/
├── belta              # Main translator script (350 lines)
├── zelta-cmds.tsv     # Command mappings
├── zelta-opts.tsv     # Option definitions
├── zelta-*.awk        # Symlinks to core AWK scripts
├── zelta-*.tsv        # Symlinks to other TSV files
└── README.md          # This file
```

### Core AWK Files (Unmodified)
- `zelta-backup.awk` - Main backup orchestration
- `zelta-match.awk` - Snapshot matching logic
- `zelta-policy.awk` - Policy engine
- `zelta-common.awk` - Shared utilities
- `zelta-report.awk` - Output formatting
- `zelta-snapshot.awk` - Snapshot management
- `zelta-args.awk` - Argument parsing
- `zelta-color.awk` - Color/styling
- `zelta-sendopts.awk` - Send option handling

## Contributing

Belta is a proof-of-concept demonstrating Zelta's flexibility. To extend it:

1. **Add new subcommands** - Extend the `case` statement in `belta`
2. **Modify TSV files** - Adjust command mappings without touching AWK
3. **Test thoroughly** - Use `shellspec` tests from the main zelta repo

## License

Same as Zelta (see main repository).

## See Also

- [Zelta Documentation](https://zelta.space)
- `TECHNICAL.md` - Deep dive into technical implementation details
