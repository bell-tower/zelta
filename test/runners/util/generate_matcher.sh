#!/bin/sh

# Check for required arguments
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    printf "Usage: %s <zelta command> <matcher_function_name> <env_var_name1:env_var_name2:...>\n" "$0" >&2
    printf "\t-> * put your zfs datasets in the desired state before running\n"
    printf "\t-> * to capture the zelta output that would be captured by a test\n"
    exit 1
fi

zelta_cmd=$1
func_name=$2

if [ $# -eq 3 ]; then
    env_var_names=$3
else
    env_var_names="SANDBOX_ZELTA_TGT_DS:SANDBOX_ZELTA_SRC_DS"
fi

echo "zelta_cmd={$zelta_cmd}"
echo "func_name=${func_name}"
echo "perform substitutes for env vars:${env_var_names}"

OUT_DIR=./tmp/${func_name}
OUT_FL=${OUT_DIR}/stdout_${func_name}.out
ERR_FL=${OUT_DIR}/stderr_${func_name}.out
MATCHER_FL=${OUT_DIR}/${func_name}.sh

mkdir -p "$OUT_DIR"

if ! eval "$zelta_cmd" > "$OUT_FL" 2> "$ERR_FL"; then
   printf " ❌ Zelta command failed: %s\n\n" "$zelta_cmd"
   cat "$ERR_FL"
fi

if [ ! -s "$OUT_FL" ]; then
    printf "\n ❌ Error: zelta produced no output\n"
    printf "****-> review and update zelta cmd: \"%s\"\n" "$zelta_cmd"
    exit 1
fi

printf "Generating matcher function...\n"
./matcher_func_generator.sh "$OUT_FL" "$func_name" "$env_var_names" > "$MATCHER_FL"

if [ $? -eq 0 ] && [ -s "$MATCHER_FL" ]; then
    printf " ✅ Success, matcher generated to file %s\n\n" "$MATCHER_FL"
else
    printf "\n ❌ Matcher generation failed!\n"
fi
