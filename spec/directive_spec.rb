require 'test'

describe PackedStruct::Directive do

  context "normal" do
    subject { Test.structs[:something].directives.first }

    its(:name) { should be :size }
    its(:modifiers) { should have(2).items }
    its(:to_s) { should == "l<" }
    its(:tags) { should == { :endian=>:little, :signedness=>:signed, :size=>32, :precision=>:single, :size_mod=>0 } }
    its(:undefined_size?) { should be false }

  end

  context "undefined size" do
    subject { Test.structs[:something].directives.select { |x| x.name == :body }.first }

    its(:name) { should be :body }
    its(:modifiers) { should have(1).item }
    its(:undefined_size?) { should be true }
  end

end
