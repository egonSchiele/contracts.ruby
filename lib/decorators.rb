module MethodDecorators
  @@decorated_method = nil
  @@decorated_methods = {}
  def self.decorated_method
    @@decorated_method
  end

  def self.decorated_methods
    @@decorated_methods
  end

  def self.decorated_methods_set(name, value)
    @@decorated_methods[name] = value
  end

  def self.extended(klass)
    klass.class_eval do
      @@__decorated_methods ||= {}
      def self.__decorated_methods
        @@__decorated_methods
      end

      def self.__decorated_methods_set(k, v)
        @@__decorated_methods[k] = v
      end
    end
  end

  # first, when you write a contract, the decorate method gets called which
  # sets the @decorators variable. Then when the next method after the contract
  # is defined, method_added is called and we look at the @decorators variable
  # to find the decorator for that method. This is how we associate decorators
  # with methods.
  def method_added(name)
    common_method_added name, false
    super
  end

  # For Ruby 1.9
  def singleton_method_added name
    common_method_added name, true
    super
  end

  def common_method_added name, is_class_method
    return unless @decorators

    decorators = @decorators.dup
    @decorators = nil

    decorators.each do |klass, args|
      # a reference to the method gets passed into the contract here. This is good because
      # we are going to redefine this method with a new name below...so this reference is
      # now the *only* reference to the old method that exists.
      if klass.respond_to? :new
        if is_class_method
          decorator = klass.new(self, method(name), *args)
        else
          decorator = klass.new(self, instance_method(name), *args)
        end
      else
        decorator = klass
      end
      #__decorated_methods_set(name, instance_method(name)) #decorator
      __decorated_methods_set(name, decorator) #decorator
      #MethodDecorators.decorated_methods_set(self, name => instance_method(name))
      #@@decorated_method = instance_method(name)
    end

    # in place of this method, we are going to define our own method. This method
    # just calls the decorator passing in all args that were to be passed into the method.
    # The decorator in turn has a reference to the actual method, so it can call it
    # on its own, after doing it's decorating of course.
    foo = <<-ruby_eval
      def #{is_class_method ? "self." : ""}#{name}(*args, &blk)
        this = self#{is_class_method ? "" : ".class"}
        return this.__decorated_methods[#{name.inspect}].call_with(self, *args, &blk)
        #return this.__decorated_methods[#{name.inspect}].bind(self).call(*args, &blk)
        #return MethodDecorators.decorated_methods[this][#{name.inspect}].bind(self).call(*args, &blk)
        #return MethodDecorators.decorated_method.bind(self).call(*args, &blk)
        #return MethodDecorators.decorated_method.call_with(self, *args, &blk)        
        #this.decorated_methods[#{name.inspect}].call_with(self, *args, &blk)
      end    
    ruby_eval
    class_eval foo, __FILE__, __LINE__ + 1
  end    

  def decorate(klass, *args)
    @decorators ||= []
    @decorators << [klass, args]
  end
end

class Decorator
  # an attr_accessor for a class variable:
  class << self; attr_accessor :decorators; end

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
