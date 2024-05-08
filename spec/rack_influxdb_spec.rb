require_relative './spec_helper'

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
      it 'does not call InfluxDB2::Client.use' do
        expect(InfluxDB2::Client).not_to receive(:use)

        get '/'
      end
    end

    context 'when config token is given' do
      before do
        allow(InfluxDB2::Client).to receive(:use)

        described_class.configure do |config|
          config.token = "token"
          config.url = "example.com"
        end
      end

      let(:conf) { described_class.configuration }

      it 'calls InfluxDB2::Client.use with right params' do
        get '/'

        expect(InfluxDB2::Client)
          .to have_received(:use)
          .with(conf.url, conf.token, conf.options)
      end
    end

    context 'when an error occurs' do
      before do
        allow(InfluxDB2::Client).to receive(:use).and_raise('Could not write')

        described_class.configure do |config|
          config.token = "token"
          config.url = "example.com"
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
        before do
          described_class.configure do |config|
            config.handle_error = ->(e) { raise e }
          end
        end

        it 'it gets handled (re-raised)' do
          expect { get '/' }.to raise_error('Could not write')
        end
      end
    end
  end
end
