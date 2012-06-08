require 'contracts'
include Contracts

def Num.to_s
  "a number please"
end

class Object
  Contract Num, Num
  def double(x)
    x * 2
  end
end

puts double("oops")
