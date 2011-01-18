jruby-hornetq
=============

### WARNING: Alpha code!!

This code should only be used for prototyping at this time, since breaking
changes are made between every release. Once the code goes to V1.0.0 we will
make every effort to not break the existing interface in any way.

Feedback is welcome and appreciated :)

### Introduction

jruby-hornetq attempts to "rubify" the HornetQ Java libraries without 
compromising performance. It does this by sprinkling "Ruby-goodness" into the
existing HornetQ Java classes and interfaces, I.e. By adding Ruby methods to
the existing classes and interfaces. Since jruby-hornetq exposes the HornetQ
Java classes directly there is no performance impact that would have been
introduced had the entire API been wrapped in a Ruby layer.

In this way, using regular Ruby constructs a Ruby program can easily
interact with HornetQ in a highly performant way

### Important

jruby-hornetq exposes the HornetQ Core API, not its JMS API. There are
several reasons for choosing the HornetQ Core API over its JMS API:
* The Core API supports the use of Addresses, not just Queues
* The Core API exposes more capabilities than the JMS API (E.g. Management APIs)
* The HornetQ team recommend the Core API for performance
* The HornetQ JMS API is just another wrapper on top of its Core API

To use the JMS API, see the jruby-jms project. (Not yet released into the wild,
let me know if you want it :) )

HornetQ
-------

For information on the HornetQ messaging and queuing system, see:

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

  ....

Consumer: Read message from a queue: 
  ....

Client-Server
-------------


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

jruby-hornetq has been tested against JRuby 1.5.1, but should work with any
current JRuby version.

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

1. [Fork][1] Resque
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an [Issue][2] with a link to your branch
5. That's it!

You might want to checkout our [Contributing][cb] wiki page for information
on coding standards, new features, etc.


Mailing List
------------

TBA

Meta
----

* Code: `git clone git://github.com/reidmorrison/jruby-hornetq.git`
* Home: <http://github.com/reidmorrison/jruby-hornetq>
* Docs: <http://jruby-hornetq.github.com/jruby-hornetq/>
* Bugs: <http://github.com/reidmorrison/jruby-hornetq/issues>
* List: TBA
* Gems: <http://gemcutter.org/gems/jruby-hornetq>

This project uses [Semantic Versioning][sv].


Author
------

Reid Morrison :: rubywmq@gmail.com :: @reidmorrison

[1]: http://help.github.com/forking/
[2]: http://github.com/reidmorrison/jruby-hornetq/issues
[sv]: http://semver.org/

