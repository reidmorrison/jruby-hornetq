#!/usr/bin/env jruby
#
# HornetQ Consumer:
#          Write messages to the queue
#

require 'rubygems'
require 'yaml'
require 'hornetq'

timeout = (ARGV[0] || 3000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
constants = config['constants']

# Create a HornetQ session
HornetQ::Client::Factory.create_session(config['client']) do |session|
  consumer = session.create_consumer(constants[:queue])
  session.start

  i = 0
  start_time = Time.now
  while message = consumer.receive(timeout)
    i += 1
    message.acknowledge
    expected_message = "Message ##{i}"
    if message.body != expected_message
      puts "Unexpected message: #{message.body} Expected: #{expected_message}"
      i = $1.to_i if message.body =~ /Message #(\d+)/
    end
    puts "#{i}\n" if i%1000 == 0
  end
  duration = Time.now - start_time - timeout/1000
  puts "Received #{i} messages in #{duration} seconds at #{i/duration} messages per second"
end
