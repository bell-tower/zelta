# Helpers for running and developing tests

### Suggested alias helpers:
```shell
ZELTA_DEV=~/src/repos/bt/zelta
ZELTA_DBG=$ZELTA_DEV/test/runners

# * Note on macOS, we need to use the homebrew bash
alias zspect='shellspec --xtrace --shell /opt/homebrew/bin/bash'
alias zhlp="alias | grep 'z'"
alias zcd="pushd $ZELTA_DEV"
alias zrenv=". $ZELTA_DBG/reset_env.sh" 
# use the helpers.sh script to setup the debug environment
alias zdbgenv=". $ZELTA_DBG/helpers.sh && setup_env 1"
alias zsetup=". $ZELTA_DBG/test_env.sh"
alias zclean="$ZELTA_DBG/manual_cleanup.sh"
alias zdbg="$ZELTA_DBG/debug_runner.sh"
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
