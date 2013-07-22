require 'test'
require 'stringio'

describe PackedStruct::Package do
  subject { Test.structs[:something] }

  its(:directives) { should have(6).items }

  it "returns correct values for has field" do
    subject.should have_field :size
    subject.should_not have_field :some_field
  end

  it "should stringify correctly" do
    subject.to_s(:size => 0).should == "l< l< l< c a0 x"
  end

  it "packs correctly" do
    subject.pack(:body => "hello world", :size => 11, :packet_id => 1, :packet_type => 0, :options => 0).should == "\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00hello world\x00"
  end

  it "unpacks correctly" do
    subject.unpack("\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00hello world\x00").should == { :size => 11, :packet_id => 1, :packet_type => 0, :body => "hello world", :options => 0 }
  end

  it "unpacks from a socket" do
    sock = StringIO.new("\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00hello world\x00")

    subject.unpack_from_socket(sock).should == { :size => 11, :packet_id => 1, :packet_type => 0, :body => "hello world", :options => 0 }
  end
end
