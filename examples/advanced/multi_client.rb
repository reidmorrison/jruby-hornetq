#
# HornetQ Requestor:
#      Multithreaded clients all doing requests
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

timeout = (ARGV[0] || 30000).to_i
thread_count = (ARGV[1] || 2).to_i
request_count = (ARGV[2] || 5).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Sample thread that does some work and then does a request-response call
def worker_thread(id, connection, timeout, request_count)
  begin
    connection.start_session do |session|
      start_time = Time.now

      # Use Requestor (Client) Pattern to do a "RPC like" call to a server
      # Under the covers the requestor creates a temporary dynamic reply to queue
      # for the server to send the reply message to
      session.requestor('ServerAddress') do |requestor|
        # Create non-durable message
        puts "Sending #{request_count} requests"
        (1..request_count).each do |i|
          message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
          message.body = "Some request data"
          # Set the user managed message id
          message.user_id = Java::org.hornetq.utils::UUIDGenerator.getInstance.generateUUID

          if reply = requestor.request(message, timeout)
            puts "Thread[#{id}]:Received Response: #{reply.inspect}" if request_count < 10
            puts "Thread[#{id}]:  Message:[#{reply.body.inspect}]" if request_count < 10
            print ".#{id}" if request_count >= 10
          else
            puts "Thread[#{id}]:Time out, No reply received after #{timeout/1000} seconds"
          end
          puts "Thread:#{id}=>#{i}" if i%1000 == 0
        end
      end

      duration = Time.now - start_time
      puts "\nThread[#{id}]:Made #{request_count} calls in #{duration} seconds at #{request_count/duration} synchronous requests per second"
    end

  rescue Exception => exc
    puts "Thread[#{id}]: Terminating due to Exception:#{exc.inspect}"
    puts exc.backtrace
  end
  puts "Thread[#{id}]: Complete"
end

# Create a HornetQ Connection
HornetQ::Client::Connection.connection(config[:connection]) do |connection|
  threads = []

  # Start threads passing in an id and the connection so that the thread
  # can create its own session
  thread_count.times do |i|
    threads << Thread.new { worker_thread(i, connection, timeout, request_count) }
  end
  # Since each thread will terminate once it has completed its required number
  # of requests, we can just wait for all the threads to terminate
  threads.each {|t| t.join}
end