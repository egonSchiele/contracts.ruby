require 'lib/contracts'

include Contracts

class Object
  class A
    def good
      true
    end
  end

  class B
    def bad
      false
    end
  end

  class C
    def good
      false
    end
    def bad
      true
    end
  end
  
  Contract Num
  def bad_double(x)
    x * 2
  end

  Contract Num, Num
  def double(x)
    x * 2
  end

  Contract String, nil
  def hello(name)
  end

  Contract lambda { |x| x.is_a? Numeric }, Num
  def square(x)
    x ** 2
  end

  Contract [Num, Num, Num], Num
  def sum_three(vals)
    vals.inject(0) do |acc, x|
      acc + x
    end
  end

  Contract ({:name => String, :age => Fixnum}), nil
  def person(data)
  end

  Contract Proc, Any
  def call(&blk)
    blk.call
  end

  Contract Args[Num], Num
  def sum(*vals)
    vals.inject(0) do |acc, val|
      acc + val
    end
  end

  Contract Pos, nil
  def pos_test(x)
  end

  Contract Neg, nil
  def neg_test(x)
  end

  Contract Any, nil
  def show(x)
  end

  Contract None, nil
  def fail_all(x)
  end

  Contract Or[Num, String], nil
  def num_or_string(x)
  end

  Contract Xor[RespondsTo[:good], RespondsTo[:bad]], nil
  def xor_test(x)
  end

  Contract And[IsA[A], RespondsTo[:good]], nil
  def and_test(x)
  end

  Contract RespondsTo[:good], nil
  def responds_test(x)
  end

  Contract Send[:good], nil
  def send_test(x)
  end

  Contract IsA[A], nil
  def isa_test(x)
  end

  Contract Not[nil], nil
  def not_nil(x)
  end

  Contract ArrayOf[Num], Num
  def product(vals)
    vals.inject(1) do |acc, x|
      acc * x
    end
  end
end
