#!/usr/bin/env jruby
#
# HornetQ Consumer:
#          Write messages to the queue
#

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'test_object'

$config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
$client = $config['client']
factory = HornetQ::Client::Factory.new($client[:connector])
$consumer_manager = HornetQ::Client::ConsumerManager.new(factory, $client[:session], $client[:addresses])

['HUP', 'INT', 'TERM'].each do |signal_name|
  Signal.trap(signal_name) do
    puts "caught #{signal_name}"
    consumer_manager.close
  end
end

$threads = []
def create_workers(address, queue, count, sleep_time)
  address_config = $client[:addresses][address]
  queue_config = address_config[:queues][queue]
  (1..count).each do |i|
    $threads << Thread.new(i) do |thread_count|
      prefix = "#{address}-#{queue}-#{thread_count}"
      begin
        $consumer_manager.each(address,queue) do |obj|
          puts "#{prefix} read #{obj.inspect}"
          sleep sleep_time
        end
        puts "#{prefix} end of thread"
      rescue Exception => e
        puts "#{prefix} Exception: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end

create_workers('address1', 'queue1_1', 5, 1)
create_workers('address1', 'queue1_2', 5, 2)
create_workers('address2', 'queue2_1', 5, 2)
create_workers('address2', 'queue2_2', 5, 1)

$threads.each { |thread| thread.join }
