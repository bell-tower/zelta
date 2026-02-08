#!/bin/sh

#SETUP_TREE_SPECS="test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_zelta_tests_spec.sh"
#TEST_CONFIG="test_defs/050_zelta_revert_test.yml"
#GENERATED_TEST_NAME="050_zelta_revert_spec.sh"

# Check for required arguments
if [ $# -lt 3 ]; then
    printf "Usage: %s <generated_test_name> <test_config> <output_dir> <setup_specs>\n" "$0" >&2
    printf "\t-> *  setup zfs tree with state represented by <setup_specs>\n"
    printf "\t-> *  use the <test_config> to generate a tess\n"
    printf "\t-> *  setup zfs tree again\n"
    printf "\t-> *  test the <generated_test_name> from <test_config>\n"
    printf "\t-> *  if test passes, move it to production\n"
    printf "example:\n"
    printf "%s \ \n" "$0"
    printf " 050_zelta_revert_spec.sh \ \n"
    printf " test_defs/050_zelta_revert_test.yml \ \n"
    printf " test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_zelta_tests_spec.sh\n"
    exit 1
fi

# setup test aliases
#. ./test_aliases.sh

GENERATED_TEST_NAME=$1
TEST_CONFIG=$2
SETUP_TREE_SPECS=$3
REPO_ROOT=$(git rev-parse --show-toplevel)

echo "REPO_ROOT is: {$REPO_ROOT}"

generate_test() {
  printf "\n*\n* generating test %s\n*\n" "$GENERATED_TEST_NAME"
  cd "$REPO_ROOT/test/runners/util" || return 1
  ./test_generator.rb "$TEST_CONFIG"
}

setup_tree() {
   printf "\n*\n* setting up tree %s\n*\n" "$SETUP_TREE_SPECS"

   cd "$REPO_ROOT" || return 1
   . ./test/runners/manual_cleanup.sh
   #shellspec --xtrace --shell /opt/homebrew/bin/bash  --pattern "$SETUP_TREE_SPECS"
   shellspec --pattern "$SETUP_TREE_SPECS"
}

confirm_generated_test_works() {
   printf "\n*\n* confirming test works %s\n*\n" "$GENERATED_TEST_NAME"

   setup_tree
   if shellspec "test/runners/util/tmp/$GENERATED_TEST_NAME"; then
      echo "test confirmed, copy to production"
      rm -f "test/$GENERATED_TEST_NAME"
      mv "test/runners/util/tmp/$GENERATED_TEST_NAME" test
   else
       return 1
   fi
}

## generate and confirm test

# setup zfs pools to desired state before running test
 if ! setup_tree; then
      printf "\n ❌ Failed to setup ZFS tree with specs %s\n!" "$SETUP_TREE_SPECS"
      exit 1
 fi

# generate the test
if ! generate_test; then
    printf "\n ❌ Test generation failed for %s!\n" "$TEST_CONFIG"
    exit 1
fi

# setup zfs pools to desired state again before running generated test
 if ! setup_tree; then
      printf "\n ❌ Failed to setup ZFS tree for testing generated tree with specs %s\n!" "$SETUP_TREE_SPECS"
      exit 1
 fi


# confirm generated test works
if ! confirm_generated_test_works; then
      printf "\n ❌ Generated test failed %s\n!" "$SETUP_TREE_SPECS"
      exit 1
fi

# good test generated and copied to prod
printf "\n ✅ Success, Generated test copied to production %s\n\n" "test/$GENERATED_TEST_NAME"
