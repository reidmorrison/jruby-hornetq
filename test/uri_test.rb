require 'rubygems'
require 'test/unit'
require 'test_helper'
require 'shoulda'
require 'hornetq'

class URITest < Test::Unit::TestCase
  context '' do
    setup do
    end

    should 'parse simple uri' do
      uri = HornetQ::URI.new('hornetq://1.2.3.4')
      assert_equal 'hornetq', uri.scheme
      assert_equal '1.2.3.4', uri.host
      assert_equal HornetQ::DEFAULT_NETTY_PORT, uri.port
      assert_nil   uri.backup_host
      assert_equal '/', uri.path
      assert_equal false, uri.backup?
    end

    should 'reject invalid scheme' do
      e = assert_raises Exception do
        HornetQ::URI.new('foo://1.2.3.4')
        conn.fail_on(1,2)
      end
      assert_match %r%scheme%, e.message
    end

    should 'parse with settings' do
      uri = HornetQ::URI.new('hornetq://foobar:1234/zulu?data_directory=../abc&myval=def')
      assert_equal 'hornetq', uri.scheme
      assert_equal 'foobar', uri.host
      assert_equal HornetQ.netty_port(1234), uri.port
      assert_nil   uri.backup_host
      assert_equal '/zulu', uri.path
      assert_equal '../abc', uri['data_directory']
      assert_equal false, uri.backup?
      assert_equal 'def', uri['myval']
    end

    should 'parse backup server' do
      uri = HornetQ::URI.new('hornetq://0.0.0.0:5446/?backup=true&data_directory=./data_backup')
      assert_equal 'hornetq', uri.scheme
      assert_equal '0.0.0.0', uri.host
      assert_equal HornetQ.netty_port(5446), uri.port
      assert_nil   uri.backup_host
      assert_equal '/', uri.path
      assert_equal './data_backup', uri['data_directory']
      assert_equal true, uri.backup?
    end

    should 'parse live server with backup specified' do
      uri = HornetQ::URI.new('hornetq://0.0.0.0,hornetq_backup')
      assert_equal 'hornetq', uri.scheme
      assert_equal '0.0.0.0', uri.host
      assert_equal HornetQ::DEFAULT_NETTY_PORT, uri.port
      assert_equal 'hornetq_backup', uri.backup_host
      assert_equal HornetQ::DEFAULT_NETTY_PORT, uri.backup_port
      assert_equal '/', uri.path
      assert_equal false, uri.backup?
    end

    should 'parse live server with backup and ports specified' do
      uri = HornetQ::URI.new('hornetq://0.0.0.0:4321,hornetq_backup:4322')
      assert_equal 'hornetq', uri.scheme
      assert_equal '0.0.0.0', uri.host
      assert_equal HornetQ.netty_port(4321), uri.port
      assert_equal 'hornetq_backup', uri.backup_host
      assert_equal HornetQ.netty_port(4322), uri.backup_port
      assert_equal '/', uri.path
      assert_equal false, uri.backup?
    end
  end
end
