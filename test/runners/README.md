# Helpers for running and developing tests

### Suggested alias helpers:
> NOTE: Adding new tests often requires setting up the 
> zfs pools and datasets in a specific way to create 
> an appropriate test enviroment from which you can
> run zelta commands in the same way they are run for
> a full test. These aliases help simplify that iterative 
> process.
```shell
# set to your repo location for zelta
ZELTA_DEV=~/src/repos/bt/zelta      # local repo location 

# debug helpers for zelta testing
ZELTA_DBG=$ZELTA_DEV/test/runners

# show all the aliases we've setup for zelta testing
alias zhlp="alias | grep 'z'"
alias zcd="cd $ZELTA_DEV"

# NOTE: the aliases work from the context of the zelta repo, use zcd before action

# run shellspec with trace and evaluation
# note: macOS requires homebrew bash, use bash shell for your env
BASH_SH=/opt/homebrew/bin/bash
alias zspect='zcd && shellspec --xtrace --shell $BASH_SH'

# force next evaluation of test/test_helpers.sh to initialize env fully
alias zrenv="zcd && . $ZELTA_DBG/reset_env.sh" 

# make debug environment
alias zdbgenv="zcd && . $ZELTA_DBG/helpers.sh && setup_env 1"

# setup pools, datasets and remotes env vars
alias zsetup="zcd && . $ZELTA_DBG/test_env.sh"

# force a clean up of pools, datasets and remotes
alias zclean="zcd && $ZELTA_DBG/manual_cleanup.sh"

# perform a debug run, customize debug_runner.sh as needed
alias zdbg="zcd && $ZELTA_DBG/debug_runner.sh"

# setup env vars for your test environment
alias ztenv="zcd && . $ZELTA_DBG/test_env.sh"

```

Directory of files in `test/runners/`:
```
test/runners/
├── debug_runner.sh      - Main test runner for debugging:
│                             Customize the helper functions below to suit your needs
│                                manual_run() - reach into test/test_helpser.sh functions
│                                spec_run()   - run specific specs    
├── test_env.sh          - Sets up core test environment (pools, datasets, remotes for ZFS testing)
├── set_reuse_tmp_env.sh - Reuses the last /tmp/zelta* install for faster test development
├── reset_env.sh         - Resets test environment by unsetting
│                          SANDBOX_ZELTA_TMP_DIR, checked in test/test_helper.sh
├── helpers.sh           - Common helper functions (setup_env, run_it, clean_ds_and_pools)
└── manual_cleanup.sh    - Manually cleans up datasets and pools between test runs
```
