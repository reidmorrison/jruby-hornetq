#
# HornetQ Consumer:
#      Reply to a request
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

timeout = (ARGV[0] || 60000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Create a HornetQ session
HornetQ::Client::Connection.start_session(config) do |session|
  # Create a non-durable ServerQueue to receive messages sent to the ServerAddress
  session.create_queue_ignore_exists('ServerAddress', 'ServerQueue', false)

  count = 0
  start_time = Time.now

  session.server('ServerQueue', timeout) do |server|
    puts "Server started and waiting for requests ..."
    server.run do |request_message|
      count += 1
      print '.'
      puts "#{count}" if count%1000 == 0

      # Create Reply Message
      reply_message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
      reply_message.body = "Echo [#{request_message.body}]"

      # The result of this block is the message to be sent back to the requestor (client)
      # Or, nil if no response should be sent back
      reply_message
    end
  end

  duration = Time.now - start_time - timeout/1000
  puts "\nReceived #{count} requests in #{duration} seconds at #{count/duration} messages per second"
end
