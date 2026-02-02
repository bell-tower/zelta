set -x
unset SANDBOX_ZELTA_TMP_DIR # forces test_helper.sh to re-evaluate ZELTA setup
set +x
. ./test/runners/test_env.sh
