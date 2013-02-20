#
# HornetQ Batch Requestor:
#      Submit a batch of requests and wait for replies
#
# This is an advanced use case where the client submits requests in a controlled
# fashion. The alternative would be just to submit all requests at the same time,
# however then it becomes extremely difficult to pull back submitted requests
# if say 80% of the first say 100 requests fail.
#
# This sample sends a total of 100 requests in batches of 10.
# One thread sends requests and the other processes replies.
# Once 80% of the replies are back, it will send the next batch
#
# Before running this sample, start server.rb first
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'batch_requestor_pattern'

batch_size = (ARGV[0] || 100).to_i
window_size = (ARGV[1] || 10).to_i

server_address = 'ServerAddress'

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Create a HornetQ session
HornetQ::Client::Connection.connection(config[:connection]) do |connection|
  window_size = batch_size if window_size > batch_size
  # * :batch_size Total size of batch
  # * :window_size Size of the sliding window. This also indicates the maximimum
  #                number of outstanding requests to have open at any time
  #                Default: 0.8
  #                (:max_outstanding_responses)

  pattern_config = {
    :connection     => connection,
    :server_address => server_address,
    :completion_ratio => 0.8
  }

  requestor = BatchRequestorPattern.new(connection, server_address) do |message|
    # Display an @ symbol for every reply received
    print '@'
  end

  times = (batch_size/window_size).to_i
  puts "Performing #{times} loops"

  times.times do |i|

    window_size.times do |i|
      message = @session.create_message(true)
      message.type = :text
      message.body = "Request Current Time. #{i}"
      requestor.send(message)
      print "."
    end

    # Wait for at least 80% of responses before sending more requests
    requestor.wait_for_outstanding_replies

  end
  puts "Done sending requests, waiting for remaining replies"
  requestor.wait_for_all_outstanding_replies
  requestor.close
end
