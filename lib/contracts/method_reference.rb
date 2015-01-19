module Contracts
  class MethodReference

    attr_reader :name

    def initialize(name, method, singleton=false)
      @name = name
      @method = method
      @singleton = singleton
    end

    def method_position
      Support.method_position(@method)
    end

    def make_alias(this)
      _aliased_name = aliased_name
      original_name = name

      alias_target(this).class_eval do
        alias_method _aliased_name, original_name
      end
    end

    def send_to(this, *args, &blk)
      this.send(aliased_name, *args, &blk)
    end

    private

    def alias_target(this)
      @singleton ? this.singleton_class : this
    end

    def aliased_name
      @_original_name ||= construct_unique_name
    end

    def construct_unique_name
      :"__contracts_ruby_original_#{name}_#{Support.unique_id}"
    end

  end
end
