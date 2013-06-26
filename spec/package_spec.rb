require 'test'
require 'stringio'

describe PackedStruct::Package do
  subject { Test.structs[:something] }

  its(:to_s) { should == "l< l< l< a0 x" }
  its(:directives) { should have(5).items }

  it "packs correctly" do
    subject.pack(:body => "hello world", :size => 11, :packet_id => 1, :packet_type => 0).should == "\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00"
  end

  it "unpacks correctly" do
    subject.unpack("\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00").should == { :size => 11, :packet_id => 1, :packet_type => 0, :body => "hello world" }
  end

  it "unpacks from a socket" do
    sock = StringIO.new("\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00")

    subject.unpack_from_socket(sock).should == { :size => 11, :packet_id => 1, :packet_type => 0, :body => "hello world" }
  end
end
