# contracts.ruby

[![Build Status](https://travis-ci.org/egonSchiele/contracts.ruby.png?branch=master)](https://travis-ci.org/egonSchiele/contracts.ruby)

Contracts let you clearly – even beautifully – express how your code behaves, and free you from writing tons of boilerplate, defensive code.

You can think of contracts as `assert` on steroids.

## Installation

    gem install contracts

## Hello World

A contract is one line of code that you write above a method definition. It validates the arguments to the method, and validates the return value of the method.

Here is a simple contract:

```ruby
  Contract Num => Num
  def double(x)
```

This says that double expects a number and returns a number. Here's the full code:

```ruby
require 'contracts'
include Contracts

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

## Use Cases

Check out [this screencast](https://vimeo.com/85883356).

## Performance

Using contracts.ruby results in very little slowdown. Check out [this blog post](http://adit.io/posts/2013-03-04-How-I-Made-My-Ruby-Project-10x-Faster.html#seconds-6) for more info.

**Q.** What Rubies can I use this with?

**A.** It's been tested with `1.8.7`, `1.9.2`, `1.9.3`, `2.0.0`, `2.1.0`, and `jruby` (both 1.8 and 1.9 modes).

If you're using the library, please [let me know](https://github.com/egonSchiele) what project you're using it on :)

## Credits

Inspired by [contracts.coffee](http://disnetdev.com/contracts.coffee/).

Copyright 2012 [Aditya Bhargava](http://adit.io).

BSD Licensed.
