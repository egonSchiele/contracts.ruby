module Contracts
  module Eigenclass

    def self.extended(eigenclass)
      return if eigenclass.respond_to?(:owner_class=)

      class << eigenclass
        attr_accessor :owner_class
      end
    end

  end
end
