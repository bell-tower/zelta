# zprune

**zprune** is a destructive snapshot pruning coordinator that works with [Zelta](https://zelta.space) to safely remove ZFS snapshots that have been replicated to a backup target.

## Design Philosophy

zprune is intentionally **thin**. All heavy lifting—argument processing, policy validation, snapshot selection—is delegated to `zelta prune`. zprune's job is:

1. Validate that the source is local (no SSH destruction)
2. Call `zelta prune --signal-policy` to get machine-readable policy status
3. If an explicit policy exists: execute destruction with appropriate safety checks
4. If no policy: pass through `zelta prune` output and explain why destruction was skipped

This mirrors how `zelta backup` coordinates with `zelta match` using parsable output flags.

## Safety Model

zprune enforces a **no-footguns** policy:

- **Local only**: Source must be a local dataset (no `user@host:` prefix)
- **Explicit policy required**: Destruction only occurs with explicit retention flags or `--default-policy`
- **Safe by default**: Without policy, zprune behaves exactly like `zelta prune` (report only)
- **Confirmation**: Type "destroy" to confirm (unless `-f` used with explicit policy)

### Policy Hierarchy

From strongest to weakest:

1. **Explicit flags**: `--keep-snap-num=50 --keep-snap-days=30`
2. **Default opt-in**: `--default-policy` (uses 100 snapshots, 90 days)
3. **Config file**: Site-defined policy in `/etc/zprune.conf` or `~/.config/zprune/zprune.conf`
4. **None**: Report only mode

## Installation

zprune is installed separately from Zelta:

```bash
./install.sh
# Or: ZPRUNE_BIN=$HOME/.local/bin ./install.sh
```

## Usage

```bash
# Report only (safe - no policy specified)
zprune tank/data backup:tank/backups/data

# Use default policy with confirmation
zprune --default-policy tank/data backup:tank/backups/data

# Use default policy without confirmation
zprune --default-policy -f tank/data backup:tank/backups/data

# Explicit policy
zprune --keep-snap-num=50 --keep-snap-days=30 -f tank/data backup:tank/backups/data

# Dry-run
zprune -n --default-policy tank/data backup:tank/backups/data
```

## Options

### zprune-Specific Options
- `--default-policy` - Accept default retention (100 snapshots, 90 days)
- `-f, --force` - Skip confirmation (requires explicit/default policy)
- `-r, --recursive` - Pass `-r` to `zfs destroy`
- `-n, --dry-run` - Show commands without executing
- `-v, --verbose` - Verbose output
- `-q, --quiet` - Suppress non-error output

### Delegated to `zelta prune`
All other options are passed through:
- `--keep-snap-num=N` - Minimum snapshots to keep
- `--keep-snap-days=N` - Minimum age in days
- `--no-ranges` - Individual snapshots instead of ranges
- `-X, --exclude=PATTERN` - Exclude datasets
- `-d, --depth=LEVELS` - Limit recursion depth

## How It Works

1. **zprune** validates source is local
2. **zprune** calls: `zelta prune --signal-policy [args] source target`
3. **zelta prune** outputs tab-delimited:
   ```
   # ZELTA_PRUNE_POLICY\t<explicit|default|none>\t<description>
   tank/data@snap1%snap5
   tank/data@snap10
   ```
4. **zprune** parses first line for policy status
5. If `explicit` or `default`: prompt (or `-f`) and destroy
6. If `none`: output snapshots and instructions for enabling destruction

## Implementation Notes (for Zelta integration)

zprune requires `zelta prune` to support `--signal-policy` flag that outputs:

```
# ZELTA_PRUNE_POLICY[tab]<status>[tab]<description>
<snapshot ranges...>
```

Status values:
- `explicit` - User specified explicit retention flags
- `default` - User used `--default-policy` (or config file default)
- `none` - No policy specified, operating in report-only mode

Example:
```
# ZELTA_PRUNE_POLICY	explicit	--keep-snap-num=50 --keep-snap-days=30
tank/data@snap1%snap5
tank/data@snap10%snap20
```

The description field is human-readable and shown to users.

## Requirements

- Zelta (with `--signal-policy` support)
- ZFS with destroy permission on source

## Warning

**Snapshot destruction is permanent.** zprune is designed to require multiple deliberate steps before destruction:

1. First run shows what would be pruned without policy
2. Add `--default-policy` to enable destruction
3. Type "destroy" to confirm (or use `-f`)

This friction is intentional. Recovery at 3am is hard enough without wondering which snapshots you accidentally deleted.

## Future Retention Policies

The following are under consideration for zelta prune integration:

### Density-Based Thinning
```
--thinning=default    # 48h: all, 7d: hourly, 30d: daily, 1y: monthly, >1y: yearly
```

### Tagged Retention (zfsnap-compatible)
```
tank/data@2025-01-30--1y   # Keep for 1 year
tank/data@2025-01-30--forever  # Never prune
--exclude-tag=forever
```

### Space-Aware Pruning
```
--space-trigger=80%   # Prune when pool reaches 80%
--lag-waves=2         # Keep 2 "waves" of data
```

### Composable Policy
```yaml
# /etc/zprune.conf
policy:
  max_age: 7y
  thinning: default
  exclude_tags: [forever, manual]
  keep_minimum: 10
```

Policy evaluation order (safest wins):
1. Excluded tags
2. Minimum count
3. Match point (never prune newer)
4. Thinning rules
5. Max-age cutoff

## See Also

- `zelta help prune` - The engine behind zprune
- `zelta help match` - Dataset comparison

## License

BSD 2-Clause (same as Zelta)
