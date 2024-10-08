# frozen_string_literal: true

require "contracts/version"
require "contracts/attrs"
require "contracts/builtin_contracts"
require "contracts/decorators"
require "contracts/errors"
require "contracts/formatters"
require "contracts/invariants"
require "contracts/method_reference"
require "contracts/support"
require "contracts/engine"
require "contracts/method_handler"
require "contracts/validators"
require "contracts/call_with"
require "contracts/core"

module Contracts
  def self.included(base)
    base.send(:include, Core)
  end

  def self.extended(base)
    base.send(:extend, Core)
  end
end

# This is the main Contract class. When you write a new contract, you'll
# write it as:
#
#   Contract [contract names] => return_value
#
# This class also provides useful callbacks and a validation method.
#
# For #make_validator and related logic see file
# lib/contracts/validators.rb
# For #call_with and related logic see file
# lib/contracts/call_with.rb
class Contract < Contracts::Decorator
  extend Contracts::Validators
  include Contracts::CallWith

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

  attr_reader :args_contracts, :kargs_contract, :ret_contract, :klass, :method

  def initialize(klass, method, *contracts)
    super(klass, method)
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
    # Extract contract for keyword arguments
    @kargs_contract = args_contracts.find { |c| c.is_a?(Contracts::Builtin::KeywordArgs) }
    args_contracts.delete(kargs_contract) if kargs_contract

    @ret_contract = contracts[-1].values[0]

    @args_validators = args_contracts.map do |contract|
      Contract.make_validator(contract)
    end

    @kargs_validator = kargs_contract ? Contract.make_validator(kargs_contract) : nil

    @args_contract_index = args_contracts.index do |contract|
      contract.is_a? Contracts::Args
    end

    @ret_validator = Contract.make_validator(ret_contract)

    @pattern_match = false

    # == @has_proc_contract
    last_contract = args_contracts.last
    is_a_proc = last_contract.is_a?(Class) && (last_contract <= Proc || last_contract <= Method)
    maybe_a_proc = last_contract.is_a?(Contracts::Maybe) && last_contract.include_proc?

    @has_proc_contract = is_a_proc || maybe_a_proc || last_contract.is_a?(Contracts::Func)

    # ====

    @klass, @method = klass, method
  end

  def pretty_contract contract
    contract.is_a?(Class) ? contract.name : contract.class.name
  end

  def to_s
    args = args_contracts.map { |c| pretty_contract(c) }.join(", ")
    ret = pretty_contract(ret_contract)
    ("#{args} => #{ret}").gsub("Contracts::Builtin::", "")
  end

  # Given a hash, prints out a failure message.
  # This function is used by the default #failure_callback method
  # and uses the hash passed into the failure_callback method.
  def self.failure_msg(data)
    indent_amount = 8
    method_name = Contracts::Support.method_name(data[:method])

    # Header
    header = if data[:return_value]
               "Contract violation for return value:"
             else
               "Contract violation for argument #{data[:arg_pos]} of #{data[:total_args]}:"
             end

    # Expected
    expected_prefix = "Expected: "
    expected_value = Contracts::Support.indent_string(
      Contracts::Formatters::Expected.new(data[:contract]).contract.pretty_inspect,
      expected_prefix.length,
    ).strip
    expected_line = "#{expected_prefix}#{expected_value},"

    # Actual
    actual_prefix = "Actual: "
    actual_value = Contracts::Support.indent_string(
      data[:arg].pretty_inspect,
      actual_prefix.length,
    ).strip
    actual_line = actual_prefix + actual_value

    # Value guarded in
    value_prefix = "Value guarded in: "
    value_value = "#{data[:class]}::#{method_name}"
    value_line = value_prefix + value_value

    # Contract
    contract_prefix = "With Contract: "
    contract_value = data[:contracts].to_s
    contract_line = contract_prefix + contract_value

    # Position
    position_prefix = "At: "
    position_value = Contracts::Support.method_position(data[:method])
    position_line = position_prefix + position_value

    [
      header,
      Contracts::Support.indent_string(
        [
          expected_line,
          actual_line,
          value_line,
          contract_line,
          position_line,
        ].join("\n"),
        indent_amount,
      ),
    ].join("\n")
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
  def self.failure_callback(data, use_pattern_matching: true)
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
  # returns true if it appended nil
  def maybe_append_block! args, blk
    return false unless @has_proc_contract && !blk &&
      (@args_contract_index || args.size < args_contracts.size)

    args << nil
    true
  end

  # Used to determine type of failure exception this contract should raise in case of failure
  def failure_exception
    if pattern_match?
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
    @pattern_match == true
  end
end
