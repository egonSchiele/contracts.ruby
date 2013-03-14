require 'testable'

=begin rdoc
This module contains all the builtin contracts.
If you want to use them, first:
  
  import Contracts

And then use these or write your own!

A simple example:

  Contract Num, Num => Num
  def add(a, b)
     a + b
   end

The contract is <tt>Contract Num, Num, Num</tt>. That says that the +add+ function takes two numbers and returns a number.
=end
module Contracts
  # Check that an argument is +Numeric+.
  class Num
    def self.valid? val
      val.is_a? Numeric
    end

    def self.testable?
      true
    end

    def self.test_data
      [-1, 0, 1, 1.5, 50000]
    end
  end

  # Check that an argument is a positive number.
  class Pos
    def self.valid? val
      val > 0
    end

    def testable?
      true
    end

    def self.test_data
      (0..5).map { rand(999) + 1 }
    end
  end

  # Check that an argument is a negative number.
  class Neg
    def self.valid? val
      val < 0
    end

    def testable?
      true
    end

    def self.test_data
      (0..5).map { (rand(999) + 1) * -1 }
    end
  end

  # Passes for any argument.
  class Any
    def self.valid? val
      true
    end
  end

  # Fails for any argument.
  class None
    def self.valid? val
      false
    end
  end

  # Use this when you are writing your own contract classes.
  # Allows your contract to be called with <tt>[]</tt> instead of <tt>.new</tt>:
  #
  # Old: <tt>Or.new(param1, param2)</tt>
  #
  # New: <tt>Or[param1, param2]</tt>
  #
  # Of course, <tt>.new</tt> still works.
  class CallableClass
    def self.[](*vals)
      self.new(*vals)
    end
  end

  # Takes a variable number of contracts.
  # The contract passes if any of the contracts pass.
  # Example: <tt>Or[Fixnum, Float]</tt>
  class Or < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      @vals.any? do |contract|
        res, _ = Contract.valid?(val, contract)
        res
      end
    end

    def to_s
      @vals[0, @vals.size-1].join(", ") + " or " + @vals[-1].to_s
    end

    # this can only be tested IF all the sub-contracts have a test_data method
    def testable?
      @vals.all? do |val|
        Testable.testable?(val)
      end    
    end

    def test_data
      @vals.map { |val|
        Testable.test_data(val)
      }.flatten
    end
  end

  # Takes a variable number of contracts.
  # The contract passes if exactly one of those contracts pass.
  # Example: <tt>Xor[Fixnum, Float]</tt>
  class Xor < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      results = @vals.map do |contract|
        res, _ = Contract.valid?(val, contract)
        res
      end
      results.count(true) == 1
    end

    def to_s
      @vals[0, @vals.size-1].join(", ") + " xor " + @vals[-1].to_s
    end

    def testable?
      @vals.all? do |val|
        Testable.testable? val
      end    
    end

    def test_data
      @vals.map { |val|
        Testable.test_data val
      }.flatten
    end    
  end  

  # Takes a variable number of contracts.
  # The contract passes if all contracts pass.
  # Example: <tt>And[Fixnum, Float]</tt>  
  class And < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      @vals.all? do |contract|
        res, _ = Contract.valid?(val, contract)
        res
      end
    end

    def to_s
      @vals[0, @vals.size-1].join(", ") + " and " + @vals[-1].to_s
    end
  end

  # Takes a variable number of method names as symbols.
  # The contract passes if the argument responds to all
  # of those methods.
  # Example: <tt>RespondTo[:password, :credit_card]</tt>
  class RespondTo < CallableClass
    def initialize(*meths)
      @meths = meths
    end

    def valid?(val)
      @meths.all? do |meth|
        val.respond_to? meth
      end
    end

    def to_s
      "a value that responds to #{@meths.inspect}"
    end
  end

  # Takes a variable number of method names as symbols.
  # Given an argument, all of those methods are called
  # on the argument one by one. If they all return true,
  # the contract passes.
  # Example: <tt>Send[:valid?]</tt>
  class Send < CallableClass
    def initialize(*meths)
      @meths = meths
    end

    def valid?(val)
      @meths.all? do |meth|
        val.send(meth)
      end
    end

    def to_s
      "a value that returns true for all of #{@meths.inspect}"
    end  
  end

  # Takes a class +A+. If argument.is_a? +A+, the contract passes.
  # Example: <tt>IsA[Numeric]</tt>
  class IsA < CallableClass
    def initialize(cls)
      @cls = cls
    end

    def valid?(val)
      val.is_a? @cls
    end

    def to_s
      "a #{@cls.inspect}"
    end
  end

  # Takes a variable number of contracts. The contract
  # passes if all of those contracts fail for the given argument.
  # Example: <tt>Not[nil]</tt>
  class Not < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      @vals.all? do |contract|
        res, _ = Contract.valid?(val, contract)
        !res
      end
    end

    def to_s
      "a value that is none of #{@vals.inspect}"
    end
  end

  # Takes a contract. The related argument must be an array.
  # Checks the contract against every element of the array.
  # If it passes for all elements, the contract passes.
  # Example: <tt>ArrayOf[Num]</tt>
  class ArrayOf < CallableClass
    def initialize(contract)
      @contract = contract
    end

    def valid?(vals)
      return false unless vals.is_a?(Array)
      vals.all? do |val|
        res, _ = Contract.valid?(val, @contract)
        res
      end
    end

    def to_s
      "an array of #{@contract}"
    end

    def testable?
      Testable.testable? @contract
    end

    def test_data
      [[], [Testable.test_data(@contract)], [Testable.test_data(@contract), Testable.test_data(@contract)]]
    end    
  end

  # Used for <tt>*args</tt> (variadic functions). Takes a contract
  # and uses it to validate every element passed in
  # through <tt>*args</tt>.
  # Example: <tt>Args[Or[String, Num]]</tt>
  class Args < CallableClass
    attr_reader :contract
    def initialize(contract)
      @contract = contract
    end

    def to_s
      "Args[#{@contract}]"
    end

    def testable?
      Testable.testable? @contract
    end

    def test_data
      [[], [Testable.test_data(@contract)], [Testable.test_data(@contract), Testable.test_data(@contract)]]
    end    
  end

  class Bool
    def self.valid? val
      val.is_a?(TrueClass) || val.is_a?(FalseClass)
    end
  end

  # Takes a Contract.
  # The contract passes if the contract passes or the given value is nil.
  # Maybe(foo) is equivalent to Or[foo, nil].
  class Maybe < Or
    def initialize(*vals)
      super(*(vals + [nil]))
    end
  end

  class ::Hash
    def testable?
      self.values.all? do |val|
        Testable.testable?(val)
      end
    end

    def test_data
      keys = self.keys
      _vals = keys.map do |key|
        ret = Testable.test_data(self[key])
        if ret.is_a? Array
          ret
        else
          [ret]
        end
      end
      all_vals = Testable.product(_vals)
      hashes = []
      all_vals.each do |vals|
        hash = {}
        keys.zip(vals).each do |key, val|
          hash[key] = val
        end
        hashes << hash
      end
      hashes
    end
  end

  class ::String
    def self.testable?
      true
    end

    def self.test_data
      # send a random string
      ('a'..'z').to_a.shuffle[0, 10].join
    end
  end

  # Used to define contracts on functions passed in as arguments.
  # Example: <tt>Func[Num => Num] # the function should take a number and return a number</tt>
  class Func < CallableClass
    attr_reader :contracts    
    def initialize(*contracts)
      @contracts = contracts
    end
  end
end
