#!/bin/sh

# Check for required arguments
if [ $# -lt 3 ] || [ $# -gt 5 ]; then
    printf "Usage: %s <zelta command> <matcher_function_name> <output_dir> [env_var_name1:env_var_name2:...] [allow_no_output]\n" "$0" >&2
    printf "\t-> * put your zfs datasets in the desired state before running\n"
    printf "\t-> * to capture the zelta output that would be captured by a test\n"
    printf "\t-> * allow_no_output: 'true' to skip output validation (optional)\n"
    exit 1
fi

zelta_cmd=$1
func_name=$2
output_dir=$3
#set -x
if [ $# -ge 4 ]; then
    env_var_names=$4
else
    # default to
    env_var_names="SANDBOX_ZELTA_TGT_DS:SANDBOX_ZELTA_SRC_DS:SANDBOX_ZELTA_TGT_EP:SANDBOX_ZELTA_SRC_EP"
fi

if [ $# -eq 5 ]; then
    allow_no_output=$5
else
    allow_no_output="false"
fi

echo "zelta_cmd={$zelta_cmd}"
echo "func_name=${func_name}"
echo "perform substitutions for env vars:${env_var_names}"

OUT_DIR=${output_dir}/${func_name}
OUT_FL=${OUT_DIR}/${func_name}_stdout.out
ERR_FL=${OUT_DIR}/${func_name}_stderr.out
MATCHER_FL=${OUT_DIR}/${func_name}.sh

mkdir -p "$OUT_DIR"

if ! sh -c "$zelta_cmd" > "$OUT_FL" 2> "$ERR_FL"; then
   # zelta exiting with error is allowed, then stderr should have output that will be put into
   # a test
   # TODO: test this case where zelta exits with non-zero code, does the test generator work correctly?
   printf " ❌ Zelta command failed: %s\n\n" "$zelta_cmd"
   cat "$ERR_FL"
fi

if [ ! -s "$OUT_FL" ]; then
    if [ "$allow_no_output" != "true" ]; then
        printf "\n ❌ Error: zelta produced no output\n"
        printf "****-> review and update zelta cmd: \"%s\"\n" "$zelta_cmd"
        exit 1
    else
        printf "\n ⚠️  Command produced no output (skipping matcher generation)\n"
        exit 0
    fi
fi

# Skip matcher generation if allow_no_output is true
if [ "$allow_no_output" = "true" ]; then
    printf "\n ℹ️  Skipping matcher generation (allow_no_output=true)\n"
    exit 0
fi

printf "Generating matcher function...\n"
./matcher_func_generator.sh "$OUT_FL" "$func_name" "$env_var_names" > "$MATCHER_FL"

if [ $? -eq 0 ] && [ -s "$MATCHER_FL" ]; then
    printf " ✅ Success, matcher generated to file %s\n\n" "$MATCHER_FL"
else
    printf "\n ❌ Matcher generation failed!\n"
    exit 1
fi
