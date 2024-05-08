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
        config.token = "123abc"
      end

      expect(described_class.configuration.token).to eq("123abc")
    end
  end
end
