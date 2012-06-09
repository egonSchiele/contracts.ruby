require 'rubygems'
require 'contracts'
include Contracts

class Object
  Contract Num, Num
  def double(x)
    x * 2
  end
end

puts double("oops")
