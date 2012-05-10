#!/usr/bin/ruby
# 产成一些36位以下的随机数字和字母组合的字串,这个小工具主要是用于测试ruby 的daemon和ruby的log格式自定义
# 

if(ARGV[0])
    puts "usage: ruby #{__FILE__}"
    puts  "then you can:  tail -f /tmp/m.log for result"
end

require 'rubygems'
logs = "/tmp/m.log"


require 'logger'

logger = Logger.new(logs)

logger.formatter = proc { |severity, datetime, progname, msg|
      "#{datetime}: #{$$} #{msg}\n"
}
  

def daemonize &block
  child = fork
  if child.nil? # is child
    $stdin.reopen "/dev/null"
    $stdout.reopen "/dev/null", "a"
    $stderr.reopen $stdout
    trap('HUP', 'IGNORE')
    block.call
  else # is parent
    Process.detach child
  end
end


daemonize do 
  
  while true
   logger.info  rand(36**25).to_s(36)
  end

end

