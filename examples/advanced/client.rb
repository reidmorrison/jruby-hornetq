#
# HornetQ Requestor:
#      Submit a request and wait for a reply
#      Uses the Requestor Pattern
#
#      The Server (server.rb) must be running first, otherwise this example
#      program will eventually timeout
#      Displays a '.' for every request completed
#      Used for performance measurements
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
HornetQ::Client::Connection.start_session(config) do |session|
  # Create a non-durable ServerQueue to receive messages sent to the ServerAddress
  session.create_queue_ignore_exists('ServerAddress', 'ServerQueue', false)
  start_time = Time.now

  # Use Requestor (Client) Pattern to do a "RPC like" call to a server
  # Under the covers the requestor creates a temporary dynamic reply to queue
  # for the server to send the reply message to
  session.requestor('ServerAddress') do |requestor|
    # Create non-durable message
    puts "Sending #{count} requests"
    (1..count).each do |i|
      message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
      message.body = "Some request data"
      # Set the user managed message id
      message.user_id = Java::org.hornetq.utils::UUIDGenerator.getInstance.generateUUID

      if reply = requestor.request(message, timeout)
        puts "Received Response: #{reply.inspect}" if count < 10
        puts "  Message:[#{reply.body.inspect}]" if count < 10
        print "." if count >= 10
      else
        puts "Time out, No reply received after #{timeout/1000} seconds"
      end
      puts "#{i}" if i%1000 == 0

    end
  end

  duration = Time.now - start_time
  puts "\nMade #{count} calls in #{duration} seconds at #{count/duration} synchronous requests per second"
end
