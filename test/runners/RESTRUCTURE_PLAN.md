# Test Runners Restructure Plan

## Current Issues
1. Mixed concerns: env setup scripts and test generation mixed at top level
2. Unclear hierarchy: difficult to understand what calls what
3. Language mixing: Ruby, AWK, and shell scripts scattered around
4. Nested structure: `util/test_generation/` inside `util/` is confusing

## Proposed Structure

```
test/runners/
├── README.md
├── doc/
│   └── README_AliasHelpers.md
│
├── env/                          # Environment setup scripts
│   ├── helpers.sh
│   ├── manual_cleanup.sh
│   ├── reset_env.sh
│   ├── set_reuse_tmp_env.sh
│   ├── setup_debug_env.sh
│   └── test_env.sh
│
└── test_generation/              # All test generation code
    ├── README.md
    ├── Gemfile                   # Ruby dependencies
    ├── Gemfile.lock
    ├── .rubocop.yml
    │
    ├── bin/                      # Tier 1: User entry points
    │   ├── debug_gen.sh          # Main entry for debugging test generation
    │   └── generate_new_tests.sh # Main entry for generating new tests
    │
    ├── config/                   # Configuration files
    │   ├── test_config_schema.yml
    │   └── test_defs/            # YAML test definitions
    │       ├── 040_zelta_tests.yml
    │       ├── 050_zelta_revert_test.yml
    │       ├── 060_zelta_clone_test.yml
    │       ├── dbg_test.yml
    │       └── example_test.yml
    │
    ├── lib/                      # Core logic
    │   ├── ruby/                 # Tier 3: Ruby modules/classes
    │   │   ├── test_generator.rb     # Main generator (requires placeholders, sys_exec)
    │   │   ├── placeholders.rb       # Module: handles placeholder substitution
    │   │   └── sys_exec.rb           # Module: executes shell commands with timeout
    │   │
    │   └── orchestration/        # Tier 2: Shell orchestration scripts
    │       ├── setup_tree.sh     # Sets up test tree structure
    │       └── generate_test.sh  # Orchestrates single test generation
    │
    ├── scripts/                  # Tier 4: Low-level utility scripts
    │   ├── awk/
    │   │   └── generate_case_stmt_func.awk  # Generates case statement matcher functions
    │   └── sh/
    │       ├── generate_matcher.sh           # Generates matcher functions for shellspec
    │       └── matcher_func_generator.sh     # Invokes AWK script for matcher generation
    │
    ├── debug/                    # Development/debugging utilities
    │   └── run_test_gen_dbg_env.rb   # RubyMine debug helper
    │
    ├── tmp/                      # Generated output (test files, matcher functions)
    └── log/                      # Log files
```

## Call Hierarchy

### Complete Call Chain
```
bin/debug_gen.sh                                    [Tier 1: Entry Point]
├─> lib/orchestration/setup_tree.sh                 [Tier 2: Orchestration]
└─> lib/orchestration/generate_test.sh              [Tier 2: Orchestration]
    └─> lib/ruby/test_generator.rb                  [Tier 3: Core Logic]
        └─> scripts/sh/generate_matcher.sh          [Tier 4: Utilities]
            ├─> scripts/sh/matcher_func_generator.sh [Tier 4: Utilities]
            └─> scripts/awk/generate_case_stmt_func.awk [Tier 4: Utilities]

bin/generate_new_tests.sh                           [Tier 1: Entry Point]
├─> lib/orchestration/setup_tree.sh                 [Tier 2: Orchestration]
└─> lib/orchestration/generate_test.sh              [Tier 2: Orchestration]
    └─> (same chain as above)

debug/run_test_gen_dbg_env.rb                       [Debug: Direct invocation]
└─> lib/ruby/test_generator.rb                      [Tier 3: Core Logic]
    └─> (same chain as above)
```

### Tier Descriptions

**Tier 1: Entry Points (`bin/`)**
- User-facing scripts
- Set up environment and invoke orchestration scripts
- Handle command-line arguments

**Tier 2: Orchestration (`lib/orchestration/`)**
- Coordinate multiple operations
- Prepare test environment (setup_tree.sh)
- Invoke core generator logic (generate_test.sh)

**Tier 3: Core Logic (`lib/ruby/`)**
- Main business logic
- `test_generator.rb`: Reads YAML config, generates shellspec tests
- `placeholders.rb`: Handles variable substitution
- `sys_exec.rb`: Executes shell commands with error handling

**Tier 4: Utilities (`scripts/`)**
- Low-level helpers
- Generate matcher functions for shellspec assertions
- Process command output into test patterns

## Component Details

### Ruby Dependencies
```
lib/ruby/test_generator.rb
  requires: placeholders.rb
  requires: sys_exec.rb
  calls: scripts/sh/generate_matcher.sh
```

### Shell Script Chain
```
scripts/sh/generate_matcher.sh
  ├─> Executes command and captures output
  └─> calls: scripts/sh/matcher_func_generator.sh
      └─> calls: scripts/awk/generate_case_stmt_func.awk
          └─> Generates bash case statement function
```

## Migration Steps

### Phase 1: Create New Structure
```bash
cd test/runners

# Create new directories
mkdir -p env
mkdir -p test_generation/{bin,config/test_defs,lib/{ruby,orchestration},scripts/{awk,sh},debug,tmp,log}

# Move environment setup scripts
git mv helpers.sh manual_cleanup.sh reset_env.sh set_reuse_tmp_env.sh \
        setup_debug_env.sh test_env.sh env/

# Move test generation files
git mv util/test_generation/{debug_gen.sh,generate_new_tests.sh} test_generation/bin/
git mv util/test_generation/{setup_tree.sh,generate_test.sh} test_generation/lib/orchestration/

git mv util/{test_generator.rb,run_test_gen_dbg_env.rb} test_generation/lib/ruby/
git mv util/lib/{placeholders.rb,sys_exec.rb} test_generation/lib/ruby/

git mv util/generate_case_stmt_func.awk test_generation/scripts/awk/
git mv util/{generate_matcher.sh,matcher_func_generator.sh} test_generation/scripts/sh/

git mv util/test_config_schema.yml test_generation/config/
git mv util/test_defs/* test_generation/config/test_defs/

git mv util/{Gemfile,Gemfile.lock,.rubocop.yml} test_generation/

# Move debug helper
git mv test_generation/lib/ruby/run_test_gen_dbg_env.rb test_generation/debug/

# Move documentation
git mv util/README.md test_generation/README.md
```

### Phase 2: Update File References

Files that need path updates:

1. **bin/debug_gen.sh** - Update paths to orchestration scripts
2. **bin/generate_new_tests.sh** - Update paths to orchestration scripts
3. **lib/orchestration/generate_test.sh** - Update path to test_generator.rb
4. **lib/ruby/test_generator.rb** - Update:
   - `require_relative` statements for placeholders and sys_exec
   - Path to generate_matcher.sh
   - Path to test_config_schema.yml
5. **scripts/sh/generate_matcher.sh** - Update path to matcher_func_generator.sh
6. **scripts/sh/matcher_func_generator.sh** - Update path to generate_case_stmt_func.awk
7. **debug/run_test_gen_dbg_env.rb** - Update path to test_generator.rb
8. **README.md files** - Update all documentation

### Phase 3: Test & Validate
1. Run debug_gen.sh and verify it works
2. Run generate_new_tests.sh and verify output
3. Test RubyMine debug helper
4. Verify all tests still pass
5. Update any CI/CD scripts if applicable

## Benefits

1. **Clear Separation**: Environment setup vs test generation
2. **Obvious Hierarchy**: 4 clear tiers (entry → orchestration → core → utilities)
3. **Language Organization**: Ruby, shell, and AWK each in their own space
4. **Scalability**: Easy to add new scripts at appropriate tier
5. **Discoverability**: New developers can understand structure immediately
6. **Dependency Clarity**: `lib/ruby/` clearly has Gemfile dependencies

## Risks & Mitigation

**Risk**: Breaking existing workflows
**Mitigation**: Create shell script aliases in old locations that call new locations

**Risk**: Missing path updates
**Mitigation**: Use grep to find all file references before migration

**Risk**: CI/CD failures
**Mitigation**: Update CI/CD configs in same commit as restructure
