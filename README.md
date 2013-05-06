jruby-hornetq
=============

* http://github.com/ClarityServices/jruby-hornetq

Feedback is welcome and appreciated :)

### Introduction

jruby-hornetq create a Ruby friendly API into the HornetQ Java libraries without
compromising performance. It does this by sprinkling "Ruby-goodness" into the
existing HornetQ Java classes and interfaces, I.e. By adding Ruby methods to
the existing classes and interfaces. Since jruby-hornetq exposes the HornetQ
Java classes directly there is no performance impact that would have been
introduced had the entire API been wrapped in a Ruby layer.

In this way, using regular Ruby constructs a Ruby program can easily
interact with HornetQ in a highly performant way

### Install

  gem install jruby-hornetq

### Important

jruby-hornetq exposes the HornetQ Core API, not its JMS API. There are
several reasons for choosing the HornetQ Core API over its JMS API:
* The Core API supports the use of Addresses, not just Queues
* The Core API exposes more capabilities than the JMS API (E.g. Management APIs)
* The HornetQ team recommend the Core API for performance
* The HornetQ JMS API is just another wrapper on top of its Core API

To use the JMS API from JRuby see the jruby-jms project

HornetQ
-------

For information on the HornetQ messaging and queuing system, see: http://www.jboss.org/hornetq

For more documentation on any of the classes, see: http://docs.jboss.org/hornetq/2.2.2.Final/api/index.html

Concepts & Terminology
----------------------

### Queue

In order to read messages a consumer needs to the read messages from a queue.
The queue is defined prior to the message being sent and is used to hold the
messages. The consumer does not have to be running in order to receive messages.

### Address

In traditional messaging and queuing systems there is only a queue when both
read and writing messages. With the advent of AMQP and in HornetQ we now have
the concept of an Address which is different from a Queue.

An Address can be thought of the address we would put on an envelope before
mailing it. We do not have to have any knowlegde of the USPS infrastructure
to mail the letter. In HornetQ we Address a message and in HornetQ the Address
is routed to one or more Queues.

### Durable

Messages in HornetQ can be marked as durable which means they will be persisted
to disk to prevent message loss in the event of a power failure or other system
failure. This does however mean that every durable message does incur the
overhead of a disk write every time it is read or written (produced or consumed).

### Broker

HornetQ is a broker based architecture which requires the use of one or more
centralized brokers. A broker is much like the "server" through which all
messages pass through.

An in-vm broker can be used for passing messages around within a Java
Virtual Machine (JVM) instance without making network calls. Highly recommended
for passing messages between threads in the same JVM.

### Consumer

### Producer

### Asynchronous Messaging

It is recommended to keep the state of the message flow in the message itself.

### Synchronous Messaging

### Messaging Patterns

### Message Priority


Overview
--------

jruby-hornetq is primarily intended to make it easy to use the HornetQ client
core API. It also supports running the HornetQ broker for scenarios such as
in-vm messaging.

The examples below address some of the messaging patterns that are used in
messaging and queuing.

Producer-Consumer
-----------------

Producer: Write messages to a queue:


    require 'rubygems'
    require 'hornetq'

    connection = HornetQ::Client::Connection.new(:uri => 'hornetq://localhost/')
    session = connection.create_session(:username=>'guest',:password=>'secret')

    producer = session.create_producer('jms.queue.CMDBDataServicesQueue')
    message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
    message.body_buffer.write_string('Hello World')
    producer.send(message)
    session.close
    connection.close


Consumer: Read message from a queue:

    require 'rubygems'
    require 'hornetq'

    HornetQ::Client::Factory.start(:connection => {:uri => 'hornetq://localhost'}) do |session|
      consumer = session.create_consumer('jms.queue.ExampleQueue')

      # Receive a single message, return immediately if no message available
      if message = consumer.receive_immediate
        puts "Received:[#{message.body}]"
        message.acknowledge
      else
        puts "No message found"
      end
    end

Client-Server
-------------

Server: Receive requests and send back a reply

    require 'rubygems'
    require 'hornetq'

    # Shutdown Server after 5 minutes of inactivity, set to 0 to wait forever
    timeout = 300000

    HornetQ::Client::Factory.start(:connection => {:uri => 'hornetq://localhost'}) do |session|
      server = session.create_server('jms.queue.ExampleQueue', timeout)

      puts "Waiting for Requests..."
      server.run do |request_message|
        puts "Received:[#{request_message.body}]"

        # Create Reply Message
        reply_message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
        reply_message.body = "Echo [#{request_message.body}]"

        # The result of the block is the message to be sent back to the client
        reply_message
      end

      # Server will stop after timeout period after no messages received
      server.close
    end


Client: Send a request and wait for a reply

    require 'rubygems'
    require 'hornetq'

    # Wait 5 seconds for a reply
    timeout = 5000

    HornetQ::Client::Factory.start(:connection => {:uri => 'hornetq://localhost'}) do |session|
      requestor = session.create_requestor('jms.queue.ExampleQueue')

      # Create non-durable message
      message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
      message.body = "Request Current Time"

      # Send message to the queue
      puts "Send request message and wait for Reply"
      if reply = requestor.request(message, timeout)
        puts "Received Response: #{reply.inspect}"
        puts "  Message: #{reply.body.inspect}"
      else
        puts "Time out, No reply received after #{timeout/1000} seconds"
      end

      requestor.close
    end


Threading
---------

A factory instance can be shared between threads, whereas a session and any
artifacts created by the session should only be used by one thread at a time.

For consumers, it is recommended to create a session for each thread and leave
that thread blocked on ClientConsumer::receive
A timeout can be used if the thread needs to do any other work. At this time
it is Not recommended to use ClientConsumer::receive_immediate across
multiple threads due to known issues in HornetQ with this API.

### Example

Logging
-------

Dependencies
------------

### JRuby

jruby-hornetq has been tested against JRuby 1.5.1, but should work with any
current JRuby version.

### HornetQ

The libraries required for the HornetQ Client and to start a simple Core API
only Broker are included with the Gem.

### GenePool

GenePool is used to implement session pooling

Running the Broker
------------------

Not only does jruby-hornetq make it easy to work with HornetQ from JRuby as a
client, it also supports using JRuby to launch a Broker instance

### Example Usage

#### Starting up a standalone hornetq server:

  bin/hornetq_server examples/server/standalone_server.yml

#### Starting up a backup/live combination

  bin/hornetq_server examples/server/backup_server.yml
  bin/hornetq_server examples/server/live_server.yml

Development
-----------

Want to contribute to jruby-hornetq?

First clone the repo and run the tests:

    git clone git://github.com/reidmorrison/jruby-hornetq.git
    cd jruby-hornetq
    jruby -S rake test

Feel free to ping the mailing list with any issues and we'll try to resolve it.


Contributing
------------

Once you've made your great commits:

1. [Fork](http://help.github.com/forking/) jruby-hornetq
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an [Issue](http://github.com/reidmorrison/jruby-hornetq/issues) with a link to your branch
5. That's it!

You might want to checkout our [Contributing][cb] wiki page for information
on coding standards, new features, etc.


Meta
----

* Code: `git clone git://github.com/ClarityServices/jruby-hornetq.git`
* Home: <https://github.com/ClarityServices/jruby-hornetq>
* Docs: TODO <http://ClarityServices.github.com/jruby-hornetq/>
* Bugs: <http://github.com/reidmorrison/jruby-hornetq/issues>
* List: TODO
* Gems: <http://rubygems.org/gems/jruby-hornetq>

This project uses [Semantic Versioning](http://semver.org/).

Authors
-------

Reid Morrison :: rubywmq@gmail.com :: @reidmorrison

Brad Pardee :: bpardee@gmail.com

License
-------

Copyright 2011 Clarity Services, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

jruby-hornetq includes files from HornetQ, which is also licensed under
the Apache License, Version 2.0: http://www.jboss.org/hornetq
