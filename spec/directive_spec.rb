require 'test'

describe PackedStruct::Directive do

  subject { Test.structs[:something].directives.first }

  its(:name) { should be :size }
  its(:size) { should be 32 }
  its(:sub_names) { should have(3).items }
  its(:to_s) { should == "l<" }
  its(:tags) { should == { :size => 32, :type => nil, :signed => :signed, :endian => :little } }

end
