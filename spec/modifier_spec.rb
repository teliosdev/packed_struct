describe PackedStruct::Modifier do
  context "identifying endians" do
    subject { PackedStruct::Modifier.new(:little_endian) }

    its(:type ) { should eq [:endian] }
    its(:value) { should eq [:little] }
  end

  context "identifying types" do
    subject { PackedStruct::Modifier.new(:int) }

    its(:type ) { should eq [:type] }
    its(:value) { should eq [:int]  }
  end

  context "identifying signedness" do
    subject { PackedStruct::Modifier.new(:unsigned) }

    its(:type ) { should eq [:signedness] }
    its(:value) { should eq [:unsigned]   }
  end

  context "identifying null" do
    subject { PackedStruct::Modifier.new(:null) }

    its(:type ) { should eq [:signedness] }
    its(:value) { should eq [:signed]     }
  end

  context "identifying string types" do
    subject { PackedStruct::Modifier.new(:hex) }

    its(:type ) { should eq [:string_type] }
    its(:value) { should eq [:hex] }
  end

  context "identifying combined types" do
    subject { PackedStruct::Modifier.new(:uint32) }

    its(:type ) { should eq [:signedness, :size] }
    its(:value) { should eq [:unsigned,   32   ] }
  end

  subject { PackedStruct::Modifier.new(:little_endian) }

  it "should only call #compile! once" do
    #subject.stub(:compile!)
    subject.stub(:compile!).with(no_args).once.and_call_original

    subject.type
    subject.value
  end
end
