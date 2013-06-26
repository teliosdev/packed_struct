module PackedStruct

  # Manages the struct overall, and keeps track of the directives.
  # Directives are packed in the order that they are joined, such
  # that the first one defined is the first one on the string.
  class Package

    # The list of directives that the package has.
    #
    # @return [Array<Directive>]
    def directives
      @directives = @directives.select { |x| x.parent.nil? }
      @directives
    end

    # Initialize the package.
    def initialize
      @directives = []
    end

    # Turn the package into a string.  Uses the directives (calls
    # {Directive#to_s} on them), and joins the result.
    #
    # @return [String] the string ready for #pack.
    def to_s
      directives.map(&:to_s).join(' ')
    end

    alias_method :to_str, :to_s

    # Packs the given data into a string.  The keys of the data
    # correspond to the names of the directives.
    #
    # @param [Hash<Symbol, Object>] the data.
    # @return [String] the packed data.
    def pack(data)
      values = []
      data.each do |k, v|
        values.push([k, v])
      end

      mapped_directives = @directives.map(&:name)

      values = values.select { |x| mapped_directives.include?(x[0]) }

      values.sort! do |a, b|
        o = mapped_directives.index(a[0]) <=> mapped_directives.index(b[0])
      end

      pack_with_array(values.map(&:last))
    end

    # Packs the directives into a string.  Uses an array.
    # The parameters can either be an array, or a set of values.
    #
    # @return [String]
    def pack_with_array(*array)
      array.flatten!

      directives.each_with_index { |e, i| e.value = array[i] }
      out = array.pack(self.to_s)
      directives.each { |x| x.value = nil }
      out
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
        total << directive.to_s
        value = string.unpack(total)[i]
        directive.value = value
        parts[directive.name] = value
      end


      directives.each { |x| x.value = nil }

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
        total << directive.to_s
        read << sock.read(directive.bytesize)
        value = read.unpack(total)[i]
        directive.value = value
        parts[directive.name] = value
      end

      directives.each { |x| x.value = nil }

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
      if @directives.map(&:name).include?(method) && arguments.length == 0
        @directives.select { |x| x.name == method }.first
      else
        directive = Directive.new(method, *arguments)
        @directives << directive
        directive
      end
    end

  end
end
