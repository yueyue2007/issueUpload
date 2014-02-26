# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby
require 'net/ssh'
require 'net/scp'

HOST = '172.16.10.9'
USER = 'hxltxb'
PASS = 'sjc()XZXY'

# execute a command
Net::SSH.start(HOST,USER,:password => PASS) do |ssh|
	result = ssh.exec!('sudo ls')
	puts result
	ssh.scp.upload!("/home/xinyue/codes/pdftest/201004.xml","/home/hxltxb/pdfs/") do |ch,name,sent,total|
		print "\r#{name}: #{(sent.to_f*100/total.to_f).to_i}%"
	end
end


