require 'contracts'
# TODO: How to avoid writing "class Object"?
# - optional args
# - remove .new in Or
# - pretty error messages for procs?
# functions?
class Object
  Contract(Fixnum, Fixnum)
  def fib(x)
    return x if x < 2
    return fib(x - 1) + fib(x - 2)
  end
end

puts fib(5)
