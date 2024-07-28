# spec/controllers/forecasts_controller_spec.rb

require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
  before do
    Rails.cache.clear
  end

  describe 'GET #show' do
    context 'with valid address' do
      let(:valid_address) { '10503 N Tantau Ave, Cupertino, CA 95014' }
      let(:geocode_data) do
        { latitude: 37.33182, longitude: -122.03118, country_code: 'US', postal_code: '95014',
          full_address: '10503 N Tantau Ave, Cupertino, CA 95014' }
      end
      let(:weather_data) { 'weather_info' }
      let(:address_cache_key) { "#{ForecastsController::ADDRESS_CACHE}#{valid_address}" }
      let(:weather_cache_key) do
        "#{ForecastsController::WEATHER_CACHE}#{geocode_data[:country_code]}/#{geocode_data[:postal_code]}"
      end

      before do
        allow(LocationService).to receive(:call).and_return(geocode_data)
        allow(WeatherService).to receive(:call).and_return(weather_data)
        Rails.cache.write(address_cache_key, geocode_data)
        Rails.cache.write(weather_cache_key, weather_data)
        get :show, params: { address: valid_address }
      end

      it 'fetches geocode and weather information' do
        expect(assigns(:geocode)).to eq(geocode_data)
        expect(assigns(:weather)).to eq(weather_data)
      end

      it 'checks existence of address cache' do
        expect(assigns(:address_cache_exists)).to be_truthy
      end

      it 'checks existence of weather cache' do
        expect(assigns(:weather_cache_exists)).to be_truthy
      end

      it 'renders the show template' do
        expect(response).to render_template(:show)
      end

      it 'does not set flash alert' do
        expect(flash.now[:alert]).to be_nil
      end
    end

    context 'with invalid address' do
      let(:invalid_address) { 'Invalid Address' }

      before do
        allow(LocationService).to receive(:call).and_raise(LocationService::LocationServiceError.new('Invalid address'))
        get :show, params: { address: invalid_address }
      end

      it 'sets flash alert for invalid address' do
        expect(flash.now[:alert]).to eq('Invalid address')
      end

      it 'renders the show template' do
        expect(response).to render_template(:show)
      end
    end
  end
end
