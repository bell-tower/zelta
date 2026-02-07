### Suggested alias helpers:
> NOTE: Adding new tests often requires setting up the
> zfs pools and datasets in a specific way to create
> an appropriate test enviroment from which you can
> run zelta commands in the same way they are run for
> a full test. These aliases help simplify that iterative
> process.
```shell

# shellspec test development aliases

# set to your repo location for zelta
ZELTA_DEV=(your local repo location)      # local repo location 

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
alias zrenv="zcd && zclean && . $ZELTA_DBG/reset_env.sh" 

# make debug environment
alias zdbgenv="zcd && . $ZELTA_DBG/helpers.sh && setup_env 1"

# setup pools, datasets and remotes env vars
alias zsetup="zcd && . $ZELTA_DBG/test_env.sh"

# force a clean up of pools, datasets and remotes
alias zclean="zcd && $ZELTA_DBG/manual_cleanup.sh"

# perform a debug run, customize debug_runner.sh as needed
alias zrdbg="zcd && zdbgenv && zclean && $ZELTA_DBG/debug_runner.sh"

# setup env vars for your test environment
alias ztenv="zcd && . $ZELTA_DBG/test_env.sh"

```
