require 'decorators'
require 'builtin_contracts'

class Class
  include MethodDecorators
end


class Contract < Decorator
  attr_accessor :contracts, :klass, :method
  decorator_name :contract
  def initialize(klass, method, *contracts)
    @klass, @method, @contracts = klass, method, contracts
  end

  def self.mkerror(validates, arg, contract)
    if validates
      [true, {}]
    else
      [false, { :arg => arg, :contract => contract }]
    end
  end

  def self.failure_msg(data)
   # TODO __file__ and __line__ won't work in Ruby 1.9.
   # It provides a source_location method instead.
   expected = if data[:contract].to_s == ""
                data[:contract].inspect
              else
                data[:contract].to_s
              end
%{Contract violation:
    Expected: #{expected},
    Actual: #{data[:arg].inspect}
    Value guarded in: #{data[:class]}::#{data[:method].name}
    With Contract: #{data[:contracts].map { |t| t.is_a?(Class) ? t.name : t.class.name }.join(", ") }
    At: #{data[:method].__file__}:#{data[:method].__line__} }
  end
  def self.failure_callback(data)
    raise failure_msg(data)
  end

  def self.success_callback(data)
  end  

  def self.validate_hash(arg, contract)
    arg.keys.each do |k|
      result, info = validate(arg[k], contract[k])
      return [result, info] unless result
    end
  end

  def self.validate_proc(arg, contract)
    mkerror(contract[arg], arg, contract)
  end

  def self.validate_class(arg, contract)
    valid = if contract.respond_to? :valid?
              contract.valid? arg
            else
              contract == arg.class
            end
    mkerror(valid, arg, contract)
  end

  def self.validate_all(args, contracts, klass, method)
    if args.size != contracts.size
      # *args
      if contracts[-2].is_a? Args
        while contracts.size < args.size + 1
          contracts.insert(-2, contracts[-2].dup)
        end
      else
        raise %{The number of arguments doesn't match the number of contracts.
Did you forget to write a contract for the return value of the function?
Or if you want a variable number of arguments using *args, use the Args contract.
Args: #{args.inspect}
Contracts: #{contracts.map { |t| t.is_a?(Class) ? t.name : t.class.name }.join(", ")}}
      end
    end

    args.zip(contracts).each do |arg, contract|
      validate(arg, contract, klass, method, contracts)
    end
  end

  def self.validate(arg, contract, klass, method, contracts)
    result, _ = valid?(arg, contract)
    if result
      success_callback({:arg => arg, :contract => contract, :class => klass, :method => method, :contracts => contracts})
    else
      failure_callback({:arg => arg, :contract => contract, :class => klass, :method => method, :contracts => contracts})
    end
  end

  # arg to method -> contract it should satisfy -> (Boolean, metadata)
  def self.valid?(arg, contract)
    case contract
    when Class
      # e.g. Fixnum
      validate_class arg, contract
    when Proc
      # e.g. lambda {true}
      validate_proc arg, contract
    when Array
      # e.g. [Num, String]
      # TODO account for these errors too
      return mkerror(false, arg, contract) unless arg.is_a?(Array)
      validate_all(arg, contract)
    when Hash
      # e.g. { :a => Num, :b => String }
      return mkerror(false, arg, contract) unless arg.is_a?(Hash)
      validate_hash(arg, contract)
    when Args
      valid? arg, contract.contract
    else
      if contract.respond_to? :valid?
        mkerror(contract.valid?(arg), arg, contract)
      else
        mkerror(arg == contract, arg, contract)
      end
    end
  end

  def call(this, *args)
    Contract.validate_all(args, @contracts, @klass, @method)
    result = @method.bind(this).call(*args)
    if args.size == @contracts.size - 1
      Contract.validate(result, @contracts[-1], @klass, @method, @contracts)
    end
    result
  end
end

class Args < Contracts::CallableClass
  attr_reader :contract
  def initialize(contract)
    @contract = contract
  end

  def to_s
    "Args[#{@contract}]"
  end
end
