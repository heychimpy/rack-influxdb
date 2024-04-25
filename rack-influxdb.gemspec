# frozen_string_literal: true

require_relative 'lib/rack/influxdb/version'

Gem::Specification.new do |s|
  s.name = 'rack-influxdb'
  s.version = Rack::InfluxDB::VERSION
  s.license = 'MIT'

  s.authors = ["Henning Vogt"]
  s.description = "A rack middleware for logging requests to InfluxDB"
  s.email = "tech@heychimpy.com"

  s.files = Dir.glob("{bin,lib}/**/*") + %w(Rakefile README.md LICENSE)
  s.homepage = 'https://github.com/heychimpy/rack-influxdb'
  s.require_paths = ["lib"]
  s.summary = 'Log HTTP requests to InfluxDB'
  s.test_files = Dir.glob("spec/**/*")

  s.required_ruby_version = '>= 2.7'

  s.add_runtime_dependency 'rack', ">= 1.0", "< 4"
  s.add_runtime_dependency 'influxdb-client', ">= 3"

  s.add_development_dependency "bundler", ">= 1.17", "< 3.0"
end
