require 'contracts'
# TODO: How to avoid writing "class Object"?
# - optional args
# functions?
# - namespacing? don't want classes with names like Any, All etc lying around.
# user-defined callback on error instead of just throwing an exception
# refactor built-in classes, maybe use each other or clean them up.

class Foo
  def check
    true
  end
end

class Object
  contract Not[1]
  def fib(x)
    return x if x < 2
    return fib(x - 1) + fib(x - 2)
  end

  contract Send[:check]
  def foo(f)
    f
  end
end

puts foo(Foo.new)
