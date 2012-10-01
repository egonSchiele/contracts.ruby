# Similar Projects

## [Handshake](https://github.com/bguthrie/handshake)

### What it has:

Quite a lot. I wish I had looked at this before I started writing contracts.ruby!

- It allows for similar syntax:

    contract positive_number? => anything
    def initialize(balance)

- Allows for contracts on procs and blocks
- Class invariants (things that get checked before and after *every* method call)
- It even allows you to specify a contract with the name of a method:
    contract :initialize, [[ String ]] => anything

### What is doesn't have:

- wraps methods, so private methods don't get checked. You have to call private methods on the special private method `checked_self`. Ugh. [From the readme](https://github.com/bguthrie/handshake).
- private methods (calls within the same class) are unchecked
  - one way to get around this would be to use eval to redefine methods that the user wants to check. See the ruby-contract project for examples.
- no callbacks, relies instead on handshake.enable! and handshake.suppress! methods
- no automatic checking.

Overall it is *really* similar to contracts.ruby. Wish I'd found it earlier :P

## [Platypus](http://rubyworks.github.com/platypus/)

Doesn't focus on contracts, but does a *lot* with typing in Ruby. Pretty cool project.

## [DesignByContract](http://split-s.blogspot.com/2006/02/design-by-contract-for-ruby.html)

Syntax isn't pretty, looks very simplistic. But it does provide the same functionality...automatically add the contract on the next method that shows up. Here's how they do it: http://split-s.blogspot.com/2006/01/replacing-methods.html

That plus method_added. From their blog post:

There is a small caveat, though. If pre/post are called before the method is first created, it cannot be intercepted. To get around this the module uses an alternative trick. Whenever the module is included, it hooks into the method_added callback of class it's included into. If pre/post are called and the corresponding method does not exist, the interception is scheduled until the method is added.

## [ruby-contract](http://rubyforge.org/frs/?group_id=543)

Old, unmaintained, and not simple.
