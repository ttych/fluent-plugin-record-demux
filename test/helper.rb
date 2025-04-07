# frozen_string_literal: true

require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter]
)

SimpleCov.start do
  add_filter '/test/'
end

require 'test-unit'
require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'

require 'mocha/test_unit'
require 'timecop'

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

require_relative 'fixtures/fixture'

Test::Unit::TestCase.include(Test::Fixture)
