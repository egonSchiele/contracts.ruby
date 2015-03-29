class GenericExample
  Contract Args[String], Num => ArrayOf[String]
  def splat_then_arg(*vals, n)
    vals.map { |v| v * n }
  end
end

RSpec.describe "Contracts:" do
  before :all do
    @o = GenericExample.new
  end

  describe "Splat not last (or penultimate to block)" do
    it "should work with arg after splat" do
      expect { @o.splat_then_arg('hello', 'world', 3) }.to_not raise_error
    end
  end
end
