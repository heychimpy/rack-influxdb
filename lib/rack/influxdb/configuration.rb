# frozen_string_literal: true

module Rack
  class InfluxDB
    # The main configuration for the gem.
    class Configuration
      attr_accessor :name, :tags, :url, :token, :options, :write_options,
                    :fields, :handle_error

      def initialize
        set_defaults
      end

      private

      def set_defaults
        @name = 'http_requests'
        @tags = {}
        @url = ''
        @token = ''
        @fields = ->(_env, _response) { {} }
        @handle_error = ->(_err) { nil }
        @options = default_options
        @write_options = default_write_options
      end

      def default_options
        {
          org: '',
          bucket: '',
          precision: InfluxDB2::WritePrecision::MILLISECOND
        }
      end

      def default_write_options
        InfluxDB2::WriteOptions.new(
          write_type: InfluxDB2::WriteType::BATCHING,
          batch_size: 100
        )
      end
    end
  end
end
