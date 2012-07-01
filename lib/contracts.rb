require 'decorators'
require 'builtin_contracts'
module Contracts
  def self.included(base)
    common base
  end

  def self.extended(base)
    common base
  end

  def self.common base
    base.extend MethodDecorators
    base.class_eval do
      def Contract(*args)
        self.class.Contract(*args)
      end
    end
  end    
end

# This is the main Contract class. When you write a new contract, you'll
# write it as:
#
#   Contract [contract names]
#
# This class also provides useful callbacks and a validation method.
class Contract < Decorator
  attr_accessor :contracts, :klass, :method
  # decorator_name :contract
  def initialize(klass, method, *contracts)
    if contracts[-1].is_a? Hash
      # internally we just convert that return value syntax back to an array
      contracts = contracts[0, contracts.size - 1] + contracts[-1].keys + contracts[-1].values
    else
      fail "It looks like your contract for #{method} doesn't have a return value. A contract should be written as `Contract arg1, arg2 => return_value`."
    end
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
   method_name = data[:method].is_a?(Proc) ? "Proc" : data[:method].name
%{Contract violation:
    Expected: #{expected},
    Actual: #{data[:arg].inspect}
    Value guarded in: #{data[:class]}::#{method_name}
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
      arg.zip(contract).each do |_arg, _contract|
        res, info = valid?(_arg, _contract)
        return mkerror(false, arg, contract) unless res
      end
    when Hash
      # e.g. { :a => Num, :b => String }
      return mkerror(false, arg, contract) unless arg.is_a?(Hash)
      validate_hash(arg, contract)
    when Contracts::Args
      valid? arg, contract.contract
    when Func
      arg.is_a?(Method) || arg.is_a?(Proc)
    else
      if contract.respond_to? :valid?
        mkerror(contract.valid?(arg), arg, contract)
      else
        mkerror(arg == contract, arg, contract)
      end
    end
  end

  def call(*args, &blk)
    call_with(nil, *args, &blk)
  end

  def call_with(this, *args, &blk)
    _args = blk ? args + [blk] : args
    res = Contract.validate_all(_args, @contracts[0, @contracts.size - 1], @klass, @method)
    return if res == false

    # contracts on methods

    contracts.each_with_index do |contract, i|
      if contract.is_a? Func
      args[i] = Contract.new(@klass, args[i], *contract.contracts)
      end
    end      
    
    if @method.respond_to? :bind
      # instance method
      result = @method.bind(this).call(*args, &blk)
    else
      # class method
      result = @method.call(*args, &blk)
    end

    Contract.validate(result, @contracts[-1], @klass, @method, @contracts)
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
    contract.keys.each do |k|
      result, info = valid?(arg[k], contract[k])
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

  def self.validate_all(params, contracts, klass, method)
    # we assume that any mismatch in # of params/contracts
    # has been checked befoer this point.
    args_index = contracts.index do |contract|
      contract.is_a? Contracts::Args
    end
    if args_index
      # there is a *args at this index.
      # Now we need to see how many arguments this contract
      # accounts for and just duplicate the contract for all
      # of those args.
      args_contract = contracts[args_index]
      while contracts.size < params.size
        contracts.insert(args_index, args_contract.dup)
      end
    end

    params.zip(contracts).each do |param, contract|
      result = validate(param, contract, klass, method, contracts)
      return result if result == false
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
