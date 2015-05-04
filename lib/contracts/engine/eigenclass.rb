module Contracts
  module Engine
    # Special case of contracts engine for eigenclasses
    # We don't care about eigenclass of eigenclass at this point
    class Eigenclass < Base
      # Class that owns this eigenclass
      attr_accessor :owner_class

      # No-op for eigenclasses
      def set_eigenclass_owner
      end

      # Fetches just eigenclasses decorators
      def all_decorators
        pop_decorators
      end

      private

      # Fails when contracts are not included in owner class
      def validate!
        fail ContractsNotIncluded unless owner?
      end

      def owner?
        !!owner_class
      end
    end
  end
end
