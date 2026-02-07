## Utilities

## Generate a shellspec test

#### Simple overview:
- put tree into desired state (use helper aliases, zdbg)
- cd `test/runners/util`
- run generator with dbg env `run_test_gen_dbg_env.rb (my_new_test_config.yml)`
- put tree back into desired state
- test generated test
- if it works, put it into the test directory and test it normally

### Working with the test generator

It can be tedious to setup your environment with the state of ZFS datasets
that represent the conditions under which you want to test Zelta.

> [!IMPORTANT]
> Use the suggested aliases ([See Alias Helpers](../doc/README_AliasHelpers.md)) 
> to put the ZFS pools and datasets into the desired state, the aliases are referenced in the recipes below
>

> [!TIP]
> Review the [test/runners/README.md](../README.md) for an overview of contents in this directory.

- - -
#### Running clean tests with standard environment

1. Update `test/runners/test_env.sh` with desired pools and datasets
> [!CAUTION]
> the pools and datasets referenced in `test_env.sh` will be removed and modified by the steps below.

2. Reset the environment to the standard state
   ```shell
   # setup fresh standard env, remove any custom pools and datasets referenced in test_env.sh
   # use the reset environment alias zrenv
   zrenv
   ````
 3. Run shellspec tests
    ```shell
    shellspec
    ```
- - -
#### Putting the zfs tree into a desired state

1. update `test/runners/debug_runner.sh` with desired functions
> [!IMPORTANT]
> You must modify the debug_runner.sh to setup the environment to match the desired state.

   `zdbg # use the alias helper`


> [!IMPORTANT]
> You must name your test definition so that it runs in the correct order.
> The shellspec test in the test directory are named with a number prefix 
> to ensure they run in the correct order.

#### Running the test generator
1. put the zfs pools into their desired state
2. create a test definition in test_defs, say `my_new_test.yml`
3. run the shellspec test generator
   
> [!IMPORTANT]
> give your test an ordered name so that it runs in the correct order.
> the test name must include `_spec` at the end, for example:
> shellspec_name: "999_my_test_spec"
   ```shell
   cd test/runners/util
   run_test_gen_dbg_env.rb ./test_defs/my_new_test.yml
   ```
4. put the zfs pools back into the desired starting state
5. manually run the generated test to verify it works as expected
   ```shell 
   zcd
   shellspec test/runners/util/tmp/my_test_spec.sh  # assuming the generated test is in tmp and has that name
   ```
6. if the test works, copy it into the test directory and run it normally to confirm it works there, start over as needed
   ```shell 
   # generate you test with an ordered name, using a numbered prefix
   cp test/runners/util/tmp/999_my_test_spec.sh test/
   # there is a working file you must remove, otherwise shellspec will find it and try to run it
   rm test/runners/util/tmp/wip_999_my_test_spec.sh 
   zrenv  # reset the environment to the standard state
   shellspec # run the full tests suite
   ```

- - -
> [!NOTE]
> Older documentation follows...
> these manual steps predate the ruby test generator

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
