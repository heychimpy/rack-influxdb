require 'bundler/setup'

require 'minitest/autorun'
require 'rack/test'
require 'rack/influxdb'

class Minitest::Spec
  include Rack::Test::Methods

  def app
    ->(env) { [200, {}, ['Hello World']] }
  end
end
