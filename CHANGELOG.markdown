## v0.9
- MAJOR fix in pattern-matching: If the return contract for a pattern-matched function fails, it should NOT try the next pattern-match function. Pattern-matching is only for params, not return values.
- raise an error if multiple defns have the same contract for pattern matching.

- New syntax for functions with no input params.
  Old way:
  Contract nil => 1
  def one

  New way:
  Contract 1
  def one

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
