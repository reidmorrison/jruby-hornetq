module HornetQ
  module Server
    # Only load as needed
    def self.load_requirements
      HornetQ.require_jar 'hornetq-core'
      HornetQ.require_jar 'netty'
      require 'hornetq/server/org_hornetq_core_server_hornet_q_server'
    end

    def self.create_server(params={})
      self.load_requirements

      if params.kind_of?(String)
        uri = HornetQ::URI.new(params)
        params = uri.params
      else
        raise "Missing :uri param in HornetQ::Server.create_server" unless params[:uri]
        uri = HornetQ::URI.new(params.delete(:uri))
        # params override uri params
        params = uri.params.merge(params)
      end
      config = Java::org.hornetq.core.config.impl.ConfigurationImpl.new
      data_directory = params.delete(:data_directory) || HornetQ::DEFAULT_DATA_DIRECTORY
      config.paging_directory = "#{data_directory}/paging"
      config.bindings_directory = "#{data_directory}/bindings"
      config.journal_directory = "#{data_directory}/journal"
      config.large_messages_directory = "#{data_directory}/large-messages"

      if uri.host == 'invm'
        acceptor = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::INVM_ACCEPTOR_CLASS_NAME)
        config.persistence_enabled = false
        config.security_enabled    = false
      else
        acceptor = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_ACCEPTOR_CLASS_NAME, {'host' => uri.host, 'port' => uri.port })
        connector = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.host, 'port' => uri.port })
        connector_conf_map = java.util.HashMap.new
        connector_conf_map.put('netty-connector', connector)
        config.connector_configurations = connector_conf_map
      end
      acceptor_conf_set = java.util.HashSet.new
      acceptor_conf_set.add(acceptor)
      config.acceptor_configurations = acceptor_conf_set

      if Java::org.hornetq.core.journal.impl.AIOSequentialFileFactory.isSupported
        config.journal_type = Java::org.hornetq.core.server.JournalType::ASYNCIO
      else
        require 'rbconfig'
        if Config::CONFIG['target_os'] == 'linux'
          HornetQ.logger.info("AIO wasn't located on this platform, it will fall back to using pure Java NIO. Install LibAIO to enable the AIO journal")
        end
        config.journal_type = Java::org.hornetq.core.server.JournalType::NIO
      end

      if params[:backup]
        HornetQ.logger.info "Creating backup server"
        config.backup = true
        config.shared_store = false
      elsif uri.backup_host
        HornetQ.logger.info "Creating live server"
        #backup_params.put('reconnectAttempts', -1)
        backup_connector = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.backup_host, 'port' => uri.backup_port })
        connector_conf_map.put('backup-connector', backup_connector)
        config.backup_connector_name = 'backup-connector'
      elsif uri.host == 'invm'
        HornetQ.logger.info 'Creating invm server'
      else
        HornetQ.logger.info 'Creating standalone server'
      end

      params.each_pair do |key, val|
        method = key.to_s+'='
        if config.respond_to? method
          config.send method, val
          #HornetQ.logger.debug "#{key} = #{config.send key}" if config.respond_to? key.to_sym
        else
          HornetQ.logger.warn "Option:#{key} class=#{key.class} with value:#{val} is invalid and being ignored"
        end
      end

      return Java::org.hornetq.core.server.HornetQServers.newHornetQServer(config)
    end

    # Start a new server instance and stop it once the supplied block completes
    def self.start(params={}, &block)
      server = nil
      begin
        server = self.create_server(params)
        server.start
        block.call(server)
      ensure
        server.stop if server
      end
    end
  end
end
