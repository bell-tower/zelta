#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require 'json-schema'
require 'yaml'
require 'fileutils'
require 'time'

# TestGenerator - Generates ShellSpec test files from YAML configuration
class TestGenerator
  GENERATE_MATCHER_SH_SCRIPT = './generate_matcher.sh'
  private_constant :GENERATE_MATCHER_SH_SCRIPT

  attr_reader :config, :output_dir, :shellspec_name, :describe_desc, :test_list,
              :matcher_files, :wip_file_path, :final_file_path

  def initialize(yaml_file_path)
    raise "YAML file not found: #{yaml_file_path}" unless File.exist?(yaml_file_path)

    @config = YAML.load_file(yaml_file_path)
    validate_config!

    @shellspec_name = @config['shellspec_name']
    @describe_desc = @config['describe_desc']
    @output_dir = @config['output_dir']
    @test_list = @config['test_list'] || []
    @matcher_files = []
    @wip_file_path = File.join(@output_dir, "#{@shellspec_name}_wip.sh")
    @final_file_path = File.join(@output_dir, "#{@shellspec_name}.sh")
    puts "Loading configuration from: #{@config.inspect}\n"
    puts '=' * 60
  end

  def generate
    create_output_directory
    create_wip_file
    process_tests
    assemble_final_file
    report_summary
  end

  private

  # Performs variable substitution in a string using the values from an object's instance variables.
  # The substitution is performed using the %{variable_name} syntax.
  #
  # Usage examples
  # substitute_placeholders("run %{zelta_command}", my_obj)
  # substitute_placeholders("run %{zelta_command}", my_obj, exclusions: [:internal_state])
  # substitute_placeholders("run %{zelta_command}", my_obj, inclusions: [:zelta_command, :runner])
  def substitute_placeholders(string, source, inclusions: nil, exclusions: nil)
    raise ArgumentError, "Cannot specify both inclusions and exclusions" if inclusions && exclusions

    vars = if source.is_a?(Hash)
             filter_hash(source, inclusions, exclusions)
           else
             extract_vars_from_object(source, inclusions, exclusions)
           end

    print "Substituting variables in string: #{string}\n"
    print "Using variables: #{vars.inspect}\n"
    string.gsub(/%\{(\w+)\}/) { vars[$1] || vars[$1.to_sym] }
  end

  private

  def filter_hash(hash, inclusions, exclusions)
    return hash if inclusions.nil? && exclusions.nil?

    hash.select do |key, _|
      key_str = key.to_s
      puts "Filtering key: #{key_str}"
      puts "inclusions.include?(key) || inclusions.include?(key_str) #{inclusions.include?(key) || inclusions.include?(key_str) || inclusions.include?(key_str.to_sym)}"
      if inclusions
        inclusions.include?(key) || inclusions.include?(key_str) || inclusions.include?(key_str.to_sym)
      elsif exclusions
        !(exclusions.include?(key) || exclusions.include?(key_str) || exclusions.include?(key_str.to_sym))
      else
        true
      end
    end
  end

  def extract_vars_from_object(obj, inclusions, exclusions)
    obj.instance_variables.each_with_object({}) do |var, hash|
      var_name = var.to_s.delete('@')

      if inclusions
        next unless inclusions.include?(var_name) || inclusions.include?(var_name.to_sym)
      elsif exclusions
        next if exclusions.include?(var_name) || exclusions.include?(var_name.to_sym)
      end

      hash[var_name] = obj.instance_variable_get(var)
    end
  end

  def matcher_func_name(test_name)
    "output_for_#{test_name}"
  end

  def validate_config!(schema_path = 'test_config_schema.yml')
    schema = YAML.load_file(schema_path)
    JSON::Validator.validate!(schema, @config)
  end

  def create_output_directory
    FileUtils.mkdir_p(@output_dir)
    puts "Created output directory: #{@output_dir}"
  end

  def create_wip_file
    File.open(@wip_file_path, 'w') do |file|
      file.puts "Describe '#{@describe_desc}'"
    end
    puts "Created WIP file: #{@wip_file_path}"
  end

  def process_tests
    @test_list.each do |test|
      test_name = test['test_name']
      # allow var substitution in test description
      it_desc = substitute_placeholders(test['it_desc'], test, inclusions: [:zelta_command])

      zelta_command = test['zelta_command']

      puts "Processing test: #{test_name}"

      # Generate matcher files
      generate_matcher_files(test_name, zelta_command)

      # Append It clause to WIP file
      append_it_clause(test_name, it_desc, zelta_command)
    end

    # Close Describe block
    File.open(@wip_file_path, 'a') do |file|
      file.puts 'End'
    end
  end

  def generate_matcher_files(test_name, zelta_command)
    matcher_script = GENERATE_MATCHER_SH_SCRIPT
    matcher_function_name = matcher_func_name(test_name)

    unless File.exist?(matcher_script)
      puts "Warning: Matcher generator script not found: #{matcher_script}"
      return
    end

    # Execute the matcher generator script
    cmd = "#{matcher_script} \"#{zelta_command}\" #{matcher_function_name} #{@output_dir}"
    output = `#{cmd} 2>&1`
    exit_status = $CHILD_STATUS.exitstatus

    puts "Matcher generation output for #{test_name}:"
    puts output
    puts "Exit status: #{exit_status}"

    if exit_status != 0
      puts "Warning: Matcher generation failed for #{test_name}"
      return
    end

    # Track the generated matcher file
    func_name = matcher_func_name(test_name)
    matcher_file = File.join(@output_dir, func_name, "#{func_name}.sh")
    puts "Generated matcher file: #{matcher_file}"
    @matcher_files << matcher_file if File.exist?(matcher_file)
  end

  def append_it_clause(test_name, it_desc, zelta_command)
    File.open(@wip_file_path, 'a') do |file|
      file.puts "  It '#{it_desc}'"

      # Check for stderr output
      stderr_file = File.join(@output_dir, "#{test_name}_stderr.out")
      if File.exist?(stderr_file) && !File.zero?(stderr_file)
        expected_error = format_expected_error(stderr_file)
        file.puts expected_error
        status_line = '    The status should be failure'
      else
        status_line = '    The status should equal 0'
      end

      file.puts "    When call #{zelta_command}"
      file.puts "    The output should satisfy #{matcher_func_name(test_name)}"

      file.puts '    The error should equal "$expected_error"' if File.exist?(stderr_file) && !File.zero?(stderr_file)
      file.puts status_line

      file.puts '  End'
      file.puts ''
    end
  end

  def format_expected_error(stderr_file)
    lines = read_stderr_file(stderr_file)
    result = "    expected_error=%text\n"
    lines.each do |line|
      result += "    #|#{line}\n"
    end
    "#{result}    End\n"
  end

  def read_stderr_file(stderr_file)
    File.readlines(stderr_file).map(&:chomp)
  rescue StandardError => e
    puts "Warning: Could not read stderr file #{stderr_file}: #{e.message}"
    []
  end

  def assemble_final_file
    File.open(@final_file_path, 'w') do |final|
      final.puts '# Auto-generated ShellSpec test file'
      final.puts "# Generated at: #{Time.now}"
      final.puts "# Source: #{@shellspec_name}"
      final.puts '# WARNING: This file was automatically generated. Manual edits may be lost.'
      final.puts ''

      # Copy all matcher function files
      @matcher_files.each do |matcher_file|
        if File.exist?(matcher_file)
          final.puts File.read(matcher_file)
          final.puts ''
        end
      end

      # Copy the WIP file content
      final.puts File.read(@wip_file_path) if File.exist?(@wip_file_path)
    end
    puts "Assembled final test file: #{@final_file_path}"
  end

  def report_summary
    puts "\n#{'=' * 60}"
    puts 'Test Generation Summary'
    puts '=' * 60
    puts "YAML Configuration: #{@config.inspect}"
    puts "ShellSpec Name: #{@shellspec_name}"
    puts "Description: #{@describe_desc}"
    puts "Output Directory: #{@output_dir}"
    puts "Tests Processed: #{@test_list.length}"
    puts "Matcher Files Generated: #{@matcher_files.length}"
    puts "\nGenerated Files:"
    puts "  - WIP File: #{@wip_file_path}"
    @matcher_files.each do |file|
      puts "  - Matcher: #{file}"
    end
    puts "\nFinal ShellSpec Test File:"
    puts "  Location: #{@final_file_path}"
    puts '=' * 60
  end
end

def run_generator
  if ARGV.empty?
    puts "Usage: #{$PROGRAM_NAME} <yaml_config_file>"
    puts "\nExample YAML format:"
    puts <<~YAML
      shellspec_name: example_tests
      describe_desc: Example Zelta Command Tests
      output_dir: test/output
      test_list:
        - test_name: test_version
          it_desc: should display version information
          zelta_command: zelta --version
        - test_name: test_help
          it_desc: should display help message
          zelta_command: zelta --help
    YAML
    return 1
  end

  yaml_file = ARGV[0]
  generator = TestGenerator.new(yaml_file)
  generator.generate
  0
end


# Script execution
run_generator if __FILE__ == $PROGRAM_NAME
