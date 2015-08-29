Feature: Simple example

  Contracts.ruby allows specification of contracts on per-method basis, where
  method arguments and return value will be validated upon method call.

  Example:

  ```ruby
  Contract C::Num, C::Num => C::Num
  def add(a, b)
    a + b
  end
  ```

  Here `Contract arg_contracts... => return_contract` defines list of argument
  contracts `args_contracts...` as `C::Num, C::Num` (i.e.: both arguments
  should be numbers) and return value contract `return_contract` as `C::Num`
  (i.e.: return value should be a number too).

  `Contract arg_contracts... => return_contract` affects next defined instance,
  class or singleton method, meaning that all of these work:

  - [Instance method](#instance-method),

  - [Class method](#class-method),

  - [Singleton method](#singleton-method).

  Scenario: Instance method
    Given a file named "instance_method.rb" with:
    """ruby
    require "contracts"
    C = Contracts

    class Example
      include Contracts::Core

      Contract C::Num, C::Num => C::Num
      def add(a, b)
        a + b
      end
    end

    puts Example.new.add(2, 2)
    """
    When I run `ruby instance_method.rb`
    Then the output should contain:
    """
    4
    """

  Scenario: Instance method contract violation
    Given a file named "instance_method_violation.rb" with:
    """ruby
    require "contracts"
    C = Contracts

    class Example
      include Contracts::Core

      Contract C::Num, C::Num => C::Num
      def add(a, b)
        a + b
      end
    end

    puts Example.new.add(2, "foo")
    """
    When I run `ruby instance_method_violation.rb`
    Then the output should contain:
    """
    : Contract violation for argument 2 of 2: (ParamContractError)
            Expected: Num,
            Actual: "foo"
            Value guarded in: Example::add
            With Contract: Num, Num => Num
            At: instance_method_violation.rb:8
    """

  Scenario: Class method
    Given a file named "class_method.rb" with:
    """ruby
    require "contracts"
    C = Contracts

    class Example
      include Contracts::Core

      Contract C::Num, C::Num => C::Num
      def self.add(a, b)
        a + b
      end
    end

    puts Example.add(2, 2)
    """
    When I run `ruby class_method.rb`
    Then the output should contain:
    """
    4
    """

  Scenario: Class method contract violation
    Given a file named "class_method_violation.rb" with:
    """ruby
    require "contracts"
    C = Contracts

    class Example
      include Contracts::Core

      Contract C::Num, C::Num => C::Num
      def self.add(a, b)
        a + b
      end
    end

    puts Example.add(:foo, 2)
    """
    When I run `ruby class_method_violation.rb`
    Then the output should contain:
    """
    : Contract violation for argument 1 of 2: (ParamContractError)
            Expected: Num,
            Actual: :foo
            Value guarded in: Example::add
            With Contract: Num, Num => Num
            At: class_method_violation.rb:8
    """

  Scenario: Singleton method
    Given a file named "singleton_method.rb" with:
    """ruby
    require "contracts"
    C = Contracts

    class Example
      include Contracts::Core

      class << self
        Contract C::Num, C::Num => C::Num
        def add(a, b)
          a + b
        end
      end
    end

    puts Example.add(2, 2)
    """
    When I run `ruby singleton_method.rb`
    Then the output should contain:
    """
    4
    """

  Scenario: Singleton method return value contract violation
    Given a file named "singleton_method_violation.rb" with:
    """ruby
    require "contracts"
    C = Contracts

    class Example
      include Contracts::Core

      class << self
        Contract C::Num, C::Num => C::Num
        def add(a, b)
          # notice here non-number is returned
          nil
        end
      end
    end

    puts Example.add(2, 2)
    """
    When I run `ruby singleton_method_violation.rb`
    Then the output should contain:
    """
    : Contract violation for return value: (ReturnContractError)
            Expected: Num,
            Actual: nil
            Value guarded in: Example::add
            With Contract: Num, Num => Num
            At: singleton_method_violation.rb:9
    """
