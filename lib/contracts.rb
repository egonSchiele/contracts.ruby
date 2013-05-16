require 'decorators'
require 'builtin_contracts'

class ContractError < ArgumentError
end

module Contracts
  def self.included(base)
    common base
  end

  def self.extended(base)
    common base
  end

  def self.common base
    base.extend MethodDecorators
    base.instance_eval do
      def functype(funcname)
        contracts = self.decorated_methods[:class_methods][funcname]
        if contracts.nil?
          "No contract for #{self}.#{funcname}"
        else
          "#{funcname} :: #{contracts}"
        end
      end
    end
    base.class_eval do
      def Contract(*args)
        self.class.Contract(*args)
      end

      def functype(funcname)
        contracts = self.class.decorated_methods[:instance_methods][funcname]
        if contracts.nil?
          "No contract for #{self.class}.#{funcname}"
        else
          "#{funcname} :: #{contracts}"
        end
      end
    end
  end    
end

# This is the main Contract class. When you write a new contract, you'll
# write it as:
#
#   Contract [contract names] => return_value
#
# This class also provides useful callbacks and a validation method.
class Contract < Decorator
  attr_reader :args_contracts, :ret_contract, :klass, :method
  # decorator_name :contract
  def initialize(klass, method, *contracts)
    if contracts[-1].is_a? Hash
      # internally we just convert that return value syntax back to an array
      @args_contracts = contracts[0, contracts.size - 1] + contracts[-1].keys
      @ret_contract = contracts[-1].values[0]
      @args_validators = @args_contracts.map do |contract|
        Contract.make_validator(contract)
      end
      @ret_validator = Contract.make_validator(@ret_contract)
    else
      fail "It looks like your contract for #{method} doesn't have a return value. A contract should be written as `Contract arg1, arg2 => return_value`."
    end
    @klass, @method= klass, method
    @has_func_contracts = args_contracts.index do |contract|
      contract.is_a? Contracts::Func
    end
  end

  def pretty_contract c
    c.is_a?(Class) ? c.name : c.class.name
  end

  def to_s
    args = @args_contracts.map { |c| pretty_contract(c) }.join(", ")
    ret = pretty_contract(@ret_contract)
    ("#{args} => #{ret}").gsub("Contracts::", "")
  end

  # Given a hash, prints out a failure message.
  # This function is used by the default #failure_callback method
  # and uses the hash passed into the failure_callback method.
  def self.failure_msg(data)
   expected = if data[:contract].to_s == "" || data[:contract].is_a?(Hash)
                data[:contract].inspect
              else
                data[:contract].to_s
              end

    if RUBY_VERSION =~ /^1\.8/
      if data[:method].respond_to?(:__file__)
        position = data[:method].__file__ + ":" + data[:method].__line__.to_s
      else
        position = data[:method].inspect
      end
    else
      file, line = data[:method].source_location
      position = file + ":" + line.to_s
    end
   method_name = data[:method].is_a?(Proc) ? "Proc" : data[:method].name
%{Contract violation:
    Expected: #{expected},
    Actual: #{data[:arg].inspect}
    Value guarded in: #{data[:class]}::#{method_name}
    With Contract: #{data[:contracts]}
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
    raise ContractError, failure_msg(data)
  end

  # Used to verify if an argument satisfies a contract.
  #
  # Takes: an argument and a contract.
  #
  # Returns: a tuple: [Boolean, metadata]. The boolean indicates
  # whether the contract was valid or not. If it wasn't, metadata
  # contains some useful information about the failure.
  def self.valid?(arg, contract)
    make_validator(contract)[arg]
  end

  # This is a little weird. For each contract
  # we pre-make a proc to validate it so we
  # don't have to go through this decision tree every time.
  # Seems silly but it saves us a bunch of time (4.3sec vs 5.2sec)
  def self.make_validator(contract)
    # if is faster than case!
    klass = contract.class
    if klass == Proc
      # e.g. lambda {true}
      contract
    elsif klass == Array
      # e.g. [Num, String]
      # TODO account for these errors too
      lambda { |arg|
        return false unless arg.is_a?(Array)
        arg.zip(contract).all? do |_arg, _contract|
          Contract.valid?(_arg, _contract)
        end
      }
    elsif klass == Hash
      # e.g. { :a => Num, :b => String }
      lambda { |arg|
        return false unless arg.is_a?(Hash)
        contract.keys.all? do |k|
          Contract.valid?(arg[k], contract[k])
        end
      }
    elsif klass == Contracts::Args
      lambda { |arg|
        Contract.valid?(arg, contract.contract)
      }
    elsif klass == Contracts::Func
      lambda { |arg|
        arg.is_a?(Method) || arg.is_a?(Proc)
      }
    else
      # classes and everything else
      # e.g. Fixnum, Num
      if contract.respond_to? :valid?
        lambda { |arg| contract.valid?(arg) }
      elsif klass == Class
        lambda { |arg| contract == arg.class }
      else
        lambda { |arg| contract == arg }        
      end
    end
  end  

  def [](*args, &blk)
    call(*args, &blk)
  end

  def call(*args, &blk)
    call_with(nil, *args, &blk)
  end

  def call_with(this, *args, &blk)
    _args = blk ? args + [blk] : args

    # check contracts on arguments
    # fun fact! This is significantly faster than .zip (3.7 secs vs 4.7 secs). Why??
    last_index = @args_validators.size - 1
    # times is faster than (0..args.size).each
    _args.size.times do |i|
      # this is done to account for extra args (for *args)
      j = i < last_index ? i : last_index
      #unless true #@args_contracts[i].valid?(args[i])
      unless @args_validators[j][_args[i]]
        call_function = Contract.failure_callback({:arg => _args[i], :contract => @args_contracts[j], :class => @klass, :method => @method, :contracts => self})
        return unless call_function
      end
    end

    if @has_func_contracts
      # contracts on methods
      contracts.each_with_index do |contract, i|
        if contract.is_a? Contracts::Func
        args[i] = Contract.new(@klass, args[i], *contract.contracts)
        end
      end
    end

    result = if @method.respond_to? :bind
      # instance method
      @method.bind(this).call(*args, &blk)
    else
      # class method
      @method.call(*args, &blk)
    end
    unless @ret_validator[result]
      Contract.failure_callback({:arg => result, :contract => @ret_contract, :class => @klass, :method => @method, :contracts => self})
    end    
    result
  end
end
