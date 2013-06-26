# PackedStruct

`PackedStruct` is a way to define packing strings (see [`Array#pack`](http://ruby-doc.org/core-2.0/Array.html#method-i-pack)).
It was created after @charliesome suggested [a format](https://gist.github.com/redjazz96/6dda0554f62e4f77253a) for defining these strings, but never finished it.

The basic way of defining a packed struct is such:

```Ruby
class RconPacket
  include PackedStruct
  struct_layout :packet do
    little_endian signed size[32] # defaults to a number of size 32.
    little_endian signed id[32]
    little_endian signed type[32]
    string body[size]
    null
  end
end
```

This can be accessed as:

```Ruby
RconPacket.structs[:packet].pack(size: 11, id: 1, type: 0, body: "hello world")
# => "\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00"
```

You can also unpack strings.

```Ruby
RconPacket.structs[:packet].unpack("\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00")
# => {:size => 11, :id => 1, :type => 0, :body => "hello world"}
```
