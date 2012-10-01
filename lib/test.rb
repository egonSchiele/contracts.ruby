require 'contracts'
require 'testable'
include Contracts

class Object

  Contract Num, Num
  def double(x)
    x * 2
  end

  # bug: the `b` here doesn't get typechecked and throws an error.
  Contract Num, Num, Num
  def add(a, b="hello!")
    a + b
  end

  Contract Proc, nil
  def run(&blk)
    puts "running:"
    blk.call
  end

  Contract Method, Num
  def call(func)
    func.call
  end

  Contract Args[Num], Num
  def sum(*vals)
    vals.inject(0) do |acc, v|
      acc + v
    end
  end

  Contract ({ :age => Num, :name => String }), nil
  def person(data)
    p data
  end

  Contract Num, Num
  def test(x)
    x + 2
  end
end

# this doesn't work
# p Object.send(:sum, 1, 2)

# but this does:
# p send(:sum, 1, 2)
#
# why???

Testable.check_all
# Testable.check(method(:double))

# p Object.test(5)
#
Object.Hello
