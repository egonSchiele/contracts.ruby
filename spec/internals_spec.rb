module UserModule
  module FakeAutoload
    def const_missing(name)
      fail if name.to_s != "Support"
      UserModule.const_set("Support", Class.new)
    end
  end

  extend FakeAutoload

  class UserClass
    extend FakeAutoload
    include Contracts

    def a_support_klass
      Support
    end
  end

  RSpec.describe "Contracts internals" do
    example "are not available to users" do
      expect(UserClass.new.a_support_klass).to eq(::UserModule::Support)
    end
  end
end
