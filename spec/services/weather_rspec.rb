# frozen_string_literal: true

# spec/services/weather_service_spec.rb

require 'rails_helper'
require 'webmock/rspec'

# Define constants for URLs
WEATHER_URL = 'https://api.openweathermap.org/data/2.5/weather'
FORECAST_URL = 'https://api.openweathermap.org/data/2.5/forecast/daily'

RSpec.describe WeatherService, type: :service do
  let(:latitude) { 37.33182 }
  let(:longitude) { -122.03118 }
  let(:forecast_days) { 4 }
  let(:api_key) { 'test_api_key' }
  let(:service) { described_class.new(latitude, longitude, forecast_days) }

  before do
    allow(Rails.application.credentials.dig(:open_weather_api, :api_key)).to receive(:api_key).and_return(api_key)
  end

  shared_examples 'successful response' do |current_weather_body, future_weather_body, expected_result|
    before do
      stub_request(:get, WEATHER_URL)
        .with(query: { lat: latitude, lon: longitude, appid: api_key, units: 'imperial' })
        .to_return(status: 200, body: current_weather_body.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, FORECAST_URL)
        .with(query: { lat: latitude, lon: longitude, appid: api_key, units: 'imperial', cnt: forecast_days })
        .to_return(status: 200, body: future_weather_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the correct weather data' do
      result = WeatherService.call(latitude, longitude, forecast_days)
      expect(result).to eq(expected_result)
    end
  end

  context 'when the response is successful and valid' do
    let(:current_weather_body) do
      {
        'main' => { 'temp' => 72.0, 'temp_min' => 60.0, 'temp_max' => 80.0 },
        'weather' => [{ 'main' => 'Clear' }],
        'dt' => 1_678_000_000
      }
    end
    let(:future_weather_body) do
      { 'list' => [
        { 'dt' => 1_678_000_000, 'temp' => { 'day' => 72.0, 'min' => 60.0, 'max' => 80.0 },
          'weather' => [{ 'main' => 'Clear' }] }
      ] }
    end
    let(:expected_result) do
      {
        temperature: 72.0,
        temperature_min: 60.0,
        temperature_max: 80.0,
        description: 'Clear',
        date: 1_678_000_000,
        next_days: [
          {
            date: 1_678_000_000,
            temperature: 72.0,
            description: 'Clear',
            temperature_min: 60.0,
            temperature_max: 80.0
          }
        ]
      }
    end

    include_examples 'successful response', current_weather_body, future_weather_body, expected_result
  end

  context 'when the API key is missing' do
    before do
      allow(Rails.application.credentials.dig(:open_weather_api, :api_key)).to receive(:api_key).and_return(nil)
    end

    it 'raises a WeatherServiceError' do
      expect { WeatherService.call(latitude, longitude, forecast_days) }
        .to raise_error(WeatherService::WeatherServiceError, 'API key is missing')
    end
  end

  context 'when the API request fails' do
    before do
      stub_request(:get, WEATHER_URL)
        .with(query: { lat: latitude, lon: longitude, appid: api_key, units: 'imperial' })
        .to_return(status: 500, body: { error: 'Server Error' }.to_json)

      stub_request(:get, FORECAST_URL)
        .with(query: { lat: latitude, lon: longitude, appid: api_key, units: 'imperial', cnt: forecast_days })
        .to_return(status: 500, body: { error: 'Server Error' }.to_json)
    end

    it 'raises a WeatherServiceError' do
      expect { WeatherService.call(latitude, longitude, forecast_days) }
        .to raise_error(WeatherService::WeatherServiceError, 'Error fetching weather data: Server Error')
    end
  end

  context 'when the response is invalid' do
    let(:invalid_weather_body) { { 'invalid_key' => 'value' } }

    before do
      stub_request(:get, WEATHER_URL)
        .with(query: { lat: latitude, lon: longitude, appid: api_key, units: 'imperial' })
        .to_return(status: 200, body: invalid_weather_body.to_json)

      stub_request(:get, FORECAST_URL)
        .with(query: { lat: latitude, lon: longitude, appid: api_key, units: 'imperial', cnt: forecast_days })
        .to_return(status: 200, body: invalid_weather_body.to_json)
    end

    it 'raises a WeatherServiceError' do
      expect { WeatherService.call(latitude, longitude, forecast_days) }
        .to raise_error(WeatherService::WeatherServiceError, 'OpenWeather response body failed')
    end
  end
end
