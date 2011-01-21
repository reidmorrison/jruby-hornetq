require 'uri'

module HornetQClient

  # Import Message Constants
  import Java::org.hornetq.api.core::Message

  # Netty Class name
  NETTY_CLASS_NAME ='org.hornetq.core.remoting.impl.netty.NettyConnectorFactory'
  INVM_CLASS_NAME = 'org.hornetq.core.remoting.impl.invm.InVMAcceptorFactory'
  DEFAULT_NETTY_PORT = 5445

  class Factory
    # Create a new Factory from which sessions can be created
    #
    # Parameters:
    # * a Hash consisting of one or more of the named parameters
    # * Summary of parameters and their default values
    #  HornetQClient::Factory.new(
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

    def initialize(parms={})
      raise "Missing :uri under :connector in config" unless uri = parms[:uri]
      # TODO: Support :uri as an array for cluster configurations

      scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI.split(uri)
      raise InvalidURIError,"bad URI(only scheme hornetq:// is supported): #{uri}" unless scheme == 'hornetq'
      backup_host = backup_port = nil

      # Check for multiple server names
      if registry
        host, backup_host = registry.split(',')
        host, port = host.split(':')
        backup_host, backup_port = backup_host.split(':')
      end

      # Extract settings passed in query
      settings = {}
      if query
        query.split(';').each do |i|
          key, value = i.split('=')
          settings[key] = value
        end
      end

      # Determine transport protocol
      factory = nil
      # In-VM Transport has no fail-over or additional parameters
      if host == 'invm'
        transport = Java::org.hornetq.api.core.TransportConfiguration.new(INVM_CLASS_NAME)
        factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
      elsif settings[:protocol]
        # Auto-Discovery just has a host name and port
        if settings[:protocol] == 'discovery'
          factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(host, port)
        elsif settings[:protocol] != 'netty'
          raise "Unknown HornetQ protocol:#{settings[:protocol]}"
        end
      end

      # Unless already created, then the factory will use the netty protocol
      unless factory
        # Primary Transport
        raise "Mandatory hostname missing in :uri" unless host
        port ||= DEFAULT_NETTY_PORT
        transport = Java::org.hornetq.api.core.TransportConfiguration.new(NETTY_CLASS_NAME, {'host' => host, 'port' => Java::java.lang.Integer.new(port)})

        # Check for backup server connection information
        if backup_host
          backup_port ||= DEFAULT_NETTY_PORT
          backup_transport = Java::org.hornetq.api.core.TransportConfiguration.new(NETTY_CLASS_NAME, {'host' => backup_host, 'port' => Java::java.lang.Integer.new(backup_port)})
          factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport, backup_transport)
        else
          factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
        end
      end

      # If any other options were supplied, apply them to the created Factory instance
      parms.each_pair do |key, val|
        next if key == :uri
        method = key.to_s+'='
        if factory.respond_to? method
          factory.send method, val
          #puts "Debug: #{key} = #{factory.send key}" if factory.respond_to? key.to_sym
        else
          puts "Warning: Option:#{key}, with value:#{val} is invalid and being ignored"
        end
      end

      @factory = factory
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
    #     factory = HornetQClient::Factory.new(:uri => 'hornetq://localhost/')
    #     session = factory.create_session
    #       ...
    #     session.close
    #     factory.close
    # * It is recommended to rather call HornetQClient::Factory.create_session
    #   so that all resouces are closed automatically
    #     HornetQClient::Factory.create_session(:uri => 'hornetq://localhost/') do |session|
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
    #     factory = HornetQClient::Factory.new(:uri => 'hornetq://localhost/')
    #     factory.create_session do |session|
    #
    #       # Create a new queue
    #       session.create_queue('Example', 'Example', true)
    #
    #       # Create a producer to send messages
    #       producer = session.create_producer('Example')
    #
    #       # Create a Text Message
    #       message = session.create_message(HornetQClient::Message::TEXT_TYPE,true)
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
    #     factory = HornetQClient::Factory.new(:uri => 'hornetq://localhost/')
    #     session = factory.create_session
    #
    #     # Create a new queue
    #     session.create_queue('Example', 'Example', true)
    #
    #     # Create a producer to send messages
    #     producer = session.create_producer('Example')
    #
    #     # Create a Text Message
    #     message = session.create_message(HornetQClient::Message::TEXT_TYPE,true)
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
    def create_session(parms={}, &proc)
      raise "HornetQClient Factory Already Closed" unless @factory
      if proc
        session = nil
        result = nil
        begin
          #session = @factory.create_session(true, true)
          session = @factory.create_session(
            parms[:username],
            parms[:password],
            parms[:xa] || false,
            parms[:auto_commit_sends].nil? ? true : parms[:auto_commit_sends],
            parms[:auto_commit_acks].nil? ? true : parms[:auto_commit_acks],
            parms[:pre_acknowledge] || false,
            parms[:ack_batch_size] || 1)
          result = proc.call(session)
        ensure
          session.close if session
        end
        result
      else
        @factory.create_session(
          parms[:username],
          parms[:password],
          parms[:xa] || false,
          parms[:auto_commit_sends].nil? ? true : parms[:auto_commit_sends],
          parms[:auto_commit_acks].nil? ? true : parms[:auto_commit_acks],
          parms[:pre_acknowledge] || false,
          parms[:ack_batch_size] || 1)
      end
    end

    # Create a Session pool
    def create_session_pool(parms={})
      SessionPool.new(self, parms)
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
    def self.create_session(parms={},&proc)
      raise "Missing mandatory code block" unless proc
      factory = nil
      session = nil
      begin
        factory = self.new(parms[:connector] || {})
        session = factory.create_session(parms[:session] || {}, &proc)
      ensure
        factory.close if factory
      end
    end
    
    # Call the supplied code block after creating a factory instance
    # See initialize for the parameter list
    # The factory is closed before returning
    # 
    # Returns the result of the code block
    def self.create_factory(parms={}, &proc)
      raise "Missing mandatory code block" unless proc
      factory = nil
      result = nil
      begin
        factory=self.new(parms)
        result = proc.call(factory)
      ensure
        factory.close
      end
      result
    end

  end
  
end