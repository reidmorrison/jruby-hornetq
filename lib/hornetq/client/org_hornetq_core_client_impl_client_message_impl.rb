
# Cannot add to the interface Java::org.hornetq.api.core::Message because these
# methods access instance variables in the Java object
class Java::OrgHornetqCoreClientImpl::ClientMessageImpl
  # Attributes
  # attr_accessor :address, :type, :durable, :expiration, :priority, :timestamp, :user_id
  
  # Is this a request message for which a reply is expected?
  def request?
    contains_property(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME)
  end
  
  # Return the Reply To Queue Name as a string
  def reply_to_queue_name
    get_string_property(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME)
  end

  # Set the Reply To Queue Name
  #  When supplied, the consumer of the message is expected to send a response to the
  #  specified queue. However, this is by convention, so no response is guaranteed
  # Note: Rather than set this directly, consider creating a Client::Requestor:
  #     requestor = session.create_requestor('Request Queue')
  #
  def reply_to_queue_name=(name)
    val = nil
    if name.is_a? Java::org.hornetq.api.core::SimpleString
      val = name
    else
      val = Java::org.hornetq.api.core::SimpleString.new(name.to_s)
    end

    put_string_property(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME, val)
  end

  # Return the size of the encoded message
  # attr_reader :encode_size

  # Return the body for this message
  # TODO: Do remaining message Types
  # 
  # WARNING: This method can only be called ONCE!
  # WARNING: Do not call after setting the body otherwise the send will have
  #          an empty body
  def body
    # Allow this buffer to be read multiple times
    body_buffer.reset_reader_index

    case type
    when Java::org.hornetq.api.core.Message::BYTES_TYPE  #4
      buf = body_buffer
      buf.reset_reader_index
      available = body_size
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
    when Java::org.hornetq.api.core.Message::DEFAULT_TYPE 	#0
    when Java::org.hornetq.api.core.Message::MAP_TYPE 	#5
      Java::org.hornetq.utils::TypedProperties.new.decode(body_buffer)
    when Java::org.hornetq.api.core.Message::OBJECT_TYPE 	#2
    when Java::org.hornetq.api.core.Message::STREAM_TYPE 	#6
    when Java::org.hornetq.api.core.Message::TEXT_TYPE 	#3
      body_buffer.read_nullable_simple_string.to_string
    else
      raise "Unknown Message Type, use Message#body_buffer instead"
    end
  end
  
  # Write data into the message body
  # 
  # Data is automatically converted based on the message type
  # 
  # DEPRECATED
  def <<(data)
    case type
    when Java::org.hornetq.api.core.Message::BYTES_TYPE  #4
      body_buffer.write_bytes(data)
    when Java::org.hornetq.api.core.Message::DEFAULT_TYPE 	#0
      raise "Cannot use Message#<< when the Message#type has not been set"
    when Java::org.hornetq.api.core.Message::MAP_TYPE 	#5
      if data.class == Java::org.hornetq.utils::TypedProperties
        body_buffer.reset_writer_index
        data.encode(body_buffer)
      elsif data.responds_to? :each_pair
        properties = Java::org.hornetq.utils::TypedProperties.new
        properties.from_hash(data)
        body_buffer.reset_writer_index
        properties.encode(body_buffer)
      end
    when Java::org.hornetq.api.core.Message::OBJECT_TYPE 	#2
    when Java::org.hornetq.api.core.Message::STREAM_TYPE 	#6
    when Java::org.hornetq.api.core.Message::TEXT_TYPE 	#3
      if data.class == Java::org.hornetq.api.core::SimpleString
        body_buffer.writeNullableSimpleString(data)
      else
        body_buffer.writeNullableSimpleString(Java::org.hornetq.api.core::SimpleString.new(data.to_s))
      end
    else
      raise "Unknown Message Type, use Message#body_buffer instead"
    end
  end
  
  # Set the body of the message
  # The type of the message is automatically set based on the type passed in.
  # The following types are automatically supported in order of priority
  #   String                                   => :text
  #   Java::org.hornetq.api.core::SimpleString => :text
  #   Java::org.hornetq.utils::TypedProperties => :map
  #   Hash (actually any object responding to  => :map
  def body=(data)
    body_buffer.reset_writer_index
    if data.is_a? String
      # Ruby String
      self.type = Java::org.hornetq.api.core.Message::TEXT_TYPE
      body_buffer.writeNullableSimpleString(Java::org.hornetq.api.core::SimpleString.new(data))
    elsif data.is_a? Java::org.hornetq.api.core::SimpleString
      # SimpleString instance
      self.type = Java::org.hornetq.api.core.Message::TEXT_TYPE
      body_buffer.writeNullableSimpleString(data)
    elsif data.is_a? Java::org.hornetq.utils::TypedProperties
      # TypedProperties
      self.type = Java::org.hornetq.api.core.Message::MAP_TYPE
      data.encode(body_buffer)
    elsif data.responds_to? :each_pair
      # Ruby Hash, or anything that responds to :each_pair
      # TODO What about Hash inside of Hash?
      self.type = Java::org.hornetq.api.core.Message::MAP_TYPE
      properties = Java::org.hornetq.utils::TypedProperties.new
      data.each_pair do |key, val|
        properties[key.to_s] = val
      end
      properties.encode(body_buffer)
    elsif data.responds_to? :to_s
      # Can be converted to a Ruby String
      self.type = Java::org.hornetq.api.core.Message::TEXT_TYPE
      body_buffer.writeNullableSimpleString(Java::org.hornetq.api.core::SimpleString.new(data.to_s))
    else
      # Otherwise Serialize Ruby object
      self.type = Java::org.hornetq.api.core.Message::BYTES_TYPE
      self['encoding', 'jruby']
      # If BYTES type is not working we could use Base64.encode64
      self << Marshal.dump(data)
      self.text = encoded
    end
  end
  
  # Serialize JRuby object and base64 encode
  def decode
    if self.get_string_property( 'encoding' ) == 'base64'
      serialized = Base64.decode64( self.text )
      Marshal.restore( serialized )
    else
      self.text
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

  # call-seq:
  #   body_buffer
  #
  # Return the message body as a HornetQBuffer
  #

  # call-seq:
  #   to_map
  #
  # Return the Message as a Map
  #

  # call-seq:
  #   remove_property(key)
  #
  # Remove a property

  # call-seq:
  #   contains_property(key)
  #
  # Returns true if this message contains a property with the given key
  # TODO: Symbols?

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
      :type => type,
      :durable => durable,
      :expiration => expiration,
      :priority => priority,
      :timestamp => timestamp,
      :user_id => user_id,
      :encode_size => encode_size
    }
  end

  # Does not include the body since it can only read once
  def inspect
    "#{self.class.name}:\nAttributes: #{attributes.inspect}\nProperties: #{properties.inspect}"
  end

end