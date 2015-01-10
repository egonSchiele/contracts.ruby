require './lib/contracts'
require 'benchmark'
require 'rubygems'
require 'method_profiler'
require 'ruby-prof'

class Obj < Struct.new(:value)
  include Contracts

  Contract Num, Num => Num
  def contracts_add a, b
    a + b
  end
end

class ObjWithInvariants < Struct.new(:value)
  include Contracts
  include Contracts::Invariants

  Invariant(:value_not_nil) { value != nil }
  Invariant(:value_not_string) { !value.is_a?(String) }

  Contract Num, Num => Num
  def contracts_add a, b
    a + b
  end
end

def benchmark
  obj = Obj.new(3)
  obj_with_invariants = ObjWithInvariants.new(3)

  Benchmark.bm 30 do |x|
    x.report 'testing contracts add' do
      1000000.times do |_|
        obj.contracts_add(rand(1000), rand(1000))
      end
    end
    x.report 'testing contracts add with invariants' do
      1000000.times do |_|
        obj_with_invariants.contracts_add(rand(1000), rand(1000))
      end
    end  
  end
end

def profile
  obj_with_invariants = ObjWithInvariants.new(3)

  profilers = []
  profilers << MethodProfiler.observe(Contract)
  profilers << MethodProfiler.observe(Object)
  profilers << MethodProfiler.observe(Contracts::Support)
  profilers << MethodProfiler.observe(Contracts::Invariants)
  profilers << MethodProfiler.observe(Contracts::Invariants::InvariantExtension)
  profilers << MethodProfiler.observe(UnboundMethod)

  10000.times do |_|
    obj_with_invariants.contracts_add(rand(1000), rand(1000))
  end  

  profilers.each { |p| puts p.report }
end

def ruby_prof
  RubyProf.start  

  obj_with_invariants = ObjWithInvariants.new(3)

  100000.times do |_|
    obj_with_invariants.contracts_add(rand(1000), rand(1000))
  end

  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
end

benchmark
profile
ruby_prof if ENV["FULL_BENCH"] # takes some time
