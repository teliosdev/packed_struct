require 'set'

module PackedStruct
  class Directive

    # The name of the directive.  This is passed as the first value of
    # the directive; from {Package}, it is the name of the method call.
    #
    # @return [Symbol]
    attr_reader :name

    # The modifiers for this directive.
    #
    # @return [Set<Modifier>]
    attr_reader :modifiers

    # Metadata about the directive.  Created when {#finalize!} is
    # called.
    #
    # @return [Hash<Symbol, Object>]
    attr_reader :tags

    # Initialize the directive.
    #
    # @param name [Symbol] the name of the directive.
    # @param package [Package] the package this directive is a part
    #   of.
    def initialize(name)
      @name = name
      @modifiers = []
      @finalized = true

      @tags = {
        :endian     => :native,
        :signedness => :signed,
        :size       => nil,
        :precision  => :single,
        :size_mod   => 0
      }
    end

    # Determines whether or not this directive is empty.  It is
    # considered empty when its tags has all of the default values,
    # it has no modifiers, and its name is not +:null+.
    #
    # @return [Boolean]
    def empty?
      tags == { :endian => :native, :signedness => :signed,
        :size => nil, :precision => :single, :size_mod => 0
      } && modifiers.length == 0 && name != :null
    end

    # Add a modifier to this directive.
    #
    # @param mod [Modifier]
    # @return [self]
    def add_modifier(mod)
      @finalized = false
      modifiers << mod
      self
    end

    # Changes the size of the directive to the given size.  It is
    # possible for the given value to the a directive; if it is,
    # it just uses the name of the directive.
    #
    # @param new_size [Numeric, Directive]
    # @return [self]
    def [](new_size)
      if new_size.is_a? Directive
        tags.merge! new_size.tags_for_sized_directive
      else
        tags[:size] = new_size
      end

      self
    end

    # Returns a hash to be merged into the tags of a directive that
    # recieved this directive for a size.
    #
    # @return [Hash<Symbol, Object>]
    def tags_for_sized_directive
      {
        :size => name,
        :size_mod => tags[:size_mod]
      }
    end

    # Modifies +self+ such that it sizes itself (on {#to_s}ing), and
    # keeping this size modification in mind.  In other words, this
    # is meant to be used in another directive's {#[]} method for
    # telling it what size it should be, and this method modifies that
    # size by the given amount.
    #
    # @example
    #   some_directive[another_directive - 5]
    # @param other [Numeric, #coerce]
    # @return [self, Object]
    def -(other)
      if other.is_a? Numeric
        tags[:size_mod] = -other
        self
      else
        self_equiv, arg_equiv = other.coerce(self)
        self_equiv - arg_equiv
      end
    end

    # (see #-)
    def +(other)
      if other.is_a? Numeric
        tags[:size_mod] = +other
        self
      else
        self_equiv, arg_equiv = other.coerce(self)
        self_equiv + arg_equiv
      end
    end

    # Coerces +self+ into a format that can be used with +Numeric+ to
    # add or subtract from this class.
    #
    # @example
    #   some_directive[1 + another_directive]
    # @param other [Object]
    # @return [Array<(self, Object)>]
    def coerce(other)
      [self, other]
    end

    # Whether or not this directive has finalized.  It is finalized
    # until a modifier is added, and then {#finalize!} is required to
    # finalize the directive.
    #
    # @return [Boolean]
    def finalized?
      @finalized
    end

    # Finalizes the directive.
    #
    # @return [void]
    def finalize!
      return if finalized?

      modifiers.each do |modifier|
        case modifier.type
        when :endian, :signedness, :precision, :type, :string_type
          tags[modifier.type] = modifier.value
        when :size
          tags[:size] = modifier.value unless tags[:size]
        else
          raise UnknownModifierError,
            "Unknown modifier: #{modifier.type}"
        end
      end

      @finalized = true
      cache_string
    end

    # Turn the directive into a string, with the given data.  It
    # shouldn't need the data unless +tags[:size]+ is a Symbol.
    #
    # @param data [Hash<Symbol, Object>] the data that may be used for
    #   the length.
    # @return [String]
    def to_s(data = {})
      return @_cache if !tags[:size].is_a?(Symbol) && @_cache
      return "x" * (tags[:size] || 1) if name == :null

      out = case tags[:type]
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
      when nil
        handle_empty_type
      else
        nil
      end

      if tags[:size].is_a? Symbol
        out << data.fetch(tags[:size]).to_s
      elsif tags[:size] && ![:null, nil].include?(tags[:type])
        out << tags[:size].to_s
      end

      out
    end

    # The number of bytes a type takes up in the string.
    BYTES_IN_STRING = {
      :char  => [0].pack("c").bytesize,
      :short => [0].pack("s").bytesize,
      :int   => [0].pack("i").bytesize,
      :long  => [0].pack("l").bytesize,
      :float_single => [0].pack("f").bytesize,
      :float_double => [0].pack("D").bytesize,
    }

    # The number of bytes this takes up in the resulting packed string.
    #
    # @param (see #to_s)
    # @return [Numeric]
    def bytesize(data = {})
      case tags[:type]
      when nil
        (size(data) || 8) / 8
      when :short, :int, :long
        BYTES_IN_STRING.fetch tags[:type]
      when :float
        if tags[:precision] == :double
          BYTES_IN_STRING[:float_double]
        else
          BYTES_IN_STRING[:float_single]
        end
      when :null
        size(data) || 1
      when :string
        size(data)
      else
        0
      end
    end

    # The size of this directive.
    #
    # @param (see #to_s)
    # @return [nil, Numeric]
    def size(data = {})
      if tags[:size].is_a? Symbol
        data.fetch(tags[:size])
      else
        tags[:size]
      end
    end

    private

    # Tries to cache the string value of this directive.  It cannot if
    # +tags[:size]+ is a Symbol, since it depends on the value of the
    # directive named by that symbol.
    #
    # @return [String]
    def cache_string
      return if tags[:size].is_a? Symbol
      return @_cache = "x" * (tags[:size] || 1) if name == :null

      @_cache = to_s
    end

    # Handles the type if there is no type, i.e. a type modifier was
    # not specified.  Can only handle directives with sizes
    # 0 (default), 8, 16, 32, and 64.
    #
    # @see #modify_if_needed
    # @return [String]
    def handle_empty_type
      maps = {
        0  => "x",
        8  => "C",
        16 => "S",
        32 => "L",
        64 => "Q"
      }

      modify_if_needed maps.fetch(tags[:size] || 0), tags[:size] != 8
    end

    # Handles the type if it is string.  Defaults to a null-padded
    # string, but if a +:hex+, +:base64+, or +:bit+ modifier is
    # specified, it will be used.
    #
    # If +:hex+ is specified, the endianness will be used to determine
    # which nibble will go first.
    #
    # If +:base64+ is specified, the endianness will be used to
    # determine whether +MSB+ or the +LSB+ will go first.
    def handle_string_type
      case tags[:string_type]
      when :hex
        modify_for_endianness "H", true
      when :base64
        "m"
      when :bit
        modify_for_endianness "B", true
      else
        modify_for_endianness "a", true
      end
    end

    # Handles the float type.  Handles the endianness and the
    # precision, returning the correct character for the float type.
    #
    # @return [String]
    def handle_float_type
      case [tags[:endian], tags[:precision]]
      when [:native, :double]
        "D"
      when [:native, :single]
        "F"
      when [:little, :double]
        "E"
      when [:little, :single]
        "e"
      when [:big, :double]
        "G"
      when [:big, :single]
        "g"
      end
    end

    # Modifies the given string if it's needed, according to
    # signness and endianness.  This assumes that a signed
    # directive should be in lowercase.
    #
    # @param str [String] the string to modify.
    # @param include_endian [Boolean] whether or not to include the
    #   endianness.
    # @return [String]
    def modify_if_needed(str, include_endian = true)
      base = if @tags[:signedness] == :signed
        str.swapcase
      else
        str
      end
      if include_endian
        modify_for_endianness(base)
      else
        base
      end
    end

    # Modifies the given string to account for endianness.  If
    # +use_case+ is true, it modifies the case of the given string to
    # represent endianness; otherwise, it appends data to the string
    # to represent endianness.
    #
    # @param str [String] the string to modify.
    # @param use_case [Boolean]
    # @return [String]
    def modify_for_endianness(str, use_case = false)
      case [tags[:endian], use_case]
      when [:little, true]
        str.swapcase
      when [:little, false]
        str + "<"
      when [:big, true]
        str
      when [:big, false]
        str + ">"
      else
        str
      end
    end

  end
end
