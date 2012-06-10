require 'decorators'
require 'builtin_contracts'

class Class
  include MethodDecorators
end

# This is the main Contract class. When you write a new contract, you'll
# write it as:
#
#   Contract [contract names]
#
# This class also provides useful callbacks and a validation method.
class Contract < Decorator
  attr_accessor :contracts, :klass, :method
  decorator_name :contract
  def initialize(klass, method, *contracts)
    @klass, @method, @contracts = klass, method, contracts
  end

  # Given a hash, prints out a failure message.
  # This function is used by the default #failure_callback method
  # and uses the hash passed into the failure_callback method.
  def self.failure_msg(data)
   expected = if data[:contract].to_s == ""
                data[:contract].inspect
              else
                data[:contract].to_s
              end

    if RUBY_VERSION =~ /^1\.8/
      position = data[:method].__file__ + ":" + data[:method].__line__.to_s
    else
      file, line = data[:method].source_location
      position = file + ":" + line.to_s
    end
   
%{Contract violation:
    Expected: #{expected},
    Actual: #{data[:arg].inspect}
    Value guarded in: #{data[:class]}::#{data[:method].name}
    With Contract: #{data[:contracts].map { |t| t.is_a?(Class) ? t.name : t.class.name }.join(", ") }
    At: #{position} }
  end

  # Callback for when a contract fails. By default it raises
  # an error and prints detailed info about the contract that
  # failed. You can also monkeypatch this callback to do whatever
  # you want...log the error, send you an email, print an error
  # message, etc.
  #
  # Example of monkeypatching:
  #
  #   Contract.failure_callback(data)
  #     puts "You had an error!"
  #     puts failure_msg(data)
  #     exit
  #   end
  def self.failure_callback(data)
    raise failure_msg(data)
  end

  # Callback for when a contract succeeds. Does nothing by default.
  def self.success_callback(data)
  end  

  # Used to verify if an argument satisfies a contract.
  #
  # Takes: an argument and a contract.
  #
  # Returns: a tuple: [Boolean, metadata]. The boolean indicates
  # whether the contract was valid or not. If it wasn't, metadata
  # contains some useful information about the failure.
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
    when Contracts::Args
      valid? arg, contract.contract
    else
      if contract.respond_to? :valid?
        mkerror(contract.valid?(arg), arg, contract)
      else
        mkerror(arg == contract, arg, contract)
      end
    end
  end

  def call(this, *args, &blk)
    _args = blk ? args + [blk] : args
    if _args.size != @contracts.size - 1
      # so it's not *args
      if !@contracts[-2].is_a? Contracts::Args
        raise %{The number of arguments doesn't match the number of contracts.
Did you forget to write a contract for the return value of the function?
Or if you want a variable number of arguments using *args, use the Args contract.
Args: #{args.inspect}
Contracts: #{@contracts.map { |t| t.is_a?(Class) ? t.name : t.class.name }.join(", ")}}
      end
    end    
    Contract.validate_all(_args, @contracts[0, @contracts.size - 1], @klass, @method)

    result = @method.bind(this).call(*args, &blk)
    
    if args.size == @contracts.size - 1
      Contract.validate(result, @contracts[-1], @klass, @method, @contracts)
    end
    result
  end

  private

  def self.mkerror(validates, arg, contract)
    if validates
      [true, {}]
    else
      [false, { :arg => arg, :contract => contract }]
    end
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
    # we assume that any mismatch in # of args/contracts
    # has been checked befoer this point.
    if args.size != contracts.size
      # assumed: contracts[-1].is_a? Args
      while contracts.size < args.size
        contracts << contracts[-1].dup
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
end
