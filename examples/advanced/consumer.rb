#
# HornetQ Consumer:
#          Consumer messages from the Queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

timeout = (ARGV[0] || 1000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Create a HornetQ session
HornetQ::Client::Connection.start(config) do |session|
  
  # Create the non-durable TestQueue to receive messages sent to the TestAddress
  session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)
  
  # Consume All messages from the queue
  stats = session.consume(:queue_name => 'TestQueue', :timeout=> 0, :statistics=>true) do |message|
    message.acknowledge
    puts "=================================="
    text = message.body
    p text
    p message
  end
  puts "Received #{stats[:count]} messages in #{stats[:duration]} seconds at #{stats[:messages_per_second]} messages per second"
end
