require 'decorators'
#require 'rubygems'
#require 'ruby-debug'

class Contract < Decorator
  attr_accessor :typeclasses, :klass, :method
  def initialize(klass, method, *typeclasses)
    @klass, @method, @typeclasses = klass, method, typeclasses
  end

  def self.error(arg, typeclass)
    "type error: expected #{typeclass}, got #{arg} (#{arg.class})"
  end

  def self.validate_hash(arg, typeclass)
    arg.keys.map { |k|
      validate(arg[k], typeclass[k])
    }.compact
  end

  def self.validate_proc(arg, typeclass)
    error(arg, typeclass) unless typeclass[arg]
  end

  def self.validate_class(arg, typeclass)
    valid = if typeclass.respond_to? :typecheck
              typeclass.typecheck arg
            else
              typeclass == arg.class
            end
    error(arg, typeclass) unless valid
  end

  def self.validate_all(args, typeclasses)
    args.zip(typeclasses).each { |arg, typeclass|
      res = validate(arg, typeclass)
      raise res if res
    }
  end

  def self.validate(arg, typeclass)
    case typeclass
    when Class
      results = validate_class arg, typeclass
    when Proc
      results = validate_proc arg, typeclass
    when Array
      # TODO account for these errors too
      error(arg, typeclass) unless arg.is_a?(Array)
      results = validate_all(arg, typeclass)
    when Hash
      error(arg, typeclass) unless arg.is_a?(Hash)
      results = validate_hash(arg, typeclass)
    else
      if typeclass.respond_to? :typecheck
        results = []
        results << error(arg, typeclass) unless typeclass.typecheck(arg)
      else
        results = []
        results << error(arg, typeclass) unless arg == typeclass
      end
    end
    return nil if results == [] || results == ""
    if results.is_a? Array
      results.join("\n")
    else
      results
    end
  end

  def call(this, *args)
    Contract.validate_all(args, @typeclasses)
    result = @method.bind(this).call(*args)
    Contract.validate_all([result], [@typeclasses[-1]])
    result
  end
end

class Class
  include MethodDecorators
end

class Odd
  def self.typecheck val
    val % 2 == 1
  end
end

class Even
  def self.typecheck val
    val % 2 == 0
  end
end

class Pos
  def self.typecheck val
    val > 0
  end
end

class Neg
  def self.typecheck val
    val < 0
  end
end

class Any
  def self.typecheck val
    true
  end
end

class None
  def self.typecheck val
    false
  end
end

class Or
  def initialize(*vals)
    @vals = vals
  end

  def typecheck(val)
    @vals.any? do |typeclass|
      !Contract.validate(val, typeclass)
    end
  end

  def to_s
    @vals[0, @vals.size-1].join(", ") + " or " + @vals[-1].to_s
  end
end

class And
  def initialize(*vals)
    @vals = vals
  end

  def typecheck(val)
    @vals.all? do |typeclass|
      !Contract.validate(val, typeclass)
    end
  end

  def to_s
    @vals[0, @vals.size-1].join(", ") + " and " + @vals[-1].to_s
  end
end

class RespondsTo
  def initialize(*meths)
    @meths = meths
  end

  def typecheck(val)
    @meths.all? do |meth|
      val.respond_to? meth
    end
  end

  def to_s
    "a value that responds to #{@meths.inspect}"
  end
end

class From
  def initialize(cls)
    @cls = cls
  end

  def typecheck(val)
    val.class < @cls
  end

  def to_s
    "a subclass of #{@cls.inspect}"
  end
end

class In
  def initialize(*vals)
    @vals = vals
  end

  def typecheck(val)
    @vals.include?(val)
  end

  def to_s
    "a value in #{@vals.inspect}"
  end
end

class Not
  def initialize(*vals)
    @vals = vals
  end

  def typecheck(val)
    @vals.all? do |typeclass|
      Contract.validate(val, typeclass)
    end
  end

  def to_s
    "a value that is none of #{@vals.inspect}"
  end
end
