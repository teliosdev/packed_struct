$LOAD_PATH.unshift 'lib'
require "packed_struct/version"

Gem::Specification.new do |s|
  s.name              = "packed_struct"
  s.version           = PackedStruct::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Cleans up the string mess when packing items."
  s.homepage          = "http://github.com/redjazz96/packed_struct"
  s.email             = "redjazz96@gmail.com"
  s.authors           = [ "Jeremy Rodi" ]
  s.has_rdoc          = false

  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.description       = <<desc
  Cleans up the string mess when packing items (in Array#pack) and unpacking items (in String#unpack).
desc
end
