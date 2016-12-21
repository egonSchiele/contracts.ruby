RSpec.describe "Contracts::ErrorFormatters" do
  before :all do
    @o = GenericExample.new
  end

  describe "self.class_for" do
    it "returns the right formatter for passed in data" do
    end
  end

  def format_message(str)
    str.split("\n").map(&:strip).join("\n")
  end

  describe "self.failure_msg" do
    it "includes normal information" do
      expect do
        @o.simple_keywordargs(age: "2", invalid_third: 1)
      end.to raise_error do |e|
        error_msg = %Q{Contract violation for argument 1 of 1:
Expected: (KeywordArgs[{:name=>String, :age=>Fixnum}])
Actual: {:age=>"2", :invalid_third=>1}
Missing Contract: {:invalid_third=>1}
Invalid Args: [{:age=>"2", :contract=>Fixnum}]
Missing Args: {:name=>String}
Value guarded in: GenericExample::simple_keywordargs
With Contract: KeywordArgs => NilClass}

        expect(e.class).to eq(ParamContractError)
        expect(format_message(e.message)).to include(format_message(error_msg))
      end
    end

    it "includes Missing Contract information" do
      expect do
        @o.simple_keywordargs(age: "2", invalid_third: 1, invalid_fourth: 1)
      end.to raise_error do |e|
        diff_msg = %Q{Missing Contract: {:invalid_third=>1, :invalid_fourth=>1}}
        expect(e.class).to eq(ParamContractError)
        expect(e.message).to include(diff_msg)
      end
    end

    it "includes Invalid Args information" do
      expect do
        @o.simple_keywordargs(age: "2", invalid_third: 1)
      end.to raise_error do |e|
        diff_msg = %Q{Invalid Args: [{:age=>"2", :contract=>Fixnum}]}
        expect(e.class).to eq(ParamContractError)
        expect(e.message).to include(diff_msg)
      end
    end

    it "includes Missing Args information" do
      expect do
        @o.simple_keywordargs(age: "2", invalid_third: 1)
      end.to raise_error do |e|
        diff_msg = %Q{Missing Args: {:name=>String}}
        expect(e.class).to eq(ParamContractError)
        expect(e.message).to include(diff_msg)
      end
    end
  end
end
