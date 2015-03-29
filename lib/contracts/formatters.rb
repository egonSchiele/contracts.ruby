module Contracts
  # A namespace for classes related to formatting.
  module Formatters
    # Used to format contracts for the `Expected:` field of error output.
    class Expected
      # @param full [Boolean] if false only unique `to_s` values will be output,
      #   non unique values become empty string.
      def initialize(contract, full = true)
        @contract, @full = contract, full
      end

      # Formats any type of Contract.
      def contract(contract = @contract)
        if contract.is_a?(Hash)
          hash_contract(contract)
        elsif contract.is_a?(Array)
          array_contract(contract)
        else
          InspectWrapper.new(contract, @full)
        end
      end

      # Formats Hash contracts.
      def hash_contract(hash)
        @full = true # Complex values output completely, overriding @full
        hash.inject({}) do |repr, (k, v)|
          repr.merge(k => InspectWrapper.new(contract(v), @full))
        end.inspect
      end

      # Formats Array contracts.
      def array_contract(array)
        @full = true
        array.map { |v| InspectWrapper.new(contract(v), @full) }.inspect
      end
    end

    # A wrapper class to produce correct inspect behaviour for different
    # contract values - constants, Class contracts, instance contracts etc.
    class InspectWrapper
      # @param full [Boolean] if false only unique `to_s` values will be output,
      #   non unique values become empty string.
      def initialize(value, full = true)
        @value, @full = value, full
      end

      # Inspect different types of contract values.
      # Contracts module prefix will be removed from classes.
      # Custom to_s messages will be wrapped in round brackets to differentiate
      # from standard Strings.
      # Primitive values e.g. 42, true, nil will be left alone.
      def inspect
        return '' unless full?
        return @value.inspect if empty_val?
        return @value.to_s if plain?
        return delim(@value.to_s) if useful_to_s?
        @value.inspect.gsub(/^Contracts::/, '')
      end

      def delim(value)
        @full ? "(#{value})" : "#{value}"
      end

      # Eliminates eronious quotes in output that plain inspect includes.
      def to_s
        inspect
      end

      private

      def empty_val?
        @value.nil? || @value == ''
      end

      def full?
        @full ||
          @value.is_a?(Hash) || @value.is_a?(Array) ||
          (!plain? && useful_to_s?)
      end

      def plain?
        # Not a type of contract that can have a custom to_s defined
        !@value.is_a?(CallableClass) && @value.class != Class
      end

      def useful_to_s?
        # Useless to_s value or no custom to_s behavious defined
        # Ruby < 2.0 makes inspect call to_s so this won't work
        @value.to_s != '' && @value.to_s != @value.inspect
      end
    end
  end
end
