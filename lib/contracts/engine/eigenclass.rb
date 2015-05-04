module Contracts
  module Engine
    class Eigenclass < Base
      attr_accessor :owner_class

      def set_eigenclass_owner
      end

      def all_decorators
        pop_decorators
      end

      private

      def validate!
        fail ContractsNotIncluded unless has_owner?
      end

      def has_owner?
        !!owner_class
      end
    end
  end
end
