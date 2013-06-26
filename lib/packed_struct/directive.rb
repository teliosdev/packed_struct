module PackedStruct

  # Contains information about a directive.  A directive can be a name
  # of the type, the endian(ness) of the type, the type of the type
  # (short, int, long, etc.), and the signed(ness) of the type.
  class Directive

    # The name of the directive.  This is passed as the first value of
    # the directive; from {Package}, it is the name of the method call.
    #
    # @return [Symbol]
    attr_reader :name

    # The arguments passed to the directive.
    #
    # @return [Array<Object>]
    attr_reader :options

    # The tags the directive has, such as type, signed(ness),
    # endian(ness), and size.  Not filled until {#to_s} is called.
    #
    # @return [Hash]
    attr_accessor :tags

    # The children of this directive.  If this directive has a parent,
    # this is nil.
    #
    # @return [nil, Array<Directive>]
    attr_reader :subs

    # The parent of this directive.  The relationship is such that
    # +parent.subs.include?(self)+ is true.  If this has a parent, it
    # is nil.
    #
    # @return [nil, Directive]
    attr_accessor :parent

    # The value this directive holds.  Only for use when packing.
    #
    # @return [nil, Object]
    attr_writer :value

    # @!parse
    #   attr_reader :value
    def value
      @value || (@tags[:original].value if @tags[:original])
    end

    # Initialize the directive.
    #
    # @param name [Symbol] the name of the directive.
    def initialize(name, *arguments)
      @name = name

      @options = arguments
      @tags    = {}
      @subs    = []
      @parent  = nil
      @value   = nil

      if arguments.first.is_a? Directive
        arguments.first.add_child(self)
        @subs = nil
      end
    end

    # Add a child to this (or its parent's) directive.  If this is a
    # child itself, it adds it to the parent of this.  Invalidates the
    # caches for {#sub_names} and {#to_s}
    #
    # @param child [Directive] the child to add.
    # @return [Directive] the child.
    def add_child(child)
      if @parent
        @parent.add_child(child)
      else
        @_str = nil
        @_sub_types = nil
        @subs << child
        child.parent = self
        child
      end
    end

    # Set the size of this directive.
    #
    # @return [self]
    def [](size)
      @tags[:size] = size
      self
    end

    # Turn the directive into a string.  Analyzes the subs before
    # determining information, then outputs that.  Caches the value
    # until {#add_child} is next called.
    #
    # @return [String]
    def to_s
      return "" unless @subs
      @subs.compact!
      @tags[:signed]   = determine_signed
      @tags[:type]     = determine_type
      @tags[:endian]   = determine_endian
      "#{make_directive}#{make_length}"
    end

    # Inspects the directive.
    #
    # @return [String]
    def inspect
      "#<#{self.class.name}:#{name}>"
    end

    # To show the size of something else, relative to this directive.
    #
    # @return [Directive]
    def -(other)
      dir = dup
      dir.tags = tags.dup
      dir.tags[:original   ] = self
      dir.tags[:size_modify] = -other
      dir
    end

    # To show the size of something else, relative to this directive.
    #
    # @return [Directive]
    def +(other)
      dir = dup
      dir.tags = tags.dup
      dir.tags[:original   ] = self
      dir.tags[:size_modify] = +other
      dir
    end

    # The number of bytes this takes up in the resulting packed string.
    #
    # @return [Numeric]
    def bytesize
      case @tags[:type]
      when nil
        size / 8
      when :short
        2
      when :int
        4
      when :long
        4
      when :float
        if sub_names.include?(:double)
          8
        else
          4
        end
      when :null
        size || 1
      when :string
        size
      else
        0
      end
    end

    private

    # Returns all of the names of the subs, and caches it.
    #
    # @param force [Boolean] force reloading the names of the subs.
    # @return [Array<Symbol>]
    def sub_names(force = false)
      if @_sub_types && !force
        @_sub_types
      else
        @subs.map(&:name) + [@name]
      end
    end

    # Determines the size of the directive by checking if it's in the
    # tags, or by searching the subs.
    #
    # @return [Numeric]
    def size
      case @tags[:size]
      when Directive
        (@tags[:size].value || 0).to_i + (@tags[:size].tags[:size_modify] || 0).to_i
      when Numeric
        @tags[:size]
      when nil
        @subs.select { |s| s && s.tags[:size] }.map { |s| s.tags[:size] }.last
      end
    end

    # Determine the type of this directive.  Uses {#sub_names} to
    # search for matching types.  Defaults to +nil+.
    #
    # @return [nil, Symbol] the return value can be any of +:short+,
    #   +:int+, +:long+, +:string+, +:float+, or +nil+.
    def determine_type
      case true
      when sub_names.include?(:short)
        :short
      when sub_names.include?(:int)
        :int
      when sub_names.include?(:long)
        :long
      when sub_names.include?(:char), sub_names.include?(:string)
        :string
      when sub_names.include?(:float)
        :float
      when sub_names.include?(:null)
        :null
      else
        nil
      end
    end

    # Determines the endianness of this directive.  Uses {#sub_names}
    # to search for matching names.  Defaults to +:native+.
    #
    # @return [Symbol] the return value can be any of +:little+,
    #   +:big+, or +:native+.
    def determine_endian
      case true
      when sub_names.include?(:little), sub_names.include?(:little_endian),
        sub_names.include?(:lsb), sub_names.include?(:low)
        :little
      when sub_names.include?(:big), sub_names.include?(:big_endian),
        sub_names.include?(:msb), sub_names.include?(:high),
        sub_names.include?(:network)
        :big
      else
        :native
      end
    end

    # Determines the signedness of this directive.  Uses {#sub_names}
    # to search for matching names.  Defaults to +:signed+.
    #
    # @return [Symbol] the return value can be any of +:unsigned+ or
    #   +:signed+.
    def determine_signed
      if sub_names.include?(:unsigned) && !sub_names.include?(:null)
        :unsigned
      else
        :signed
      end
    end

    # Determines the directive to be used in the pack string, using
    # the type from {#determine_type} to manage it.
    #
    # @return [String] the directive for the pack string.
    def make_directive
      case @tags[:type]
      when nil
        handle_nil_type
      when :short
        modify_if_needed "S"
      when :int
        modify_if_needed "I"
      when :long
        modify_if_needed "L"
      when :string
        handle_string_type
      when :float
        handle_float_type
      when :null
        "x" * (size || 1)
      else
        nil
      end
    end

    # Determines the length to be added to the pack string.
    #
    # @return [String]
    def make_length
      if size && ![:null, nil].include?(@tags[:type])
        size.to_s
      else
        ""
      end
    end

    # Handles the nil type.  Uses the size to match the type with
    # the directive.
    #
    # @return [String]
    def handle_nil_type
      maps = {
        8  => "C",
        16 => "S",
        32 => "L",
        64 => "Q"
      }

      raise StandardError,
        "Cannot make number of #{size} length" unless
          maps.keys.include?(size)

      modify_if_needed maps[size]
    end

    # Handles a string type.  If the name of the directive is
    # +:null+, returns a string containing a number of +x+s (nulls)
    # exactly equal to the size (or 1, if it doesn't exist).
    # Otherwise, determines the type of string from the sub names;
    # types of strings can include +:hex+, +:base64+, +:bit+, or
    # +:binary+ (defaults to binary).
    #
    # @return [String]
    def handle_string_type

      case true
      when sub_names.include?(:hex)
        modify_if_needed "H"
      when sub_names.include?(:base64)
        "m"
      when sub_names.include?(:bit)
        modify_if_needed "B", false
      else
        modify_if_needed "A", false
      end
    end

    # Handles float types.  Can handle double- or single- precision
    # floats, and manage their byte order.
    #
    # @return [String]
    def handle_float_type
      double = sub_names.include?(:double)

      case @tags[:endian]
      when :native
        if double
          "D"
        else
          "F"
        end
      when :little
        if double
          "E"
        else
          "e"
        end
      when :big
        if double
          "G"
        else
          "g"
        end
      end
    end

    # Modifies the given string as needed; it assumes that a lowercase
    # letter stands for a signed type and the given string stands for
    # an unsigned type.  It also assumes that "<" added means little
    # endian, and that ">" added means big endian (and that nothing
    # added stands for native).
    #
    # @param str [String]
    # @return [String]
    def modify_if_needed(str, include_endian = true)
      base = if @tags[:signed] == :signed
        str.downcase
      else
        str
      end

      base += case @tags[:endian]
      when :little
        "<"
      when :big
        ">"
      else
        ""
      end if include_endian

      base
    end

  end
end
