module Contracts
  class ContractsGenerator
    def initialize
      # Class names are strings rather than constants, because some classes may not exist yet
      @validators = {
      'Proc' =>

      '# e.g. lambda {true}
      contract',

      'Array' =>

      '# e.g. [Num, String]
      # TODO: account for these errors too
      lambda do |arg|
        return false unless arg.is_a?(Array) && arg.length == contract.length
        arg.zip(contract).all? do |_arg, _contract|
          Contract.valid?(_arg, _contract)
        end
      end',

      'Hash' =>

      '# e.g. { :a => Num, :b => String }
      lambda do |arg|
        return false unless arg.is_a?(Hash)
        contract.keys.all? do |k|
          Contract.valid?(arg[k], contract[k])
        end
      end',

      'Contracts::Args' =>

      'lambda do |arg|
        Contract.valid?(arg, contract.contract)
      end',

      'Contracts::Func' =>

      'lambda do |arg|
        arg.is_a?(Method) || arg.is_a?(Proc)
      end',

      'Class' => 'lambda { |arg| arg.is_a?(contract) }'
      }
    end

    def set_validator(klass, func)
      @validators[klass] = func
    end

    def make_validator
    <<VALIDATOR
    # if is faster than case!
    klass = contract.class
    if klass == Proc
      #{@validators['Proc']}
    elsif klass == Array
      #{@validators['Array']}
    elsif klass == Hash
      #{@validators['Hash']}
    elsif klass == Contracts::Args
      #{@validators['Contracts::Args']}
    elsif klass == Contracts::Func
      #{@validators['Contracts::Func']}
    else
      # classes and everything else
      # e.g. Fixnum, Num
      if contract.respond_to? :valid?
        lambda { |arg| contract.valid?(arg) }
      elsif klass == Class
        #{@validators['Class']}
      else
        lambda { |arg| contract == arg }
      end
    end
VALIDATOR
    end
  end
end

