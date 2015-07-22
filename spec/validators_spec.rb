require "spec_helper"

module Contracts
  RSpec.describe "range contract validator" do
    subject(:o) { GenericExample.new }

    it "passes when value is in range" do
      expect do
        o.method_with_range_contract(5)
      end.not_to raise_error(ContractError)
    end

    it "fails when value is not in range" do
      expect do
        o.method_with_range_contract(300)
      end.to raise_error(ContractError, /Expected: 1\.\.10/)
    end

    it "fails when value is incorrect" do
      expect do
        o.method_with_range_contract("hello world")
      end.to raise_error(ContractError, /Expected: 1\.\.10.*Actual: "hello world"/m)
    end
  end
end
