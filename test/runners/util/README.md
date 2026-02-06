## Utilities

## Generate a shellspec test

- TODO: create better docs for auto test generation
  - this config [test_defs/divergent_tree_zelta_test.yml](test_defs/divergent_tree_zelta_test.yml)
  - produced this test [../../040_zelta_tests_spec.sh](../../040_zelta_tests_spec.sh)

#### steps are:
- put tree into desired state (use helper aliases, zdbg)
- run generator with dbg env `test/runners/util/run_test_gen_dbg_env.rb (test config.yml)`
- put tree back into desired state
- test generated test
- if it works, put it into the test directory and test it normally



## Generating a shellspec matcher function 
- in shellspec test use: 
   - `The output should satisfy (generated matcher function name)`

### Steps
- put the zfs dataset in the desired state

#### Generate matcher function automatically
- run the `./generate_matcher.sh` script with the desired zelta command and desired matcher function name as arguments
- the output will be written to a directory with the matcher function name 
- example invocation
    ```shell
    ./generate_matcher.sh \ 
    "zelta match dever@zfsdev:apool/treetop dever@zfsdev:bpool/backups" \
    backup_after_rotate \
    output_for_backup_after_rotate
    ```

#### Generate matcher function manual steps
- run the zelta command whose output you want to capture and save it to a file
- run `./match_function_generator.sh`
   - 1st arg the output file from the zelta command 
   - 2nd arg is the name of the function to generate
   - copy the output into your shellspec test


## Using the generated matcher

### Shellspec matcher example 
- ### Generating a matcher function for shellspec from zelta match output
```shell
util % ./generate_matcher.sh \
> "zelta backup $SANDBOX_ZELTA_SRC_EP $SANDBOX_ZELTA_TGT_EP" \
> output_backup_after_rotate_v2
zelta_cmd={zelta backup dever@zfsdev:apool/treetop dever@zfsdev:bpool/backups}
func_name=output_backup_after_rotate_v2
perform substitutions for env vars:SANDBOX_ZELTA_TGT_DS:SANDBOX_ZELTA_SRC_DS
Generating matcher function...
 ✅ Success, matcher generated to file ./tmp/output_backup_after_rotate_v2/output_backup_after_rotate_v2.sh
```

```shell
output_backup_after_rotate_v2() {
  while IFS= read -r line; do
    # normalize whitespace, remove leading/trailing spaces
    normalized=$(echo "$line" | tr -s '[:space:]' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$normalized" in
        "syncing 10 datasets"|\
        "10 datasets up-to-date"|\
        "* sent, * streams received in * seconds")
        ;;
      *)
        printf "Unexpected line format: %s\n" "$line" >&2
        return 1
        ;;
    esac
  done
  return 0
}
```

- ### Shellspec example using the generated matcher
```shell
Describe 'test example'
    It "backup again after rotate"
       When call zelta backup "$SANDBOX_ZELTA_SRC_EP" "$SANDBOX_ZELTA_TGT_EP"    
       The output should satisfy output_backup_after_rotate_v2
       The status should equal 0
    End
Enc
```
