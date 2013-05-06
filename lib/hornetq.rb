include Java

module HornetQ

  # Netty Class name
  NETTY_CONNECTOR_CLASS_NAME = 'org.hornetq.core.remoting.impl.netty.NettyConnectorFactory'
  NETTY_ACCEPTOR_CLASS_NAME  = 'org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory'
  INVM_CONNECTOR_CLASS_NAME  = 'org.hornetq.core.remoting.impl.invm.InVMConnectorFactory'
  INVM_ACCEPTOR_CLASS_NAME   = 'org.hornetq.core.remoting.impl.invm.InVMAcceptorFactory'

  DEFAULT_NETTY_PORT     = java.lang.Integer.new(5445)
  DEFAULT_DATA_DIRECTORY = './data'

  # Allow override of our included jars so we don't have to keep up with hornetq releases
  def self.require_jar(jar_name)
    if ENV['HORNETQ_HOME']
      require "#{ENV['HORNETQ_HOME']}/lib/#{jar_name}.jar"
    else
      require "hornetq/java/#{jar_name}.jar"
    end
  end

  def self.netty_port(port)
    port ||= DEFAULT_NETTY_PORT
    return java.lang.Integer.new(port)
  end

  # Convert string into a HornetQ SimpleString
  def self.as_simple_string(str)
   str.is_a?(Java::org.hornetq.api.core::SimpleString) ? str : Java::org.hornetq.api.core::SimpleString.new(str.to_s)
  end

end

require 'hornetq/server'
require 'hornetq/client'
require 'hornetq/uri'
require 'hornetq/common/logging'
