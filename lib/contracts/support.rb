module Contracts
  module Support

    def self.method_position(method)
      if RUBY_VERSION =~ /^1\.8/
        if method.respond_to?(:__file__)
          method.__file__ + ":" + method.__line__.to_s
        else
          method.inspect
        end
      else
        file, line = method.source_location
        file + ":" + line.to_s
      end
    end

    def self.method_name(method)
      method.is_a?(Proc) ? "Proc" : method.name
    end

  end
end
