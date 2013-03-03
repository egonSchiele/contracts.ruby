require './lib/contracts'
include Contracts

Contract Num, Num => Num
def add a, b
  a + b
end

p add(1, 2)
