#!/bin/sh
# Zelta One-Shot Installer
# Downloads latest Zelta from GitHub and runs install.sh
#
# Usage: curl -fsSL https://raw.githubusercontent.com/bellhyve/zelta/main/contrib/install-from-git.sh | sh
# Or specify branch: curl ... | sh -s -- --branch=develop

set -e

REPO="https://github.com/bellhyve/zelta.git"
BRANCH="${1:-main}"
TMPDIR="${TMPDIR:-/tmp}"
WORKDIR="$TMPDIR/zelta-install-$$"

# Detect git
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required but not found"
    exit 1
fi

# Clone to temp location
echo "Downloading Zelta from GitHub..."
git clone --depth=1 --branch="$BRANCH" "$REPO" "$WORKDIR" || {
    echo "Error: Failed to clone repository"
    exit 1
}

cd "$WORKDIR"

# Verify we got a real repo
if [ ! -f "install.sh" ] || [ ! -d ".git" ]; then
    echo "Error: Downloaded files appear incomplete"
    rm -rf "$WORKDIR"
    exit 1
fi

# Show what we're installing
echo
echo "Installing Zelta from commit: $(git rev-parse --short HEAD)"
echo

# Run the real installer
sh install.sh "$@"
_exit=$?

# Cleanup
cd /
rm -rf "$WORKDIR"

exit $_exit
