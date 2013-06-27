require 'test'

describe PackedStruct::Directive do

  subject { Test.structs[:something].directives.first }

  its(:name) { should be :size }
  its(:modifiers) { should have(2).items }
  its(:to_s) { should == "l<" }
  its(:tags) { should == { :endian=>:little, :signedness=>:signed, :size=>32, :precision=>:single, :size_mod=>0 } }

end
