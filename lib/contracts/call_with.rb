# frozen_string_literal: true

module Contracts
  module CallWith
    def call_with(this, *args, **kargs, &blk)
      call_with_inner(false, this, *args, **kargs, &blk)
    end

    def call_with_inner(returns, this, *args, **kargs, &blk)
      args << blk if blk

      # Explicitly append blk=nil if nil != Proc contract violation anticipated
      nil_block_appended = maybe_append_block!(args, blk)

      # Explicitly append options={} if Hash contract is present
      kargs_appended = maybe_append_options!(args, kargs, blk)

      # Loop forward validating the arguments up to the splat (if there is one)
      (@args_contract_index || args.size).times do |i|
        contract = args_contracts[i]
        arg = args[i]
        validator = @args_validators[i]

        unless validator && validator[arg]
          data = {
            arg:          arg,
            contract:     contract,
            class:        klass,
            method:       method,
            contracts:    self,
            arg_pos:      i+1,
            total_args:   args.size,
            return_value: false,
          }
          return ParamContractError.new("as return value", data) if returns
          return unless Contract.failure_callback(data)
        end

        if contract.is_a?(Contracts::Func) && blk && !nil_block_appended
          blk = Contract.new(klass, arg, *contract.contracts)
        elsif contract.is_a?(Contracts::Func)
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
            # rubocop:disable Style/SoleNestedConditional
            return unless Contract.failure_callback({
              :arg => arg,
              :contract => contract,
              :class => klass,
              :method => method,
              :contracts => self,
              :arg_pos => i - 1,
              :total_args => args.size,
              :return_value => false,
            })
            # rubocop:enable Style/SoleNestedConditional
          end

          if contract.is_a?(Contracts::Func)
            args[args.size - 1 - i] = Contract.new(klass, arg, *contract.contracts)
          end
        end
      end

      # If we put the block into args for validating, restore the args
      # OR if we added a fake nil at the end because a block wasn't passed in.
      args.slice!(-1) if blk || nil_block_appended
      args.slice!(-1) if kargs_appended
      result = if method.respond_to?(:call)
                 # proc, block, lambda, etc
                 method.call(*args, **kargs, &blk)
               else
                 # original method name reference
                 # Don't reassign blk, else Travis CI shows "stack level too deep".
                 target_blk = blk
                 target_blk = lambda { |*params| blk.call(*params) } if blk.is_a?(Contract)
                 method.send_to(this, *args, **kargs, &target_blk)
               end

      unless @ret_validator[result]
        Contract.failure_callback({
          arg:          result,
          contract:     ret_contract,
          class:        klass,
          method:       method,
          contracts:    self,
          return_value: true,
        })
      end

      this.verify_invariants!(method) if this.respond_to?(:verify_invariants!)

      if ret_contract.is_a?(Contracts::Func)
        result = Contract.new(klass, result, *ret_contract.contracts)
      end

      result
    end
  end
end
