require 'yard'

class ContractHandler < YARD::Handlers::Ruby::AttributeHandler
  handles method_call(:Contract)

  def process
    puts "Handling a contract!"
    name = statement.parameters.first.jump(:tstring_content, :ident).source
    object = YARD::CodeObjects::MethodObject.new(namespace, name, :instance) do |o|
      o.visibility = "public"
      o.source     = statement.source + " wut source"
      o.signature  = "Hi from adit"
      o.explicit   = true
      o.docstring  = "Whaaaaaat docstring!"
    end
    register(object)
  end
end

# class ContractHandler < YARD::Handlers::Ruby::Legacy::AttributeHandler
#   handles /\AContract\b/

#   def process
#     puts "Handling a contract!"
#   end
# end
