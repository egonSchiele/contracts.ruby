class A
  include Contracts

  Contract Num => Num
  def self.a_class_method x
    x + 1
  end

  def good
    true
  end

  Contract Num => Num
  def triple x
    x * 3
  end

  Contract Num => Num
  def instance_and_class_method x
    x * 2
  end

  Contract String => String
  def self.instance_and_class_method x
    x * 2
  end
end

class B
  include Contracts

  def bad
    false
  end

  Contract String => String
  def triple x
    x * 3
  end
end

class C
  include Contracts

  def good
    false
  end
  def bad
    true
  end
end

class GenericExample
  include Contracts

  Contract Num => Num
  def GenericExample.a_class_method x
    x + 1
  end

  Contract Num => nil
  def bad_double(x)
    x * 2
  end

  Contract Num => Num
  def double(x)
    x * 2
  end

  Contract String => nil
  def hello(name)
  end

  Contract lambda { |x| x.is_a? Numeric } => Num
  def square(x)
    x ** 2
  end

  Contract [Num, Num, Num] => Num
  def sum_three(vals)
    vals.inject(0) do |acc, x|
      acc + x
    end
  end

  Contract ({:name => String, :age => Fixnum}) => nil
  def person(data)
  end

  Contract Proc => Any
  def do_call(&blk)
    blk.call
  end

  Contract Args[Num] => Num
  def sum(*vals)
    vals.inject(0) do |acc, val|
      acc + val
    end
  end

  Contract Args[Num], Proc => Num
  def with_partial_sums(*vals, &blk)
    sum = vals.inject(0) do |acc, val|
      blk[acc]
      acc + val
    end
    blk[sum]
  end

  Contract Args[Num], Func[Num => Num] => Num
  def with_partial_sums_contracted(*vals, &blk)
    sum = vals.inject(0) do |acc, val|
      blk[acc]
      acc + val
    end
    blk[sum]
  end

  Contract Num, Proc => nil
  def double_with_proc(x, &blk)
    blk.call(x * 2)
    nil
  end

  Contract Pos => nil
  def pos_test(x)
  end

  Contract Neg => nil
  def neg_test(x)
  end

  Contract Nat => nil
  def nat_test(x)
  end

  Contract Any => nil
  def show(x)
  end

  Contract None => nil
  def fail_all(x)
  end

  Contract Or[Num, String] => nil
  def num_or_string(x)
  end

  Contract Xor[RespondTo[:good], RespondTo[:bad]] => nil
  def xor_test(x)
  end

  Contract And[A, RespondTo[:good]] => nil
  def and_test(x)
  end

  Contract RespondTo[:good] => nil
  def responds_test(x)
  end

  Contract Send[:good] => nil
  def send_test(x)
  end

  Contract Not[nil] => nil
  def not_nil(x)
  end

  Contract ArrayOf[Num] => Num
  def product(vals)
    vals.inject(1) do |acc, x|
      acc * x
    end
  end

  Contract Bool => nil
  def bool_test(x)
  end

  Contract nil => Num
  def no_args
    1
  end

  Contract ArrayOf[Num], Func[Num => Num] => ArrayOf[Num]
  def map(arr, func)
    ret = []
    arr.each do |x|
      ret << func[x]
    end
    ret
  end

  Contract Num => Num
  def default_args(x = 1)
    2
  end

  Contract Maybe[Num] => Maybe[Num]
  def maybe_double x
    if x.nil?
      nil
    else
      x * 2
    end
  end

  Contract HashOf[Symbol, Num] => Num
  def gives_max_value(hash)
    hash.values.max
  end

  Contract nil => String
  def a_private_method
    "works"
  end
  private :a_private_method

  Contract nil => String
  def a_protected_method
    "works"
  end
  protected :a_protected_method

  private

  Contract nil => String
  def a_really_private_method
    "works for sure"
  end

  protected

  Contract nil => String
  def a_really_protected_method
    "works for sure"
  end
end

# for testing inheritance
class Parent
  include Contracts

  Contract Num => Num
  def double x
    x * 2
  end
end

class Child < Parent
end

class GenericExample
  Contract Parent => Parent
  def id_ a
    a
  end

  Contract Exactly[Parent] => nil
  def exactly_test(x)
  end
end

# for testing equality
class Foo
end
module Bar
end
Baz = 1

class GenericExample
  Contract Eq[Foo] => Any
  def eq_class_test(x)
  end

  Contract Eq[Bar] => Any
  def eq_module_test(x)
  end

  Contract Eq[Baz] => Any
  def eq_value_test(x)
  end
end

# pattern matching example with possible deep contract violation
class PatternMatchingExample
  include Contracts

  class Success < Struct.new(:request)
  end

  class Failure
  end

  Response = Or[Success, Failure]

  class StringWithHello
    def self.valid?(string)
      String === string && !!string.match(/hello/i)
    end
  end

  Contract Success => Response
  def process_request(status)
    Success[decorated_request(status.request)]
  end

  Contract Failure => Response
  def process_request(status)
    Failure.new
  end

  Contract StringWithHello => String
  def decorated_request(request)
    request + "!"
  end
end

# invariant example (silliest implementation ever)
class MyBirthday < Struct.new(:day, :month)
  include Contracts
  include Contracts::Invariants

  Invariant(:day) { 1 <= day && day <= 31 }
  Invariant(:month) { 1 <= month && month <= 12 }

  Contract None => Fixnum
  def silly_next_day!
    self.day += 1
  end

  Contract None => Fixnum
  def silly_next_month!
    self.month += 1
  end

  Contract None => Fixnum
  def clever_next_day!
    return clever_next_month! if day == 31
    self.day += 1
  end

  Contract None => Fixnum
  def clever_next_month!
    return next_year! if month == 12
    self.month += 1
    self.day = 1
  end

  Contract None => Fixnum
  def next_year!
    self.month = 1
    self.day = 1
  end
end

class SingletonClassExample
  # This turned out to be required line here to make singleton classes
  # work properly under all platforms. Not sure if it worth trying to
  # do something with it.
  include Contracts

  class << self
    Contract String => String
    def hoge(str)
      "super#{str}"
    end

    Contract Num, Num => Num
    def add(a, b)
      a + b
    end
  end
end

with_enabled_no_contracts do
  class NoContractsSimpleExample
    include Contracts

    Contract String => nil
    def some_method(x)
      nil
    end
  end

  class NoContractsInvariantsExample
    include Contracts
    include Contracts::Invariants

    attr_accessor :day

    Invariant(:day_rule) { 1 <= day && day <= 7 }

    Contract None => nil
    def next_day
      self.day += 1
    end
  end

  class NoContractsPatternMatchingExample
    include Contracts

    Contract 200, String => String
    def on_response(status, body)
      body + "!"
    end

    Contract Fixnum, String => String
    def on_response(status, body)
      "error #{status}: #{body}"
    end
  end
end

module ModuleExample
  # This inclusion is required to actually override `method_added`
  # hooks for module.
  include Contracts
  include Contracts::Modules

  Contract Num, Num => Num
  def plus(a, b)
    a + b
  end

  Contract String => String
  def self.hoge(str)
    "super#{str}"
  end

  class << self
    Contract String => nil
    def eat(food)
      # yummy
      nil
    end
  end
end

class KlassWithModuleExample
  include ModuleExample
end

class SingletonInheritanceExample
  include Contracts

  Contract Any => Any
  def self.a_contracted_self
    self
  end
end

class SingletonInheritanceExampleSubclass < SingletonInheritanceExample
end
