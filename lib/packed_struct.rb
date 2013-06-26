require 'packed_struct/package'
require 'packed_struct/directive'

module PackedStruct

  def structs
    @structs ||= {}
  end

  def struct_layout(name = nil, &block)
    structs[name] = Package.new
    structs[name].instance_exec &block

    if name == nil
      @structs = structs[name]
    end

    structs
  end

  def self.included(reciever)
    reciever.extend self
  end

end
