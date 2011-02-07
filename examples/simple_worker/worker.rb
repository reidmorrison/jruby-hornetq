#!/usr/bin/env jruby
#
# HornetQ Consumer:
#          Write messages to the queue
#

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'test_object'

timeout = (ARGV[0] || 3000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
client = config['client']
factory = HornetQ::Client::Factory.new(client[:connector])
consumer_manager = HornetQ::Client::ConsumerManager.new(factory, client[:session], config['queues'])

['HUP', 'INT', 'TERM'].each do |signal_name|
  Signal.trap(signal_name) do
    puts "caught #{signal_name}"
    consumer_manager.close
  end
end

threads = []
(1..50).each do |i|
  threads << Thread.new(i) do |thread_count|
    begin
      consumer_manager.each(:queue1) do |obj|
        puts "Thread #{thread_count} read #{obj}"
        sleep 2
      end
      puts "Thread #{thread_count} end of each(:queue1)"
    rescue Exception => e
      puts "Thread #{thread_count} Exception: #{e.message}"
    end
  end
end
(51..60).each do |i|
  threads << Thread.new(i) do |thread_count|
    begin
      consumer_manager.each(:queue2) do |obj|
        puts "Thread #{thread_count} read #{obj}"
      end
      puts "Thread #{thread_count} end of each(:queue2)"
    rescue Exception => e
      puts "Thread #{thread_count} Exception: #{e.message}"
    end
  end
end

threads.each { |thread| thread.join }
