require 'test'

describe PackedStruct do
  it "extends the reciever" do
    Test.should respond_to :structs
  end

  it "keeps track of the structs" do
    Test.structs.should have_key :something
  end
end
