#
# HornetQ Requestor:
#      Submit a request and wait for a reply
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

count = (ARGV[0] || 1).to_i
timeout = (ARGV[1] || 30000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Create a HornetQ session
HornetQ::Client::Factory.session(config) do |session|
  #session.create_queue('Example', 'Example', true)
  requestor = session.create_requestor('jms.queue.ExampleQueue')
  session.start
  start_time = Time.now

  puts "Sending messages"
  (1..count).each do |i|
    message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
    # Set the message body text
    message.body = "Request Current Time"
    # Set the user managed message id
    message.user_id = Java::org.hornetq.utils::UUIDGenerator.getInstance.generateUUID
    # Send request message and wait for reply
    if reply = requestor.request(message, timeout)
      puts "Received Response: #{reply.inspect}" if count < 10
      puts "  Message:[#{reply.body.inspect}]" if count < 10
      print "." if count >= 10
    else
      puts "Time out, No reply received after #{timeout/1000} seconds"
    end
    puts "#{i}" if i%1000 == 0
    puts "Durable" if message.durable
  end
  
  requestor.close
  duration = Time.now - start_time
  puts "\nMade #{count} calls in #{duration} seconds at #{count/duration} messages per second"
end
