require "contracts/builtin_contracts"
require "contracts/decorators"
require "contracts/errors"
require "contracts/formatters"
require "contracts/invariants"
require "contracts/method_reference"
require "contracts/support"
require "contracts/engine"
require "contracts/method_handler"
require "contracts/contracts_generator"
require "contracts/configure"

if Contracts.load_on_require
  Contracts.load
end
