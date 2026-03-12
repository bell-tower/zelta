#!/usr/bin/env bash
# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEST_GEN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$TEST_GEN_DIR/config/test_defs"
GENERATE_TEST="$TEST_GEN_DIR/lib/orchestration/generate_test.sh"

# Generate tests for 70 examples

if ! "$GENERATE_TEST" \
 "$CONFIG_DIR/070_zelta_prune_test.yml" \
 "test/01*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_*_spec.sh|test/050_*_spec.sh|test/060_*_spec.sh"; then

  printf "\n ❌ Failed to generate 070 test\n"
  exit 1
fi
