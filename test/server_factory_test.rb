require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'hornetq'
require 'fileutils'

class MyThread < ::Thread
  def initialize(name, &block)
    super() do
      begin
        yield
      rescue => e
        puts("Thread #{name} died due to exception #{e.message}\n#{e.backtrace.join("\n")}")
      end
    end
  end
end

class ServerFactoryTest < Test::Unit::TestCase
  context 'standalone server' do
    setup do
      @server       = nil
      @tmp_data_dir = "/tmp/data_dir/#{$$}"
      @uri          = "hornetq://localhost:15445"
      @server_thread = MyThread.new('standalone server') do
        @server = HornetQ::Server::Factory.create_server(:uri => @uri, :data_directory => @tmp_data_dir)
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
      HornetQ::Client::Factory.session(config) do |session|
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

      HornetQ::Client::Factory.session(config) do |session|
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
      @count      = 20

      @server              = nil
      @tmp_data_dir        = "/tmp/data_dir/#{$$}"
      @uri                 = "hornetq://localhost:15445,localhost:15446"

      @backup_server       = nil
      @backup_tmp_data_dir = "/tmp/backup_data_dir/#{$$}"
      @backup_uri          = "hornetq://localhost:15446"

      @backup_server_thread = MyThread.new('backup server') do
        begin
          @backup_server = HornetQ::Server::Factory.create_server(:uri => @backup_uri, :data_directory => @backup_tmp_data_dir, :backup => true)
          @backup_server.start
        rescue Exception => e
          puts "Error in backup server thread: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end
      # Give the backup server time to startup
      sleep 10

      @server_thread = MyThread.new('live server') do
        begin
          @server = HornetQ::Server::Factory.create_server(:uri => @uri, :data_directory => @tmp_data_dir)
          @server.start
        rescue Exception => e
          puts "Error in live server thread: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end

      # Give the live server time to startup
      sleep 10

      @queue_name = 'test_queue'
      @config = {
        :connector => {
          :uri                            => @uri,
          :failover_on_initial_connection => true,
          :failover_on_server_shutdown    => true,
        },
        :session   => { :username =>'guest', :password => 'guest'}
      }

      @killer_thread = MyThread.new('killer') do
        sleep 5
        @server.stop
      end

      @producer_thread = MyThread.new('producer') do
        # Create a HornetQ session
        HornetQ::Client::Factory.session(@config) do |session|
          session.create_queue(@queue_name, @queue_name, true)
          producer = session.create_producer(@queue_name)
          (1..@count).each do |i|
            message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, true)
            # Set the message body text
            message << "Message ##{i}"
            # Send message to the queue
            begin
              puts "Producing message: #{message.body}"
              producer.send(message)
              sleep 1
            rescue Java::org.hornetq.api.core.HornetQException => e
              puts "Received producer exception: #{e.message} with code=#{e.cause.code}"
              if e.cause.getCode == Java::org.hornetq.api.core.HornetQException::UNBLOCKED
                puts "Retrying the send"
                retry
              end
            rescue Exception => e
              puts "Received producer exception: #{e.message}"
            end
          end
        end
      end
    end

    teardown do
      @server.stop
      @backup_server.stop
      [ @server_thread, @backup_server_thread, @killer_thread, @producer_thread ].each do |thread|
        thread.join
      end
      FileUtils.rm_rf([@tmp_data_dir, @backup_tmp_data_dir])
    end

    should 'failover to backup server w/o message loss' do
      # Let the producer create the queue
      sleep 2
      HornetQ::Client::Factory.session(@config) do |session|
        consumer = session.create_consumer(@queue_name)
        session.start

        i = 0
        while message = consumer.receive(1000)
          i += 1
          message.acknowledge
          assert_equal "Message ##{i}", message.body
          puts "Consuming message #{message.body}"
        end
        assert_equal @count, i
      end

      killer_thread.join
      producer_thread.join
    end
  end
end
