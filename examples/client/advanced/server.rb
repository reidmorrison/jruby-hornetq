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
HornetQ::Client::Factory.create_session(config) do |session|
  server = session.create_server('jms.queue.ExampleQueue', timeout)
  session.start
  
  count = 0
  start_time = Time.now
  puts "Server started and waiting for requests ..."
  server.run do |request_message|
    count += 1
    print '.'
    puts "#{count}" if count%1000 == 0
    puts "Durable" if request_message.durable
    reply_message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
    reply_message << "Test Response"
    reply_message
  end
  
  duration = Time.now - start_time - timeout/1000
  puts "\nReceived #{count} requests in #{duration} seconds at #{count/duration} messages per second"
  
  server.close
end
