#
# Message
#
# A Message is a routable instance that has a payload.
#
# The payload (the "body") is opaque to the messaging system. A Message also has
# a fixed set of headers (required by the messaging system) and properties
# (defined by the users) that can be used by the messaging system to route the
# message (e.g. to ensure it matches a queue filter).
#
# See: http://hornetq.sourceforge.net/docs/hornetq-2.1.0.Final/api/org/hornetq/api/core/client/ClientMessage.html
#
# Other methods still directly accessible through this class:
#
# void   acknowledge()
#          Acknowledge reception of this message. If the session responsible to
#          acknowledge this message has :auto_commit_acks => true, the
#          transaction will automatically commit the current transaction.
#          Otherwise, this acknowledgement will not be committed until the
#          client commits the session transaction
#
# Message attribute methods available directly from the Java Message class:
#
# String address()
#          Returns the address this message is sent to.
# void   address=(SimpleString address)
#          Sets the address to send this message to
#
# int   body_size()
#          Return the size (in bytes) of this message's body
#
# int   delivery_count()
#          Returns the number of times this message was delivered
#
# boolean durable?()
#          Returns whether this message is durable or not
# void   durable=(boolean durable)
#          Sets whether this message is durable or not.
#
# int   encode_size()
#          Returns the size of the encoded message
#
# boolean expired?()
#          Returns whether this message is expired or not
#
# long   expiration()
#          Returns the expiration time of this message
# void   expiration=(long expiration)
#          Sets the expiration of this message.
#
# boolean large_message?()
#          Returns whether this message is a large message or a regular message
#
# long   message_id()
#          Returns the messageID
#          This is an internal message id used by HornetQ itself, it cannot be
#          set by the user.
#          The message is only visible when consuming messages, when producing
#          messages the message_id is Not returned to the caller
#          Use user_id to carry user supplied message id's for correlating
#          responses to requests
#
# byte   priority()
#          Returns the message priority.
#          Values range from 0 (less priority) to 9 (more priority) inclusive.
# void   priority=(byte priority)
#          Sets the message priority.
#          Value must be between 0 and 9 inclusive.
#
# #TODO Add timestamp_time attribute that converts to/from expiration under the covers
# long   timestamp()
#          Returns the message timestamp. The timestamp corresponds to the time
#          this message was handled by a HornetQ server.
# void   timestamp=(long timestamp)
#          Sets the message timestamp.
#
# byte   type()
#          Returns this message type
#          See: type_sym below for dealing with message types using Ruby Symbols
#
# org.hornetq.utils.UUID   user_id()
#          Returns the userID - this is an optional user specified UUID that can be set to identify the message and will be passed around with the message
# void   user_id=(org.hornetq.utils.UUID userID)
#          Sets the user ID
#
# Methods available directly for dealing with properties:
#
#  boolean   contains_property?(key)
#          Returns true if this message contains a property with the given key, false else
#
#  Note: Several other property methods are available directly, but since JRuby
#        deals with the conversion for you they are not documented here
#
# Other methods still directly accessible through this class from its child classes:
#
# HornetQBuffer   body_buffer()
#          Returns the message body as a HornetQBuffer
#
# Map<String,Object>   toMap()
#
#
# Methods for dealing with large messages:
#
# void   save_to_output_stream(OutputStream out)
#          Saves the content of the message to the OutputStream.
#          It will block until the entire content is transfered to the OutputStream.
#
# void   body_input_stream=(InputStream bodyInputStream)
#          Sets the body's IntputStream.
#          This method is used when sending large messages
#
# void   output_stream=(OutputStream out)
#          Sets the OutputStream that will receive the content of a message received
#          in a non blocking way. This method is used when consuming large messages
#
# boolean   wait_output_stream_completion(long timeMilliseconds)
#          Wait the outputStream completion of the message. This method is used when consuming large messages
#          timeMilliseconds - - 0 means wait forever
#
# Developer notes:
#   Cannot add to the interface Java::org.hornetq.api.core::Message because these
#   methods access instance variables in the Java object
class Java::OrgHornetqCoreClientImpl::ClientMessageImpl
  # Attributes
  # attr_accessor :address, :type, :durable, :expiration, :priority, :timestamp, :user_id

  # Is this a request message for which a reply is expected?
  def request?
    contains_property(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME)
  end

  # Return the Reply To Address as a string
  def reply_to_address
    get_string_property(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME)
  end

  # Set the Reply To Address
  #  When supplied, the consumer of the message is expected to send a response to the
  #  specified address. However, this is by convention, so no response is guaranteed
  #
  # Note: Rather than set this directly, consider creating a Client::Requestor:
  #     requestor = session.create_requestor('Request Queue')
  #
  def reply_to_address=(name)
    put_string_property(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME, HornetQ::as_simple_string(name))
  end

  # Generate a new user_id
  #
  # Sets the user_id to a newly generated id, using a UUID algorithm
  #
  # The user_id is similar to the message_id in other JMS based messaging systems
  # in fact the HornetQ JMS API uses the user_id as the JMS Message ID.
  #
  # The internal message_id is set by the HornetQ Server and is Not returned
  # when sending messages
  #
  # Returns generated user_id
  def generate_user_id
    self.user_id = Java::org.hornetq.utils::UUIDGenerator.instance.generateUUID
  end

  # Returns the message type as one of the following symbols
  #   :text    => org.hornetq.api.core.Message::TEXT_TYPE
  #   :bytes   => org.hornetq.api.core.Message::BYTES_TYPE
  #   :map     => org.hornetq.api.core.Message::MAP_TYPE
  #   :object  => org.hornetq.api.core.Message::OBJECT_TYPE
  #   :stream  => org.hornetq.api.core.Message::STREAM_TYPE
  #   :default => org.hornetq.api.core.Message::DEFAULT_TYPE
  #   :unknown => Any other value for message type
  #
  # If the type is none of the above, nil is returned
  #
  def type_sym
    case self.type
    when Java::org.hornetq.api.core.Message::TEXT_TYPE   #3
      :text
    when Java::org.hornetq.api.core.Message::BYTES_TYPE  #4
      :bytes
    when Java::org.hornetq.api.core.Message::MAP_TYPE   #5
      :map
    when Java::org.hornetq.api.core.Message::OBJECT_TYPE   #2
      :object
    when Java::org.hornetq.api.core.Message::STREAM_TYPE   #6
      :stream
    when Java::org.hornetq.api.core.Message::DEFAULT_TYPE   #0
      :default
    else
      :unknown
    end
  end

  # Set the message type using a Ruby symbol
  # Parameters
  #  sym: Must be any one of the following symbols
  #   :text    => org.hornetq.api.core.Message::TEXT_TYPE
  #   :bytes   => org.hornetq.api.core.Message::BYTES_TYPE
  #   :map     => org.hornetq.api.core.Message::MAP_TYPE
  #   :object  => org.hornetq.api.core.Message::OBJECT_TYPE
  #   :stream  => org.hornetq.api.core.Message::STREAM_TYPE
  #   :default => org.hornetq.api.core.Message::DEFAULT_TYPE
  #
  def type_sym=(sym)
    case sym
    when :text
      self.type = Java::org.hornetq.api.core.Message::TEXT_TYPE   #3
    when :bytes
      self.type = Java::org.hornetq.api.core.Message::BYTES_TYPE  #4
    when :map
      self.type = Java::org.hornetq.api.core.Message::MAP_TYPE   #5
    when :object
      self.type = Java::org.hornetq.api.core.Message::OBJECT_TYPE   #2
    when :stream
      self.type = Java::org.hornetq.api.core.Message::STREAM_TYPE   #6
    when :default
      self.type = Java::org.hornetq.api.core.Message::DEFAULT_TYPE   #0
    else
      raise "Invalid message type_sym:#{sym.to_s}"
    end
  end

  # Return the body for this message
  # TODO: Do remaining message Types
  def body
    # Allow this buffer to be read multiple times
    buf = body_buffer
    buf.reset_reader_index
    available = body_size

    return nil if available == 0

    case type
    when Java::org.hornetq.api.core.Message::BYTES_TYPE  #4
      result = ""
      bytes_size = 1024
      bytes = Java::byte[bytes_size].new

      while (n = available < bytes_size ? available : bytes_size) > 0
        buf.read_bytes(bytes, 0, n)
        if n == bytes_size
          result << String.from_java_bytes(bytes)
        else
          result << String.from_java_bytes(bytes)[0..n-1]
        end
        available -= n
      end
      result

    when Java::org.hornetq.api.core.Message::DEFAULT_TYPE   #0
      #TODO Default Type?

    when Java::org.hornetq.api.core.Message::MAP_TYPE   #5
      Java::org.hornetq.utils::TypedProperties.new.decode(body_buffer)

    when Java::org.hornetq.api.core.Message::OBJECT_TYPE   #2
      # TODO Java Object Type

    when Java::org.hornetq.api.core.Message::STREAM_TYPE   #6
      #TODO Stream Type

    when Java::org.hornetq.api.core.Message::TEXT_TYPE   #3
      body_buffer.read_nullable_simple_string.to_string
    else
      raise "Unknown Message Type, use Message#body_buffer instead"
    end
  end

  # Write data into the message body
  #
  # Note: The message type Must be set before calling this method
  #
  # Data is automatically converted based on the message type
  #
  def body=(data)
    body_buffer.reset_writer_index
    case type

    when Java::org.hornetq.api.core.Message::BYTES_TYPE  #4
      body_buffer.write_bytes(data.respond_to?(:to_java_bytes) ? data.to_java_bytes : data)

    when Java::org.hornetq.api.core.Message::MAP_TYPE   #5
      if data.kind_of? Java::org.hornetq.utils::TypedProperties
        data.encode(body_buffer)
      elsif data.responds_to? :each_pair
        # Ruby Hash, or anything that responds to :each_pair
        # TODO What about Hash inside of Hash?
        properties = Java::org.hornetq.utils::TypedProperties.new
        data.each_pair do |key, val|
          properties[key.to_s] = val
        end
        properties.encode(body_buffer)
      else
        raise "Unrecognized data type #{data.class.name} being set when the message type is MAP"
      end

    when Java::org.hornetq.api.core.Message::OBJECT_TYPE   #2
      # Serialize Java Object
      # TODO Should we do the serialize here?
      body_buffer.write_bytes(data)

    when Java::org.hornetq.api.core.Message::STREAM_TYPE   #6
      # TODO Stream Type

    when Java::org.hornetq.api.core.Message::TEXT_TYPE   #3
      if data.kind_of? Java::org.hornetq.api.core::SimpleString
        body_buffer.writeNullableSimpleString(data)
      else
        body_buffer.writeNullableSimpleString(Java::org.hornetq.api.core::SimpleString.new(data.to_s))
      end

    when Java::org.hornetq.api.core.Message::DEFAULT_TYPE   #0
      raise "The Message#type must be set before attempting to set the message body"

    else
      raise "Unknown Message Type, use Message#body_buffer directly"
    end
  end

  # Get a property
  def [](key)
    getObjectProperty(key.to_s)
  end

  # Set a property
  # TODO: Does it need proper translation, otherwise it will be a Ruby object
  def []=(key,value)
    putObjectProperty(key, value)
  end

  # Does this message include the supplied property?
  def include?(key)
    # Ensure a Ruby true is returned
    property_exists(key.to_s) == true
  end

  # Return TypedProperties
  def getProperties
    properties
  end

  # Iterate over all the properties
  #
  def properties_each_pair(&proc)
    enum = getPropertyNames
    while enum.has_more_elements
      key = enum.next_element
      proc.call key, getObjectProperty(key)
    end
  end

  # Return all message Attributes as a hash
  def attributes
    {
      :address => address.nil? ? '' : address.to_string,
      :body_size => body_size,
      :delivery_count => delivery_count,
      :durable? => durable?,
      :encode_size => encode_size,
      :expired? => expired?,
      :expiration => expiration,
      :large_message? => large_message?,
      :message_id => message_id,
      :priority => priority,
      :timestamp => timestamp,
      :type_sym => type_sym,
      :user_id => user_id.nil? ? nil : user_id.to_s,
    }
  end

  # Does not include the body since it can only read once
  def inspect
    "#{self.class.name}:\nBody: #{body.inspect}\nAttributes: #{attributes.inspect}\nProperties: #{properties.inspect}"
  end

end