class GenericExample
  Contract Args[String], { repeat: Maybe[Num] } => ArrayOf[String]
  def splat_then_optional_named(*vals, repeat: 2)
    vals.map { |v| v * repeat }
  end
end

RSpec.describe "Contracts:" do
  before :all do
    @o = GenericExample.new
  end

  describe "Optional named arguments" do
    it "should work with optional named argument unfilled after splat" do
      expect { @o.splat_then_optional_named('hello', 'world') }.to_not raise_error
    end

    it "should work with optional named argument filled after splat" do
      expect { @o.splat_then_optional_named('hello', 'world', repeat: 3) }.to_not raise_error
    end
  end
end



