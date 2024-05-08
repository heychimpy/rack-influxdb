require 'bundler/setup'

require 'rack'
require 'rack/test'
require 'rack/influxdb'

def app
  Rack::Builder.new do
    # Include the InfluxDB middleware.
    use Rack::InfluxDB

    run lambda { |_env| [200, {}, ['Hello World']] }
  end.to_app
end

RSpec.configure do |config|
  config.expect_with :rspec do |conf|
    conf.syntax = :expect
  end
end
