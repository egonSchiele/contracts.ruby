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

  - [Instance method](#instance-method);
  - [Class method](#class-method);
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

    puts Example.new.functype(:add)
    puts Example.new.add(2, 2)
    """
    When I run `ruby instance_method.rb`
    Then the output should contain:
    """
    add :: Num, Num => Num
    4
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

    puts Example.functype(:add)
    puts Example.add(2, 2)
    """
    When I run `ruby class_method.rb`
    Then the output should contain:
    """
    add :: Num, Num => Num
    4
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

    puts Example.functype(:add)
    puts Example.add(2, 2)
    """
    When I run `ruby singleton_method.rb`
    Then the output should contain:
    """
    add :: Num, Num => Num
    4
    """
