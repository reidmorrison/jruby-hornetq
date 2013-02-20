# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'yaml'
require 'hornetq'

class LoggingTest < Test::Unit::TestCase
  context 'Without Connection' do
    def log_it
      HornetQ::logger.error 'Hello'
      HornetQ::logger.warn 'Hello'
      HornetQ::logger.info 'Hello'
      HornetQ::logger.debug 'Hello'
      HornetQ::logger.trace 'Hello'
    end

    should 'be able to use the default HornetQ logger' do
      # Reset logger to HornetQ logger
      HornetQ::logger = nil
      log_it
    end

    should 'be able to use the default HornetQ Ruby logger' do
      HornetQ::logger = HornetQ::ruby_logger
      log_it
    end

  end
end