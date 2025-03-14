# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/out_record_demux'

class RecordDemuxOutputTest < Test::Unit::TestCase
  BASE_CONF = %(
    tag test
    demux_keys a
  )

  TEST_TIME = Fluent::EventTime.parse('2025-01-01T00:00:00.000Z')

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
        create_driver('demux_keys a')
      end
    end

    test 'demux_keys and shared_keys cannot be empty' do
      fluentd_conf = %(
        tag test
      )
      assert_raise(Fluent::ConfigError) do
        create_driver(fluentd_conf)
      end
    end
  end

  sub_test_case 'demux through demux_keys' do
    test 'it should compute shared_keys' do
      fluentd_conf  = %(
        tag test
        demux_keys a, b
      )

      driver = create_driver(fluentd_conf)
      input_event = { 'a' => 1, 'b' => 2, 'c' => 3 }
      driver.run do
        driver.feed('input_tag', TEST_TIME, input_event)
      end

      events = driver.events
      events_records = events.map { |event| event[2] }
      assert_equal [{ 'a' => 1, 'c' => 3 }, { 'b' => 2, 'c' => 3 }], events_records
    end

    test 'it should compute shared_keys when remove_keys is defined' do
      fluentd_conf  = %(
        tag test
        demux_keys a, b
        remove_keys d
      )

      driver = create_driver(fluentd_conf)
      input_event = { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 }
      driver.run do
        driver.feed('input_tag', TEST_TIME, input_event)
      end

      events = driver.events
      events_records = events.map { |event| event[2] }
      assert_equal [{ 'a' => 1, 'c' => 3 }, { 'b' => 2, 'c' => 3 }], events_records
    end
  end

  sub_test_case 'demux through shared_keys' do
    test 'it should compute demux_keys' do
      fluentd_conf  = %(
        tag test
        shared_keys c
      )

      driver = create_driver(fluentd_conf)
      input_event = { 'a' => 1, 'b' => 2, 'c' => 3 }
      driver.run do
        driver.feed('input_tag', TEST_TIME, input_event)
      end

      events = driver.events
      events_records = events.map { |event| event[2] }
      assert_equal [{ 'a' => 1, 'c' => 3 }, { 'b' => 2, 'c' => 3 }], events_records
    end

    test 'it should compute demux_keys when remove_keys is defined' do
      fluentd_conf  = %(
        tag test
        shared_keys c
        remove_keys d
      )

      driver = create_driver(fluentd_conf)
      input_event = { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 }
      driver.run do
        driver.feed('input_tag', TEST_TIME, input_event)
      end

      events = driver.events
      events_records = events.map { |event| event[2] }
      assert_equal [{ 'a' => 1, 'c' => 3 }, { 'b' => 2, 'c' => 3 }], events_records
    end
  end

  sub_test_case 'demux through demux_keys and shared_keys' do
    test 'it should compute demux_keys' do
      fluentd_conf  = %(
        tag test
        demux_keys a, b
        shared_keys c
      )

      driver = create_driver(fluentd_conf)
      input_event = { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 }
      driver.run do
        driver.feed('input_tag', TEST_TIME, input_event)
      end

      events = driver.events
      events_records = events.map { |event| event[2] }
      assert_equal [{ 'a' => 1, 'c' => 3 }, { 'b' => 2, 'c' => 3 }], events_records
    end

    test 'it should compute demux_keys when remove_keys is defined' do
      fluentd_conf  = %(
        tag test
        demux_keys a, b
        shared_keys
        remove_keys d
      )

      driver = create_driver(fluentd_conf)
      input_event = { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 }
      driver.run do
        driver.feed('input_tag', TEST_TIME, input_event)
      end

      events = driver.events
      events_records = events.map { |event| event[2] }
      assert_equal [{ 'a' => 1 }, { 'b' => 2 }], events_records
    end
  end

  private

  def create_driver(conf = BASE_CONF)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RecordDemuxOutput).configure(conf)
  end
end
