module Contracts
  module Engine
    class Target
      def initialize(target)
        @target = target
      end

      def apply(engine_class = Base)
        return if applied?

        apply_to_eigenclass

        target.class_eval do
          define_singleton_method(:__contracts_engine) do
            @__contracts_engine ||= engine_class.new(self)
          end
        end

        engine.set_eigenclass_owner
      end

      def applied?
        target.respond_to?(:__contracts_engine)
      end

      def engine
        applied? && target.__contracts_engine
      end

      private
      attr_reader :target

      def apply_to_eigenclass
        return unless has_meaningless_eigenclass?
        
        self.class.new(eigenclass).apply(Eigenclass)
        eigenclass.extend(MethodDecorators)
        eigenclass.send(:include, Contracts)
      end

      def eigenclass
        Support.eigenclass_of(target)
      end

      def has_meaningless_eigenclass?
        return true if target.class == Module
        return false if target < Module
        !Support.eigenclass?(target)
      end
    end
  end
end
