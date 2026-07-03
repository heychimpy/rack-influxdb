# frozen_string_literal: true

require_relative './spec_helper'
require 'weakref'

RSpec.describe Rack::InfluxDB do
  describe '.configuration' do
    it 'returns a new instance of Rack::InfluxDB::Configuration' do
      expect(described_class.configuration)
        .to be_a(Rack::InfluxDB::Configuration)
    end

    it 'memoizes the configuration' do
      conf = described_class.configuration

      expect(described_class.configuration).to eq(conf)
    end
  end

  describe '.configure' do
    it 'passes the configuration object to block' do
      conf = described_class.configuration

      expect { |block| described_class.configure(&block) }.to \
        yield_with_args(conf)
    end

    it 'saves new configuration values' do
      described_class.configure do |config|
        config.name = 'test_name'
      end

      expect(described_class.configuration.name).to eq('test_name')
    end
  end

  describe '#call' do
    it 'returns the initial status code' do
      get '/'

      expect(last_response.status).to eq(200)
    end

    it 'returns the initial body' do
      get '/'

      expect(last_response.body).to eq('Hello World')
    end

    context 'when no config token is given' do
      it 'does not call InfluxDB2::Client.new' do
        expect(InfluxDB2::Client).not_to receive(:new)

        get '/'
      end
    end

    context 'when config token is given' do
      let(:conf) { described_class.configuration }
      let(:influx_client) { double('InfluxDB2::Client') }
      let(:write_api) { double('InfluxDB2::WriteApi') }
      let(:write_calls) { [] }
      let(:write_mutex) { Mutex.new }

      before do
        allow(InfluxDB2::Client).to receive(:new).and_return(influx_client)
        allow(influx_client).to receive(:create_write_api).and_return(write_api)
        allow(write_api).to receive(:write) do |data:|
          write_mutex.synchronize { write_calls << data }
        end

        described_class.configure do |config|
          config.token = 'token'
          config.url = 'example.com'
        end
      end

      it 'calls InfluxDB2::Client.new with right params' do
        get '/'

        wait_for { write_calls.any? }

        expect(InfluxDB2::Client)
          .to have_received(:new)
          .with(conf.url, conf.token, conf.options)
      end

      it 'writes a data point to InfluxDB' do
        get '/'

        wait_for { write_calls.any? }

        expect(write_calls).to include(hash_including(name: conf.name))
      end

      it 'reuses the same write API instead of creating a new one per request' do
        middleware = described_class.new(->(_env) { [200, {}, ['Hello World']] })

        2.times { middleware.call(Rack::MockRequest.env_for('/')) }

        wait_for { write_calls.size >= 2 }

        expect(influx_client).to have_received(:create_write_api).once
      end

      it 'returns the response without waiting for the write to InfluxDB' do
        allow(write_api).to receive(:write) do |data:|
          sleep 0.3
          write_mutex.synchronize { write_calls << data }
        end

        middleware = described_class.new(->(_env) { [200, {}, ['Hello World']] })

        started_at = Time.now
        middleware.call(Rack::MockRequest.env_for('/'))
        elapsed = Time.now - started_at

        expect(elapsed).to be < 0.1
      end

      it 'creates exactly one worker thread no matter how many requests come in' do
        thread_count = 0
        thread_count_mutex = Mutex.new
        allow(Thread).to receive(:new).and_wrap_original do |original, *args, &block|
          thread_count_mutex.synchronize { thread_count += 1 }
          original.call(*args, &block)
        end

        middleware = described_class.new(->(_env) { [200, {}, ['Hello World']] })
        5.times { middleware.call(Rack::MockRequest.env_for('/')) }

        wait_for { write_calls.size >= 5 }

        expect(thread_count).to eq(1)
      end

      it 'does not retain the Rack env after the worker has processed it' do
        middleware = described_class.new(->(_env) { [200, {}, ['Hello World']] })

        # Building the env and the WeakRef inside a lambda, rather than in
        # local variables of the example itself, lets `env` fall out of
        # scope (and become eligible for GC) as soon as the lambda returns.
        weak_env = lambda do
          env = Rack::MockRequest.env_for('/')
          ref = WeakRef.new(env)
          middleware.call(env)
          ref
        end.call

        wait_for { write_calls.any? }
        GC.start

        # `weakref_alive?` is falsy (nil or false, depending on Ruby version)
        # once the referenced object has been collected.
        expect(weak_env.weakref_alive?).to be_falsey
      end
    end

    context 'when an error occurs' do
      before do
        allow(InfluxDB2::Client).to receive(:new).and_raise('Could not write')

        described_class.configure do |config|
          config.token = 'token'
          config.url = 'example.com'
        end
      end

      it 'the error is swallowed' do
        expect { get '/' }.not_to raise_error
      end

      it 'returns the initial status code' do
        get '/'

        expect(last_response.status).to eq(200)
      end

      context 'when custom error handling is applied' do
        it 'passes the raised error to the custom error handler' do
          handled_errors = []
          handled_mutex = Mutex.new

          described_class.configure do |config|
            config.handle_error = lambda do |e|
              handled_mutex.synchronize { handled_errors << e }
            end
          end

          get '/'

          wait_for { handled_errors.any? }

          expect(handled_errors.first.message).to eq('Could not write')
        end
      end
    end
  end
end
