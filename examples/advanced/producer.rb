#
# HornetQ Producer:
#          Write messages to the queue
#          This example will display the message count after every 1000
#          messages written to the address
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

count = (ARGV[0] || 1).to_i
config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Create a HornetQ session
HornetQ::Client::Connection.session(config) do |session|
  # Create a non-durable TestQueue to receive messages sent to the TestAddress
  session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)
  start_time = Time.now

  session.producer('TestAddress') do |producer|
    puts "Sending messages"
    (1..count).each do |i|
      message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
      message.body = "#{Time.now}: ### Hello, World ###"
      message.body = "#{Time.now}: #{i} : ### Hello, World ###"
      message.user_id = Java::org.hornetq.utils::UUIDGenerator.getInstance.generateUUID

      producer.send(message)
      puts "#{i}\n" if i%1000 == 0
    end
  end

  duration = Time.now - start_time
  puts "Delivered #{count} messages in #{duration} seconds at #{count/duration} messages per second"
end
