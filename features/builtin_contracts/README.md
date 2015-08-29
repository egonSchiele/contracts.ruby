To use builtin contracts you can refer them with `Contracts::*`:

```ruby
Contract Contracts::Num => Contracts::Maybe(Contracts::Num)
```

It is recommended to use a short alias for `Contracts`, for example `C`:

```ruby
C = Contracts

Contract C::Num => C::Maybe(C::Num)
```

It is possible to `include Contracts` and refer them without namespace, but
this is deprecated and not recommended.

*NOTE: in the future it will be possible to do `include Contracts::Builtin`
instead.*
