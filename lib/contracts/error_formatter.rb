module Contracts
  class ErrorFormatters
    def self.failure_msg(data)
      class_for(data).new(data).message
    end

    def self.class_for(data)
      return Contracts::KeywordArgsErrorFormatter if keyword_args?(data)
      DefaultErrorFormatter
    end

    def self.keyword_args?(data)
      data[:contract].is_a?(Contracts::Builtin::KeywordArgs) && data[:arg].is_a?(Hash)
    end
  end

  class DefaultErrorFormatter
    attr_accessor :data
    def initialize(data)
      @data = data
    end

    def message
      %{#{header}
        Expected: #{expected},
        Actual: #{data[:arg].inspect}
        Value guarded in: #{data[:class]}::#{method_name}
        With Contract: #{data[:contracts]}
        At: #{position} }
    end

    private

    def header
      if data[:return_value]
        "Contract violation for return value:"
      else
        "Contract violation for argument #{data[:arg_pos]} of #{data[:total_args]}:"
      end
    end

    def expected
      Contracts::Formatters::Expected.new(data[:contract]).contract
    end

    def position
      Contracts::Support.method_position(data[:method])
    end

    def method_name
      Contracts::Support.method_name(data[:method])
    end
  end

  class KeywordArgsErrorFormatter < DefaultErrorFormatter
    def message
      s = []
      s << "#{header}"
      s << "        Expected: #{expected}"
      s << "        Actual: #{data[:arg].inspect}"
      s << "        Missing Contract: #{missing_contract_info}" unless missing_contract_info.empty?
      s << "        Invalid Args: #{invalid_args_info}"         unless invalid_args_info.empty?
      s << "        Missing Args: #{missing_args_info}"         unless missing_args_info.empty?
      s << "        Value guarded in: #{data[:class]}::#{method_name}"
      s << "        With Contract: #{data[:contracts]}"
      s << "        At: #{position} "

      s.join("\n")
    end

    private

    def missing_args_info
      @missing_args_info ||= begin
        missing_keys = contract_options.keys - arg.keys
        contract_options.select do |key, _|
          missing_keys.include?(key)
        end
      end
    end

    def missing_contract_info
      @missing_contract_info ||= begin
        contract_keys = contract_options.keys
        arg.select { |key, _| !contract_keys.include?(key) }
      end
    end

    def invalid_args_info
      @invalid_args_info ||= begin
        invalid_keys = []
        arg.each do |key, value|
          contract = contract_options[key]
          next unless contract
          invalid_keys.push(key) unless check_contract(contract, value)
        end
        invalid_keys.map do |key|
          {key => arg[key], :contract => contract_options[key] }
        end
      end
    end

    def check_contract(contract, value)
      if contract.respond_to?(:valid?)
        contract.valid?(value)
      else
        value.is_a?(contract)
      end
    rescue
      false
    end

    def contract_options
      @contract_options ||= data[:contract].send(:options)
    end

    def arg
      data[:arg]
    end
  end
end
