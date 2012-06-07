module MethodDecorators
  def self.extended(klass)
    class << klass
      attr_accessor :decorated_methods
    end
  end

  def method_missing(name, *args, &blk)
    if Object.const_defined?(name)
      const = Object.const_get(name)
    elsif Decorator.decorators.key?(name)
      const = Decorator.decorators[name]
    else
      return super
    end

    instance_eval <<-ruby_eval, __FILE__, __LINE__ + 1
      def #{name}(*args, &blk)
        decorate(#{const.name}, *args, &blk)
      end
    ruby_eval

    send(name, *args, &blk)
  end

  def method_added(name)
    return unless @decorators

    decorators = @decorators.dup
    @decorators = nil
    @decorated_methods ||= Hash.new {|h,k| h[k] = []}

    class << self; attr_accessor :decorated_methods; end

    decorators.each do |klass, args|
      decorator = klass.respond_to?(:new) ? klass.new(self, instance_method(name), *args) : klass
      @decorated_methods[name] << decorator
    end

    class_eval <<-ruby_eval, __FILE__, __LINE__ + 1
      def #{name}(*args, &blk)
        ret = nil
        self.class.decorated_methods[#{name.inspect}].each do |decorator|
          ret = decorator.call(self, *args, &blk)
        end
        ret
      end
    ruby_eval
  end

  def decorate(klass, *args)
    @decorators ||= []
    @decorators << [klass, args]
  end
end

class Decorator
  class << self
    attr_accessor :decorators
    def decorator_name(name)
      Decorator.decorators ||= {}
      Decorator.decorators[name] = self
    end
  end

  def self.inherited(klass)
    name = klass.name.gsub(/^./) {|m| m.downcase}

    return if name =~ /^[^A-Za-z_]/ || name =~ /[^0-9A-Za-z_]/

    MethodDecorators.module_eval <<-ruby_eval, __FILE__, __LINE__ + 1
      def #{klass}(*args, &blk)
        decorate(#{klass}, *args, &blk)
      end
    ruby_eval
  end

  def initialize(klass, method)
    @method = method
  end
end
