# lib/sys_exec.rb
require 'open3'
require 'timeout'

module SysExec
  class ExecutionTimeout < StandardError; end

  def self.run(cmd, timeout: 30, debug: true)
    puts "Executing: #{cmd}" if debug

    stdout = ''
    stderr = ''
    status = nil
    pid = nil
    timed_out = false

    begin
      Open3.popen3(cmd) do |stdin, out, err, wait_thr|
        pid = wait_thr.pid
        stdin.close

        # Non-blocking read with timeout
        start_time = Time.now

        loop do
          if Time.now - start_time > timeout
            timed_out = true
            break
          end

          # Use select to check if data is available
          ready = IO.select([out, err], nil, nil, 0.1)
          if ready
            ready[0].each do |io|
              begin
                stdout << io.read_nonblock(1024) if io == out
                stderr << io.read_nonblock(1024) if io == err
              rescue IO::WaitReadable
                # Nothing available right now
              rescue EOFError
                # Stream closed
              end
            end
          end

          # Check if process finished
          break unless wait_thr.alive?
        end

        if timed_out
          Process.kill('TERM', pid) rescue nil
          sleep 0.1
          Process.kill('KILL', pid) rescue nil
        else
          status = wait_thr.value
        end
      end
    rescue => e
      timed_out = true
    end

    if timed_out
      env_cmd = cmd.gsub(/\$\{?(\w+)\}?/) { ENV[$1] || "#{$&}:undefined" }

      error_msg = <<~MSG
          \nERROR: Command timed out after #{timeout} seconds
          Command: #{cmd}
          Command with env substitution: #{env_cmd}
          STDOUT so far:
        #{stdout.lines.map { |line| "  : #{line}" }.join}
          STDERR so far:
        #{stderr.lines.map { |line| "  : #{line}" }.join}
      MSG

      error_msg = error_msg.lines.map { |line| "*** #{line}" }.join

      raise ExecutionTimeout, error_msg
    end

    if debug
      puts "STDOUT: #{stdout}" unless stdout.empty?
      puts "STDERR: #{stderr}" unless stderr.empty?
      puts "Exit status: #{status.exitstatus}"
    end

    { stdout: stdout, stderr: stderr, exit_status: status.exitstatus }
  end
end
