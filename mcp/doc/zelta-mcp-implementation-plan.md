---
pdf_options:
  format: Letter
  margin: 20mm
css: |
  table { font-size: 11px; width: 100%; table-layout: fixed; }
  th, td { padding: 6px 8px; word-wrap: break-word; }
  code { font-size: 10px; white-space: nowrap; }
  pre { font-size: 10px; }
  h1 { font-size: 24px; }
  h2 { font-size: 18px; margin-top: 24px; }
  h3 { font-size: 14px; }
  h4 { font-size: 12px; }
---

# Zelta MCP Server Implementation Plan

**Version:** 1.0
**Date:** January 2026
**Author:** Infrastructure Team

---

## Executive Summary

This document outlines the implementation plan for building an MCP (Model Context Protocol) server for Zelta, enabling AI assistants to perform intelligent storage management operations. The integration leverages Zelta's unique strengths: non-destructive operations, storage efficiency through ZFS block sharing, and hybrid cloud support.

### Strategic Differentiation

Unlike generic Kubernetes MCP wrappers, Zelta+MCP provides:

| Capability | Traditional Orchestrators | Zelta+MCP |
|------------|--------------------------|-----------|
| **Data Model** | Pods, containers (ephemeral) | Datasets, snapshots, replication state |
| **Operations** | Delete and recreate | Clone, test, rotate when ready |
| **Cost Model** | N copies = N × storage | N clones = shared blocks + deltas |
| **Scope** | Single cloud vendor | Any ZFS system (bare metal to cloud) |

---

## 1. Architecture Overview

### 1.1 System Architecture

**Layer 1: AI Application** (Claude, ChatGPT, etc.)
- Connects via MCP Protocol (JSON-RPC 2.0)

**Layer 2: Zelta MCP Server**
- **Tools** - Actions (backup, clone, rotate, revert, match)
- **Resources** - Data (config, status, snapshots)
- **Prompts** - Templates (disaster recovery, test environment)
- **Executor** - Runs Zelta commands, parses JSON output

**Layer 3: Zelta CLI** (`bin/zelta` → `share/zelta/*.awk`)
- Connects via SSH for remote endpoints

**Layer 4: ZFS Endpoints**
- Local pools, remote servers, cloud instances

### 1.2 Transport Strategy

| Transport | Use Case | When to Use |
|-----------|----------|-------------|
| **STDIO** | Local CLI integration | Claude Code, local AI tools |
| **HTTP** | Centralized management | Multi-user, web dashboards |

**Phase 1:** STDIO only (simplest, matches Zelta's local-first design)
**Phase 2:** Add HTTP transport for centralized management scenarios

---

## 2. Tool Design

### 2.1 Core Tools (Phase 1)

Based on MCP best practices ("less is more"), we expose 8 focused tools:

#### Read-Only Tools (Intelligence Gathering)

| Tool | Description | Maps to |
|------|-------------|---------|
| `zelta_match` | Compare source/target datasets, report sync status | `zelta match --json` |
| `zelta_list` | List datasets with properties (size, snapshots, etc.) | `zfs list` wrapper |
| `zelta_status` | Get replication status for a policy or endpoint | `zelta match` + parsing |

#### Action Tools (Safe Operations)

| Tool | Description | Maps to | Safe? |
|------|-------------|---------|-------|
| `zelta_backup` | Replicate datasets | `zelta backup` | Yes |
| `zelta_snapshot` | Create snapshot | `zelta snapshot` | Yes |
| `zelta_clone` | Clone dataset | `zelta clone` | Yes |
| `zelta_rotate` | Recover sync continuity | `zelta rotate` | Yes |
| `zelta_revert` | Non-destructive rollback | `zelta revert` | Yes |

#### Policy Tools (Phase 2)

| Tool | Description | Maps to |
|------|-------------|---------|
| `zelta_policy_list` | List configured backup policies | Config parsing |
| `zelta_policy_run` | Execute a named policy | `zelta policy` |
| `zelta_policy_status` | Check status of all policy targets | `zelta match` loop |

### 2.2 Tool Specifications

#### `zelta_match` - Dataset Comparison

```json
{
  "name": "zelta_match",
  "description": "Compare source and target datasets to identify sync status, matching snapshots, and divergence. Returns detailed information about replication state including snapshot counts, data sizes, and transfer requirements. This is a read-only operation that never modifies data.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "source": {
        "type": "string",
        "description": "Source endpoint: [user@host:]pool[/dataset][@snapshot]"
      },
      "target": {
        "type": "string",
        "description": "Target endpoint: [user@host:]pool[/dataset]"
      },
      "recursive": {
        "type": "boolean",
        "description": "Include child datasets",
        "default": true
      }
    },
    "required": ["source", "target"]
  },
  "annotations": {
    "readOnlyHint": true,
    "destructiveHint": false,
    "idempotentHint": true
  }
}
```

#### `zelta_backup` - Dataset Replication

```json
{
  "name": "zelta_backup",
  "description": "Replicate ZFS datasets from source to target with intelligent incremental detection. Creates read-only backups by default. Automatically handles snapshot creation, intermediate snapshots, and resume of interrupted transfers. Zelta never performs destructive operations - existing data is always preserved.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "source": {
        "type": "string",
        "description": "Source endpoint: [user@host:]pool[/dataset][@snapshot]"
      },
      "target": {
        "type": "string",
        "description": "Target endpoint: [user@host:]pool[/dataset]"
      },
      "snapshot": {
        "type": "boolean",
        "description": "Create snapshot on source before backup if needed",
        "default": true
      },
      "intermediate": {
        "type": "boolean",
        "description": "Include all intermediate snapshots (not just latest)",
        "default": true
      },
      "dryrun": {
        "type": "boolean",
        "description": "Show what would be done without executing",
        "default": false
      }
    },
    "required": ["source", "target"]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": true
  }
}
```

#### `zelta_clone` - Space-Efficient Cloning

```json
{
  "name": "zelta_clone",
  "description": "Create a space-efficient clone of a dataset at a specific snapshot. Clones share blocks with their origin, so 5 clones of a 100GB dataset might only use 100GB + deltas, not 500GB. Perfect for test environments, schema migrations, or safe experimentation. The clone is fully writable while the original remains unchanged.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "source": {
        "type": "string",
        "description": "Source dataset with snapshot: pool/dataset@snapshot"
      },
      "target": {
        "type": "string",
        "description": "Target path for clone: pool/clone-name"
      },
      "recursive": {
        "type": "boolean",
        "description": "Clone child datasets recursively",
        "default": true
      }
    },
    "required": ["source", "target"]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false
  }
}
```

#### `zelta_rotate` - Sync Recovery

```json
{
  "name": "zelta_rotate",
  "description": "Recover sync continuity when source and target have diverged. Instead of destroying the diverged target, Zelta renames it (preserving for forensics), creates a clone from the last common snapshot, and syncs forward. Both old and new versions are preserved. Use this when zelta_match shows 'divergent' status.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "source": {
        "type": "string",
        "description": "Source endpoint (the authoritative version)"
      },
      "target": {
        "type": "string",
        "description": "Target endpoint (the diverged backup)"
      },
      "dryrun": {
        "type": "boolean",
        "description": "Show what would be done without executing",
        "default": false
      }
    },
    "required": ["source", "target"]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": true
  }
}
```

#### `zelta_revert` - Non-Destructive Rollback

```json
{
  "name": "zelta_revert",
  "description": "Rewind a dataset to a previous snapshot WITHOUT destroying data. Unlike 'zfs rollback', zelta revert renames the current dataset (preserving it) and creates a clone from the target snapshot at the original path. You keep both versions: the reverted state and the pre-revert state for forensic analysis.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "dataset": {
        "type": "string",
        "description": "Dataset to revert: pool/dataset"
      },
      "snapshot": {
        "type": "string",
        "description": "Snapshot to revert to: @snapshot-name"
      },
      "dryrun": {
        "type": "boolean",
        "description": "Show what would be done without executing",
        "default": false
      }
    },
    "required": ["dataset", "snapshot"]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false
  }
}
```

---

## 3. Resources Design

MCP Resources expose data for AI context without side effects.

### 3.1 Resource URIs

| URI Pattern | Description | Content Type |
|-------------|-------------|--------------|
| `zelta://config` | Current zelta.conf contents | text/plain |
| `zelta://env` | Current zelta.env defaults | text/plain |
| `zelta://status/{endpoint}` | Backup status for endpoint | application/json |
| `zelta://snapshots/{dataset}` | Snapshot list for dataset | application/json |
| `zelta://policies` | List of configured policies | application/json |

### 3.2 Resource Implementation

```python
@mcp.resource("zelta://config")
def get_config() -> str:
    """Current Zelta policy configuration (zelta.conf)"""
    config_paths = [
        "/usr/local/etc/zelta/zelta.conf",
        "/etc/zelta/zelta.conf",
        os.path.expanduser("~/.config/zelta/zelta.conf")
    ]
    for path in config_paths:
        if os.path.exists(path):
            with open(path) as f:
                return f.read()
    return "# No zelta.conf found"

@mcp.resource("zelta://snapshots/{dataset}")
def get_snapshots(dataset: str) -> dict:
    """List snapshots for a dataset with creation times and sizes"""
    result = subprocess.run(
        ["zfs", "list", "-t", "snapshot", "-o", "name,creation,used,refer",
         "-Hp", dataset],
        capture_output=True, text=True
    )
    # Parse and return structured data
    ...
```

---

## 4. Prompts Design

Pre-built instruction templates for common workflows.

### 4.1 Disaster Recovery Prompt

```python
@mcp.prompt()
def disaster_recovery_assessment(source: str, target: str) -> list:
    """Generate a disaster recovery assessment for a backup relationship"""
    return [
        {
            "role": "user",
            "content": f"""Perform a disaster recovery assessment for the backup
relationship between {source} (production) and {target} (backup).

Steps:
1. Use zelta_match to check snapshot alignment between source and target
2. Identify the most recent common snapshot (recovery point)
3. Calculate data at risk (changes since last successful backup)
4. If divergent, explain the zelta_rotate recovery process
5. Provide a recovery time estimate based on data transfer size

Remember: Zelta NEVER destroys data. All recovery operations preserve existing
versions for forensic analysis."""
        }
    ]
```

### 4.2 Test Environment Prompt

```python
@mcp.prompt()
def create_test_environment(production_dataset: str) -> list:
    """Guide creation of a space-efficient test environment"""
    return [
        {
            "role": "user",
            "content": f"""Help me create a test environment from {production_dataset}.

I want to:
1. Create a snapshot of current production state
2. Clone it to a test location (space-efficient - shares blocks with origin)
3. Understand the actual storage cost (just deltas, not full copy)
4. Know how to promote or destroy the test environment when done

Use zelta_snapshot to create the snapshot, then zelta_clone to create the
test environment. Calculate the storage efficiency."""
        }
    ]
```

### 4.3 Compliance Audit Prompt

```python
@mcp.prompt()
def compliance_audit(policy_name: str) -> list:
    """Audit backup compliance for a policy"""
    return [
        {
            "role": "user",
            "content": f"""Perform a compliance audit for the '{policy_name}' backup policy.

Check:
1. All configured endpoints are reachable
2. Backup freshness (time since last successful sync)
3. Snapshot retention compliance
4. Any divergent datasets requiring attention
5. Storage efficiency metrics

Generate a compliance report suitable for audit documentation."""
        }
    ]
```

---

## 5. Implementation Phases

### Phase 1: Core Foundation (Week 1-2)

**Goal:** Working MCP server with read-only tools

**Deliverables:**
- [ ] Project scaffolding (pyproject.toml, directory structure)
- [ ] `zelta_match` tool implementation
- [ ] `zelta_list` tool implementation
- [ ] `zelta_status` tool implementation
- [ ] Basic resource: `zelta://config`
- [ ] STDIO transport working
- [ ] Unit tests for all tools
- [ ] Claude Desktop integration tested

**Directory Structure:**

- `zelta-mcp/`
  - `pyproject.toml`
  - `README.md`
  - `src/zelta_mcp/`
    - `__init__.py`
    - `server.py` - FastMCP server entry point
    - `executor.py` - Zelta command execution
    - `tools/` - match.py, list.py, status.py
    - `resources/` - config.py
  - `tests/` - test_match.py, conftest.py

### Phase 2: Action Tools (Week 3-4)

**Goal:** Safe write operations

**Deliverables:**
- [ ] `zelta_backup` tool
- [ ] `zelta_snapshot` tool
- [ ] `zelta_clone` tool
- [ ] `zelta_rotate` tool
- [ ] `zelta_revert` tool
- [ ] Dry-run mode for all action tools
- [ ] Integration tests with real ZFS
- [ ] Error handling and user-friendly messages

### Phase 3: Policy & Resources (Week 5-6)

**Goal:** Policy orchestration and rich resources

**Deliverables:**
- [ ] `zelta_policy_list` tool
- [ ] `zelta_policy_run` tool
- [ ] `zelta_policy_status` tool
- [ ] Resource: `zelta://snapshots/{dataset}`
- [ ] Resource: `zelta://status/{endpoint}`
- [ ] Resource: `zelta://policies`
- [ ] Prompts: disaster recovery, test environment, compliance audit

### Phase 4: Production Hardening (Week 7-8)

**Goal:** Production-ready release

**Deliverables:**
- [ ] HTTP transport option
- [ ] Authentication for HTTP mode
- [ ] Comprehensive documentation
- [ ] Performance optimization
- [ ] Logging and observability
- [ ] Package publishing (PyPI)
- [ ] Claude Desktop configuration examples

---

## 6. Code Implementation

### 6.1 Project Configuration

**pyproject.toml:**
```toml
[project]
name = "zelta-mcp"
version = "0.1.0"
description = "MCP server for Zelta ZFS backup operations"
readme = "README.md"
requires-python = ">=3.10"
license = {text = "BSD-2-Clause"}
authors = [
    {name = "Zelta Team"}
]
dependencies = [
    "mcp>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "pytest-asyncio>=0.21",
]

[project.scripts]
zelta-mcp = "zelta_mcp.server:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### 6.2 Server Implementation

**src/zelta_mcp/server.py:**
```python
#!/usr/bin/env python3
"""Zelta MCP Server - AI-powered ZFS backup management."""

import asyncio
import json
import subprocess
from typing import Any

from mcp.server.fastmcp import FastMCP

# Initialize MCP server
mcp = FastMCP(
    "Zelta",
    description="Intelligent ZFS backup and recovery operations. "
                "Zelta never destroys data - all operations preserve existing versions."
)


class ZeltaExecutor:
    """Execute Zelta commands and parse results."""

    def __init__(self, zelta_path: str = "zelta"):
        self.zelta_path = zelta_path

    async def run(
        self,
        verb: str,
        *args: str,
        json_output: bool = True,
        dryrun: bool = False
    ) -> dict[str, Any]:
        """Run a Zelta command and return structured result."""
        cmd = [self.zelta_path, verb]

        if json_output:
            cmd.append("--json")
        if dryrun:
            cmd.append("--dryrun")

        cmd.extend(args)

        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()

        result = {
            "success": proc.returncode == 0,
            "returncode": proc.returncode,
            "command": " ".join(cmd),
        }

        if json_output and stdout:
            try:
                result["data"] = json.loads(stdout.decode())
            except json.JSONDecodeError:
                result["output"] = stdout.decode()
        else:
            result["output"] = stdout.decode()

        if stderr:
            result["stderr"] = stderr.decode()

        return result


# Global executor instance
executor = ZeltaExecutor()


# ============================================================================
# READ-ONLY TOOLS
# ============================================================================

@mcp.tool()
async def zelta_match(
    source: str,
    target: str,
    recursive: bool = True
) -> dict[str, Any]:
    """Compare source and target datasets to identify sync status.

    Returns detailed information about replication state including:
    - Matching snapshots between source and target
    - Number of snapshots needing transfer
    - Data size to transfer
    - Divergence detection

    This is a read-only operation that never modifies data.

    Args:
        source: Source endpoint [user@host:]pool[/dataset][@snapshot]
        target: Target endpoint [user@host:]pool[/dataset]
        recursive: Include child datasets (default: True)

    Returns:
        Comparison results with sync status for each dataset
    """
    args = []
    if not recursive:
        args.append("--depth=0")
    args.extend([source, target])

    return await executor.run("match", *args)


@mcp.tool()
async def zelta_list(
    endpoint: str,
    properties: list[str] | None = None
) -> dict[str, Any]:
    """List ZFS datasets with their properties.

    Provides dataset information including size, snapshot count,
    compression ratio, and replication status.

    Args:
        endpoint: Endpoint to list [user@host:]pool[/dataset]
        properties: Specific ZFS properties to include

    Returns:
        List of datasets with requested properties
    """
    # Use zfs list directly for this tool
    cmd = ["zfs", "list", "-H", "-o"]
    props = properties or ["name", "used", "avail", "refer", "mountpoint"]
    cmd.append(",".join(props))
    cmd.append(endpoint)

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()

    if proc.returncode != 0:
        return {
            "success": False,
            "error": stderr.decode()
        }

    # Parse tab-separated output
    datasets = []
    for line in stdout.decode().strip().split("\n"):
        if line:
            values = line.split("\t")
            datasets.append(dict(zip(props, values)))

    return {
        "success": True,
        "datasets": datasets,
        "count": len(datasets)
    }


# ============================================================================
# ACTION TOOLS
# ============================================================================

@mcp.tool()
async def zelta_backup(
    source: str,
    target: str,
    snapshot: bool = True,
    intermediate: bool = True,
    dryrun: bool = False
) -> dict[str, Any]:
    """Replicate ZFS datasets from source to target.

    Creates read-only backups with intelligent incremental detection.
    Automatically handles:
    - Snapshot creation (if needed and enabled)
    - Intermediate snapshot inclusion
    - Resume of interrupted transfers
    - Safe defaults (read-only targets, no overlapping mounts)

    Zelta NEVER performs destructive operations. Existing data is always preserved.

    Args:
        source: Source endpoint [user@host:]pool[/dataset][@snapshot]
        target: Target endpoint [user@host:]pool[/dataset]
        snapshot: Create snapshot on source before backup if needed
        intermediate: Include all intermediate snapshots
        dryrun: Show what would be done without executing

    Returns:
        Backup results including bytes transferred and snapshots synced
    """
    args = []
    if not snapshot:
        args.append("--no-snap")
    if not intermediate:
        args.append("--no-intermediate")
    args.extend([source, target])

    return await executor.run("backup", *args, dryrun=dryrun)


@mcp.tool()
async def zelta_snapshot(
    dataset: str,
    name: str | None = None,
    recursive: bool = True
) -> dict[str, Any]:
    """Create a point-in-time snapshot of a dataset.

    Snapshots are atomic, instantaneous, and space-efficient.
    They only consume space as data changes from the snapshot point.

    Args:
        dataset: Dataset to snapshot [user@host:]pool/dataset
        name: Snapshot name (default: zelta_YYYY-MM-DD_HH.MM.SS)
        recursive: Include child datasets

    Returns:
        Snapshot creation result with full snapshot name
    """
    args = []
    if not recursive:
        args.append("--depth=0")
    if name:
        args.extend(["--snap-name", name])
    args.append(dataset)

    return await executor.run("snapshot", *args)


@mcp.tool()
async def zelta_clone(
    source: str,
    target: str,
    recursive: bool = True
) -> dict[str, Any]:
    """Create a space-efficient clone of a dataset.

    Clones share blocks with their origin through ZFS copy-on-write.
    5 clones of a 100GB dataset might only use 100GB + deltas, not 500GB.

    Perfect for:
    - Test environments (clone production, test changes safely)
    - Schema migrations (clone DB, test migration, rotate if successful)
    - Development sandboxes

    Args:
        source: Source dataset@snapshot to clone from
        target: Target path for the clone
        recursive: Clone child datasets

    Returns:
        Clone creation result with space savings estimate
    """
    args = []
    if not recursive:
        args.append("--depth=0")
    args.extend([source, target])

    return await executor.run("clone", *args)


@mcp.tool()
async def zelta_rotate(
    source: str,
    target: str,
    dryrun: bool = False
) -> dict[str, Any]:
    """Recover sync continuity when source and target have diverged.

    When a backup target has diverged from source (e.g., someone wrote to it),
    zelta rotate recovers without destroying data:

    1. Finds the last common snapshot
    2. Renames diverged target to dataset_snapshot (preserving it)
    3. Creates clone from common snapshot at original path
    4. Syncs source changes to restored target

    Both old (diverged) and new (synced) versions are preserved.

    Args:
        source: Source endpoint (authoritative)
        target: Target endpoint (diverged backup)
        dryrun: Show what would be done without executing

    Returns:
        Rotation result showing preserved and new dataset paths
    """
    return await executor.run("rotate", source, target, dryrun=dryrun)


@mcp.tool()
async def zelta_revert(
    dataset: str,
    snapshot: str,
    dryrun: bool = False
) -> dict[str, Any]:
    """Rewind a dataset to a previous snapshot WITHOUT destroying data.

    Unlike 'zfs rollback' which destroys all snapshots after the target,
    zelta revert preserves everything:

    1. Renames current dataset to dataset_snapshot (preserving it)
    2. Creates clone from target snapshot at original path

    You keep both: the reverted state AND the pre-revert state.
    Perfect for "oops" recovery with full forensic preservation.

    Args:
        dataset: Dataset to revert (pool/dataset)
        snapshot: Snapshot to revert to (@snapshot-name)
        dryrun: Show what would be done without executing

    Returns:
        Revert result showing preserved and reverted dataset paths
    """
    # Combine dataset and snapshot
    full_snap = f"{dataset}{snapshot}" if snapshot.startswith("@") else f"{dataset}@{snapshot}"
    return await executor.run("revert", full_snap, dryrun=dryrun)


# ============================================================================
# RESOURCES
# ============================================================================

@mcp.resource("zelta://config")
def get_zelta_config() -> str:
    """Current Zelta policy configuration (zelta.conf)."""
    import os
    config_paths = [
        "/usr/local/etc/zelta/zelta.conf",
        "/etc/zelta/zelta.conf",
        os.path.expanduser("~/.config/zelta/zelta.conf"),
        "zelta.conf"  # Current directory
    ]
    for path in config_paths:
        if os.path.exists(path):
            with open(path) as f:
                return f.read()
    return "# No zelta.conf found in standard locations"


@mcp.resource("zelta://env")
def get_zelta_env() -> str:
    """Current Zelta environment defaults (zelta.env)."""
    import os
    env_paths = [
        "/usr/local/etc/zelta/zelta.env",
        "/etc/zelta/zelta.env",
        os.path.expanduser("~/.config/zelta/zelta.env"),
        "zelta.env"
    ]
    for path in env_paths:
        if os.path.exists(path):
            with open(path) as f:
                return f.read()
    return "# No zelta.env found in standard locations"


# ============================================================================
# PROMPTS
# ============================================================================

@mcp.prompt()
def disaster_recovery(source: str, target: str) -> str:
    """Disaster recovery assessment for a backup relationship."""
    return f"""Perform a disaster recovery assessment for:
- Production: {source}
- Backup: {target}

Steps:
1. Use zelta_match to check snapshot alignment
2. Identify the recovery point (most recent common snapshot)
3. Calculate data at risk (unsynced changes)
4. If divergent, explain the zelta_rotate recovery process
5. Provide recovery recommendations

Remember: Zelta NEVER destroys data. All operations preserve existing versions."""


@mcp.prompt()
def test_environment(production: str, test_path: str) -> str:
    """Create a space-efficient test environment."""
    return f"""Help create a test environment:
- Production dataset: {production}
- Test location: {test_path}

Steps:
1. Create snapshot of production (zelta_snapshot)
2. Clone to test location (zelta_clone)
3. Calculate actual storage cost (blocks shared vs unique)
4. Explain cleanup options when testing is complete

Highlight the storage efficiency: clones share blocks with origin."""


@mcp.prompt()
def safe_upgrade(dataset: str, description: str) -> str:
    """Plan a safe upgrade with rollback capability."""
    return f"""Plan a safe upgrade for {dataset}:
Task: {description}

Steps:
1. Create pre-upgrade snapshot (zelta_snapshot)
2. Perform the upgrade
3. If problems occur, use zelta_revert to rollback (preserves both versions)
4. If successful, the snapshot serves as a restore point

This approach ensures zero data loss regardless of outcome."""


def main():
    """Run the Zelta MCP server."""
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
```

### 6.3 Claude Desktop Configuration

**claude_desktop_config.json:**
```json
{
  "mcpServers": {
    "zelta": {
      "command": "zelta-mcp",
      "args": [],
      "env": {
        "PATH": "/usr/local/bin:/usr/bin:/bin"
      }
    }
  }
}
```

Or if running from source:
```json
{
  "mcpServers": {
    "zelta": {
      "command": "python",
      "args": ["-m", "zelta_mcp.server"],
      "cwd": "/path/to/zelta-mcp",
      "env": {
        "PATH": "/usr/local/bin:/usr/bin:/bin"
      }
    }
  }
}
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

```python
# tests/test_match.py
import pytest
from unittest.mock import AsyncMock, patch
from zelta_mcp.server import zelta_match

@pytest.mark.asyncio
async def test_match_basic():
    """Test basic match operation."""
    with patch('zelta_mcp.server.executor.run', new_callable=AsyncMock) as mock:
        mock.return_value = {
            "success": True,
            "data": {
                "datasets": [
                    {"name": "tank/data", "match": "@snap1", "status": "ok"}
                ]
            }
        }

        result = await zelta_match("source:tank/data", "target:tank/backup")

        assert result["success"]
        mock.assert_called_once()

@pytest.mark.asyncio
async def test_match_divergent():
    """Test detection of divergent datasets."""
    with patch('zelta_mcp.server.executor.run', new_callable=AsyncMock) as mock:
        mock.return_value = {
            "success": True,
            "data": {
                "datasets": [
                    {"name": "tank/data", "status": "divergent"}
                ]
            }
        }

        result = await zelta_match("source:tank/data", "target:tank/backup")

        assert result["success"]
        assert result["data"]["datasets"][0]["status"] == "divergent"
```

### 7.2 Integration Tests

```python
# tests/test_integration.py
import pytest
import subprocess

@pytest.fixture
def test_pool():
    """Create a test ZFS pool (requires root)."""
    # Setup: create test pool
    subprocess.run(["truncate", "-s", "1G", "/tmp/test_pool.img"], check=True)
    subprocess.run(["zpool", "create", "testpool", "/tmp/test_pool.img"], check=True)
    yield "testpool"
    # Teardown
    subprocess.run(["zpool", "destroy", "testpool"])
    subprocess.run(["rm", "/tmp/test_pool.img"])

@pytest.mark.integration
@pytest.mark.asyncio
async def test_full_backup_workflow(test_pool):
    """Test complete backup workflow."""
    from zelta_mcp.server import zelta_snapshot, zelta_backup, zelta_match

    # Create test dataset
    subprocess.run(["zfs", "create", f"{test_pool}/source"], check=True)
    subprocess.run(["zfs", "create", f"{test_pool}/target"], check=True)

    # Create snapshot
    snap_result = await zelta_snapshot(f"{test_pool}/source")
    assert snap_result["success"]

    # Backup
    backup_result = await zelta_backup(
        f"{test_pool}/source",
        f"{test_pool}/target"
    )
    assert backup_result["success"]

    # Verify
    match_result = await zelta_match(
        f"{test_pool}/source",
        f"{test_pool}/target"
    )
    assert match_result["success"]
```

---

## 8. Security Considerations

### 8.1 Authentication Model

**Security Boundaries:**

1. **MCP Client** (Claude) ↔ **Zelta MCP Server**
   - Transport: STDIO (local)
   - Server runs as invoking USER with USER's credentials

2. **Zelta MCP Server** → **Remote Endpoints**
   - Transport: SSH (user's keys)
   - ZFS delegation controls access on endpoints

### 8.2 ZFS Delegation

Zelta relies on ZFS delegation for fine-grained permissions:

```bash
# On remote endpoint, allow backup user specific permissions
zfs allow -u backupuser send,snapshot,hold tank/data
zfs allow -u backupuser create,receive,mount,mountpoint tank/backups
```

### 8.3 MCP Server Permissions

The MCP server inherits the invoking user's permissions:
- SSH keys for remote access
- ZFS permissions on local pools
- No additional privilege escalation

---

## 9. Example Conversations

### 9.1 Disaster Recovery

**User:** "Check if my database backup is current"

**AI uses:** `zelta_match("db.prod.local:tank/postgres", "backup.local:tank/backups/db")`

**AI Response:** "Your PostgreSQL backup is 4 hours behind. There are 3 snapshots pending transfer totaling 2.1GB. The last successful sync was at 2026-01-21 08:00 UTC. Would you like me to run a backup now?"

### 9.2 Test Environment Creation

**User:** "I need to test a schema migration on a copy of production"

**AI uses:**
1. `zelta_snapshot("db.prod.local:tank/postgres", name="pre-migration-test")`
2. `zelta_clone("db.prod.local:tank/postgres@pre-migration-test", "db.prod.local:tank/postgres-test")`

**AI Response:** "Created test environment at tank/postgres-test. This clone shares 847GB of blocks with production and currently uses only 12MB of unique storage. You can run your migration safely - if it fails, simply destroy the clone. If it succeeds, we can use zelta_rotate to swap it into production while preserving the original."

### 9.3 Recovery from Divergence

**User:** "Someone accidentally wrote to the backup server, now syncs are failing"

**AI uses:** `zelta_match("prod:tank/data", "backup:tank/data")`

**AI Response:** "The backup has diverged from production. Last common snapshot was 3 days ago (@zelta_2026-01-18_00.00.00). I can use zelta_rotate to recover:

1. Rename diverged backup to tank/data_zelta_2026-01-18_00.00.00 (preserved)
2. Clone from common snapshot to tank/data
3. Sync 3 days of production changes

Both versions will be preserved. Want me to proceed?"

---

## 10. Success Metrics

### 10.1 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tool response time | < 2s for read-only | Logging |
| Backup throughput | Match native Zelta | Benchmarks |
| Error rate | < 1% | Monitoring |
| Test coverage | > 80% | pytest-cov |

### 10.2 User Experience Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Successful task completion | > 90% | User feedback |
| AI understanding accuracy | > 95% | Review conversations |
| Documentation clarity | Positive feedback | User surveys |

---

## 11. Future Enhancements

### Phase 5+: Advanced Features

1. **Streaming Progress** - Real-time transfer progress for long backups
2. **Cost Calculator** - Estimate storage costs across providers
3. **Policy Suggestions** - AI-driven backup schedule recommendations
4. **Anomaly Detection** - Alert on unusual backup patterns
5. **Multi-Site Orchestration** - Coordinate backups across regions

---

## Appendix A: MCP Protocol Reference

### JSON-RPC Message Format

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "zelta_backup",
    "arguments": {
      "source": "prod:tank/data",
      "target": "backup:tank/data"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"success\": true, \"bytes_transferred\": 1073741824}"
      }
    ]
  }
}
```

---

## Appendix B: Zelta Command Reference

| Command | MCP Tool | Description |
|---------|----------|-------------|
| `zelta match` | `zelta_match` | Compare datasets |
| `zelta backup` | `zelta_backup` | Replicate datasets |
| `zelta snapshot` | `zelta_snapshot` | Create snapshots |
| `zelta clone` | `zelta_clone` | Create clones |
| `zelta rotate` | `zelta_rotate` | Recover from divergence |
| `zelta revert` | `zelta_revert` | Non-destructive rollback |
| `zelta policy` | `zelta_policy_run` | Execute policies |

---

## Appendix C: Resources

### Official Documentation
- [MCP Specification](https://modelcontextprotocol.io/specification/2025-11-25)
- [Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [FastMCP Tutorial](https://gofastmcp.com/tutorials/create-mcp-server)

### Zelta Documentation
- [Zelta Manual](doc/zelta.md)
- [Backup Operations](doc/zelta-backup.md)
- [Match Operations](doc/zelta-match.md)
- [Rotate Operations](doc/zelta-rotate.md)

---

*Document Version: 1.0 | Last Updated: January 2026*
