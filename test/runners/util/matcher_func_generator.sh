#!/bin/sh

# Check for required arguments
if [ $# -ne 3 ]; then
    printf "Usage: %s <output_to_match_file> <matcher_function_name> <env_var_name1:env_var_name2:...>\n" "$0" >&2
    exit 1
fi

input_file="$1"
func_name="$2"
env_var_names="$3"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    printf "Error: File '%s' not found\n" "$input_file" >&2
    exit 1
fi

awk -v func_name="$func_name" \
    -v env_names="$env_var_names" \
    -f generate_case_stmt_func.awk "$input_file"