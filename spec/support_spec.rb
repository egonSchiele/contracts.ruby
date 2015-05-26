module Contracts
  RSpec.describe ContractsSupport do
    describe "eigenclass?" do
      it "is falsey for non-singleton classes" do
        expect(Contracts::ContractsSupport.eigenclass? String).to be_falsey
      end

      it "is truthy for singleton classes" do
        singleton_class = String.instance_exec { class << self; self; end }
        expect(Contracts::ContractsSupport.eigenclass? singleton_class).to be_truthy
      end
    end

    describe "eigenclass_of" do
      it "returns the eigenclass of a given object" do
        singleton_class = String.instance_exec { class << self; self; end }
        expect(Contracts::ContractsSupport.eigenclass_of String).to eq singleton_class
      end
    end
  end
end
