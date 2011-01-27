#!/usr/bin/env jruby
#
# HornetQ Producer:
#          Write messages to the queue
#

require 'rubygems'
require 'yaml'
require 'hornetq'

count = (ARGV[0] || 1).to_i
config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')
constants = config['constants']

# Create a HornetQ session
HornetQ::Client::Factory.session(config['client']) do |session|
  session.delete_queue(constants[:queue]) rescue nil
  session.create_queue(constants[:address], constants[:queue], constants[:durable])
  producer = session.create_producer(constants[:address])
  start_time = Time.now

  puts "Sending messages"
  (1..count).each do |i|
    message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, true)
    # Set the message body text
    message << "Message ##{i}"
    message.put_string_property(Java::org.hornetq.api.core.SimpleString.new(HornetQ::Client::Message::HDR_DUPLICATE_DETECTION_ID.to_s), Java::org.hornetq.api.core.SimpleString.new("uniqueid#{i}"))
    # Send message to the queue
    begin
      producer.send(message)
    rescue Java::org.hornetq.api.core.HornetQException => e
      puts "Received producer exception: #{e.message} with code=#{e.cause.code}"
      if e.cause.code == Java::org.hornetq.api.core.HornetQException::UNBLOCKED
        puts "Retrying the send"
        retry
      end
    end
    #puts message
    puts "#{i}\n" if i%1000 == 0
  end

  duration = Time.now - start_time
  puts "Delivered #{count} messages in #{duration} seconds at #{count/duration} messages per second"
end
