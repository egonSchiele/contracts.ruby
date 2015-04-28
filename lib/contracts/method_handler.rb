module Contracts
  class MethodHandler
    def initialize(method_name, is_class_method)
      @method_name = method_name
      @is_class_method = is_class_method
    end

    # TODO: refactor it to private methods
    def handle(target)
      name = method_name

      return unless Engine.applied?(target)
      engine = Engine.fetch_from(target)

      decorators = engine.all_decorators
      return if decorators.empty?

      if is_class_method
        method_reference = SingletonMethodReference.new(name, target.method(name))
        method_type = :class_methods
      else
        method_reference = MethodReference.new(name, target.instance_method(name))
        method_type = :instance_methods
      end

      unless decorators.size == 1
        fail %{
Oops, it looks like method '#{name}' has multiple contracts:
#{decorators.map { |x| x[1][0].inspect }.join("\n")}

Did you accidentally put more than one contract on a single function, like so?

Contract String => String
Contract Num => String
def foo x
end

If you did NOT, then you have probably discovered a bug in this library.
Please file it along with the relevant code at:
https://github.com/egonSchiele/contracts.ruby/issues
        }
      end

      engine.decorated_methods[method_type][name] ||= []

      pattern_matching = false
      decorators.each do |klass, args|
        # a reference to the method gets passed into the contract here. This is good because
        # we are going to redefine this method with a new name below...so this reference is
        # now the *only* reference to the old method that exists.
        # We assume here that the decorator (klass) responds to .new
        decorator = klass.new(target, method_reference, *args)
        new_args_contract = decorator.args_contracts
        matched = engine.decorated_methods[method_type][name].select do |contract|
          contract.args_contracts == new_args_contract
        end
        unless matched.empty?
          fail ContractError.new(%{
It looks like you are trying to use pattern-matching, but
multiple definitions for function '#{name}' have the same
contract for input parameters:

#{(matched + [decorator]).map(&:to_s).join("\n")}

Each definition needs to have a different contract for the parameters.
          }, {})
        end
        engine.add_method_decorator(method_type, name, decorator)
        pattern_matching ||= decorator.pattern_match?
      end

      if engine.decorated_methods[method_type][name].any? { |x| x.method != method_reference }
        engine.decorated_methods[method_type][name].each(&:pattern_match!)

        pattern_matching = true
      end

      method_reference.make_alias(target)

      return if ENV["NO_CONTRACTS"] && !pattern_matching

      # in place of this method, we are going to define our own method. This method
      # just calls the decorator passing in all args that were to be passed into the method.
      # The decorator in turn has a reference to the actual method, so it can call it
      # on its own, after doing it's decorating of course.

      # Very important: THe line `current = #{target}` in the start is crucial.
      # Not having it means that any method that used contracts could NOT use `super`
      # (see this issue for example: https://github.com/egonSchiele/contracts.ruby/issues/27).
      # Here's why: Suppose you have this code:
      #
      #     class Foo
      #       Contract String
      #       def to_s
      #         "Foo"
      #       end
      #     end
      #
      #     class Bar < Foo
      #       Contract String
      #       def to_s
      #         super + "Bar"
      #       end
      #     end
      #
      #     b = Bar.new
      #     p b.to_s
      #
      #     `to_s` in Bar calls `super`. So you expect this to call `Foo`'s to_s. However,
      #     we have overwritten the function (that's what this next defn is). So it gets a
      #     reference to the function to call by looking at `decorated_methods`.
      #
      #     Now, this line used to read something like:
      #
      #       current = target#{is_class_method ? "" : ".class"}
      #
      #     In that case, `target` would always be `Bar`, regardless of whether you were calling
      #     Foo's to_s or Bar's to_s. So you would keep getting Bar's decorated_methods, which
      #     means you would always call Bar's to_s...infinite recursion! Instead, you want to
      #     call Foo's version of decorated_methods. So the line needs to be `current = #{target}`.

      current = target
      current_engine = engine
      method_reference.make_definition(target) do |*args, &blk|
        ancestors = current.ancestors
        ancestors.shift # first one is just the class itself
        while current && current_engine && !current_engine.has_decorated_methods?
          current = ancestors.shift
          current_engine = Engine.fetch_from(current)
        end

        unless current_engine && current_engine.has_decorated_methods?
          fail "Couldn't find decorator for method " + self.class.name + ":#{name}.\nDoes this method look correct to you? If you are using contracts from rspec, rspec wraps classes in it's own class.\nLook at the specs for contracts.ruby as an example of how to write contracts in this case."
        end
        methods = current_engine.decorated_methods[method_type][name]

        # this adds support for overloading methods. Here we go through each method and call it with the arguments.
        # If we get a ContractError, we move to the next function. Otherwise we return the result.
        # If we run out of functions, we raise the last ContractError.
        success = false
        i = 0
        result = nil
        expected_error = methods[0].failure_exception
        until success
          method = methods[i]
          i += 1
          begin
            success = true
            result = method.call_with(self, *args, &blk)
          rescue expected_error => error
            success = false
            unless methods[i]
              begin
                ::Contract.failure_callback(error.data, false)
              rescue expected_error => final_error
                raise final_error.to_contract_error
              end
            end
          end
        end
        result
      end
    end

    private
    attr_reader :method_name, :is_class_method
  end
end
