# zprune

`zprune` is the destructive companion to `zelta prune`.

`zelta prune` reports snapshots that are safe prune candidates. `zprune` runs the same candidate selection, displays the list, asks for confirmation, and destroys those snapshots from the local source dataset.

## Design

`zprune` is intentionally thin:

1. Reserve destructive wrapper flags such as `-f` and `--force`.
2. Pass normal Zelta options through to `zelta prune`.
3. Request individual snapshot candidates with `--no-ranges` for clone checks.
4. Display the candidate list.
5. Destroy only after the user types `destroy`, unless `--force` is used.

Retention policy, replication detection, recursion, depth limits, and exclusions belong to `zelta prune` and the `ZELTA_` option system.

## Defaults

With no retention flags, `zprune` uses the same defaults as `zelta prune`:

- Keep at least `ZELTA_KEEP_SNAP_NUM` snapshots, default `30`.
- Keep snapshots newer than `ZELTA_KEEP_SNAP_DAYS`, default `30`.
- Only select snapshots detected as successfully replicated to the target.

This means the command name and confirmation prompt are the destructive safety boundary. Extra opt-in policy flags are not required.

## Usage

```sh
# Show candidates, then ask before destroying
zprune tank/data backup:tank/data

# Destroy without prompting
zprune -f tank/data backup:tank/data

# Override retention through normal zelta prune options
zprune --keep-snap-num=60 --keep-snap-days=14 tank/data backup:tank/data

# Use normal recursive controls from Zelta candidate selection
zprune --depth=1 --exclude='*/tmp' tank/data backup:tank/data

# Show destroy commands without destroying
zprune -n tank/data backup:tank/data
```

For non-destructive reporting, use `zelta prune` directly.

## Safety Model

- `zprune` never destroys through SSH; the source operand must be local.
- `zprune` never uses `zfs destroy -R`.
- `zprune` checks candidate snapshots for clones before destruction.
- `zprune` prompts for `destroy` unless `-f` or `--force` is used.
- Normal Zelta options are parsed by Zelta, not duplicated in `zprune`.

## See Also

- `zelta help prune`
- `zelta help options`
