# frozen_string_literal: true

# spec/simplecov_helper.rb
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/' # Exclude test files from coverage
end
