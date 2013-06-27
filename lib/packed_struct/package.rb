module PackedStruct

  # Manages the struct overall, and keeps track of the directives.
  # Directives are packed in the order that they are joined, such
  # that the first one defined is the first one on the string.
  class Package

    # The list of directives that the package has.
    #
    # @return [Array<Directive>]
    def directives
      @directives
    end

    # Initialize the package.
    def initialize
      @directives = []
    end

    # Turn the package into a string.  Uses the directives (calls
    # {Directive#to_s} on them), and joins the result.
    #
    # @param data [Hash<Symbol, Object>] the data to pass to
    #   {Directive#to_s}.
    # @return [String] the string ready for #pack.
    def to_s(data = {})
      directives.map { |x| x.to_s(data) }.join(' ')
    end

    alias_method :to_str, :to_s

    # Packs the given data into a string.  The keys of the data
    # correspond to the names of the directives.
    #
    # @param data [Hash<Symbol, Object>] the data.
    # @return [String] the packed data.
    def pack(data)
      values = []
      data.each do |k, v|
        values.push([k, v])
      end

      mapped_directives = @directives.map(&:name)

      values = values.select { |x| mapped_directives.include?(x[0]) }

      values.sort! do |a, b|
        mapped_directives.index(a[0]) <=> mapped_directives.index(b[0])
      end

      ary = values.map(&:last)
      ary.pack to_s(data)
    end

    # Unpacks the given string with the directives.  Returns a hash
    # containing the values, with the keys being the names of the
    # directives.
    #
    # @param string [String] the packed string.
    # @return [Hash<Symbol, Object>] the unpacked data.
    def unpack(string)
      total = ""
      parts = {}
      directives.each_with_index do |directive, i|
        total << directive.to_s(parts)
        parts[directive.name] = string.unpack(total)[i]
      end

      parts.delete(:null) {}
      parts
    end

    # Unpacks from a socket.
    #
    # @param sock [#read] the socket to unpack from.
    # @return [Hash<Symbol, Object>] the unpacked data.
    def unpack_from_socket(sock)
      read  = ""
      total = ""
      parts = {}

      directives.each_with_index do |directive, i|
        total << directive.to_s(parts)
        read << sock.read(directive.bytesize parts)
        parts[directive.name] = read.unpack(total)[i]
      end

      parts.delete(:null) {}
      parts
    end

    # This unpacks the entire string at once.  It assumes that none of
    # the directives will need the values of other directives.  If
    # you're not sure what this means, don't use it.
    #
    # @param string [String] the packed string.
    # @return [Hash<Symbol, Object>] the unpacked data.
    def fast_unpack(string)
      out = string.unpack(to_s)
      parts = {}

      directives.each_with_index do |directive, i|
        parts[directive.name] = out[i]
      end

      parts.delete(:null) {}
      parts
    end

    # Finalizes all of the directives.
    #
    # @return [void]
    def finalize_directives!
      @finalized = true
      directives.reject!(&:empty?)
      directives.map(&:finalize!)
    end

    # Inspects the package.
    #
    # @return [String]
    def inspect
      "#<#{self.class.name}:#{"0x%014x" % directives.map(&:object_id).inject(&:+)}>"
    end

    # Creates a new directive with the given method and arguments.
    #
    # @return [Directive] the new directive.
    def method_missing(method, *arguments, &block)
      super if @finalized
      if arguments.length == 1 && arguments.first.is_a?(Directive)
        arguments.first.add_modifier Modifier.new(method)
      else
        (directives.push Directive.new(method)).last
      end
    end

  end
end
