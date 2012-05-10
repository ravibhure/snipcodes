#!/usr/bin/ruby 
require 'socket'
require 'thread'


class Webserver
  def info(txt) ; puts "nw>i> #{txt}" ; end
  def error(txt) ; puts "nw>e> #{txt}" ; end
  def unescape(string) ; string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2}))/n) { [$1.delete('%')].pack('H*') } ;  end

  def initialize(port=7080,cadence=10,timeout=120)
	@last_mtime=File.mtime(__FILE__)
	@port=port
	@timeout=timeout
	@th={}
	@cb={}
	@redirect={}
	info("serveur http #{port} ...")
	@server = TCPServer.new('0.0.0.0', @port)
	@server.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
	info("serveur http #{port} ready!")
	observe(cadence,120)
	Thread.new {
	begin
	  while (session = @server.accept)
		Thread.new(session) do |sess|
		   @th[Thread.current]=Time.now
		   request(sess) 
		   @th.delete(Thread.current) 
		end
	  end
	rescue
	  error($!.to_s)
	end
	}
  end
  def serve(uri,&blk)
	@cb[uri] = blk
  end  
  def observe(sleeping,delta)
	Thread.new do loop do
	  sleep(sleeping) 
	  nowDelta=Time.now-delta
	  l=@th.select { |th,tm| (tm<nowDelta) }
	  l.each { |th,tm| info("killing thread") ; th.kill; @th.delete(th)  }
	end ; end
  end
  def request(session)
	  request = session.gets
	  uri = (request.split(/\s+/)+['','',''])[1]
	  #info uri
	  service,param,*bidon=(uri+"?").split(/\?/)
	  params=Hash[*(param.split(/#/)[0].split(/[=&]/))] rescue {}
	  params.each { |k,v| params[k]=unescape(v) }
	  uri=unescape(service)[1..-1].gsub(/\.\./,"")
	  userpass=nil
	  if (buri=uri.split(/@/)).size>1
		uri=buri[1..-1].join("@")
		userpass=buri[0].split(/:/)
	  end
	  do_service(session,request,uri,userpass,params)
  rescue
	error("Error Web get on #{request}: \n #{$!.to_s} \n #{$!.backtrace.join("\n     ")}" ) rescue nil
	session.write "HTTP/1.1 501/NOK\rContent-type: text/html\r\n\r\n<html><head><title>WS</title></head><body>Error : #{$!}" rescue nil
  ensure
	session.close rescue nil
  end  
  def redirect(o,d)
   @redirect[o]=d
  end  
  def do_service(session,request,service,user_passwd,params)
	#info "request='"+service+"'"
	redir=@redirect["/"+service]
	service=redir.gsub(/^\//,"") if @redirect[redir]
	if redir &&  ! @redirect[redir] 
	  do_service(session,request,redir.gsub(/^\//,""),user_passwd,params)
	elsif @cb["/"+service]
	  begin
	   code,type,data= @cb["/"+service].call(params)
	   if code==0 && data != '/'+service
		  do_service(session,request,data[1..-1],user_passwd,params)
	   else
		 code==200 ?  sendData(session,type,data) : sendError(session,code,data)
	   end
	  rescue
	   puts "Error in get /#{service} : #{$!}"
	   sendError(session,501,$!.to_s)
	  end
	elsif service =~ /^stop/ 
	  sendData(session,".html","Stopping...");	   
	  Thread.new() { sleep(0.1); stop_browser()  }
	elsif File.directory?("./"+service)
	  sendData(session,".html",makeIndex("./"+service))
	elsif File.exists?(service)
	  sendFile(session,service)
	else
	  info("unknown request serv=#{service} params=#{params.inspect} #{File.exists?(service)}")
	  sendError(session,500);
	end
  end
  def stop_browser
	info "exit on web demand !"
	@serveur.close rescue nil
	exit!(0) 
  end
  def makeIndex(dir)
	dirs,files=Dir.glob(dir=="./" ? "*" :dir+"/*").sort.partition { |f| File.directory?(f)}
	updir = dir.split(/\//)[0..-2].join("/")
	dirs=[updir]+dirs if updir.length>0
	"<html><body><h3>Repertoire #{dir}</h3><hr><br>#{to_table(dirs.map {|s| "<a href='#{"/"+s}'>"+s+"/"+"</a>"})}<hr>#{to_tableb(files) {|f| [LICON[rand(LICON.size)],"<a href='#{"/"+f}'>"+File.basename(f)+"</a>",File.size(f),File.mtime(f).strftime("%d/%m/%Y %H:%M:%S")]}}</body></html>"
  end  
  def to_table(l)
	 "<table><tr>#{l.map {|s| "<td>#{s}</td>"}.join("</tr><tr>")}</tr></table>"
  end
  def to_tableb(l,&bl)
	 "<table><tr>#{l.map {|s| "<td>#{bl.call(s).join("</td><td>")}</td>"}.join("</tr><tr>")}</tr></table>"
  end
  def sendError(sock,no,txt=nil)
	 if txt
	   txt="<html><body><pre></pre>#{txt}</body></html>"
	 end
	sock.write "HTTP/1.1 #{no}/NOK\rContent-type: #{mime(".html")}\r\n\r\n <html><p>Error #{no} : #{txt}</p></html>"
  end
  def sendData(sock,type,content)
	sock.write "HTTP/1.1 200/OK\rContent-type: #{mime(type)}\r\nContent-size: #{content.size}\r\n\r\n"
	sock.write(content)
  end
  def sendFile(sock,filename)
	sock.write "HTTP/1.1 200/OK\rContent-type: #{mime(filename)}\r\nContent-size: #{File.size(filename)}\r\n\r\n"
	File.open(filename,"rb") { |f| sock.write(f.read) }
  end
  def mime(string)
	 MIME[string.split(/\./).last] || "data-octet-stream"
  end
  LICON="&#9728;&#9731;&#9742;&#9745;&#9745;&#9760;&#9763;&#9774;&#9786;&#9730;".split(/;/).map {|c| c+";"}
  MIME={"png" => "image/png", "gif" => "image/gif", "html" => "text/html","htm" => "text/html",
	"js" => "text/javascript" ,"css" => "text/css","jpeg" => "image/jpeg" ,"jpg" => "image/jpeg" ,
	"pdf"=> "application/pdf"   , "svg" => "image/svg+xml","svgz" => "image/svg+xml",
	"xml" => "text/xml"   ,"xsl" => "text/xml"   ,"bmp" => "image/bmp"  ,"txt" => "text/plain" ,
	"rb"  => "text/plain" ,"pas" => "text/plain" ,"tcl" => "text/plain" ,"java" => "text/plain" ,
	"c" => "text/plain" ,"h" => "text/plain" ,"cpp" => "text/plain", "xul" => "application/vnd.mozilla.xul+xml"
  } 

end # 130 loc webserver :)


$ws=Webserver.new(7007,1,120)


$ws.serve "/index" do |params|
 [200,".html","hello!"]
end
