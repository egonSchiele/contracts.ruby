require './lib/contracts'
require 'benchmark'
require 'rubygems'
require 'method_profiler'
require 'ruby-prof'

include Contracts

def add a, b
  a + b
end

Contract Num, Num => Num
def contracts_add a, b
  a + b
end

def explicit_add a, b
  raise unless a.is_a?(Numeric)
  raise unless b.is_a?(Numeric)
  c = a + b
  raise unless c.is_a?(Numeric)
  c
end

def benchmark
  Benchmark.bm 30 do |x|
    x.report 'testing add' do
      1000000.times do |_|
        add(rand(1000), rand(1000))
      end
    end
    x.report 'testing contracts add' do
      1000000.times do |_|
        contracts_add(rand(1000), rand(1000))
      end
    end  
  end
end

def profile
  profilers = []
  profilers << MethodProfiler.observe(Contract)
  profilers << MethodProfiler.observe(Object)
  profilers << MethodProfiler.observe(MethodDecorators)
  profilers << MethodProfiler.observe(Decorator)
  profilers << MethodProfiler.observe(UnboundMethod)
  10000.times do |_|
    contracts_add(rand(1000), rand(1000))
  end  
  profilers.each { |p| puts p.report }
end

def ruby_prof
RubyProf.start  
    100000.times do |_|
      contracts_add(rand(1000), rand(1000))
    end
result = RubyProf.stop
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
end

benchmark
