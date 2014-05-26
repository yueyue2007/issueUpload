# -*- encoding : utf-8 -*-
require 'net/ssh'
require 'net/scp'
require 'optparse'


HOST = '172.16.10.9'
USER = 'hxltxb'
PASSWORD = 'sjc()XZXY' # or use ENV variables?
commands = 'sudo ls -l'
USERNAME = 'ojsadmin'



#1. 检查参数及配置文件是否存在？
options = {}
options_parser = OptionParser.new do |opts|
  opts.banner = "ssh期刊文章上传程序，用法如下： \n 
    ruby testssh.rb --xml *.xml  --name xuebao(luntan) "
  opts.on("--xml XML","提交的pdf文件名") do |xml|
    options[:xml_file] = xml 
  end
  opts.on("--name NAME","杂志名称：xuebao（或luntan）") do |name|
    options[:magazine_name] = name 
  end
end.parse!
unless options[:xml_file]&&options[:magazine_name]
  puts "缺少参数，请输入ruby testssh.rb -h查看帮助。"
  exit
end

puts options.inspect
xml_file = options[:xml_file]
if options[:magazine_name] == "xuebao"
  journal_path = "hnxzxyxb"
elsif options[:magazine_name] == "luntan"
  journal_path = "hxlt"
else
  puts "杂志参数不正确，请输入ruby testssh.rb -h查看帮助。"
  exit
end

# 2 将xml文件上传到服务器中
Net::SSH.start(HOST,USER) do |ssh|  
  ssh.scp.upload!(xml_file,'./pdfs/') do |ch,name,sent,total|
    print "\r#{name}: #{(sent.to_f * 100 /total.to_f).to_i}%"
  end
end

# 3 command

 phpcommand = " sudo php  /var/www/ojs/tools/importExport.php NativeImportExportPlugin import "
 phpcommand << "pdfs/"
 phpcommand << xml_file
 phpcommand << " "
 phpcommand << journal_path
 phpcommand << " "
 phpcommand << USERNAME

 puts "使用如下所示命令将期刊导入到网站中..."
 p phpcommand
 # system(phpcommand)

Net::SSH.start(HOST, USER) do |ssh| # , :password => PASSWORD
  ssh.open_channel do |channel|
    channel.request_pty do |ch, success|
      if success
        puts "Successfully obtained pty"
      else
        puts "Could not obtain pty"
      end
    end

    channel.exec(phpcommand) do |ch, success|
      abort "Could not execute commands!" unless success
        channel.on_data do |ch, data|
          puts "#{data}"
          channel.send_data "#{PASSWORD}\n" if data =~ /password/
        end

        channel.on_extended_data do |ch, type, data|
          puts "stderr: #{data}"
        end

        channel.on_close do |ch|
          puts "Channel is closing!"
        end
      end
    end
  ssh.loop
end
