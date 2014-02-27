# -*- encoding : utf-8 -*-
require 'net/ssh'

HOST = '172.16.10.9'
USER = 'hxltxb'
PASSWORD = 'XXXX' # or use ENV variables?
commands = 'sudo ls -l'

Net::SSH.start(HOST, USER, :password => PASSWORD) do |ssh|
  ssh.open_channel do |channel|
    channel.request_pty do |ch, success|
      if success
        puts "Successfully obtained pty"
      else
        puts "Could not obtain pty"
      end
    end

    channel.exec(commands) do |ch, success|
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
