# Helpers for running and developing tests

### Define and use aliases to run helper scripts
[See Alias Helpers](doc/README_AliasHelpers.md)

- Use the alias helpers to run the test runner scripts.
- Use util/test_generator.rb to generate new tests. 

Directory of files in `test/runners/`:
```
test/runners/
├── debug_runner.sh      - Main test runner for debugging:
│                             Customize the helper functions below to suit your needs
│                                manual_run() - reach into test/test_helpser.sh functions
│                                spec_run()   - run specific specs
├── setup_debug_env.sh   - Sets up environment for debugging test generator
├── test_env.sh          - Sets up core test environment (pools, datasets, remotes for ZFS testing)
├── set_reuse_tmp_env.sh - Reuses the last /tmp/zelta* install for faster test development
├── reset_env.sh         - Resets test environment by unsetting
│                          SANDBOX_ZELTA_TMP_DIR, checked in test/test_helper.sh
├── helpers.sh           - Common helper functions (setup_env, run_it, clean_ds_and_pools)
├── manual_cleanup.sh    - Manually cleans up datasets and pools between test runs
├── doc/                 - Documentation files
│
├── util/                - Test generator utilities 
│   ├── test_generator.rb         - Main test generator script, manages full shellspec test creation
│   ├── run_test_gen_dbg_env.rb   - Debug runner for test generator, this allows Ruby debugging
│   ├── generate_matcher.sh       - Top level script for invoking matcher function generator, 
│   │                               runs commandd and captures output, then runs awk script to 
│   │                               generate matcher functions. The generated matcher functions are
│   │                               used in in shellspec expreassisons like 
│   │                               "The output should satisfy <matcher_func_name>"
│   ├── matcher_func_generator.sh - Generates matcher functions via awk script invocation from comand output
│   ├── generate_case_stmt_func.awk - AWK script for case statement generation for matcher functions
│   ├── test_config_schema.yml    - YAML schema for test configuration, used by test_generator.rb
│   ├── test_defs/                - Test definition files from which shellspec tests are generated
│   ├── lib/                      - Ruby library files
│   └── tmp/                      - suggested default output directory for test_geneartor.rb output
│
└── README.md            - This file
```
