module Contracts
  class EngineTarget
    def initialize(target)
      @target = target
    end

    def apply(engine_class = Engine)
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
      
      EngineTarget.new(eigenclass).apply(EigenclassEngine)
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

  class Engine
    def self.apply(klass)
      EngineTarget.new(klass).apply
    end

    def self.applied?(klass)
      EngineTarget.new(klass).applied?
    end

    def self.fetch_from(klass)
      EngineTarget.new(klass).engine
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

  class EigenclassEngine < Engine
    attr_accessor :owner_class

    def set_eigenclass_owner
    end

    def all_decorators
      pop_decorators
    end

    private

    def validate!
      fail Contracts::ContractsNotIncluded unless has_owner?
    end

    def has_owner?
      !!owner_class
    end
  end
end
