module Rack
  class InfluxDB
    class Configuration
      attr_accessor :name, :tags, :url, :token, :options, :write_options,
                    :fields

      def initialize
        set_defaults
      end

      private

      def set_defaults
        @name = 'http_requests'
        @tags = {}
        @url = ''
        @token = ''
        @fields = lambda { |env, response| return {} }
        @options = {
          org: '',
          bucket: '',
          precision: InfluxDB2::WritePrecision::MILLISECOND
        }

        @write_options = InfluxDB2::WriteOptions.new(
          write_type: InfluxDB2::WriteType::BATCHING,
          batch_size: 100,
        )
      end
    end
  end
end
