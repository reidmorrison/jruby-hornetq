#
# HornetQ Consumer:
#          Read a single message from the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# Using Connect.start since a session must be started in order to consume messages
HornetQ::Client::Connection.start_session('hornetq://localhost') do |session|

  # Create a non-durable TestQueue to receive messages sent to the TestAddress
  session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)

  # Consume All messages from the queue and gather statistics
  stats = session.consume(:queue_name => 'TestQueue', :timeout=> 0, :statistics=>true) do |message|
    p message
    puts "=================================="
    message.acknowledge
  end
  puts "Consumed #{stats[:count]} messages in #{stats[:duration]} seconds at #{stats[:messages_per_second]} messages per second"
end
