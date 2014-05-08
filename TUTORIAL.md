# The contracts.ruby tutorial

## Introduction

contracts.ruby brings code contracts to the Ruby language. Code contracts allow you make some assertions about your code, and then checks them to make sure they hold. This lets you

- catch bugs faster
- make it very easy to catch certain types of bugs
- make sure that the user gets proper messaging when a bug occurs.

## Installation

    gem install contracts

## Basics

A simple example:

```ruby
Contract Num, Num => Num
def add(a, b)
   a + b
 end
```

Here, the contract is `Contract Num, Num => Num`. This says that the `add` function takes two numbers and returns a number.

Copy this code into a file and run it:

```ruby
require 'contracts'
include Contracts

Contract Num, Num => Num
def add(a, b)
   a + b
end

puts add(1, "foo")
```

You'll see a detailed error message like so:

    ./contracts.rb:60:in `failure_callback': Contract violation: (RuntimeError)
        Expected: Contracts::Num,
        Actual: "foo"
        Value guarded in: Object::add
        With Contract: Contracts::Num, Contracts::Num
        At: foo.rb:6 

That tells you that your contract was violated! `add` expected a `Num`, and got a string (`"foo"`) instead.
By default, an exception is thrown when a contract fails. This can be changed to do whatever you want. More on this later.

You can also see the contract for a function with the `functype` method:

    functype(:add)
    => "add :: Num, Num => Num"

This can be useful if you're in a repl and want to figure out how a function should be used.

## Builtin Contracts

`Num` is one of the builtin contracts that contracts.ruby comes with. The builtin contracts are in the `Contracts` namespace. The easiest way to use them is to put `include Contracts` at the top of your file, but beware that they will pollute your namespace with new class names.

contracts.ruby comes with a lot of builtin contracts, including:

    Num, Pos, Neg, Any, None, Or, Xor, And, Not, RespondTo, Send, Exactly, ArrayOf, HashOf, Bool, Maybe

To see all the builtin contracts and what they do, check out the [rdoc](http://rubydoc.info/gems/contracts/Contracts).

## More Examples

### Hello, World

```ruby
Contract String => nil
def hello(name)
  puts "hello, #{name}!"
end
```

You always need to specify a contract for the return value. In this example, `hello` doesn't return anything, so the contract is `nil`. Now you know that you can use a constant like `nil` as the of a contract. Valid values for a contract are:

- the name of a class (like `String` or `Fixnum`)
- a constant (like `nil` or `1`)
- a `Proc` that takes a value and returns true or false to indicate whether the contract passed or not
- a class that responds to the `valid?` class method (more on this later)
- an instance of a class that responds to the `valid?` method (more on this later)

### A Double Function

```ruby
Contract Or[Fixnum, Float] => Or[Fixnum, Float]
def double(x)
  2 * x
end
```

Sometimes you want to be able to choose between a few contracts. `Or` takes a variable number of contracts and checks the argument against all of them. If it passes for any of the contracts, then the `Or` contract passes.
This introduces some new syntax. One of the valid values for a contract is an instance of a class that responds to the `valid?` method. This is what `Or[Fixnum, Float]` is. The longer way to write it would have been:

```ruby
Contract Or.new(Fixnum, Float) => Or.new(Fixnum, Float)
```

All the builtin contracts have overridden the square brackets (`[]`) to give the same functionality. So you could write

```ruby
Contract Or[Fixnum, Float] => Or[Fixnum, Float]
```

or

```ruby
Contract Or.new(Fixnum, Float) => Or.new(Fixnum, Float)
```

whichever you prefer. They both mean the same thing here: make a new instance of `Or` with `Fixnum` and `Float`. Use that instance to validate the argument.

### A Product Function

```ruby
Contract ArrayOf[Num] => Num
def product(vals)
  total = 1
  vals.each do |val|
    total *= val
  end
  total
end
```

This contract uses the `ArrayOf` contract. Here's how `ArrayOf` works: it takes a contract. It expects the argument to be a list. Then it checks every value in that list to see if it satisfies that contract.

```ruby
# passes
product([1, 2, 3, 4])

# fails
product([1, 2, 3, "foo"])
```

### Another Product Function

```ruby
Contract Args[Num] => Num
def product(*vals)
  total = 1
  vals.each do |val|
    total *= val
  end
  total
end
```

This function uses varargs (`*args`) instead of an array. To make a contract on varargs, use the `Args` contract. It takes one contract as an argument and uses it to validate every element passed in through `*args`. So for example,

`Args[Num]` means they should all be numbers. 

`Args[Or[Num, String]]` means they should all be numbers or strings.

`Args[Any]` means all arguments are allowed (`Any` is a contract that passes for any argument).

### Contracts On Arrays

If an array is one of the arguments and you know how many elements it's going to have, you can put a contract on it:

```ruby
# a function that takes an array of two elements...a person's age and a person's name.
Contract [Num, String] => nil
def person(data)
  p data
end
```

If you don't know how many elements it's going to have, use `ArrayOf`.

### Contracts On Hashes

Here's a contract that requires a Hash. We can put contracts on each of the keys:

```ruby
# note the parentheses around the hash; without those you would get a syntax error
Contract ({ :age => Num, :name => String }) => nil
def person(data)
  p data
end
```

Then if someone tries to call the function with bad data, it will fail:

```ruby
# error: age can't be nil!
person({:name => "Adit", :age => nil})
```

You don't need to put a contract on every key. So this call would succeed:

```ruby
person({:name => "Adit", :age => 42, :foo => "bar"})
```

even though we don't specify a type for `:foo`.

Peruse this contract on the keys and values of a Hash.

```ruby
Contract HashOf[Symbol, Num] => Num
def give_largest_value(hsh)
  hsh.values.max
end
```
Which you use like so:
```ruby
# succeeds
give_largest_value(a: 1, b: 2, c: 3) # returns 3

# fails
give_largest_value("a" => 1, 2 => 2, c: 3)
```

### Contracts On Functions

If you're writing higher-order functions (functions that take functions as parameters) and want to write a contract for the passed-in function, you can!
Use the `Func` contract. `Func` takes a contract as it's argument, and uses that contract on the function that you pass in.

Here's a `map` function that requires an array of numbers, and a function that takes a number and returns a number:

```ruby
Contract ArrayOf[Num], Func[Num => Num] => ArrayOf[Num]
def map(arr, func)
  ret = []
  arr.each do |x|
    ret << func[x]
  end
  ret
end
```

This will add the contract `Num => Num` on `func`. Try it with these two examples:

```ruby
p map([1, 2, 3], lambda { |x| x + 1 }) # works
p map([1, 2, 3], lambda { |x| "oops" }) # fails, the lambda returns a string.
```

### Returning Multiple Values
Treat the return value as an array. For example, here's a function that returns two numbers:

```ruby
Contract Num => [Num, Num]
def mult(x)
  return x, x+1
end
```

## Synonyms For Contracts

If you use a contract a lot, it's a good idea to give it a meaningful synonym that tells the reader more about what your code returns. For example, suppose you have many functions that return a `Hash` or `nil`. If a `Hash` is returned, it contains information about a person. Your contact might look like this:

```ruby
Contract String => Or[Hash, nil]
def some_func(str)
```

You can make your contract more meaningful with a synonym:

```ruby
# the synonym
Person = Or[Hash, nil]

# use the synonym here
Contract String => Person
def some_func(str)
```

Now you can use `Person` wherever you would have used `Or[Hash, nil]`. Your code is now cleaner and more clearly says what the function is doing.

## Defining Your Own Contracts

Contracts are very easy to define. To re-iterate, there are 5 kinds of contracts:

- the name of a class (like `String` or `Fixnum`)
- a constant (like `nil` or `1`)
- a `Proc` that takes a value and returns true or false to indicate whether the contract passed or not
- a class that responds to the `valid?` class method (more on this later)
- an instance of a class that responds to the `valid?` method (more on this later)

The first two don't need any extra work to define: you can just use any constant or class name in your contract and it should just work. Here are examples for the rest:

### A Proc

```ruby
Contract lambda { |x| x.is_a? Numeric } => Num
def double(x)
```

The lambda takes one parameter: the argument that is getting passed to the function. It checks to see if it's a `Numeric`. If it is, it returns true. Otherwise it returns false.
It's not good practice to write a lambda right in your contract...if you find yourself doing it often, write it as a class instead:

### A Class With `valid?` As a Class Method

Here's how the `Num` class is defined. It does exactly what the `lambda` did in the previous example:

```ruby
class Num
  def self.valid? val
    val.is_a? Numeric
  end
end
```

The `valid?` class method takes one parameter: the argument that is getting passed to the function. It returns true or false.

### A Class With `valid?` As an Instance Method

Here's how the `Or` class is defined:

```ruby
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
end
```

The `Or` contract takes a sequence of contracts, and passes if any of them pass. It uses `Contract.valid?` to validate the value against the contracts.

This class inherits from `CallableClass`, which allows us to use `[]` when using the class:

```ruby
Contract Or[Fixnum, Float] => Num
def double(x)
  2 * x
end
```

Without `CallableClass`, we would have to use `.new` instead:

```ruby
Contract Or.new(Fixnum, Float) => Num
def double(x)
# etc
```

You can use `CallableClass` in your own contracts to make them callable using `[]`.

## Customizing Error Messages

When a contract fails, part of the error message prints the contract:

    ...
    Expected: Contracts::Num,
    ...

You can customize this message by overriding the `to_s` method on your class or proc. For example, suppose we overrode `Num`'s `to_s` method:

```ruby
def Num.to_s
  "a number please"
end
```

Now the error says:

    ...
    Expected: a number please,
    ...

## Failure Callbacks

Supposing you don't want contract failures to become exceptions. You run a popular website, and when there's a contract exception you would rather log it and continue than throw an exception and break your site.

contracts.ruby provides a `failure_callback` that gets called when a contract fails. By monkeypatching `failure_callback`, you can customize the behavior of contracts.ruby. For example, here we log every failure instead of raising an error:

```ruby
class Contract
  def self.failure_callback(data)
    info failure_msg(data)
  end
end
```

`failure_msg` is a function that prints out information about the failure. `failure_callback` takes a hash with the following values:

    {
      :arg => the argument to the method,
      :contract => the contract that got violated,
      :class => the method's class,
      :method => the method,
      :contracts => the contract object
    }

If `failure_callback` returns `false`, the method that the contract is guarding will not be called (the default behaviour).

## Method overloading

You can use contracts for method overloading! For example, here's a factorial function without method overloading:

```ruby
Contract Num => Num
def fact x
  if x == 1
    x
  else
    x * fact(x - 1)
  end
end
```

Here it is again, re-written with method overloading:

```ruby
Contract 1 => 1
def fact x
  x
end

Contract Num => Num
def fact x
  x * fact(x - 1)
end
```

For an argument, each function will be tried in order. The first function that doesn't raise a `ContractError` will be used. So in this case, if x == 1, the first function will be used. For all other values, the second function will be used.

## Misc

Please submit any bugs [here](https://github.com/egonSchiele/contracts.ruby/issues) and I'll try to get them resolved ASAP!

See any mistakes in this tutorial? I try to make it bug-free, but they can creep in. [File an issue](https://github.com/egonSchiele/contracts.ruby/issues).

If you're using the library, please [let me know](https://github.com/egonSchiele) what project you're using it on :)

See the [wiki](https://github.com/egonSchiele/contracts.ruby/wiki) for more info.

Happy Coding!
