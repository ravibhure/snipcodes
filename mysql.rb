#!/usr/bin/env ruby 
# connect to mysql use mysql gems
#
require "rubygems" 
def conmysql(val)
  @val= 'ss' + val
  require "mysql"   
  begin   
    dbh = Mysql.real_connect("localhost", "", "", "test")
    dbh.query("drop table if exists test_rb") 
    dbh.query("create table test_rb(id int,name varchar(20))") 
    dbh.query("insert into test_rb values(1,'ss')") 
    dbh.query("insert into test_rb values(1,'aaa')") 
    printf "%d rows were inserted\n",dbh.affected_rows 
  
    res=dbh.query("SELECT name FROM test_rb") 
    puts "===============\n" 
    while row=res.fetch_row do 
    printf "%s,%s\n",row[0],row[1] 
    end 
    puts "================\n" 
    puts "Server version:"+dbh.get_server_info 
    rescue Mysql::Error=>e 
    puts "Error code:#{e.errno}" 
    puts "Error message:#{e.error}" 
    puts "Error SQLSTATE:#{e.sqlstate}" if e.respond_to?("sqlstate") 
    ensure 
    dbh.close if dbh 
  end
end 



