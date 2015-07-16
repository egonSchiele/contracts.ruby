## v0.10.1

- Enhancement: make `@pattern_match` instance variable not render ruby warning. Required to use new aruba versions in rspec tests - [Dennis Günnewig](https://github.com/dg-ratiodata) [#179](https://github.com/egonSchiele/contracts.ruby/pull/179)

## v0.10

- Bugfix: make `Maybe[Proc]` work correctly - [Simon George](https://github.com/sfcgeorge) [#142](https://github.com/egonSchiele/contracts.ruby/pull/142)
- Bugfix: make `Func` contract verified when used as return contract - [Rob Rosenbaum](https://github.com/robnormal) [#145](https://github.com/egonSchiele/contracts.ruby/pull/145)
- Bugfix: make `Pos`, `Neg` and `Nat` contracts handle non-numeric values correctly - [Matt Griffin](https://github.com/betamatt) and [Gavin Sinclair](https://github.com/gsinclair) [#147](https://github.com/egonSchiele/contracts.ruby/pull/147) [#173](https://github.com/egonSchiele/contracts.ruby/pull/173)
- Enhancement: reduce user class pollution through introduction of contracts engine - [Oleksii Fedorov](https://github.com/waterlink) [#141](https://github.com/egonSchiele/contracts.ruby/pull/141)
- Feature: add builtin `KeywordArgs` and `Optional` contracts for keyword arguments handling - [Oleksii Fedorov](https://github.com/waterlink) [#151](https://github.com/egonSchiele/contracts.ruby/pull/151)
- Feature: recognize module as a class contract - [Oleksii Fedorov](https://github.com/waterlink) [#153](https://github.com/egonSchiele/contracts.ruby/pull/153)
- Feature: custom validators with `Contract.override_validator` - [Oleksii Fedorov](https://github.com/waterlink) [#159](https://github.com/egonSchiele/contracts.ruby/pull/159)
- Feature: add builtin `RangeOf[...]` contract - [Gavin Sinclair](https://github.com/gsinclair) [#171](https://github.com/egonSchiele/contracts.ruby/pull/171)

## v0.9

- MAJOR fix in pattern-matching: If the return contract for a pattern-matched function fails, it should NOT try the next pattern-match function. Pattern-matching is only for params, not return values.
- raise an error if multiple defns have the same contract for pattern matching.

- New syntax for functions with no input params (the old style still works)  
  Old way:
  ```ruby
  Contract nil => 1
  def one
  ```
  New way:
  ```
  Contract 1
  def one
  ```

- Prettier HashOf contract can now be written like this: `HashOf[Num => String]`
- Add `SetOf` contract
- various small fixes

## v0.8

- code refactored (very slight loss of performance, big increase in readability)
- fail when defining a contract on a module without `include Contracts::Modules`
- fixed several bugs in argument parsing, functions with complex params get contracts applied correctly now.
- added rubocop to ci.
- if a contract is set on a protected method, it should not become public.
- fixed pattern matching when the multiple definitions of functions have different arities.
- couple of new built-in contracts: Nat, Eq.
- changed `Invariant` to `invariant`: `invariant(:day) { 1 <= day && day <= 31 }`
- prettier error messages (`Contracts::Num` is now just `Num`, for example)
- support for yard-contracts
