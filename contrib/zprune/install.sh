#!/bin/sh
#
# zprune Installer
#
# Installs zprune separately from the main zelta package.
# zprune requires zelta to be installed.

ZPRUNE_VERSION="0.1.0"

# Check for zelta dependency
if ! command -v zelta >/dev/null 2>&1; then
	echo "Error: zelta is required but not found in PATH." >&2
	echo "Please install zelta first: https://zelta.space" >&2
	exit 1
fi

# Determine installation paths
if [ "$(id -u)" -eq 0 ]; then
	: ${ZPRUNE_BIN:="/usr/local/bin"}
	: ${ZPRUNE_SHARE:="/usr/local/share/zprune"}
	: ${ZPRUNE_DOC:="/usr/local/man/man8"}
else
	: ${ZPRUNE_BIN:="$HOME/bin"}
	: ${ZPRUNE_SHARE:="$HOME/.local/share/zprune"}
	: ${ZPRUNE_DOC:="$HOME/.local/share/man/man8"}

	if [ -z "$ZPRUNE_BIN_SET" ]; then
		echo "Installing zprune for current user."
		echo ""
		echo "Installation paths:"
		echo "  Binary:  $ZPRUNE_BIN"
		echo "  Share:   $ZPRUNE_SHARE"
		echo ""
		echo "To use system paths, run as root or set ZPRUNE_BIN, etc."
		echo ""
		echo "Press Control-C to cancel or Return to continue."
		read _wait
	fi
fi

# Installation directory for this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create directories
mkdir -p "$ZPRUNE_BIN" "$ZPRUNE_SHARE" 2>/dev/null || {
	echo "Error: Failed to create directories" >&2
	exit 1
}

copy_file() {
	_mode="${3:-644}"
	if [ ! -f "$2" ] || [ "$1" -nt "$2" ]; then
		echo "installing: $1 -> $2"
		cp "$1" "$2"
		chmod "$mode" "$2"
	fi
}

# Install main binary
copy_file "$SCRIPT_DIR/zprune" "$ZPRUNE_BIN/zprune" 755

# Install man page if it exists
if [ -f "$SCRIPT_DIR/zprune.8" ] && [ -n "$ZPRUNE_DOC" ]; then
	mkdir -p "$ZPRUNE_DOC"
	copy_file "$SCRIPT_DIR/zprune.8" "$ZPRUNE_DOC/zprune.8" 644
fi

# Verify installation
if ! command -v zprune >/dev/null 2>&1; then
	echo ""
	echo "Warning: 'zprune' not found in PATH." >&2
	echo "Add this to your shell startup file:"
	echo "    export PATH=\"\$PATH:$ZPRUNE_BIN\""
fi

echo ""
echo "zprune $ZPRUNE_VERSION installed successfully."
