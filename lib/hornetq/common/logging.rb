# Add HornetQ logging capabilities
module HornetQ
  # Returns the logger being used by both HornetQ and jruby-hornetq
  def self.logger
    @logger ||= (rails_logger || default_logger)
  end

  # Replace the logger for both HornetQ and jruby-hornetq
  # TODO Directly support Log4J as logger since HornetQ has direct support for Log4J
  def self.logger=(logger)
    HornetQ::Client.load_requirements unless defined? Java::org.hornetq.core.logging::Logger
    @logger = logger
    # Also replace the HornetQ logger
    Java::org.hornetq.core.logging::Logger.setDelegateFactory(HornetQ::LogDelegateFactory.new)
    # TODO org.hornetq.core.logging.Logger.setDelegateFactory(org.hornetq.integration.logging.Log4jLogDelegateFactory.new)
  end

  private
  def self.rails_logger
    (defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger) ||
      (defined?(RAILS_DEFAULT_LOGGER) && RAILS_DEFAULT_LOGGER.respond_to?(:debug) && RAILS_DEFAULT_LOGGER)
  end

  # By default we use the HornetQ Logger
  def self.default_logger
    HornetQ::Client.load_requirements unless defined? Java::org.hornetq.core.logging::Logger
    Java::org.hornetq.core.logging::Logger.getLogger(org.hornetq.api.core.client::HornetQClient)
    #    require 'logger'
    #    l = Logger.new(STDOUT)
    #    l.level = Logger::INFO
    #    l
  end

end
