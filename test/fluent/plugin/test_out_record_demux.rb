# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/out_record_demux'

class RecordDemuxOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case 'configuration' do
    test 'default configuration' do
      driver = create_driver
      output = driver.instance

      assert output
      # to be completed ...
    end

    test 'tag should not be empty' do
      assert_raise(Fluent::ConfigError) do
        create_driver('')
      end
    end
  end

  private

  BASE_CONF = %(
    tag test
  )

  def create_driver(conf = BASE_CONF)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RecordDemuxOutput).configure(conf)
  end
end
