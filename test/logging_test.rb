# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'yaml'
require 'hornetq'

class LoggingTest < Test::Unit::TestCase
  context 'Without Connection' do
    
    should 'be able to use the default HornetQ Ruby logger' do
      HornetQ::logger.info 'Hello'
    end
    
  end
end