module HornetQ::Server

  class Factory
    def self.load_requirments
    end

    def self.create_server(server_config)
      HornetQ::Server.load_requirements

      data_directory = server_config['data_directory'] || './data'
      host = server_config['host'] || 'localhost'
      port = server_config['port'] || 5445

      config = Java::org.hornetq.core.config.impl.ConfigurationImpl.new
      config.persistence_enabled = false
      config.security_enabled = false
      config.paging_directory = "#{data_directory}/paging"
      config.bindings_directory = "#{data_directory}/bindings"
      config.journal_directory = "#{data_directory}/journal"
      config.journal_min_files = 10
      config.large_messages_directory = "#{data_directory}/large-messages"

      if Java::org.hornetq.core.journal.impl.AIOSequentialFileFactory.isSupported
        config.journal_type = Java::org.hornetq.core.server.JournalType::ASYNCIO
      else
        puts("AIO wasn't located on this platform, it will fall back to using pure Java NIO. If your platform is Linux, install LibAIO to enable the AIO journal");
        config.journal_type = Java::org.hornetq.core.server.JournalType::NIO
      end

      netty_acceptor_class_name = Java::org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory.java_class.name
      netty_connector_class_name = Java::org.hornetq.core.remoting.impl.netty.NettyConnectorFactory.java_class.name

      transport_conf_params = java.util.HashMap.new
      transport_conf_params.put('host', host)
      transport_conf_params.put('port', java.lang.Integer.new(port))
      transport_conf = Java::org.hornetq.api.core.TransportConfiguration.new(netty_acceptor_class_name, transport_conf_params);

      transport_conf_set = java.util.HashSet.new
      transport_conf_set.add(transport_conf)

      config.acceptor_configurations = transport_conf_set

      if server_config['backup']
        puts "backup"
        config.backup = true
        config.shared_store = false
      elsif server_config['backup_host']
        puts "live"
        backup_params = java.util.HashMap.new
        backup_params.put('host', server_config['backup_host'])
        backup_port = server_config['backup_port'] || 5445
        backup_params.put('port', java.lang.Integer.new(backup_port))
        #backup_params.put('reconnectAttempts', -1)
        backup_connector_conf = Java::org.hornetq.api.core.TransportConfiguration.new(netty_connector_class_name, backup_params)

        connector_conf_map = java.util.HashMap.new
        connector_conf_map.put('backup-connector', backup_connector_conf)

        config.connector_configurations = connector_conf_map
        config.backup_connector_name = 'backup-connector'
      else
        puts 'standalone'
      end

      return Java::org.hornetq.core.server.HornetQServers.newHornetQServer(config)
    end

  end
end
