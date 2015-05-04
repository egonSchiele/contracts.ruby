module Contracts
  module Engine
    class Base
      def self.apply(klass)
        Engine::Target.new(klass).apply
      end

      def self.applied?(klass)
        Engine::Target.new(klass).applied?
      end

      def self.fetch_from(klass)
        Engine::Target.new(klass).engine
      end

      def initialize(target)
        @target = target
      end

      def decorate(klass, *args)
        validate!
        decorators << [klass, args]
      end

      def set_eigenclass_owner
        eigenclass_engine.owner_class = target
      end

      def all_decorators
        pop_decorators + eigenclass_engine.all_decorators
      end

      def pop_decorators
        decorators.tap { clear_decorators }
      end

      def decorated_methods
        @_decorated_methods ||= { :class_methods => {}, :instance_methods => {} }
      end

      def has_decorated_methods?
        !decorated_methods[:class_methods].empty? ||
          !decorated_methods[:instance_methods].empty?
      end

      def add_method_decorator(type, name, decorator)
        decorated_methods[type][name] ||= []
        decorated_methods[type][name] << decorator
      end

      private
      attr_reader :target

      def validate!
      end

      def eigenclass
        Support.eigenclass_of(target)
      end

      def eigenclass_engine
        Engine.fetch_from(eigenclass)
      end

      def decorators
        @_decorators ||= []
      end

      def clear_decorators
        @_decorators = []
      end
    end
  end
end
