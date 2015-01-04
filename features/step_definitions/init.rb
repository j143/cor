require 'subprocess'
require 'timeout'
require 'minitest'

Given(/^the following code for \/sbin\/init:$/) do |string|
  File.write("init.c", string)
  Subprocess.check_call(["touch", "init.c"]) # to trigger make
end

Given(/^I use the following linker script for init:$/) do |string|
  File.write("init.ld", string)
  Subprocess.check_call(["touch", "init.ld"]) # to trigger make
end

When(/^I run the machine$/) do
  Subprocess.check_call(%w(make clean all))
  @process = Subprocess.popen(["bin/run"], stdout: Subprocess::PIPE)
end

Then(/^I should see "(.*?)"$/) do |needle|
  @out = ""
  catch :bye do
    begin
      Timeout.timeout(2) do
        loop do
          l = @process.stdout.gets
          @out << l
          if @out.include?(needle)
            throw :bye
          end
        end
      end
    rescue Timeout::Error
      assert @out.include?(needle), "expected to find \"#{needle}\" in \"#{@out}\""
    end
  end
end

After do
  @process.terminate if @process
end
