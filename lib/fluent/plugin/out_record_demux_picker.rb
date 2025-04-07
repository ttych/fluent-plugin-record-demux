# frozen_string_literal: true

#
# Copyright 2024- Thomas Tych
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/output'

module Fluent
  module Plugin
    class RecordDemuxPickerOutput < Fluent::Plugin::Output
      NAME = 'record_demux_picker'
      Fluent::Plugin.register_output(NAME, self)

      DEMUX_KEY_NORMALIZE_KEY_NAME = 'key'
      DEMUX_KEY_NORMALIZE_VALUE_NAME = 'value'

      helpers :event_emitter, :timer, :record_accessor

      desc 'tag to emit events on'
      config_param :tag, :string

      desc 'list of keys to demux'
      config_param :demux_keys, :hash
      desc 'list of keys to be shared in all new events'
      config_param :shared_keys, :hash, default: {}

      desc 'normalize demux key format'
      config_param :demux_key_normalize, :bool, default: false
      desc 'demux key normalize key name'
      config_param :demux_key_normalize_key_name, :string, default: DEMUX_KEY_NORMALIZE_KEY_NAME
      desc 'demux key normalize value name'
      config_param :demux_key_normalize_value_name, :string, default: DEMUX_KEY_NORMALIZE_VALUE_NAME

      desc 'timestamp key'
      config_param :timestamp_key, :string, default: nil
      desc 'timestamp format'
      config_param :timestamp_format, :enum, list: %i[iso epochmillis], default: :iso

      def configure(conf)
        super

        @demux_keys_mappers = @demux_keys.map { |key, target| KeyMapper.new(key, target) }
        @shared_keys_mappers = @shared_keys.map { |key, target| KeyMapper.new(key, target) }

        true
      end

      def multi_workers_ready?
        true
      end

      def process(_events_tag, events)
        demux_events = MultiEventStream.new
        events.each do |time, event|
          new_events = process_event(time, event)
          new_events.each { |new_event| demux_events.add(time, new_event) }
        end
        router.emit_stream(tag, demux_events)
      end

      def process_event(time, event)
        shared_event = extract_shared_event(event)

        @demux_keys_mappers.map do |mapper|
          value = mapper.accessor.call(event)
          shared_event
            .merge(format_demux_key(mapper.target, value))
            .merge(format_time(time))
        rescue StandardError => e
          log.warn "#{NAME} : failure while processing event : #{e}"
          nil
        end.compact
      end

      private

      def extract_shared_event(event)
        @shared_keys_mappers.each_with_object({}) do |mapper, new_event|
          value = mapper.accessor.call(event)
          new_event[mapper.target] = value
        rescue StandardError => e
          log.warn "#{NAME} : failure while processing event : #{e}"
          next
        end
      end

      def format_demux_key(key, value)
        if demux_key_normalize
          { demux_key_normalize_key_name => key,
            demux_key_normalize_value_name => value }
        else
          { key => value }
        end
      end

      def format_time(time)
        return {} unless timestamp_key

        { timestamp_key => format_timestamp(time) }
      end

      def format_timestamp(time)
        return (time.to_time.utc.to_f * 1000).to_i if @timestamp_format == :epochmillis

        time.to_time.utc.iso8601(3)
      end

      class KeyMapper
        include Fluent::PluginHelper::RecordAccessor

        attr_reader :key, :accessor, :target, :setter

        def initialize(key, target)
          @key = key
          @accessor = record_accessor_create(key)
          @target = target
          @target ||= @accessor.keys.is_a?(Array) ? @accessor.keys.last : @accessor.keys
        end
      end
    end
  end
end
