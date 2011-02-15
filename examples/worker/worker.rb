#!/usr/bin/env jruby
#
# HornetQ Worker:
#          Creates multiple threads for processing of messages.
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'test_object'
require 'json'

$config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
$client_config = $config['client']
$session_config = $client_config[:session]
$factory = HornetQ::Client::Factory.new($client_config[:connector])

['HUP', 'INT', 'TERM'].each do |signal_name|
  Signal.trap(signal_name) do
    puts "caught #{signal_name}"
    $factory.close
  end
end

$threads = []
def create_workers(address, queue, count, sleep_time, is_durable, &block)
  (1..count).each do |i|
    session = $factory.create_session($session_config)
    puts "Creating queue address=#{address} queue=#{queue}" if i==1
    session.create_queue_ignore_exists(address, queue, is_durable) if i == 1
    $threads << Thread.new(i, session) do |thread_count, session|
      prefix = "#{address}-#{queue}-#{thread_count}"
      begin
        consumer = session.create_consumer(queue)
        session.start
        puts "#{prefix} waiting for message"
        while msg = consumer.receive
          case msg['format']
            when 'json'
              object = JSON::Parser.new(msg.body).parse
            when 'ruby_marshal'
              object =  Marshal.load(msg.body)
            else
              object = msg.body
          end
          puts "#{prefix} read #{object.inspect}"
          sleep sleep_time
        end
        puts "#{prefix} end of thread"
      rescue Java::org.hornetq.api.core.HornetQException => e
        if e.cause.code != Java::org.hornetq.api.core.HornetQException::OBJECT_CLOSED
          puts "#{prefix} HornetQException: #{e.message}\n#{e.backtrace.join("\n")}"
        else
          # Normal exit
        end
      rescue Exception => e
        puts "#{prefix} Exception: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end

create_workers('address1', 'address1', 5, 1, false)
create_workers('address1', 'queue1_1', 5, 1, false)
create_workers('address1', 'queue1_2', 5, 2, true)
create_workers('address2', 'queue2_1', 5, 2, true)
create_workers('address2', 'queue2_2', 5, 1, false)

$threads.each { |thread| thread.join }
