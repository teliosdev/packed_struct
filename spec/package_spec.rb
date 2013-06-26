require 'test'

describe PackedStruct::Package do
  subject { Test.structs[:something] }

  its(:to_s) { should == "l< l< l< a0 x" }
  its(:directives) { should have(5).items }

  it "packs correctly" do
    subject.pack(:size => 11, :id => 1, :type => 0, :body => "hello world").should == "\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00"
  end

  it "unpacks correctly" do
    subject.unpack("\v\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00hello world\x00").should == { :size => 11, :id => 1, :type => 0, :body => "hello world" }
  end
end
