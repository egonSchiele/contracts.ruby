- How to avoid writing "class Object"? Seriously.
- write specs
- make a complete easy walkthrough
- maybe I could add better contracts for functions? specify a contract, and then save that in a hash as (:funcname => contract } for this scope only. Then check every function cal in that scope to see if there's a corresponding contract for that function. If so, validate that function call.
- maybe make some screencasts

- bug: default args don't get typechecked at all, so they could violate your contract.
The reason is, of course, that they aren't passed in as args and we only check those args. Is there some way to get a list of the default args in a function?
    See answer here: http://stackoverflow.com/questions/10959299/inspecting-default-values-on-a-method-in-ruby

- Email the creators of contracts.ruby and ask for feedback. Who else? Maybe the guys behind rspec?


- ugh. Ruby doesn't require *args to be the last element in the arg list. wtf.
