# frozen_string_literal: true

module Contracts
  module Attrs
    def attr_reader_with_contract(*names, contract)
      names.each do |name|
        Contract Contracts::None => contract
        attr_reader(name)
      end
    end

    def attr_writer_with_contract(*names, contract)
      names.each do |name|
        Contract contract => contract
        attr_writer(name)
      end
    end

    def attr_accessor_with_contract(*names, contract)
      attr_reader_with_contract(*names, contract)
      attr_writer_with_contract(*names, contract)
    end
  end

  include Attrs
end
