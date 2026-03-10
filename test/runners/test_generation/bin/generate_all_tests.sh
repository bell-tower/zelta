#!/usr/bin/env bash
# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

"$SCRIPT_DIR/generate_tests_40_50_60.sh"
"$SCRIPT_DIR/generate_prune_test.sh"
"$SCRIPT_DIR/generate_policy_test.sh"

