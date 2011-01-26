require 'uri'

module HornetQ::Client

  class Factory
    # Create a new Factory from which sessions can be created
    #
    # Parameters:
    # * a Hash consisting of one or more of the named parameters
    # * Summary of parameters and their default values
    #  HornetQ::Client::Factory.new(
    #    :uri                            => 'hornetq://localhost',
    #    :ack_batch_size                 => ,
    #    :auto_group                     => ,
    #    :block_on_acknowledge           => ,
    #    :block_on_durable_send          => ,
    #    :block_on_non_durable_send      => ,
    #    :cache_large_messages_client    => ,
    #    :call_timeout                   => ,
    #    :client_failure_check_period    => ,
    #    :confirmation_window_size       => ,
    #    :connection_load_balancing_policy_class_name => ,
    #    :connection_ttl                 => ,
    #    :consumer_max_rate              => ,
    #    :consumer_window_size           => ,
    #    :discovery_address              => ,
    #    :discovery_initial_wait_timeout => ,
    #    :discovery_port                 => ,
    #    :discovery_refresh_timeout      => ,
    #    :failover_on_initial_connection => true,
    #    :failover_on_server_shutdown    => true,
    #    :group_id                       => ,
    #    :initial_message_packet_size    => ,
    #    :java_object                    => ,
    #    :local_bind_address             => ,
    #    :max_retry_interval             => ,
    #    :min_large_message_size         => ,
    #    :pre_acknowledge                => ,
    #    :producer_max_rate              => ,
    #    :producer_window_size           => ,
    #    :reconnect_attempts             => 1,
    #    :retry_interval                 => ,
    #    :retry_interval_multiplier      => ,
    #    :scheduled_thread_pool_max_size => ,
    #    :static_connectors              => ,
    #    :thread_pool_max_size           => ,
    #    :use_global_pools               =>
    #  )
    #
    # Mandatory Parameters
    # * :uri
    #   * The hornetq uri as to which server to connect with and which
    #     transport protocol to use. Format:
    #       hornetq://server:port,backupserver:port/?protocol=[netty|discover]
    #   * To use the default netty transport
    #       hornetq://server:port
    #   * To use the default netty transport and specify a backup server
    #       hornetq://server:port,backupserver:port
    #   * To use auto-discovery
    #       hornetq://server:port/?protocol=discovery
    #   * To use HornetQ within the current JVM
    #       hornetq://invm
    #
    # Optional Parameters
    # * :ack_batch_size
    # * :auto_group
    # * :block_on_acknowledge
    # * :block_on_durable_send
    # * :block_on_non_durable_send
    # * :cache_large_messages_client
    # * :call_timeout
    # * :client_failure_check_period
    # * :confirmation_window_size
    # * :connection_load_balancing_policy_class_name
    # * :connection_ttl
    # * :consumer_max_rate
    # * :consumer_window_size
    # * :discovery_address
    # * :discovery_initial_wait_timeout
    # * :discovery_port
    # * :discovery_refresh_timeout
    # * :failover_on_initial_connection
    # * :failover_on_server_shutdown
    # * :group_id
    # * :initial_message_packet_size
    # * :java_object
    # * :local_bind_address
    # * :max_retry_interval
    # * :min_large_message_size
    # * :pre_acknowledge
    # * :producer_max_rate
    # * :producer_window_size
    # * :reconnect_attempts
    # * :retry_interval
    # * :retry_interval_multiplier
    # * :scheduled_thread_pool_max_size
    # * :static_connectors
    # * :thread_pool_max_size
    # * :use_global_pools

    def initialize(params={})
      HornetQ::Client.load_requirements
      uri = nil
      # TODO: Support :uri as an array for cluster configurations
      if params.kind_of?(String)
        uri = HornetQ::URI.new(params)
        params = uri.params
      else
        raise "Missing :uri param in HornetQ::Server.create_server" unless params[:uri]
        uri = HornetQ::URI.new(params.delete(:uri))
        # params override uri params
        params = uri.params.merge(params)
      end
      
      @factory = nil
      # In-VM Transport has no fail-over or additional parameters
      if uri.host == 'invm'
        transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::INVM_CONNECTOR_CLASS_NAME)
        @factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
      elsif params[:protocol]
        # Auto-Discovery just has a host name and port
        if params[:protocol] == 'discovery'
          @factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(uri.host, uri.port)
        elsif params[:protocol] != 'netty'
          raise "Unknown HornetQ protocol:#{params[:protocol]}"
        end
      end

      # Unless already created, then the factory will use the netty protocol
      unless @factory
        # Primary Transport
        transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.host, 'port' => uri.port })

        # Check for backup server connection information
        if uri.backup_host
          backup_transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.backup_host, 'port' => uri.backup_port })
          @factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport, backup_transport)
        else
          @factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
        end
      end

      # If any other options were supplied, apply them to the created Factory instance
      params.each_pair do |key, val|
        next if key == :uri
        method = key.to_s+'='
        if @factory.respond_to? method
          @factory.send method, val
          #puts "Debug: #{key} = #{@factory.send key}" if @factory.respond_to? key.to_sym
        else
          puts "Warning: Option:#{key}, with value:#{val} is invalid and being ignored"
        end
      end
    end

    # Create a new HornetQ session
    # 
    # If a block is passed in the block will be passed the session as a parameter
    # and this method will return the result of the block. The session is
    # always closed once the proc completes
    # 
    # If no block is passed, a new session is returned and it is the responsibility
    # of the caller to close the session
    #
    # Note:
    # * The returned session MUST be closed once complete
    #     factory = HornetQ::Client::Factory.new(:uri => 'hornetq://localhost/')
    #     session = factory.create_session
    #       ...
    #     session.close
    #     factory.close
    # * It is recommended to rather call HornetQ::Client::Factory.create_session
    #   so that all resouces are closed automatically
    #     HornetQ::Client::Factory.create_session(:uri => 'hornetq://localhost/') do |session|
    #       ...
    #     end
    #
    # Returns:
    # * A new HornetQ ClientSession
    # * See org.hornetq.api.core.client.ClientSession for documentation on returned object
    #
    # Throws:
    # * NativeException
    # * ...
    # 
    # Example:
    #   require 'hornetq'
    #
    #   factory = nil
    #   begin
    #     factory = HornetQ::Client::Factory.new(:uri => 'hornetq://localhost/')
    #     factory.create_session do |session|
    #
    #       # Create a new queue
    #       session.create_queue('Example', 'Example', true)
    #
    #       # Create a producer to send messages
    #       producer = session.create_producer('Example')
    #
    #       # Create a Text Message
    #       message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,true)
    #       message << 'Hello World'
    #
    #       # Send the message
    #       producer.send(message)
    #     end
    #   ensure
    #     factory.close if factory
    #   end
    #
    # Example:
    #   require 'hornetq'
    #
    #   factory = nil
    #   session = nil
    #   begin
    #     factory = HornetQ::Client::Factory.new(:uri => 'hornetq://localhost/')
    #     session = factory.create_session
    #
    #     # Create a new queue
    #     session.create_queue('Example', 'Example', true)
    #
    #     # Create a producer to send messages
    #     producer = session.create_producer('Example')
    #
    #     # Create a Text Message
    #     message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,true)
    #     message.body_buffer.write_string('Hello World')
    #
    #     # Send the message
    #     producer.send(message)
    #   ensure
    #     session.close if session
    #     factory.close if factory
    #   end
    #
    # Parameters:
    # * a Hash consisting of one or more of the named parameters
    # * Summary of parameters and their default values
    #  factory.create_session(
    #   :username          => 'my_username',   # Default is no authentication
    #   :password          => 'password',      # Default is no authentication
    #   :xa                => false,
    #   :auto_commit_sends => true,
    #   :auto_commit_acks  => true,
    #   :pre_acknowledge   => false,
    #   :ack_batch_size    => 1
    #   )
    #
    # Mandatory Parameters
    # * None
    #
    # Optional Parameters
    # * :username
    #   * The user name. To create an authenticated session
    #
    # * :password
    #   * The user password. To create an authenticated session
    #
    # * :xa
    #   * Whether the session supports XA transaction semantics or not
    #
    # * :auto_commit_sends
    #   * true: automatically commit message sends
    #   * false: commit manually
    #
    # * :auto_commit_acks
    #   * true: automatically commit message acknowledgement
    #   * false: commit manually
    #
    # * :pre_acknowledge
    #   * true: to pre-acknowledge messages on the server
    #   * false: to let the client acknowledge the messages
    #   * Note: It is possible to pre-acknowledge messages on the server so that the
    #     client can avoid additional network trip to the server to acknowledge
    #     messages. While this increases performance, this does not guarantee
    #     delivery (as messages can be lost after being pre-acknowledged on the
    #     server). Use with caution if your application design permits it.
    #
    #  * :ack_batch_size
    #    * the batch size of the acknowledgements
    #
    def create_session(params={}, &proc)
      raise "HornetQ::Client::Factory Already Closed" unless @factory
      if proc
        session = nil
        result = nil
        begin
          session = @factory.create_session(
            params[:username],
            params[:password],
            params[:xa] || false,
            params[:auto_commit_sends].nil? ? true : params[:auto_commit_sends],
            params[:auto_commit_acks].nil? ? true : params[:auto_commit_acks],
            params[:pre_acknowledge] || false,
            params[:ack_batch_size] || 1)
          result = proc.call(session)
        ensure
          session.close if session
        end
        result
      else
        @factory.create_session(
          params[:username],
          params[:password],
          params[:xa] || false,
          params[:auto_commit_sends].nil? ? true : params[:auto_commit_sends],
          params[:auto_commit_acks].nil? ? true : params[:auto_commit_acks],
          params[:pre_acknowledge] || false,
          params[:ack_batch_size] || 1)
      end
    end

    # Create a Session pool
    # TODO Raise an exception when gene_pool is not available
    def create_session_pool(params={})
      require 'hornetq/client/session_pool'
      SessionPool.new(self, params)
    end
    
    # Close Factory connections
    def close
      @factory.close if @factory
      @factory = nil
    end

    # Create a new Factory and Session
    # 
    #  Creates a new factory and session, then passes the session to the supplied
    #  block. Upon completion the session and factory are both closed
    # See Factory::initialize and Factory::create_session for the list
    #  of parameters
    def self.create_session(params={},&proc)
      raise "Missing mandatory code block" unless proc
      factory = nil
      session = nil
      begin
        if params.kind_of?(String)
          # TODO: Support passing username and password from URI to Session
          factory = self.new(params)
          session = factory.create_session({}, &proc)
        else
          factory = self.new(params[:connector] || {})
          session = factory.create_session(params[:session] || {}, &proc)
        end
      ensure
        session.close if session
        factory.close if factory
      end
    end
    
    # Create a new Factory along with a Session, and then start the session
    # 
    #  Creates a new factory and session, then passes the session to the supplied
    #  block. Upon completion the session and factory are both closed
    # See Factory::initialize and Factory::create_session for the list
    #  of parameters
    def self.start(params={},&proc)
      create_session(params) do |session|
        session.start
        proc.call(session)
      end
    end
    
    # Call the supplied code block after creating a factory instance
    # See initialize for the parameter list
    # The factory is closed before returning
    # 
    # Returns the result of the code block
    def self.create_factory(params={}, &proc)
      raise "Missing mandatory code block" unless proc
      factory = nil
      result = nil
      begin
        factory=self.new(params)
        result = proc.call(factory)
      ensure
        factory.close
      end
      result
    end

  end
  
end