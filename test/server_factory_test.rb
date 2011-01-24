require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'hornetq'
require 'fileutils'

class ServerFactoryTest < Test::Unit::TestCase
  context 'standalone server' do
    setup do
      @server       = nil
      @tmp_data_dir = "/tmp/data_dir/#{$$}"
      @uri          = "hornetq://localhost:15445/?data_directory=#{@tmp_data_dir}"
      @server_thread = Thread.new do
        @server = HornetQ::Server::Factory.create_server(@uri)
        @server.start
      end
      # Give the server time to startup
      sleep 5
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
        session.create_queue(queue_name, queue_name, true)
        producer = session.create_producer(queue_name)
        (1..count).each do |i|
          message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
          message.durable = true
          # Set the message body text
          message << "Message ##{i}"
          # Send message to the queue
          producer.send(message)
        end
      end

      HornetQ::Client::Factory.create_session(config) do |session|
        consumer = session.create_consumer(queue_name)
        session.start

        i = 0
        while message = consumer.receive(1000)
          i += 1
          message.acknowledge
          assert_equal "Message ##{i}", message.body
        end
      end
    end
  end

  context 'live and backup server' do
    setup do
      @server              = nil
      @tmp_data_dir        = "/tmp/data_dir/#{$$}"
      @uri                 = "hornetq://localhost:15445,localhost:15446/?data_directory=#{@tmp_data_dir}"

      @backup_server       = nil
      @backup_tmp_data_dir = "/tmp/data_dir/#{$$}"
      @backup_uri          = "hornetq://localhost:15446/?backup=true&data_directory=#{@backup_tmp_data_dir}"

      @backup_server_thread = Thread.new do
        @backup_server = HornetQ::Server::Factory.create_server(@uri)
        @backup_server.start
      end

      @server_thread = Thread.new do
        @server = HornetQ::Server::Factory.create_server(@uri)
        @server.start
      end

      # Give the servers time to startup
      sleep 5
    end

    teardown do
      @server.stop
      @server_thread.join
      @backup_server.stop
      @backup_server.join
      FileUtils.rm_rf(@tmp_data_dir, @backup_tmp_data_dir)
    end

    should 'failover to backup server w/o message loss' do
      count      = 10
      queue_name = 'test_queue'
      config = {
        :connector => { :uri => @uri },
        :session   => { :username =>'guest', :password => 'guest'}
      }

      # Create a HornetQ session
      HornetQ::Client::Factory.create_session(config) do |session|
        session.create_queue(queue_name, queue_name, true)
        producer = session.create_producer(queue_name)
        (1..count).each do |i|
          message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
          message.durable = true
          # Set the message body text
          message << "Message ##{i}"
          # Send message to the queue
          producer.send(message)
        end
      end

      HornetQ::Client::Factory.create_session(config) do |session|
        consumer = session.create_consumer(queue_name)
        session.start

        i = 0
        while message = consumer.receive(1000)
          i += 1
          message.acknowledge
          assert_equal "Message ##{i}", message.body
        end
      end
    end
  end
end
