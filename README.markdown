# contracts.ruby

Contracts for Ruby.

Contracts let you clearly – even beautifully – express how your code behaves, and free you from writing tons of boilerplate, defensive code.

You can think of contracts as `assert` on steroids.

## Installation

    gem install contracts

## Basics

Here is a simple contract:

```ruby
  Contract Num, Num
  def double(x)
```

This says that double expects a number and returns a number. Here's the full code:

```ruby
require 'contracts'
include Contracts

class Object
  Contract Num, Num
  def double(x)
    x * 2
  end
end
```

Now if we run this with `double("oops")`, we get a nice error:

    ./contracts.rb:34:in `failure_callback': Contract violation: (RuntimeError)
        Expected: Contracts::Num,
        Actual: "oops"
        Value guarded in: Object::double
        With Contract: Contracts::Num, Contracts::Num
        At: main.rb:6 
        ...stack trace...

You can do more than just throw an exception...more on that later.

## Builtin Contracts

contracts.ruby comes with a lot of builtin contracts, including:

    Num, Pos, Neg, Any, None, Or, Xor, And, Not, RespondsTo, Send, IsA, ArrayOf

To use any of these contracts, include the module first with

    include Contracts

See the full documentation (TBD) on builtin contracts for more information on each one.

## More Examples

    # Array arguments
    Contract [String, String, Num], nil
    def person(some_array)

    # An array of numbers
    Contract ArrayOf[Num], Num
    def sum(vals)

    # Multiple choice
    Contract Or[Fixnum, Float], Num
    def add_ten(x)

    # Negate
    Contract Not[nil], nil
    def save(val)

    # Nested contracts
    Contract Or[And[RespondsTo[:to_s], Not[nil]], String, 5], String
    def some_crazy_function(x)

## Defining Your Own Contracts

Contracts are very easy to define. There are 4 kinds of contracts:

1. a constant (e.g. `nil`). The argument must equal this constant.
2. a class (e.g. `String`). The argument's class must match this class.
3. a class that implements `valid?` as a class method (e.g. `Num`).
4. a class that implements `valid?` as an instance method (e.g. `Or`). In both cases, `valid?` takes a value and returns a boolean indicating if it is a valid type.
5. a proc that takes a value and returns a boolean.

Here are some examples:

### A Class With `valid?` As a Class Method

```ruby
class Num
  def self.valid? val
    val.is_a? Numeric
  end
end
```

### A Class With `valid?` As an Instance Method

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

The `Or` contract takes a sequence of contracts, and passes if any of them pass. It uses `Contract.valid?`, which returns a array of [result, data], where result is a boolean and data is a hash. The values in data are listed in [Failure and Success Callbacks](#failure-and-success-callbacks).

This class inherits from `CallableClass`, which allows us to use `[]` when using the class:

```ruby
Contract Or[Fixnum, Float]
def double(x)
2 * x
end
```

Without `CallableClass`, we would have to use `.new` instead:

```ruby
Contract Or.new(Fixnum, Float)
def double(x)
# etc
```

### A Proc

```ruby
Contract lambda { |x| x.is_a? Numeric }
def double(x)
```

## Customizing Error Messages

When a contract fails, part of the error message prints the contract:

    ...
    Expected: Contracts::Num,
    ...

You can customize this message by overriding the `to_s` method on your class or proc. For example, suppose we overrode `Num`'s `to_s` method:

    def Num.to_s
      "a number please"
    end

Now the error says:

    ...
    Expected: a number please,
    ...

## Failure and Success Callbacks

Supposing you don't want contract failures to become exceptions. You run a popular website, and when there's a contract exception you would rather log it and continue than break your site.

contracts.ruby provides a `failure_callback` that gets called when a contract fails. By overriding `failure_callback`, you can customize the behavior of contracts.ruby. For example, here we log every failure instead of raising an error:

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
      :contracts => a list of contracts on the method
    }

There's also a `success_callback` that gets called when a contract succeeds.

## Gotchas

Contracts don't work on top level functions yet. Any function with a contract should be in a class.

## Credits

Inspired by [contracts.coffee](http://disnetdev.com/contracts.coffee/). I also heavily "borrowed" from their README to write this one. Sorry/thanks!

Copyright 2012 [Aditya Bhargava](http://adit.io).

BSD Licensed.
