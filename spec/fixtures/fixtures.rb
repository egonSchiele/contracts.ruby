include Contracts

class A

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
  def bad
    false
  end

  Contract String => String
  def triple x
    x * 3
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

public # we need this otherwise all these methods will automatically be marked private
Contract Num => Num
def Object.a_class_method x
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

Contract Pos => nil
def pos_test(x)
end

Contract Neg => nil
def neg_test(x)
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

# for testing inheritance
class Parent
  Contract Num => Num
  def double x
    x * 2
  end
end

class Child < Parent
end

Contract Parent => Parent
def id_ a
  a
end

Contract Exactly[Parent] => nil
def exactly_test(x)
end

# pattern matching example with possible deep contract violation
class PatternMatchingExample
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
  end
end

class SingletonInheritanceExample
  Contract Any => Any
  def self.a_contracted_self
    self
  end
end

class SingletonInheritanceExampleSubclass < SingletonInheritanceExample
end
