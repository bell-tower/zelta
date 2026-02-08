#!/bin/sh

if ! ./generate_test.sh \
 040_zelta_tests_spec.sh \
 test_defs/040_zelta_tests.yml \
 "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh"; then

  printf "\n ❌ Failed to generate 040 test"
  exit 1
fi


if ! ./generate_test.sh \
 050_zelta_revert_spec.sh \
 test_defs/050_zelta_revert_test.yml \
 "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_*_spec.sh"; then

  printf "\n ❌ Failed to generate 050 test"
  exit 1
fi


if ! ./generate_test.sh \
 060_zelta_clone_spec.sh \
 test_defs/060_zelta_clone_test.yml \
 "test/00*_spec.sh|test/01*_spec.sh|test/02*_spec.sh|test/040_*_spec.sh|test/050_*_spec.sh"; then

  printf "\n ❌ Failed to generate 060 test"
  exit 1
fi
