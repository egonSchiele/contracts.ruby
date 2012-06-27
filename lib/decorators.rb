module MethodDecorators
  def self.extended(klass)
    class << klass
      attr_accessor :decorated_methods
    end
  end

  # first, when you write a contract, the decorate method gets called which
  # sets the @decorators variable. Then when the next method after the contract
  # is defined, method_added is called and we look at the @decorators variable
  # to find the decorator for that method. This is how we associate decorators
  # with methods.
  def method_added(name)
    return unless @decorators

    decorators = @decorators.dup
    @decorators = nil
    @decorated_methods ||= Hash.new {|h,k| h[k] = []}

    # attr_accessor on the class variable decorated_methods
    class << self; attr_accessor :decorated_methods; end

    decorators.each do |klass, args|
      # a reference to the method gets passed into the contract here. This is good because
      # we are going to redefine this method with a new name below...so this reference is
      # now the *only* reference to the old method that exists.
      decorator = klass.respond_to?(:new) ? klass.new(self, instance_method(name), *args) : klass
      @decorated_methods[name] << decorator
    end

    # in place of this method, we are going to define our own method. This method
    # just calls the decorator passing in all args that were to be passed into the method.
    # The decorator in turn has a reference to the actual method, so it can call it
    # on its own, after doing it's decorating of course.
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
  # an attr_accessor for a class variable:
  class << self; attr_accessor :decorators; end

=begin
  def self.decorator_name(name)
    Decorator.decorators ||= {}
    Decorator.decorators[name] = self
  end
=end

  def self.inherited(klass)
    name = klass.name.gsub(/^./) {|m| m.downcase}

    return if name =~ /^[^A-Za-z_]/ || name =~ /[^0-9A-Za-z_]/

    # the file and line parameters set the text for error messages
    # make a new method that is the name of your decorator.
    # that method accepts random args and a block.
    # inside, `decorate` is called with those params.
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
