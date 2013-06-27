describe PackedStruct::Modifier do
  context "identifying endians" do
    subject { PackedStruct::Modifier.new(:little_endian) }

    its(:type ) { should be :endian }
    its(:value) { should be :little }
  end

  context "identifying types" do
    subject { PackedStruct::Modifier.new(:int) }

    its(:type ) { should be :type }
    its(:value) { should be :int  }
  end

  context "identifying signedness" do
    subject { PackedStruct::Modifier.new(:unsigned) }

    its(:type ) { should be :signedness }
    its(:value) { should be :unsigned   }
  end

  context "identifying null" do
    subject { PackedStruct::Modifier.new(:null) }

    its(:type ) { should be :signedness }
    its(:value) { should be :signed     }
  end

  context "identifying string types" do
    subject { PackedStruct::Modifier.new(:hex) }

    its(:type ) { should be :string_type }
    its(:value) { should be :hex }
  end

  subject { PackedStruct::Modifier.new(:little_endian) }

  it "should only call #compile! once" do
    #subject.stub(:compile!)
    subject.stub(:compile!).with(no_args).once.and_call_original

    subject.type
    subject.value
  end
end
