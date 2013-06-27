require 'packed_struct/package'
require 'packed_struct/directive'
require 'packed_struct/modifier'

# Create structs to manage packed strings.
module PackedStruct

  # The structs that were defined on the module that included this.
  # If the structs were defined without a name, this will be the one
  # and only struct that was defined (or the last one that was
  # defined).
  #
  # @return [Package, Hash<Symbol, Package>]
  def structs
    @structs ||= {}
  end

  alias_method :struct, :structs

  # Define a struct.  The name will be used for {#structs}, and the
  # block will run in the context of a {Package}.
  #
  # @yield []
  # @param name [Symbol, nil] the name of the struct.  If it's nil, it
  #   is set as the only struct of the included module.
  # @return (see #structs)
  def struct_layout(name = nil, &block)
    structs[name] = Package.new
    structs[name].instance_exec &block
    structs[name].finalize_directives!

    if name == nil
      @structs = structs[name]
    end

    structs
  end

  # Called when this is included into another module.
  #
  # @api private
  # @param reciever [Module] the reciever that included this one.
  # @return [void]
  def self.included(reciever)
    reciever.extend self
  end

end
