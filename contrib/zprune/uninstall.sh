#!/bin/sh
#
# zprune Uninstaller
#
# Removes zprune from the system.

ZPRUNE_VERSION="0.1.0"

# Determine installation paths (same logic as install.sh)
if [ "$(id -u)" -eq 0 ]; then
	: ${ZPRUNE_BIN:="/usr/local/bin"}
	: ${ZPRUNE_SHARE:="/usr/local/share/zprune"}
	: ${ZPRUNE_DOC:="/usr/local/man/man8"}
else
	: ${ZPRUNE_BIN:="$HOME/bin"}
	: ${ZPRUNE_SHARE:="$HOME/.local/share/zprune"}
	: ${ZPRUNE_DOC:="$HOME/.local/share/man/man8"}
fi

# Allow override from command line
while [ $# -gt 0 ]; do
	case "$1" in
		--bin)
			ZPRUNE_BIN="$2"
			shift 2
			;;
		--share)
			ZPRUNE_SHARE="$2"
			shift 2
			;;
		--doc)
			ZPRUNE_DOC="$2"
			shift 2
			;;
		-f|--force)
			FORCE="1"
			shift
			;;
		-h|--help)
			echo "usage: uninstall.sh [-f] [--bin PATH] [--share PATH] [--doc PATH]"
			exit 0
			;;
		*)
			echo "Error: unknown option: $1" >&2
			exit 1
			;;
	esac
done

# Confirmation
if [ -z "$FORCE" ]; then
	echo "This will remove zprune from:"
	echo "  Binary: $ZPRUNE_BIN/zprune"
	echo "  Share:  $ZPRUNE_SHARE"
	if [ -n "$ZPRUNE_DOC" ]; then
		echo "  Man:    $ZPRUNE_DOC/zprune.8"
	fi
	echo ""
	printf "Continue? [y/N] "
	read _confirm
	case "$_confirm" in
		[Yy]*)
			;;
		*)
			echo "Aborted."
			exit 0
			;;
	esac
fi

# Remove files
removed=0

if [ -f "$ZPRUNE_BIN/zprune" ]; then
	echo "removing: $ZPRUNE_BIN/zprune"
	rm -f "$ZPRUNE_BIN/zprune"
	removed=$((removed + 1))
fi

if [ -d "$ZPRUNE_SHARE" ]; then
	echo "removing: $ZPRUNE_SHARE"
	rm -rf "$ZPRUNE_SHARE"
	removed=$((removed + 1))
fi

if [ -n "$ZPRUNE_DOC" ] && [ -f "$ZPRUNE_DOC/zprune.8" ]; then
	echo "removing: $ZPRUNE_DOC/zprune.8"
	rm -f "$ZPRUNE_DOC/zprune.8"
	removed=$((removed + 1))
fi

if [ "$removed" -eq 0 ]; then
	echo "zprune does not appear to be installed."
else
	echo "zprune uninstalled."
fi
