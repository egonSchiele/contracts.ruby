module Contracts
  module MethodDecorators
    def self.extended(klass)
      Engine.apply(klass)
    end

    # first, when you write a contract, the decorate method gets called which
    # sets the @decorators variable. Then when the next method after the contract
    # is defined, method_added is called and we look at the @decorators variable
    # to find the decorator for that method. This is how we associate decorators
    # with methods.
    def method_added(name)
      MethodHandler.new(name, false).handle(self)
      super
    end

    def singleton_method_added(name)
      MethodHandler.new(name, true).handle(self)
      super
    end
  end

  class Decorator
    # an attr_accessor for a class variable:
    class << self; attr_accessor :decorators; end

    def self.inherited(klass)
      name = klass.name.gsub(/^./) { |m| m.downcase }

      return if name =~ /^[^A-Za-z_]/ || name =~ /[^0-9A-Za-z_]/

      # the file and line parameters set the text for error messages
      # make a new method that is the name of your decorator.
      # that method accepts random args and a block.
      # inside, `decorate` is called with those params.
      MethodDecorators.module_eval <<-ruby_eval, __FILE__, __LINE__ + 1
        def #{klass}(*args, &blk)
          ::Contracts::Engine.fetch_from(self).decorate(#{klass}, *args, &blk)
        end
      ruby_eval
    end

    def initialize(klass, method)
      @method = method
    end
  end
end
