# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'yaml'
require 'hornetq'

class RubyLoggingTest < Test::Unit::TestCase
  context 'Without Connection' do
    
    should 'be able to use Ruby logger' do
      require 'logger'
      l = Logger.new(STDOUT)
      l.level = Logger::DEBUG
      HornetQ::logger=l
      HornetQ::logger.info 'Hello'
    end
    
  end
end