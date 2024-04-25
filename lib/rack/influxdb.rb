require 'influxdb-client'
require 'rack/influxdb/configuration'

module Rack
  class InfluxDB
    class << self
      attr_reader :configuration

      def configuration
        @configuration ||= Rack::InfluxDB::Configuration.new
      end

      def configure
        yield(configuration)
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env).tap { |response| write_request(env, response) }
    end

    private

    def write_request(env, response)
      # The presence or absence of a token implicitly determines whether it
      # should be executed at all. This allows this gem to run in each
      # environment.
      return unless config.token

      InfluxDB2::Client.use(config.url, config.token, **config.options) do |c|
        write_api = c.create_write_api
        write_api.write(data: point(env, response))
      end
    end

    def point(env, response)
      {
        name: config.name,
        tags: config.tags,
        fields: {
          status: response[0],
          bytes_out: bytes_out(response),
          remote_addr: env['REMOTE_ADDR'],
          user_agent: env['HTTP_USER_AGENT'],
          method: env['REQUEST_METHOD'],
          path: env['REQUEST_PATH']
        }.compact
      }
    end

    def config
      Rack::InfluxDB.configuration
    end

    def bytes_out(response)
      response[2].reduce(0) { |sum, str| sum += (str&.bytesize || 0) }
    end
  end
end
