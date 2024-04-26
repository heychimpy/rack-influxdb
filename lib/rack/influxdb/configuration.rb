module Rack
  class InfluxDB
    class Configuration
      attr_accessor :name, :tags, :url, :token, :options, :write_options

      def initialize
        set_defaults
      end

      private

      def set_defaults
        @name = 'http_requests'
        @tags = {}
        @url = ''
        @token = ''
        @options = {
          org: '',
          bucket: '',
          precision: InfluxDB2::WritePrecision::MILLISECOND
        }
        @write_options = {
          write_type: InfluxDB2::WriteType::BATCHING,
          batch_size: 100,
        }
      end
    end
  end
end
