require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'hornetq'
require 'fileutils'

class ServerFactoryTest < Test::Unit::TestCase
  context 'standalone server' do
    setup do
      @server = nil
      @tmp_data_dir = "/tmp/data_dir/#{$$}"
      @uri = "hornetq://localhost/?data_directory=#{@tmp_data_dir}"
      @server_thread = Thread.new do
        @server = HornetQ::Server::Factory.create_server(@uri)
        @server.start
      end
      # Give the server time to startup
      sleep 10
    end

    teardown do
      @server.stop
      @server_thread.join
      FileUtils.rm_rf(@tmp_data_dir)
    end

    should 'pass simple messages' do
      count      = 10
      queue_name = 'test_queue'
      config = {
        :connector => { :uri => @uri },
        :session   => { :username =>'guest', :password => 'guest'}
      }

      # Create a HornetQ session
      HornetQ::Client::Factory.create_session(config) do |session|
        #session.create_queue('Example', 'Example', true)
        producer = session.create_producer(queue_name)
        (1..count).each do |i|
          message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
          # Set the message body text
          message << "Message ##{count}"
          # Send message to the queue
          producer.send(message)
        end
      end

      # Create a HornetQ session
      HornetQ::Client::Factory.create_session(config) do |session|
        consumer = session.create_consumer(queue_name)
        session.start

        count = 0
        while message = consumer.receive(1000)
          count = count + 1
          message.acknowledge
          assert_equal "Message ##{count}", message.body
        end
      end
    end
  end
end
