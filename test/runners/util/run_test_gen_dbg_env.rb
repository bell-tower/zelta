#!/usr/bin/env ruby

# Find repo root (assumes we're in a git repo)
repo_root = `git rev-parse --show-toplevel`.chomp

# Source shell environment setup from repo root
debug_env_script = File.join(repo_root, 'test/runners/setup_debug_env.sh')

# Source shell environment setup
if File.exist?(debug_env_script)
  output = `bash -c 'cd #{repo_root} && source #{debug_env_script} && env' 2>&1`
  
  if $?.exitstatus != 0
    $stderr.puts "Failed to source #{debug_env_script}:"
    $stderr.puts output
    exit $?.exitstatus
  end
  
  ENV.update(
    output
      .split("\n")
      .map { |line| line.split('=', 2) }
      .select { |pair| pair.size == 2 }
      .to_h
  )
end

# Replace Ruby process with test_generator.rb
exec('ruby', 'test_generator.rb', *ARGV)
