# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/out_record_demux_picker'

class RecordDemuxPickerOutputTest < Test::Unit::TestCase
  BASE_CONF = %(
    tag test
    demux_keys a
  )

  TEST_TIME = '2025-01-01T00:00:00.000Z'
  TEST_FLUENT_TIME = Fluent::EventTime.parse(TEST_TIME)

  setup do
    Fluent::Test.setup

    @nested_data = load_json_fixture('nested_data.json')
  end

  sub_test_case 'configuration' do
    test 'default configuration' do
      driver = create_driver
      output = driver.instance

      assert_equal ({}), output.shared_keys
      assert_equal false, output.demux_key_normalize
      assert_equal 'key', output.demux_key_normalize_key_name
      assert_equal 'value', output.demux_key_normalize_value_name
      assert_equal nil, output.timestamp_key
      assert_equal :iso, output.timestamp_format
    end

    test 'tag should not be empty' do
      conf = %(
        demux_keys a
      )
      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end

    test 'demux_keys should not be empty' do
      conf = %(
        tag test
      )
      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end
  end

  sub_test_case 'demux nested record' do
    test 'it should demux record' do
      conf = %(
        tag test
        demux_keys $.state.state1:target1 , $.state.state2:target2 ,\
                   $.state.state3:target3 , $.state.state4:target4 , $.state.state5:target5
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, {
          'target1' => 'value_state1'
        }],
        ['test', TEST_FLUENT_TIME, {
          'target2' => 'value_state2'
        }],
        ['test', TEST_FLUENT_TIME, {
          'target3' => 'value_state3'
        }],
        ['test', TEST_FLUENT_TIME, {
          'target4' => 'value_state4'
        }],
        ['test', TEST_FLUENT_TIME, {
          'target5' => 'value_state5'
        }]
      ]

      assert_equal 5, events.size
      assert_equal expected_events, events
    end

    test 'it should demux record with target' do
      conf = %(
        tag test
        demux_keys $.state.state1 , $.state.state2 , $.state.state3 , $.state.state4 ,\
                   $.state.state5
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, {
          'state1' => 'value_state1'
        }],
        ['test', TEST_FLUENT_TIME, {
          'state2' => 'value_state2'
        }],
        ['test', TEST_FLUENT_TIME, {
          'state3' => 'value_state3'
        }],
        ['test', TEST_FLUENT_TIME, {
          'state4' => 'value_state4'
        }],
        ['test', TEST_FLUENT_TIME, {
          'state5' => 'value_state5'
        }]
      ]

      assert_equal 5, events.size
      assert_equal expected_events, events
    end

    test 'it should demux record with shared data' do
      conf = %(
        tag test
        demux_keys $.state.state1:state1 , $.state.state2:state2 , $.state.state3:state3
        shared_keys $.common.metadata1:metadata1 , $.common.metadata2:metadata2 ,\
                    $.common.metadata3:metadata3
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, { 'metadata1' => 'value_metadata1',
                                     'metadata2' => 'value_metadata2',
                                     'metadata3' => 'value_metadata3',
                                     'state1' => 'value_state1' }],
        ['test', TEST_FLUENT_TIME, { 'metadata1' => 'value_metadata1',
                                     'metadata2' => 'value_metadata2',
                                     'metadata3' => 'value_metadata3',
                                     'state2' => 'value_state2' }],
        ['test', TEST_FLUENT_TIME, { 'metadata1' => 'value_metadata1',
                                     'metadata2' => 'value_metadata2',
                                     'metadata3' => 'value_metadata3',
                                     'state3' => 'value_state3' }]
      ]

      assert_equal 3, events.size
      assert_equal expected_events, events
    end
  end

  sub_test_case 'normalize demux key' do
    test 'it can normalize demux key' do
      conf = %(
        tag test
        demux_keys $.state.state4:state4 , $.state.state5:state5
        shared_keys $.common.metadata4:metadata4 , $.common.metadata5:metadata5
        demux_key_normalize true
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, { 'metadata4' => 'value_metadata4',
                                     'metadata5' => 'value_metadata5',
                                     'key' => 'state4',
                                     'value' => 'value_state4' }],
        ['test', TEST_FLUENT_TIME, { 'metadata4' => 'value_metadata4',
                                     'metadata5' => 'value_metadata5',
                                     'key' => 'state5',
                                     'value' => 'value_state5' }]
      ]

      assert_equal 2, events.size
      assert_equal expected_events, events
    end

    test 'normalize demux key / value can be defined' do
      conf = %(
        tag test
        demux_keys $.state.state4:state4 , $.state.state5:state5
        shared_keys $.common.metadata4:metadata4 , $.common.metadata5:metadata5
        demux_key_normalize true
        demux_key_normalize_key_name name
        demux_key_normalize_value_name data
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, { 'metadata4' => 'value_metadata4',
                                     'metadata5' => 'value_metadata5',
                                     'name' => 'state4',
                                     'data' => 'value_state4' }],
        ['test', TEST_FLUENT_TIME, { 'metadata4' => 'value_metadata4',
                                     'metadata5' => 'value_metadata5',
                                     'name' => 'state5',
                                     'data' => 'value_state5' }]
      ]

      assert_equal 2, events.size
      assert_equal expected_events, events
    end
  end

  sub_test_case 'timestamp key' do
    test 'it does not inject timestamp when no timestamp_key' do
      conf = %(
        tag test
        demux_keys $.state.state1:state1 , $.state.state3:state3
        shared_keys $.common.metadata2:metadata2
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, {
          'metadata2' => 'value_metadata2',

          'state1' => 'value_state1'
        }],
        ['test', TEST_FLUENT_TIME, {
          'metadata2' => 'value_metadata2',

          'state3' => 'value_state3'
        }]
      ]

      assert_equal 2, events.size
      assert_equal expected_events, events
    end

    test 'it can inject timestamp in iso format' do
      conf = %(
        tag test
        demux_keys $.state.state1:state1 , $.state.state3:state3
        shared_keys $.common.metadata2:metadata2
        timestamp_key timestamp
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, { 'timestamp' => TEST_TIME,
                                     'metadata2' => 'value_metadata2',

                                     'state1' => 'value_state1' }],
        ['test', TEST_FLUENT_TIME, { 'timestamp' => TEST_TIME,
                                     'metadata2' => 'value_metadata2',

                                     'state3' => 'value_state3' }]
      ]

      assert_equal 2, events.size
      assert_equal expected_events, events
    end

    test 'it can inject timestamp in epochmillis format' do
      conf = %(
        tag test
        demux_keys $.state.state1:state1 , $.state.state3:state3
        shared_keys $.common.metadata2:metadata2
        timestamp_key timestamp
        timestamp_format epochmillis
      )

      driver = create_driver(conf)
      driver.run do
        driver.feed('test_input_tag', TEST_FLUENT_TIME, @nested_data)
      end
      events = driver.events

      expected_events = [
        ['test', TEST_FLUENT_TIME, { 'timestamp' => 1_735_689_600_000,
                                     'metadata2' => 'value_metadata2',

                                     'state1' => 'value_state1' }],
        ['test', TEST_FLUENT_TIME, { 'timestamp' => 1_735_689_600_000,
                                     'metadata2' => 'value_metadata2',

                                     'state3' => 'value_state3' }]
      ]

      assert_equal 2, events.size
      assert_equal expected_events, events
    end
  end

  private

  def create_driver(conf = BASE_CONF)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RecordDemuxPickerOutput).configure(conf)
  end
end
