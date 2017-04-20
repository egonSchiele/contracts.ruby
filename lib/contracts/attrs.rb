module Contracts
  module Attrs
    def attr_reader_with_contract(*names, contract)
      Contract Contracts::None => contract
      attr_reader(*names)
    end

    def attr_writer_with_contract(*names, contract)
      Contract contract => contract
      attr_writer(*names)
    end

    def attr_accessor_with_contract(*names, contract)
      attr_reader_with_contract(*names, contract)
      attr_writer_with_contract(*names, contract)
    end
  end

  include Attrs
end
