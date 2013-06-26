class Test
  include PackedStruct

  struct_layout :something do
    little_endian signed size[32] # defaults to a number of size 32.
    little_endian signed id[32]
    little_endian signed type[32]
    string body[size]
    null
  end
end
