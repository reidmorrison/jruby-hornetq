#
# HornetQ Consumer:
#          Write messages to the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

timeout = (ARGV[0] || 1000).to_i
env = ARGV[1] || 'development'
config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')[env]

# Create a HornetQ session
HornetQ::Client::Factory.create_session(config) do |session|
  consumer = session.create_consumer('jms.queue.ExampleQueue')
  session.start
  
  count = 0
  start_time = Time.now
  while message = consumer.receive(timeout)
    count = count + 1
    message.acknowledge
    puts "=================================="
    text = message.body
    p text
    p message
    puts "Durable" if message.durable
    # Redirect stdout to /dev/null if you just want count updates
    $stderr.puts "#{count}\n" if count%1000 == 0
  end
  duration = Time.now - start_time - timeout/1000
  puts "Received #{count} messages in #{duration} seconds at #{count/duration} messages per second"
end
