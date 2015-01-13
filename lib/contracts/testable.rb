module Contracts
  class Testable
    # Given an array-of-arrays of arguments,
    # gives you the product of those arguments so that
    # each possible combination is tried.
    # Example: <tt>[[1, 2], [3, 4]]</tt> would give you:
    #
    #   [[1, 3], [1, 4], [2, 3], [2, 4]]
    def self.product(arrays)
      arrays.inject { |acc, x|
        acc.product(x)
      }.flatten(arrays.size - 2)
    end
    
    # Given a contract, tells if you it's testable
    def self.testable?(contract)
      if contract.respond_to?(:testable?)
        contract.testable?
      else
        contract.respond_to?(:new) && contract.method(:new).arity == 0
      end
    end

    # Given a contract, returns the test data associated with that contract
    def self.test_data(contract)
      if contract.respond_to?(:testable?)
        contract.test_data
      else
        contract.new
      end
    end

    # TODO Should work on whatever class it was invoked on, no?
    def self.check_all
      o = Object.new
      Object.decorated_methods.each do |name, contracts|
        check(o.method(name))
      end
    end

    def self.check(meth)
      contracts = meth.owner.decorated_methods[meth.name.to_sym][0].contracts
      arg_contracts = contracts[0, contracts.size - 1]
      return_val = contracts[-1]
      checkable = arg_contracts.all? do |arg_contract|
        Testable.testable?(arg_contract)
      end

      if checkable
        print "Checking #{meth.name}..."
        _test_data = arg_contracts.map do |arg_contract|
          data = Testable.test_data(arg_contract)
          data.is_a?(Array) ? data : [data]
        end
        test_data = Testable.product _test_data
        test_data.each do |args|
          if args.is_a? Hash
            # because *hash destroys the hash
            res = meth.call(args)
          else
            res = meth.call(*args)
          end
          Contract.valid?(res, return_val)
        end
        puts "#{test_data.size} tests run."
      end
    end    
  end
end
