# spec/services/location_service_spec.rb

require 'rails_helper'

RSpec.describe LocationService, type: :service do
  describe '.call' do
    let(:address) { '10503 N Tantau Ave, Cupertino, CA 95014' }
    let(:service) { described_class.new(address) }

    before do
      stub_request(:get, 'https://nominatim.openstreetmap.org/search')
        .with(query: { q: address, format: 'json', addressdetails: 1, limit: 1 },
              headers: { 'User-Agent' => 'Httparty' })
        .to_return(status:, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when the response is successful and valid' do
      let(:status) { 200 }
      let(:response_body) do
        [
          {
            'lat' => '37.33182',
            'lon' => '-122.03118',
            'display_name' => '10503 N Tantau Ave, Cupertino, CA 95014, United States',
            'address' => {
              'country_code' => 'US',
              'postcode' => '95014'
            }
          }
        ]
      end

      it 'returns the correct geocode information' do
        result = LocationService.call(address)
        expect(result).to eq({
                               latitude: 37.33182,
                               longitude: -122.03118,
                               full_address: '10503 N Tantau Ave, Cupertino, CA 95014, United States',
                               country_code: 'US',
                               postal_code: '95014'
                             })
      end
    end

    context 'when the response is successful but invalid' do
      let(:status) { 200 }
      let(:response_body) { [{}] }

      it 'raises a LocationServiceError' do
        expect do
          LocationService.call(address)
        end.to raise_error(LocationService::LocationServiceError, 'Missing coordinates')
      end
    end

    context 'when the response has no location' do
      let(:status) { 200 }
      let(:response_body) { [] }

      it 'raises a LocationServiceError' do
        expect do
          LocationService.call(address)
        end.to raise_error(LocationService::LocationServiceError, 'Location not found')
      end
    end

    context 'when the response is unsuccessful' do
      let(:status) { 500 }
      let(:response_body) { { error: 'Server Error' } }

      it 'raises a LocationServiceError with the response message' do
        expect do
          LocationService.call(address)
        end.to raise_error(LocationService::LocationServiceError,
                           'Error fetching geocode: Server Error')
      end
    end
  end
end
