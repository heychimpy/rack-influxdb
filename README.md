# rack-influxdb

[![Continuous Integration](https://github.com/heychimpy/rack-influxdb/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/heychimpy/rack-influxdb/actions/workflows/test.yml)

This gem provides a Rack middleware for [InfluxDB](https://github.com/influxdata/influxdb).

- [Installation](#installation)
- [Usage](#usage)
  - [Configuration](#configuration)
  - [Basic usage](#basic-usage)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-influxdb'
```

Then run:

```ruby
bundle
```

## Usage

### Configuration
The Rack::InfluxDB gem can be easily configured

```ruby
Rack::InfluxDB.configure do |config|
  # The name of your measurement
  config.name = "http_requests"

  # Custom tags
  config.tags = { app: "my-awesome-api", env: "production" }

  # The URL of your InfluxDB instance
  config.url = "https://test.influxdb.example.com"

  # The API token provided by InfluxDB
  config.token = "topsecret"

  # A lambda that returns a hash containing the fields to write.
  # E.g. to just track the HTTP status:
  config.fields = lambda { |env, response| return { status: response[0] } }

  # Handle errors individually
  config.handle_errors = lambda { |err| report_error(err) }

  # Options like Org, Bucket and Precision
  config.options = {
    org: 'my-org',
    bucket: 'my-bucket',
    precision: InfluxDB2::WritePrecision::MILLISECOND
  }

  # Write options - it's highly recommended to use batching and not
  # synchronous writing.
  config.write_options = {
    write_type: InfluxDB2::WriteType::BATCHING,
    batch_size: 1_000
  }
end
```

### Basic usage
All you have to do is to include the middleware in your Rack stack. 

In Rails:

```ruby
# config/application.rb

class Application < Rails::Application
  ...
  config.middleware.use Rack::InfluxDB
end
```
