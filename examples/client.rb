#
# HornetQ Requestor:
#      Submit a request and wait for a reply
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'yaml'
require 'hornetq'

count = (ARGV[0] || 1).to_i
timeout = (ARGV[1] || 30000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Create a HornetQ session
HornetQClient::Factory.create_session(config) do |session|
  #session.create_queue('Example', 'Example', true)
  requestor = session.create_requestor('jms.queue.ExampleQueue')
  session.start
  start_time = Time.now

  puts "Sending messages"
  count.times do |i|
    message = session.create_message(HornetQClient::Message::TEXT_TYPE,false)
    # Set the message body text
    message << "Request Current Time"
    # Set the user managed message id
    message.user_id = Java::org.hornetq.utils::UUIDGenerator.getInstance.generateUUID
    # Send message to the queue
    puts "Sending Request"
    if reply = requestor.request(message, timeout)
      puts "Received Response: #{reply.inspect}"
      puts "  Message:[#{reply.body.inspect}]"
      #print "."
    else
      puts "Time out, No reply received after #{timeout/1000} seconds"
    end
    #p message
    puts "#{i}" if i%1000 == 0
    puts "Durable" if message.durable
  end
  
  requestor.close
  duration = Time.now - start_time
  puts "\nDelivered #{count} messages in #{duration} seconds at #{count/duration} messages per second"
end
