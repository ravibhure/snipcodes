#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
# connect to  mq use stomp protcol
# snip code from internet 
# for fun 
require 'rubygems'
require 'stomp'
require 'logger'	

class Slogger
 
  def initialize(init_parms = nil)
    @log = Logger::new(STDOUT)		
    @log.level = Logger::DEBUG		
    @log.info("Logger initialization complete.")
  end
  # Log connecting events
  def on_connecting(parms)
    begin
      @log.debug "Connecting: #{info(parms)}"
    rescue
      @log.debug "Connecting oops"
    end
  end
 
  # Log connected events
  def on_connected(parms)
    begin
      @log.debug "Connected: #{info(parms)}"
    rescue
      @log.debug "Connected oops"
    end
  end

  # Log connectfail events
  def on_connectfail(parms)
    begin
      @log.debug "Connect Fail #{info(parms)}"
    rescue
      @log.debug "Connect Fail oops"
    end
  end

  # Log disconnect events
  def on_disconnect(parms)
    begin
      @log.debug "Disconnected #{info(parms)}"
    rescue
      @log.debug "Disconnected oops"
    end
  end

  # Log miscellaneous errors
  def on_miscerr(parms, errstr)
    begin
      @log.debug "Miscellaneous Error #{info(parms)}"
      @log.debug "Miscellaneous Error String #{errstr}"
    rescue
      @log.debug "Miscellaneous Error oops"
    end
  end

  # Subscribe
  def on_subscribe(parms, headers)
    begin
      @log.debug "Subscribe Parms #{info(parms)}"
      @log.debug "Subscribe Headers #{headers}"
    rescue
      @log.debug "Subscribe oops"
    end
  end

  # Publish
  def on_publish(parms, message, headers)
    begin
      @log.debug "Publish Parms #{info(parms)}"
      @log.debug "Publish Message #{message}"
      @log.debug "Publish Headers #{headers}"
    rescue
      @log.debug "Publish oops"
    end
  end

  # Receive
  def on_receive(parms, result)
    begin
      @log.debug "Receive Parms #{info(parms)}"
      @log.debug "Receive Result #{result}"
    rescue
      @log.debug "Receive oops"
    end
  end

  private

  def info(parms)
    #
    # Available in the Hash:
    # parms[:cur_host]
    # parms[:cur_port]
    # parms[:cur_login]
    # parms[:cur_passcode]
    # parms[:cur_ssl]
    # parms[:cur_recondelay]
    # parms[:cur_parseto]
    # parms[:cur_conattempts]
    #
    # For the on_ssl_connectfail callback these are also available:
    # parms[:ssl_exception]
    #
    "Host: #{parms[:cur_host]}, Port: #{parms[:cur_port]}, Login: Port: #{parms[:cur_login]}, Passcode: #{parms[:cur_passcode]}, ssl: #{parms[:cur_ssl]}"
  end
end 



begin
  mylog = Slogger::new  
    
    login = "system"
    passwd = "manager"
    host = "localhost"
    
    port = 61613
    headers = {:ack => "client",}  
    qname = "/queue/Queue1"  
    hash = {
        :hosts => [
          {:login => login, :passcode => passwd, :host => host, :port => port },
        ],
        :initial_reconnect_delay => 0.01,
        :max_reconnect_delay => 30.0,
        :use_exponential_back_off => true,
        :back_off_multiplier => 2,
        :max_reconnect_attempts => 0,
        :randomize => false,
        :backup => false,
        :timeout => -1,
        :connect_headers => {},
        :parse_timeout => 5,
        :logger => mylog,
      }
    # for client or connection
    client = Stomp::Client.new(hash)
    
    data = "message payload:" + rand(36**25).to_s(36)*rand(2).to_f
    
    # for publish
    client.publish qname, data ,headers
    conn = Stomp::Connection.new(hash) if !client.open?
    
    
    # for # Receive 
    uuid = client.uuid() 
    message = nil
    
    client.subscribe(qname, {'id' => uuid}) {|m| 
      message = m
    }
    sleep 0.1 until message 

    client.close 
    
         
rescue
end
 












