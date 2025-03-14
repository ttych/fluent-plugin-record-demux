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
    class RecordDemuxOutput < Fluent::Plugin::Output
      NAME = 'record_demux'
      Fluent::Plugin.register_output(NAME, self)

      helpers :event_emitter, :timer

      desc 'tag to emit events on'
      config_param :tag, :string, default: nil

      desc 'list of keys to demux'
      config_param :demux_keys, :array, value_type: :string, default: nil
      desc 'list of keys to be shared in all new records'
      config_param :shared_keys, :array, value_type: :string, default: []
      desc 'list of keys to be removed'
      config_param :remove_keys, :array, value_type: :string, default: []

      desc 'event key format uniformize'
      config_param :event_key_uniformize, :bool, default: false

      desc 'event key prefix'
      config_param :event_key_prefix, :string, default: ''
      desc 'shared key prefix'
      config_param :shared_key_prefix, :string, default: ''

      desc 'timestamp key'
      config_param :timestamp_key, :string, default: nil
      desc 'timestamp format'
      config_param :timestamp_format, :enum, list: %i[iso epochmillis], default: :iso

      def configure(conf)
        super

        return unless @tag.nil?

        raise Fluent::ConfigError, "#{NAME}: `tag` must be specified"
      end

      def multi_workers_ready?
        true
      end

      def process(_events_tag, events)
        demux_events = Fluent::EventStream.new
        events.each do |time, record|
          record_keys = record.keys - remove_keys
          record_shared_keys = record_keys.intersection(shared_keys)
          record.slice(*record_shared_keys)
          record_demux_keys = record_keys - record_shared_keys if !demux_keys || demux_keys.empty?

          record_demux_keys.each do |key|
            next unless record.key?(key)

            new_record = format(time, key, record[key], shared)
            demux_events.add(time, new_record)
          end
        end
        router.emit_stream(tag, demux_events)
      end

      private

      def format(time, name, value, shared = {})
        record = {}

        shared.each do |shared_key, shared_value|
          record["#{shared_key_prefix}#{shared_key}"] = shared_value
        end

        record[@timestamp_key] = format_timestamp(time) if @timestamp_key

        if event_key_uniformize
          record["#{event_key_prefix}name"] = name
          record["#{event_key_prefix}value"] = value
        else
          record[name] = value
        end

        record
      end

      def format_timestamp(time)
        return (time.to_time.utc.to_f * 1000).to_i if @timestamp_format == :epochmillis

        time.to_time.utc.iso8601(3)
      end
    end
  end
end
