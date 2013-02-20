# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'hornetq'
require 'yaml'

class ClientConnectionTest < Test::Unit::TestCase
  context 'Client Connection' do

    setup do
      # This test requires a hornetq running local on the default port
      @config = 'hornetq://localhost'
    end

    should 'Create Connection to the Server' do
      connection = HornetQ::Client::Connection.new(@config)
      #HornetQ::logger.info connection.to_s
      assert_not_nil connection
      connection.close
    end

    should 'Create and start Connection to the Server with block' do
      HornetQ::Client::Connection.connection(@config) do |connection|
        assert_not_nil connection
      end
    end

    should 'Create and start Connection to the Server with block and start one session' do
      HornetQ::Client::Connection.session(@config) do |session|
        assert_not_nil session
      end
    end

    should 'Start and stop connection' do
      # Connection is started when created
      connection = HornetQ::Client::Connection.new(@config)
      assert_not_nil connection
      assert_nil connection.close
    end

    should 'Create a session from the connection' do
      connection = HornetQ::Client::Connection.new(@config)
      session = connection.create_session
      assert_not_nil session

      assert_nil session.start

      assert_equal session.auto_commit_acks?, true
      assert_equal session.auto_commit_sends?, true
      assert_equal session.block_on_acknowledge?, false
      assert_equal session.closed?, false
      assert_equal session.rollback_only?, false
      assert_equal session.xa?, false

      assert_nil session.stop

      # Close the session
      assert_nil session.close
      assert_equal session.closed?, true

      assert_nil connection.close
    end

    should 'Create a session with a block' do
      connection = HornetQ::Client::Connection.new(@config)

      connection.session do |session|
        assert_not_nil session
        assert_equal session.auto_commit_acks?, true
        assert_equal session.auto_commit_sends?, true
        assert_equal session.block_on_acknowledge?, false
        assert_equal session.rollback_only?, false

        assert_equal session.xa?, false
        assert_equal session.closed?, false
      end

      assert_nil connection.close
    end

    should 'create a session without a block and throw exception' do
      connection = HornetQ::Client::Connection.new(@config)

      assert_raise(RuntimeError) { connection.session }

      assert_nil connection.close
    end

#    should 'Create a session from the connection with params' do
#      connection = HornetQ::Client::Connection.new(@config)
#
#      session_parms = {
#        :transacted => true,
#        :options => javax.jms.Session::AUTO_ACKNOWLEDGE
#      }
#
#      session = connection.create_session(session_parms)
#      assert_not_nil session
#      assert_equal session.transacted?, true
#      # When session is transacted, options are ignore, so ack mode must be transacted
#      assert_equal session.acknowledge_mode, javax.jms.Session::SESSION_TRANSACTED
#      assert_nil session.close
#
#      assert_nil connection.stop
#      assert_nil connection.close
#    end
#
#    should 'Create a session from the connection with block and params' do
#      HornetQ::Client::Connection.start_session(@config) do |connection|
#
#        session_parms = {
#          :transacted => true,
#          :options => javax.jms.Session::CLIENT_ACKNOWLEDGE
#        }
#
#        connection.session(session_parms) do |session|
#          assert_not_nil session
#          assert_equal session.transacted?, true
#          # When session is transacted, options are ignore, so ack mode must be transacted
#          assert_equal session.acknowledge_mode, javax.jms.Session::SESSION_TRANSACTED
#        end
#      end
#    end
#
#    should 'Create a session from the connection with block and params opposite test' do
#      HornetQ::Client::Connection.start_session(@config) do |connection|
#
#        session_parms = {
#          :transacted => false,
#          :options => javax.jms.Session::AUTO_ACKNOWLEDGE
#        }
#
#        connection.session(session_parms) do |session|
#          assert_not_nil session
#          assert_equal session.transacted?, false
#          assert_equal session.acknowledge_mode, javax.jms.Session::AUTO_ACKNOWLEDGE
#        end
#      end
#    end
#
#    context 'HornetQ::Client Connection additional capabilities' do
#
#      should 'start an on_message handler' do
#        HornetQ::Client::Connection.start_session(@config) do |connection|
#          value = nil
#          connection.on_message(:transacted => true, :queue_name => :temporary) do |message|
#            value = "received"
#          end
#        end
#      end
#
#    end

  end
end
