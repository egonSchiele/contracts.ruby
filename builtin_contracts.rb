module Contracts
  class Num
    def self.valid? val
      val.is_a? Numeric
    end
  end

  class Pos
    def self.valid? val
      val > 0
    end
  end

  class Neg
    def self.valid? val
      val < 0
    end
  end

  class Any
    def self.valid? val
      true
    end
  end

  class None
    def self.valid? val
      false
    end
  end

  class CallableClass
    def self.[](*vals)
      self.new(*vals)
    end
  end

  class Or < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      @vals.any? do |contract|
        res, _ = Contract.valid?(val, contract)
        res
      end
    end

    def to_s
      @vals[0, @vals.size-1].join(", ") + " or " + @vals[-1].to_s
    end
  end

  class Xor < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      results = @vals.map do |contract|
        res, _ = Contract.valid?(val, contract)
        res
      end
      results.count(true) == 1
    end

    def to_s
      @vals[0, @vals.size-1].join(", ") + " xor " + @vals[-1].to_s
    end
  end  

  class And < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      @vals.all? do |contract|
        res, _ = Contract.valid?(val, contract)
        res
      end
    end

    def to_s
      @vals[0, @vals.size-1].join(", ") + " and " + @vals[-1].to_s
    end
  end

  class RespondsTo < CallableClass
    def initialize(*meths)
      @meths = meths
    end

    def valid?(val)
      @meths.all? do |meth|
        val.respond_to? meth
      end
    end

    def to_s
      "a value that responds to #{@meths.inspect}"
    end
  end

  class Send < CallableClass
    def initialize(*meths)
      @meths = meths
    end

    def valid?(val)
      @meths.all? do |meth|
        val.send(meth)
      end
    end

    def to_s
      "a value that returns true for all of #{@meths.inspect}"
    end  
  end

  class IsA < CallableClass
    def initialize(cls)
      @cls = cls
    end

    def valid?(val)
      val.is_a? @cls
    end

    def to_s
      "a #{@cls.inspect}"
    end
  end

  class Not < CallableClass
    def initialize(*vals)
      @vals = vals
    end

    def valid?(val)
      @vals.all? do |contract|
        res, _ = Contract.valid?(val, contract)
        !res
      end
    end

    def to_s
      "a value that is none of #{@vals.inspect}"
    end
  end

  class ArrayOf < CallableClass
    def initialize(contract)
      @contract = contract
    end

    def valid?(vals)
      vals.all? do |val|
        res, _ = Contract.valid?(val, @contract)
        res
      end
    end

    def to_s
      "an array of #{@contract}"
    end
  end
end
