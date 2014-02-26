# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby


require 'roo'
require 'builder'
require 'base64'
require 'date'
require 'optparse'
require 'pdf-reader'
require 'net/ssh'
require 'net/scp'


# 上传xml文件到web服务器...
HOST = '172.16.10.9'
USER = 'hxltxb'

xml_file = "行政201401.xml"
Net::SSH.start(HOST,USER) do |ssh|  
  # ssh.scp.upload!(xml_file,'./pdfs/') do |ch,name,sent,total|
  #   print "\r#{name}: #{(sent.to_f * 100 /total.to_f).to_i}%"
  # end
  result = nil
  ssh.open_channel do |channel|
  	channel.request_pty do |ch,success|
  		if success 
  			puts "successfully obtaind pty"
  		else
  			puts "could not obtain pty"
  		end
  	end
  	channel.exec("sudo ls -l") do |ch,success|
  		abort "could not execute commands " unless success
  		channel.on_data do |ch,data|
  			puts "#{data}"
  			ch.send_data "sjc()XZXY" # if data =~ /password/
  		end
  	end
  end
  # ssh.exec!("sudo ls -l") do |channel,stream,data|
  # 	puts data 
  # 	if data=~ /password/
  # 		channel.send_data 'sjc()XZXY'
  # 	else 
  # 		# p data 
  # 	end
  # end
  # puts result 
end

#  #调用php，导入刊期和文章
#  phpcommand = " sudo php  /var/www/ojs/tools/importExport.php NativeImportExportPlugin import "
#  phpcommand << xml_file
#  phpcommand << " "+tree['journal_path']+" "+tree["username"]

#  puts "使用如下所示命令将期刊导入到网站中..."
#  puts phpcommand
#  system(phpcommand)