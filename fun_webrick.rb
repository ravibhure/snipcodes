#!/usr/bin/env ruby
# an easy server with webrick
# it 's a demo  for fun 

require 'webrick'

include WEBrick

def start_webrick(config = {})
    # always listen on port 3000
    config.update(:Port => 3000)
    config.update(:MimeTypes => {'rhtml' => 'text/html'})
    server = HTTPServer.new(config)
    yield server if block_given?
    ['INT', 'TERM'].each {|signal| 
        trap(signal) {server.shutdown}
    }
    server.start
end

start_webrick(:DocumentRoot => Dir::pwd)

