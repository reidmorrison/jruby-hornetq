#
# HornetQ Consumer:
#          Read a single message from the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

timeout = (ARGV[0] || 60000).to_i

# Using Connect.start since a session must be started in order to consume messages
HornetQ::Client::Connection.connection('hornetq://localhost') do |connection|
  
  # Create a non-durable TestQueue to receive messages sent to the TestAddress
  connection.session do |session|
    session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)
  end
  
  # Consume All messages from the queue and gather statistics
  connection.on_message(:queue_name => 'TestQueue', :statistics=>true) do |message|
    p message
    puts "=================================="
    message.acknowledge
  end
  
  puts "Started and waiting for messages"
  # Wait for timeout period
  sleep(timeout/1000)
  connection.on_message_statistics.each do |stats|
    puts "Received #{stats[:count]} messages in #{stats[:duration]} seconds at #{stats[:messages_per_second]} messages per second"
  end
end
