#
# HornetQ Consumer:
#          Multi-threaded Consumer
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

# Arguments: 'number of threads' 'timeout'
$thread_count = (ARGV[0] || 3).to_i
$timeout = (ARGV[1] || 1000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

def worker(id, session)
  begin
    consumer = session.create_consumer('jms.queue.ExampleQueue')
    session.start
  
    count = 0
    start_time = Time.now
    while message = consumer.receive($timeout)
      count = count + 1
      message.acknowledge
      #puts "=================================="
      #text = message.body
      #p text
      #p message
      puts "Durable" if message.durable
      print "#{id}."
    end
    duration = Time.now - start_time - $timeout/1000
    puts "\nReceived #{count} messages in #{duration} seconds at #{count/duration} messages per second"
  rescue Exception => exc
    puts "Thread #{id} Terminating"
    p exc
  ensure
    session.close
  end
end

# Create a HornetQ session
HornetQClient::Factory.create_factory(config[:connector]) do |factory|
  threads = []
  $thread_count.times do |i|
    session = factory.create_session(config[:session])
    threads << Thread.new { worker(i, session) }
  end
  threads.each {|t| t.join}
end
