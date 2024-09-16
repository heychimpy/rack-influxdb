# frozen_string_literal: true

require 'influxdb-client'
require 'rack/influxdb/configuration'

module Rack
  # The InfluxDB rack middleware class.
  class InfluxDB
    class << self
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
      return if config.token.to_s.empty?

      # Run the write logic inside a thread so we don't slow down
      # main request.
      Thread.new do
        write(env, response)
      rescue StandardError => e
        config.handle_error.call(e)
      end
    rescue StandardError => e
      # Let the app decide what needs to be done when an error occurs.
      config.handle_error.call(e)
    end

    def point(env, response)
      {
        name: config.name,
        tags: config.tags,
        fields: config.fields.call(env, response)
      }
    end

    def write(env, response)
      client do |c|
        write_api = c.create_write_api(write_options: config.write_options)
        write_api.write(data: point(env, response))
      end
    end

    def client
      @client ||= InfluxDB2::Client.use \
        config.url, config.token, **config.options
    end

    def config
      Rack::InfluxDB.configuration
    end
  end
end
