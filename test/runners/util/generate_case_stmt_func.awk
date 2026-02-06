#!/usr/bin/awk -f

BEGIN {
    # env_names - accept colon delmited list of env var names
    # create two corresponding arrays
    # sorted in descending order by length of value
    # env_names_arr  - array of env var names
    # err_values_arr - array of corresponding env var values

    # Split just the environment variable names
    split(env_names, env_names_arr, ":")
    env_count = length(env_names_arr)

    # Read values from environment and sort by length (descending)
    for (i = 1; i <= env_count; i++) {
        env_values_arr[i] = ENVIRON[env_names_arr[i]]
    }

    # Sort by value length (descending) - bubble sort
    for (i = 1; i <= env_count; i++) {
        for (j = i + 1; j <= env_count; j++) {
            if (length(env_values_arr[i]) < length(env_values_arr[j])) {
                tmp_val = env_values_arr[i]
                env_values_arr[i] = env_values_arr[j]
                env_values_arr[j] = tmp_val

                tmp_name = env_names_arr[i]
                env_names_arr[i] = env_names_arr[j]
                env_names_arr[j] = tmp_name
            }
        }
    }
}
# ignore blank lines
/^$/ { next }

# ignore comment lines starting with #
/^[[:space:]]*#/ { next }

# Process data lines
{
    gsub(/[[:space:]]+/, " ", $0)
    gsub(/@zelta_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}\.[0-9]{2}\.[0-9]{2}/, "@zelta_\"*\"",$0)
    gsub(/`/, "\\`", $0)

    # wildcard time and quantity sent
    if (match($0, /[0-9]+[KMGT]? sent, [0-9]+ streams/)) {
        # Extract the part with streams
        streams_part = substr($0, RSTART, RLENGTH)
        # Extract just the number before " streams"
        match(streams_part, /[0-9]+ streams/)
        stream_count = substr(streams_part, RSTART, RLENGTH)
        gsub(/[0-9]+[KMGT]? sent, [0-9]+ streams received in [0-9]+\.[0-9]+ seconds/, "* sent, " stream_count " received in * seconds", $0)
    }

    # substitute env var name for any value matching it's value
    for (i = 1; i <= env_count; i++) {
        gsub(env_values_arr[i], "${" env_names_arr[i] "}", $0)
    }

    lines[count++] = $0
}

END {
    print func_name "() {"
    print "  while IFS= read -r line; do"
    print "    # normalize whitespace, remove leading/trailing spaces"
    print "    normalized=$(echo \"$line\" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    print "    case \"$normalized\" in"

    line_continue = "\"|\\"
    case_end = "\")"

    for (i = 0; i < count; i++) {
        line_end = (i + 1 == count) ? case_end : line_continue
        print "        \"" lines[i] line_end
    }

    print "        ;;"
    print "      *)"
    print "        printf \"Unexpected line format: %s\\n\" \"$line\" >&2"
    print "        return 1"
    print "        ;;"
    print "    esac"
    print "  done"
    print "  return 0"
    print "}"
}
