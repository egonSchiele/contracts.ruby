module Contracts
  module Validators
    DEFAULT_VALIDATOR_STRATEGIES = {
      # e.g. lambda {true}
      Proc => lambda { |contract| contract },

      # e.g. [Num, String]
      # TODO: account for these errors too
      Array => lambda do |contract|
        lambda do |arg|
          return false unless arg.is_a?(Array) && arg.length == contract.length
          arg.zip(contract).all? do |_arg, _contract|
            Contract.valid?(_arg, _contract)
          end
        end
      end,

      # e.g. { :a => Num, :b => String }
      Hash => lambda do |contract|
        lambda do |arg|
          return false unless arg.is_a?(Hash)
          contract.keys.all? do |k|
            Contract.valid?(arg[k], contract[k])
          end
        end
      end,

      Contracts::Args => lambda do |contract|
        lambda do |arg|
          Contract.valid?(arg, contract.contract)
        end
      end,

      Contracts::Func => lambda do |_|
        lambda do |arg|
          arg.is_a?(Method) || arg.is_a?(Proc)
        end
      end,

      :valid => lambda do |contract|
        lambda { |arg| contract.valid?(arg) }
      end,

      :class => lambda do |contract|
        lambda { |arg| arg.is_a?(contract) }
      end,

      :default => lambda do |contract|
        lambda { |arg| contract == arg }
      end
    }.freeze

    # Allows to override validator with custom one.
    # Example:
    #   Contract.override_validator(Array) do |contract|
    #     lambda do |arg|
    #       # .. implementation for Array contract ..
    #     end
    #   end
    #
    #   Contract.override_validator(:class) do |contract|
    #     lambda do |arg|
    #       arg.is_a?(contract) || arg.is_a?(RSpec::Mocks::Double)
    #     end
    #   end
    def override_validator(name, &block)
      validator_strategies[name] = block
    end

    # This is a little weird. For each contract
    # we pre-make a proc to validate it so we
    # don't have to go through this decision tree every time.
    # Seems silly but it saves us a bunch of time (4.3sec vs 5.2sec)
    def make_validator(contract)
      klass = contract.class
      key = if validator_strategies.key?(klass)
              klass
            else
              if contract.respond_to? :valid?
                :valid
              elsif klass == Class || klass == Module
                :class
              else
                :default
              end
            end

      validator_strategies[key].call(contract)
    end

    # @private
    def validator_strategies
      @_validator_strategies ||= restore_validators
    end

    # @private
    def restore_validators
      @_validator_strategies = DEFAULT_VALIDATOR_STRATEGIES.dup
    end
  end
end
