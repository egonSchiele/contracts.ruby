require "contracts/builtin_contracts"
require "contracts/decorators"
require "contracts/errors"
require "contracts/formatters"
require "contracts/invariants"
require "contracts/method_reference"
require "contracts/support"
require "contracts/engine"
require "contracts/method_handler"

module Contracts
  def self.included(base)
    common(base)
  end

  def self.extended(base)
    common(base)
  end

  def self.common(base)
    #Eigenclass.lift(base)

    return if base.respond_to?(:Contract)

    base.extend(MethodDecorators)

    base.instance_eval do
      def functype(funcname)
        contracts = Engine.fetch_from(self).decorated_methods[:class_methods][funcname]
        if contracts.nil?
          "No contract for #{self}.#{funcname}"
        else
          "#{funcname} :: #{contracts[0]}"
        end
      end
    end

    base.class_eval do
      unless base.instance_of?(Module)
        def Contract(*args)
          return if ENV["NO_CONTRACTS"]
          if self.class == Module
            puts %{
Warning: You have added a Contract on a module function
without including Contracts::Modules. Your Contract will
just be ignored. Please include Contracts::Modules into
your module.}
          end
          self.class.Contract(*args)
        end
      end

      def functype(funcname)
        contracts = Engine.fetch_from(self.class).decorated_methods[:instance_methods][funcname]
        if contracts.nil?
          "No contract for #{self.class}.#{funcname}"
        else
          "#{funcname} :: #{contracts[0]}"
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
class Contract < Contracts::Decorator
  # Default implementation of failure_callback. Provided as a block to be able
  # to monkey patch #failure_callback only temporary and then switch it back.
  # First important usage - for specs.
  DEFAULT_FAILURE_CALLBACK = proc do |data|
    if data[:return_value]
      # this failed on the return contract
      fail ReturnContractError.new(failure_msg(data), data)
    else
      # this failed for a param contract
      fail data[:contracts].failure_exception.new(failure_msg(data), data)
    end
  end

  attr_reader :args_contracts, :ret_contract, :klass, :method
  def initialize(klass, method, *contracts)
    unless contracts.last.is_a?(Hash)
      unless contracts.one?
        fail %{
          It looks like your contract for #{method.name} doesn't have a return
          value. A contract should be written as `Contract arg1, arg2 =>
          return_value`.
        }.strip
      end
      contracts = [nil => contracts[-1]]
    end

    # internally we just convert that return value syntax back to an array
    @args_contracts = contracts[0, contracts.size - 1] + contracts[-1].keys

    @ret_contract = contracts[-1].values[0]

    @args_validators = args_contracts.map do |contract|
      Contract.make_validator(contract)
    end

    @args_contract_index = args_contracts.index do |contract|
      contract.is_a? Contracts::Args
    end

    @ret_validator = Contract.make_validator(ret_contract)

    # == @has_proc_contract
    last_contract = args_contracts.last
    is_a_proc = last_contract.is_a?(Class) && (last_contract <= Proc || last_contract <= Method)

    @has_proc_contract = is_a_proc || last_contract.is_a?(Contracts::Func)
    # ====

    # == @has_options_contract
    last_contract = args_contracts.last
    penultimate_contract = args_contracts[-2]
    @has_options_contract = if @has_proc_contract
                              penultimate_contract.is_a?(Hash)
                            else
                              last_contract.is_a?(Hash)
                            end
    # ===

    @klass, @method = klass, method
  end

  def pretty_contract c
    c.is_a?(Class) ? c.name : c.class.name
  end

  def to_s
    args = args_contracts.map { |c| pretty_contract(c) }.join(", ")
    ret = pretty_contract(ret_contract)
    ("#{args} => #{ret}").gsub("Contracts::", "")
  end

  # Given a hash, prints out a failure message.
  # This function is used by the default #failure_callback method
  # and uses the hash passed into the failure_callback method.
  def self.failure_msg(data)
    expected = Contracts::Formatters::Expected.new(data[:contract]).contract
    position = Contracts::Support.method_position(data[:method])
    method_name = Contracts::Support.method_name(data[:method])

    header = if data[:return_value]
               "Contract violation for return value:"
             else
               "Contract violation for argument #{data[:arg_pos]} of #{data[:total_args]}:"
             end

    %{#{header}
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
  #   def Contract.failure_callback(data)
  #     puts "You had an error!"
  #     puts failure_msg(data)
  #     exit
  #   end
  def self.failure_callback(data, use_pattern_matching = true)
    if data[:contracts].pattern_match? && use_pattern_matching
      return DEFAULT_FAILURE_CALLBACK.call(data)
    end

    fetch_failure_callback.call(data)
  end

  # Used to override failure_callback without monkeypatching.
  #
  # Takes: block parameter, that should accept one argument - data.
  #
  # Example usage:
  #
  #   Contract.override_failure_callback do |data|
  #     puts "You had an error"
  #     puts failure_msg(data)
  #     exit
  #   end
  def self.override_failure_callback(&blk)
    @failure_callback = blk
  end

  # Used to restore default failure callback
  def self.restore_failure_callback
    @failure_callback = DEFAULT_FAILURE_CALLBACK
  end

  def self.fetch_failure_callback
    @failure_callback ||= DEFAULT_FAILURE_CALLBACK
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
      # TODO: account for these errors too
      lambda do |arg|
        return false unless arg.is_a?(Array) && arg.length == contract.length
        arg.zip(contract).all? do |_arg, _contract|
          Contract.valid?(_arg, _contract)
        end
      end
    elsif klass == Hash
      # e.g. { :a => Num, :b => String }
      lambda do |arg|
        return false unless arg.is_a?(Hash)
        contract.keys.all? do |k|
          Contract.valid?(arg[k], contract[k])
        end
      end
    elsif klass == Contracts::Args
      lambda do |arg|
        Contract.valid?(arg, contract.contract)
      end
    elsif klass == Contracts::Func
      lambda do |arg|
        arg.is_a?(Method) || arg.is_a?(Proc)
      end
    else
      # classes and everything else
      # e.g. Fixnum, Num
      if contract.respond_to? :valid?
        lambda { |arg| contract.valid?(arg) }
      elsif klass == Class
        lambda { |arg| arg.is_a?(contract) }
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

  # if we specified a proc in the contract but didn't pass one in,
  # it's possible we are going to pass in a block instead. So lets
  # append a nil to the list of args just so it doesn't fail.

  # a better way to handle this might be to take this into account
  # before throwing a "mismatched # of args" error.
  def maybe_append_block! args, blk
    return unless @has_proc_contract && !blk &&
        (@args_contract_index || args.size < args_contracts.size)
    args << nil
  end

  # Same thing for when we have named params but didn't pass any in.
  def maybe_append_options! args, blk
    return unless @has_options_contract
    if @has_proc_contract && args_contracts[-2].is_a?(Hash) && !args[-2].is_a?(Hash)
      args.insert(-2, {})
    elsif args_contracts[-1].is_a?(Hash) && !args[-1].is_a?(Hash)
      args << {}
    end
  end

  def call_with(this, *args, &blk)
    args << blk if blk

    # Explicitly append blk=nil if nil != Proc contract violation anticipated
    maybe_append_block!(args, blk)

    # Explicitly append options={} if Hash contract is present
    maybe_append_options!(args, blk)

    # Loop forward validating the arguments up to the splat (if there is one)
    (@args_contract_index || args.size).times do |i|
      contract = args_contracts[i]
      arg = args[i]
      validator = @args_validators[i]

      unless validator && validator[arg]
        return unless Contract.failure_callback(:arg => arg,
                                                :contract => contract,
                                                :class => klass,
                                                :method => method,
                                                :contracts => self,
                                                :arg_pos => i+1,
                                                :total_args => args.size,
                                                :return_value => false)
      end

      if contract.is_a?(Contracts::Func)
        args[i] = Contract.new(klass, arg, *contract.contracts)
      end
    end

    # If there is a splat loop backwards to the lower index of the splat
    # Once we hit the splat in this direction set its upper index
    # Keep validating but use this upper index to get the splat validator.
    if @args_contract_index
      splat_upper_index = @args_contract_index
      (args.size - @args_contract_index).times do |i|
        arg = args[args.size - 1 - i]

        if args_contracts[args_contracts.size - 1 - i].is_a?(Contracts::Args)
          splat_upper_index = i
        end

        # Each arg after the spat is found must use the splat validator
        j = i < splat_upper_index ? i : splat_upper_index
        contract = args_contracts[args_contracts.size - 1 - j]
        validator = @args_validators[args_contracts.size - 1 - j]

        unless validator && validator[arg]
          return unless Contract.failure_callback(:arg => arg,
                                                  :contract => contract,
                                                  :class => klass,
                                                  :method => method,
                                                  :contracts => self,
                                                  :arg_pos => i-1,
                                                  :total_args => args.size,
                                                  :return_value => false)
        end

        if contract.is_a?(Contracts::Func)
          args[args.size - 1 - i] = Contract.new(klass, arg, *contract.contracts)
        end
      end
    end

    # If we put the block into args for validating, restore the args
    args.slice!(-1) if blk
    result = if method.respond_to?(:call)
               # proc, block, lambda, etc
               method.call(*args, &blk)
             else
               # original method name referrence
               method.send_to(this, *args, &blk)
             end

    unless @ret_validator[result]
      Contract.failure_callback(:arg => result,
                                :contract => ret_contract,
                                :class => klass,
                                :method => method,
                                :contracts => self,
                                :return_value => true)
    end

    this.verify_invariants!(method) if this.respond_to?(:verify_invariants!)

    result
  end

  # Used to determine type of failure exception this contract should raise in case of failure
  def failure_exception
    if @pattern_match
      PatternMatchingError
    else
      ParamContractError
    end
  end

  # @private
  # Used internally to mark contract as pattern matching contract
  def pattern_match!
    @pattern_match = true
  end

  # Used to determine if contract is a pattern matching contract
  def pattern_match?
    @pattern_match
  end
end
