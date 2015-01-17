include Contracts

RSpec.describe "Contracts:" do
  before :all do
    @o = Object.new
  end

  describe "basic" do
    it "should fail for insufficient arguments" do
      expect {
        @o.hello
      }.to raise_error
    end

    it "should fail for insufficient contracts" do
      expect { @o.bad_double(2) }.to raise_error(ContractError)
    end
  end

  describe "pattern matching" do
    let(:string_with_hello) { "Hello, world" }
    let(:string_without_hello) { "Hi, world" }
    let(:expected_decorated_string) { "Hello, world!" }
    subject { PatternMatchingExample.new }

    it "should work as expected when there is no contract violation" do
      expect(
        subject.process_request(PatternMatchingExample::Success[string_with_hello])
      ).to eq(PatternMatchingExample::Success[expected_decorated_string])

      expect(
        subject.process_request(PatternMatchingExample::Failure.new)
      ).to be_a(PatternMatchingExample::Failure)
    end

    it "should not fall through to next pattern when there is a deep contract violation" do
      expect(PatternMatchingExample::Failure).not_to receive(:is_a?)
      expect {
        subject.process_request(PatternMatchingExample::Success[string_without_hello])
      }.to raise_error(ContractError)
    end

    it "should fail when the pattern-matched method's contract fails" do
      expect {
        subject.process_request("bad input")
      }.to raise_error(ContractError)
    end

    context "when failure_callback was overriden" do
      before do
        ::Contract.override_failure_callback do |_data|
          raise RuntimeError, "contract violation"
        end
      end

      it "calls a method when first pattern matches" do
        expect(
          subject.process_request(PatternMatchingExample::Success[string_with_hello])
        ).to eq(PatternMatchingExample::Success[expected_decorated_string])
      end

      it "falls through to 2nd pattern when first pattern does not match" do
        expect(
          subject.process_request(PatternMatchingExample::Failure.new)
        ).to be_a(PatternMatchingExample::Failure)
      end

      it "uses overriden failure_callback when pattern matching fails" do
        expect {
          subject.process_request("hello")
        }.to raise_error(RuntimeError, /contract violation/)
      end
    end
  end

  describe "usage in singleton class" do
    it "should work normally when there is no contract violation" do
      expect(SingletonClassExample.hoge("hoge")).to eq("superhoge")
    end

    it "should fail with proper error when there is contract violation" do
      expect {
        SingletonClassExample.hoge(3)
      }.to raise_error(ContractError, /Expected: String/)
    end

    context "when owner class does not include Contracts" do
      it "fails with descriptive error" do
        expect {
          Class.new do
            class << self
              Contract String => String
              def hoge(name)
                "super#{name}"
              end
            end
          end
        }.to raise_error(Contracts::ContractsNotIncluded, ContractsNotIncluded::DEFAULT_MESSAGE)
      end
    end
  end

  describe "singleton methods self in inherited methods" do
    it "should be a proper self" do
      expect(SingletonInheritanceExampleSubclass.a_contracted_self).to eq(SingletonInheritanceExampleSubclass)
    end
  end

  describe "instance methods" do
    it "should allow two classes to have the same method with different contracts" do
      a = A.new
      b = B.new
      expect {
        a.triple(5)
        b.triple("a string")
      }.to_not raise_error
    end
  end

  describe "instance and class methods" do
    it "should allow a class to have an instance method and a class method with the same name" do
      a = A.new
      expect {
        a.instance_and_class_method(5)
        A.instance_and_class_method("a string")
      }.to_not raise_error
    end
  end

  describe "class methods" do
    it "should pass for correct input" do
      expect { Object.a_class_method(2) }.to_not raise_error
    end

    it "should fail for incorrect input" do
      expect { Object.a_class_method("bad") }.to raise_error(ContractError)
    end
  end

  it "should work for functions with no args" do
    expect { @o.no_args }.to_not raise_error
  end

  describe "classes" do
    it "should pass for correct input" do
      expect { @o.hello("calvin") }.to_not raise_error
    end

    it "should fail for incorrect input" do
      expect { @o.hello(1) }.to raise_error(ContractError)
    end
  end

  describe "classes with a valid? class method" do
    it "should pass for correct input" do
      expect { @o.double(2) }.to_not raise_error
    end

    it "should fail for incorrect input" do
      expect { @o.double("bad") }.to raise_error(ContractError)
    end
  end

  describe "Procs" do
    it "should pass for correct input" do
      expect { @o.square(2) }.to_not raise_error
    end

    it "should fail for incorrect input" do
      expect { @o.square("bad") }.to raise_error(ContractError)
    end
  end

  describe "Arrays" do
    it "should pass for correct input" do
      expect { @o.sum_three([1, 2, 3]) }.to_not raise_error
    end

    it "should fail for insufficient items" do
      expect { @o.square([1, 2]) }.to raise_error(ContractError)
    end

    it "should fail for some incorrect elements" do
      expect { @o.sum_three([1, 2, "three"]) }.to raise_error(ContractError)
    end
  end

  describe "Hashes" do
    it "should pass for exact correct input" do
      expect { @o.person({:name => "calvin", :age => 10}) }.to_not raise_error
    end

    it "should pass even if some keys don't have contracts" do
      expect { @o.person({:name => "calvin", :age => 10, :foo => "bar"}) }.to_not raise_error
    end

    it "should fail if a key with a contract on it isn't provided" do
      expect { @o.person({:name => "calvin"}) }.to raise_error(ContractError)
    end

    it "should fail for incorrect input" do
      expect { @o.person({:name => 50, :age => 10}) }.to raise_error(ContractError)
    end
  end

  describe "blocks" do
    it "should pass for correct input" do
      expect { @o.do_call {
        2 + 2
      }}.to_not raise_error
    end

    it "should fail for incorrect input" do
      expect { @o.do_call(nil) }.to raise_error(ContractError)
    end
  end

  describe "varargs" do
    it "should pass for correct input" do
      expect { @o.sum(1, 2, 3) }.to_not raise_error
    end

    it "should fail for incorrect input" do
      expect { @o.sum(1, 2, "bad") }.to raise_error(ContractError)
    end
  end

  describe "contracts on functions" do
    it "should pass for a function that passes the contract" do
      expect { @o.map([1, 2, 3], lambda { |x| x + 1 }) }.to_not raise_error
    end

    it "should fail for a function that doesn't pass the contract" do
      expect { @o.map([1, 2, 3], lambda { |x| "bad return value" }) }.to raise_error(ContractError)
    end
  end

  describe "default args to functions" do
    it "should work for a function call that relies on default args" do
      expect { @o.default_args }.to_not raise_error
      expect { @o.default_args("foo") }.to raise_error(ContractError)
    end
  end

  describe "classes" do
    it "should not fail for an object that is the exact type as the contract" do
      p = Parent.new
      expect { @o.id_(p) }.to_not raise_error
    end

    it "should not fail for an object that is a subclass of the type in the contract" do
      c = Child.new
      expect { @o.id_(c) }.to_not raise_error
    end
  end

  describe "failure callbacks" do
    before :each do
      ::Contract.override_failure_callback do |_data|
        should_call
      end
    end

    context "when failure_callback returns false" do
      let(:should_call) { false }

      it "does not call a function for which the contract fails" do
        res = @o.double("bad")
        expect(res).to eq(nil)
      end
    end

    context "when failure_callback returns true" do
      let(:should_call) { true }

      it "calls a function for which the contract fails" do
        res = @o.double("bad")
        expect(res).to eq("badbad")
      end
    end
  end

  describe "functype" do
    it "should correctly print out a instance method's type" do
      expect(@o.functype(:double)).not_to eq("")
    end

    it "should correctly print out a class method's type" do
      expect(A.functype(:a_class_method)).not_to eq("")
    end
  end

  describe "private methods" do
    it "should raise an error if you try to access a private method" do
      expect { @o.a_private_method }.to raise_error
    end
  end

  describe "inherited methods" do
    it "should apply the contract to an inherited method" do
      c = Child.new
      expect { c.double(2) }.to_not raise_error
      expect { c.double("asd") }.to raise_error
    end
  end
end
