module Rack
  class InfluxDB
    class Configuration
      attr_accessor :name, :tags, :url, :token, :options

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
      end
    end
  end
end
