# Gemfile
# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'brakeman', '~> 6.2'
  # rack-test pulls in rack/mock, which needs 'cgi/cookie'. The cgi library
  # was fully removed from Ruby's default gems as of 4.0 (only a minimal
  # cgi/escape subset ships now), so declare it explicitly.
  gem 'cgi'
  gem 'reek', '~> 6.1'
  gem 'rubocop', '~> 1.0'
  gem 'simplecov', '~> 0.22'
  gem 'simplecov-cobertura', '~> 3.1'
end
