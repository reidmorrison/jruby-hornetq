#!/usr/bin/env jruby
#
# HornetQ Producer:
#          Write messages to the queue
#

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'logger'
require 'json'
require 'test_object'

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
client = config['client']

# Create a HornetQ session
logger = Logger.new($stdout)
factory = HornetQ::Client::Factory.new(client[:connector])
session_pool = factory.create_session_pool(client[:session_pool])

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
      session_pool.producer('address1') do |session, producer|
        message = session.create_message(HornetQ::Client::Message::BYTES_TYPE, true)
        message.body = Marshal.dump(obj)
        message['format'] = 'ruby_marshal'
        puts "Sending on address1 #{obj.inspect}"
        producer.send(message)
      end
      # session_pool.send('address1', obj, :persistent => true, :format => :ruby_marshal)
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
      session_pool.producer('address2') do |session, producer|
        message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
        message.body = obj.to_json
        message['format'] = 'json'
        puts "Sending on address2 #{obj.inspect}"
        producer.send(message)
      end
      # session_pool.send('address2', obj, :persistent => false, :format => :json)
      sleep 2
    end
  end
end

threads.each { |thread| thread.join }