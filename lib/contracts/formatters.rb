module Contracts
  # A namespace for classes related to formatting.
  module Formatters
    # Used to format contracts for the `Expected:` field of error output.
    class Expected
      def initialize(contract)
        @contract = contract
      end

      # Formats any type of Contract.
      def contract(contract = @contract)
        if contract.is_a?(Hash)
          hash_contract(contract)
        elsif contract.is_a?(Array)
          array_contract(contract)
        else
          ContractInspectWrapper.new(contract)
        end
      end

      # Formats Hash contracts.
      def hash_contract(hash)
        hash.inject({}) { |repr, (k, v)|
          repr.merge(k => ContractInspectWrapper.new(contract(v)))
        }.inspect
      end

      # Formats Array contracts.
      def array_contract(array)
        array.map{ |v| ContractInspectWrapper.new(contract(v)) }.inspect
      end
    end

    # A wrapper class to produce correct inspect behaviour for different
    # contract values - constants, Class contracts, instance contracts etc.
    class ContractInspectWrapper
      def initialize(value)
        @value = value
      end

      # Inspect different types of contract values.
      # Contracts module prefix will be removed from classes.
      # Custom to_s messages will be wrapped in round brackets to differentiate
      # from standard Strings.
      # Primitive values e.g. 42, true, nil will be left alone.
      def inspect
        return @value.inspect if empty_val?
        return @value.to_s if plain?
        return "(#{@value.to_s})" if has_useful_to_s?
        @value.inspect.gsub(/^Contracts::/, '')
      end

      # Eliminates eronious quotes in output that plain inspect includes.
      def to_s
        inspect
      end

      private
      def empty_val?
        @value.nil? || @value == ""
      end

      def plain?
        # Not a type of contract that can have a custom to_s defined
        !@value.is_a?(CallableClass) && @value.class != Class
      end

      def has_useful_to_s?
        # Useless to_s value or no custom to_s behavious defined
        @value.to_s != "" && @value.to_s != @value.inspect
      end
    end
  end
end
