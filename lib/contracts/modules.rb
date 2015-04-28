module Contracts
  module Modules
    def self.included(base)
      common(base)
    end

    def self.extended(base)
      common(base)
    end

    def self.common(base)
      return unless base.instance_of?(Module)
      #base.extend(MethodDecorators)
      #Eigenclass.lift(base)
    end
  end
end
