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

# Polls `block` until it returns truthy, or raises after `timeout` seconds.
# Used to synchronize with work happening on the middleware's background
# worker thread without coupling tests to sleep durations.
def wait_for(timeout: 2)
  deadline = Time.now + timeout

  until yield
    raise "wait_for timed out after #{timeout}s" if Time.now > deadline

    sleep 0.01
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |conf|
    conf.syntax = :expect
  end
end
