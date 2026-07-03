# Gemfile
# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'brakeman', '~> 6.2'
  # dry-configurable (a transitive dependency via reek -> dry-schema)
  # requires Ruby >= 3.3 as of 1.4.0, which breaks the Ruby 3.2 CI leg.
  # Pin below that until Ruby 3.2 support is dropped.
  gem 'dry-configurable', '< 1.4'
  gem 'reek', '~> 6.1'
  gem 'rubocop', '~> 1.0'
  gem 'simplecov', '~> 0.22'
  gem 'simplecov-cobertura', '~> 2.1'
end
