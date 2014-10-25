#require 'lib/contracts'
require File.join(File.dirname(__FILE__), "../lib/contracts")
require 'rubygems'

module Mod
  include Contracts
  Contract Num => Num
  def self.a_module_method a
     a + 1
  end
end

describe "module methods" do
  it "should pass for correct input" do
    expect { Mod.a_module_method(2) }.to_not raise_error
  end

  it "should fail for incorrect input" do
    expect { Mod.a_module_method("bad") }.to raise_error
  end
end  
