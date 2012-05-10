#!/usr/bin/env ruby 
require 'rubygems'
require 'socket'

class Httpcli   
  def initialize(port=80)
    @timeout = 30
    @ver=1.0
    @port = port
  end
  
  def parse_url(url)
    /http:\/\/([^\/]+)(.*)?/ =~ url or
      puts "wront URI formart";
    @host = $~[1]
    @path = $~[2]
    @path = "/index.php"  if !@path
  end
  
  
  def connect_to(host, port, timeout=nil)
        sock = nil
        addr = Socket.getaddrinfo(host, nil)
        sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        begin
            sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
      
            if timeout
              secs = Integer(timeout)
              optval = [secs, 0].pack("l_2")
                sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
                sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
            end
            
            sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
            
          rescue Exception => ex
              puts "Unable to open host: #{addr[0][3]} with port #{@port}"
              puts  "\t#{ex.class.name}, #{ex.message}"
              sock.close if sock 
              exit  
        end
      return sock if sock 
  end
      
  def request(url,post=nil)
    parse_url url
    headers = "#{@methed} #{@path} HTTP/1.0\r\nHOST: #{@host}\r\n"
    headers << "Content-Type: application/x-www-form-urlencoded\r\n" if post
    headers << "User-Agent: ruby/httpcheck\r\n"
    headers << "Content-Length:" + post.size.to_s +  "\n\n" if post
    
    @socket = connect_to @host,@port,@timeout
    @socket.write headers
    @socket.write post.to_s  if post
    @socket.write  "\r\n"  if post.nil?
    return @socket  if @socket
  end
    

  def head(url)
     @methed = "HEAD" 
     request url,header
     puts @socket.read
  end

   def post(url,post)   
      @methed = "POST" 
      request url,post
      puts @socket.read.split("\r\n\r\n")[1]
  end
  
  def get(url)
     @methed = "GET" 
     request url
     puts @socket.read.split("\r\n\r\n")[1]
 end
 
 
 def ifok(url)
      @methed = "HEAD" 
      request url
      code=@socket.gets.scan(/\AHTTP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/min)[0][1].to_i
      case code
      when 100...200; puts "info"
      when 200...300; puts "Success"
      when 300...400; puts "Redirect"
      when 400...500; puts "ClientError #{code}"
      when 500...600; puts "ServerError #{code}"
      end     
    end
end


def main
  action = ARGV[0]
  url = ARGV[1]
  http = Httpcli.new
  
  case action
  	when "head" ;http.head url
  	when "get"  ;http.get url
  	when "ifok" ;http.ifok url
    when "post" then 
      post = ARGV[1] 
      url = ARGV[2]
      http.post url, post  
  	when  nil  ;puts "usage: ruby #{__FILE__} get/head/ifok  URI"
                puts "usage: ruby #{__FILE__} post fileds ='value'  URI" 
    else
      puts "unsupported method."
  end
end

main if(__FILE__==$0)
