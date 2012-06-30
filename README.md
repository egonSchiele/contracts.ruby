# contracts.ruby

Contracts let you clearly – even beautifully – express how your code behaves, and free you from writing tons of boilerplate, defensive code.

You can think of contracts as `assert` on steroids.

## Current Status

**Experimental, actively developing.**

This project is stable enough for use. However, it's API / usage is still evolving, and future versions will probably break older versions (for now!).

## Installation

    gem install contracts

## Running Tests

    rspec spec/*.rb

## Hello World

A contract is one line of code that you write above a method definition. It validates the arguments to the method, and validates it's return value.

Here is a simple contract:

```ruby
  Contract Num => Num
  def double(x)
```

This says that double expects a number and returns a number. Here's the full code:

```ruby
require 'contracts'
use_contracts self

Contract Num => Num
def double(x)
  x * 2
end

puts double("oops")
```

Save this in a file and run it. Notice we are calling `double` with `"oops"`, which is not a number. The contract fails with a detailed error message:

    ./contracts.rb:34:in `failure_callback': Contract violation: (RuntimeError)
        Expected: Contracts::Num,
        Actual: "oops"
        Value guarded in: Object::double
        With Contract: Contracts::Num, Contracts::Num
        At: main.rb:6 
        ...stack trace...

Instead of throwing an exception, you could log it, print a clean error message for your user...whatever you want. contracts.ruby is here to help you handle bugs better, not to get in your way.

## Tutorial

Check out [this awesome tutorial](http://egonschiele.github.com/contracts.ruby).

## Gotchas

Contracts don't work on top level functions. Any function with a contract should be in a class. In our example we just stuck the `double` function in the `Object` class.

**Q.** Is this compatible with Ruby 1.9?

**A.** Yes.

If you're using the library, please [let me know](https://github.com/egonSchiele) what project you're using it on :)

## Credits

Inspired by [contracts.coffee](http://disnetdev.com/contracts.coffee/). I also heavily "borrowed" from their README to write this one. Sorry/thanks!

Copyright 2012 [Aditya Bhargava](http://adit.io).

BSD Licensed.
