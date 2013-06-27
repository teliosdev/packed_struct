module PackedStruct
  class Modifier

    # Initializes the modifier.
    def initialize(name)
      @name = name
      @type = nil
      @value = nil
    end

    # The type of modifier it is.  Has three possible values:
    # +:endian+, +:size+, and +:signedness+.
    #
    # @return [Symbol]
    # @!parse
    #   attr_reader :type
    def type
      compile! unless @compiled
      @type
    end

    # The value of the modifier.  Has multiple possible values,
    # including: +:little+, +:big+, +:short+, +:int+, +:long+,
    # +:float+, +:null+, +:string+, +:unsigned+, +:signed+.
    #
    # @return [Symbol]
    # @!parse
    #   attr_reader :value
    def value
      compile! unless @compiled
      @value
    end

    # Compiles the modifier into a usable format.  Stores the values
    # it determines in +@type+ and +@value+.
    #
    # @raises [UnknownModifierError] if it can't detect the type of
    #   modifier.
    # @return [void]
    def compile!
      @compiled ||= begin
        case @name
        when :little_endian, :little, :lsb, :low
          @type  = :endian
          @value = :little
        when :big_endian, :big, :msb, :high, :network
          @type  = :endian
          @value = :big
        when :short, :int, :long, :float, :string
          @type  = :type
          @value = @name
        when :unsigned, :signed
          @type  = :signedness
          @value = @name
        when :null
          @type  = :signedness
          @value = :signed
        when :spaced
          @type  = :signedness
          @value = :unsigned
        when :double
          @type  = :length
          @value = :double
        when :hex, :base64, :bit
          @type  = :string_type
          @value = @name
        else
          raise UnknownModifierError, "Unkown modifier: #{@name}"
        end
        true
      end
    end
  end

  class UnknownModifierError < StandardError; end
end
