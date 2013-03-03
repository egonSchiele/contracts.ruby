require 'benchmark'

module Bar
  def go
    @val ||= {}
    class << self; attr_accessor :val; end
    p self
    p self.val
  end
end

class Baz
  extend Bar
end

Baz.go

p Baz
p Baz.val

exit

class Caller
  def initialize(method)
    @method = method
  end

  def call_with(*args, &blk)
    @method.call(*args, &blk)
  end
end

class Foo
def add a, b
  a + b
end

class_eval %{
  def evaled_add a, b
    method(:add).call(a, b)
  end
}
end

f = Foo.new
c = Caller.new(f.method(:add))

Benchmark.bm 30 do |x|
  x.report 'add' do
    100000.times do |_|
      f.add(rand(1000), rand(1000))
    end
  end
  x.report 'evaled_add' do
    100000.times do |_|
      f.evaled_add(rand(1000), rand(1000))
    end
  end  
  x.report 'caller object' do
    100000.times do |_|
      c.call_with(rand(1000), rand(1000))
    end
  end  
end
