class Module
  unless Object.respond_to?(:singleton_class)
    # Compatibility with ruby 1.8
    def singleton_class
      class << self; self; end
    end
  end

  unless Object.respond_to?(:singleton_class?)
    # Compatibility with ruby 1.8
    def singleton_class?
      self <= Object.singleton_class
    end
  end
end
