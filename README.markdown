# contracts.ruby

Contracts for Ruby.
Inspired by [contracts.coffee](http://disnetdev.com/contracts.coffee/).

This is a work-in-progress.

## Example:

```ruby
Contract(Fixnum, Fixnum)
def fib(x)
  return x if x < 2
  return fib(x - 1) + fib(x - 2)
end
```

## Available types:

    Odd
    Even
    Pos
    Neg
    Any
    None
    Or
    And
    RespondsTo
    From

