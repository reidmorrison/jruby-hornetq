#
# HornetQ Consumer:
#          Use Connection::on_message to consume all messages in separate
#          threads so as not to block the main thread
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

sleep_time = (ARGV[0] || 60000).to_i
session_count = (ARGV[1] || 1).to_i

# Using Connect.start since a session must be started in order to consume messages
HornetQ::Client::Connection.connection('hornetq://localhost') do |connection|

  # Create a non-durable TestQueue to receive messages sent to the TestAddress
  connection.session do |session|
    session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)
  end

  # Consume All messages from the queue and gather statistics
  # on_message will call the supplied block for every message received in another
  # thread. As a result, the on_message call returns immediately!
  # Other work can be performed on this thread, or just a sleep as in this example
  #
  # :session_count can be used to spawn multiple consumers simultaneously, each
  # receiving messages simultaneously on their own threads
  connection.on_message(:queue_name    => 'TestQueue',
                        :session_count => session_count,
                        :statistics    => true) do |message|
    p message
    puts "=================================="
    message.acknowledge
  end

  puts "Started #{session_count} consumers, will wait for #{sleep_time/1000} seconds before shutting down"
  # Wait for sleep_time before shutting down the server
  sleep(sleep_time/1000)

  connection.on_message_statistics.each do |stats|
    puts "Received #{stats[:count]} messages in #{stats[:duration]} seconds at #{stats[:messages_per_second]} messages per second"
  end
end
