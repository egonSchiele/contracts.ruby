- How to avoid writing "class Object"?
- maybe I could add better contracts for functions? specify a contract, and then save that in a hash as (:funcname => contract } for this scope only. Then check every function cal in that scope to see if there's a corresponding contract for that function. If so, validate that function call.
- maybe make some screencasts

- bug: default args don't get typechecked at all, so they could violate your contract.
The reason is, of course, that they aren't passed in as args and we only check those args. Is there some way to get a list of the default args in a function?
    See answer here: http://stackoverflow.com/questions/10959299/inspecting-default-values-on-a-method-in-ruby

- ugh. Ruby doesn't require *args to be the last element in the arg list. fix this.

- you can now do something like Haskell's quickcheck. Every contract has a method 'test_data' or something. You can use that data to automatically check methods with contracts to make sure they are correct.
  - for stuff like the Not contract, should I make a standard set of classes to check those functions with? Would that be useful at all?
  - also write specs for this stuff

- change syntax to `Num, Num => Num` ? Looks easier to read.

- what about multiple return values?

- contracts don't work on class methods. So this:

  class A
    Contract Num, Num
    def self.square(x)
      x ** 2
    end
  end

  square doesn't have a contract on it here : (

  The reason is, although I am overriding method_added, I also need to override singleton_method_added for class methods. See the full explanation here:
      http://blog.sidu.in/2007/12/rubys-methodadded.html

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


What happens if another library also monkeypatches method_missing and method_added? Especially since I'm doing it on Class, that seems quite likely. Then I'll be in hot water.

