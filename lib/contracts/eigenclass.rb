module Contracts
  module Eigenclass

    extend MethodDecorators

    def self.extended(eigenclass)
      return if eigenclass.respond_to?(:owner_class=)

      class << eigenclass
        attr_accessor :owner_class
      end
    end

    def self.lift(base)
      return if base.singleton_class?

      eigenclass = base.singleton_class

      unless eigenclass.respond_to?(:owner_class=)
        eigenclass.extend(Eigenclass)
      end

      unless eigenclass.respond_to?(:Contract)
        eigenclass.extend(MethodDecorators)
      end

      eigenclass.owner_class = base
    end

  end
end
