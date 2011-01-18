#!/usr/bin/env jruby

raise 'Environment variable HORNETQ_HOME not set' unless ENV['HORNETQ_HOME']
require "#{ENV['HORNETQ_HOME']}/lib/hornetq-core.jar"
require "#{ENV['HORNETQ_HOME']}/lib/netty.jar"

backup_host = ARGV[0]
is_backup = backup_host.nil?

config = Java::org.hornetq.core.config.impl.ConfigurationImpl.new
config.persistence_enabled = false
config.security_enabled = false
config.paging_directory = '../data/paging'
config.bindings_directory = '../data/bindings'
config.journal_directory = '../data/journal'
config.journal_min_files = 10
config.large_messages_directory = '../data/large-messages'

if Java::org.hornetq.core.journal.impl.AIOSequentialFileFactory.isSupported
  config.journal_type = Java::org.hornetq.core.server.JournalType::ASYNCIO
else
  puts("AIO wasn't located on this platform, it will fall back to using pure Java NIO. If your platform is Linux, install LibAIO to enable the AIO journal");
  config.journal_type = Java::org.hornetq.core.server.JournalType::NIO
end

netty_acceptor_class_name = Java::org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory.java_class.name
netty_connector_class_name = Java::org.hornetq.core.remoting.impl.netty.NettyConnectorFactory.java_class.name

transport_conf_params = java.util.HashMap.new
transport_conf_params.put('host', '0.0.0.0')
transport_conf_params.put('port', 5445)
transport_conf = Java::org.hornetq.api.core.TransportConfiguration.new(netty_acceptor_class_name, transport_conf_params);

transport_conf_set = java.util.HashSet.new
transport_conf_set.add(transport_conf)

config.acceptor_configurations = transport_conf_set

if is_backup
  puts "backup"
  config.backup = true
  config.shared_store = false
else
  puts "live"
  backup_params = java.util.HashMap.new
  backup_params.put('host', backup_host)
  backup_params.put('port', 5445)
  #backup_params.put('reconnectAttempts', -1)
  backup_connector_conf = Java::org.hornetq.api.core.TransportConfiguration.new(netty_connector_class_name, backup_params);
  
  connector_conf_map = java.util.HashMap.new
  connector_conf_map.put('backup-connector', backup_connector_conf)
  
  config.connector_configurations = connector_conf_map
  config.backup_connector_name = 'backup-connector'
end

server = Java::org.hornetq.core.server.HornetQServers.newHornetQServer(config)
server.start
