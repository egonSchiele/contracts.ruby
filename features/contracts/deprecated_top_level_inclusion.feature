Feature: Deprecated top level inclusion

  `include Contracts` in top level or in `Object` is deprecated. If
  `Contracts` gets included in one of these, it will issue a
  deprecation warning. In the release version this will raise error.

  On the other hand `Contracts` still can be included in repls, such
  as `irb` and `pry`. These will not issue a deprecation warning and
  will not raise error in release version.

  Background:

    Given a file named "normal_usage.rb" with:
      """ruby
      require 'contracts'

      class Example
        include Contracts
      end
      """

    Given a file named "top_level_inclusion.rb" with:
      """ruby
      require 'contracts'

      include Contracts
      """

    Given a file named "object_inclusion.rb" with:
      """ruby
      require 'contracts'

      class Object
        include Contracts
      end
      """

  Scenario: Intended Contracts inclusion in user class
    When I run `bundle exec ruby normal_usage.rb`
    Then the stderr should not contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """
    

  Scenario: Top level inclusion outside of repl
    When I run `bundle exec ruby top_level_inclusion.rb`
    Then the stderr should contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """
     And the stderr should contain:
      """
      top_level_inclusion.rb:3
      """

  Scenario: Object inclusion outside of repl
    When I run `bundle exec ruby object_inclusion.rb`
    Then the stderr should contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """
     And the stderr should contain:
      """
      object_inclusion.rb:4
      """
 
  Scenario: Top level inclusion from irb
    When I run `bundle exec irb` interactively
     And I type "require 'contracts'"
     And I type "include Contracts"
     And I type "exit"
    Then the stderr should not contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """

  Scenario: Top level inclusion from pry
    When I run `bundle exec pry` interactively
     And I type "require 'contracts'"
     And I type "include Contracts"
     And I type "exit"
    Then the stderr should not contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """

  Scenario: Object inclusion from irb
    When I run `bundle exec irb` interactively
     And I type "require 'contracts'"
     And I type "class Object; include Contracts; end"
     And I type "exit"
    Then the stderr should not contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """

  Scenario: Object inclusion from pry
    When I run `bundle exec pry` interactively
     And I type "require 'contracts'"
     And I type "class Object; include Contracts; end"
     And I type "exit"
    Then the stderr should not contain:
      """
      [WARN] Top level inclusion is deprecated, backtrace:
      """
