#!/usr/bin/env jruby
#
# HornetQ Producer:
#          Write messages to the queue
#

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'logger'
require 'test_object'

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
client = config['client']

# Create a HornetQ session
logger = Logger.new($stdout)
factory = HornetQ::Client::Factory.new(client[:connector])
session_pool = factory.create_session_pool(client[:session_pool])
producer_manager = HornetQ::Client::ProducerManager.new(session_pool, client[:addresses], true)

['HUP', 'INT', 'TERM'].each do |signal_name|
  Signal.trap(signal_name) do
    puts "caught #{signal_name}"
    $stopped = true
  end
end

$stopped = false
threads = []
(1..5).each do |i|
  threads << Thread.new(i) do |thread_count|
    msg_count = 0
    while !$stopped
      msg_count += 1
      obj = TestObject.new("Message ##{thread_count}-#{msg_count}")
      producer_manager.send('address1', obj)
      sleep 1
    end
  end
end
(6..10).each do |i|
  threads << Thread.new(i) do |thread_count|
    msg_count = 0
    while !$stopped
      msg_count += 1
      obj = {:thread => thread_count, :message => msg_count}
      producer_manager.send('address2', obj)
      sleep 2
    end
  end
end

threads.each { |thread| thread.join }