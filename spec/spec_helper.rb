# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
SimpleCov.start

require 'bundler/setup'

require 'rack'
require 'rack/test'
require 'rack/influxdb'

# The dummy app which includes the Rack::InfluxDB middleware.
def app
  Rack::Builder.new do
    # Include the InfluxDB middleware.
    use Rack::InfluxDB

    run ->(_env) { [200, {}, ['Hello World']] }
  end.to_app
end

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |conf|
    conf.syntax = :expect
  end
end
