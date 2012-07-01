- maybe make some screencasts

- you can now do something like Haskell's quickcheck. Every contract has a method 'test_data' or something. You can use that data to automatically check methods with contracts to make sure they are correct.
  - http://www.cse.chalmers.se/~rjmh/QuickCheck/manual.html
  - for stuff like the Not contract, should I make a standard set of classes to check those functions with? Would that be useful at all?
  - also write specs for this stuff

- change syntax to `Num, Num => Num` ? Looks easier to read.

Two methods, a and b:

class Object
    def a(x)
      x + 2
    end

    Contract Num, Num
    def b(x)
      x + 2
    end
end

Both exactly the same, except `b` has a contract on it. This causes problems:

    p Object.a(5) # works
    p Object.b(5) # Error! self doesn't have a decorated_methods array!
