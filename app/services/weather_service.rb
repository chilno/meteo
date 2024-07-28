# frozen_string_literal: true

# Weather Service takes latitude and longitude and returns weather data
class WeatherService
  include HTTParty

  class WeatherServiceError < StandardError; end

  base_uri 'api.openweathermap.org'

  def self.call(latitude, longitude, forecast_days = 4)
    new(latitude, longitude, forecast_days).call
  end

  def initialize(latitude, longitude, forecast_days)
    @latitude = latitude
    @longitude = longitude
    @forecast_days = forecast_days
  end

  def call
    response_body = fetch_current_and_future_weather_data
    validate_response(response_body)
    format_weather_data(response_body)
  rescue WeatherServiceError => e
    handle_error(e)
  end

  private

  # We use threads here to fetch the current and future weather data in parallel
  # Other solutions would be better for production usage, but this is fine for now
  def fetch_current_and_future_weather_data
    current_weather_data = Thread.new do
      fetch_current_weather_data
    end

    future_weather_data = Thread.new do
      fetch_future_weather_data
    end

    current, future = [current_weather_data, future_weather_data].map(&:value)
    current['list'] = future['list']
    current
  end

  def fetch_current_weather_data
    fetch_weather_data('/data/2.5/weather', {
                         query: { lat: @latitude, lon: @longitude, appid: api_key, units: 'imperial' }
                       })
  end

  def fetch_future_weather_data
    fetch_weather_data('/data/2.5/forecast/daily', {
                         query: { lat: @latitude, lon: @longitude, appid: api_key, units: 'imperial',
                                  cnt: @forecast_days }
                       })
  end

  def fetch_weather_data(url, query_options = {})
    response = self.class.get(url, query_options)
    raise WeatherServiceError, "Error fetching weather data: #{response.message}" unless response.success?

    response.parsed_response
  end

  def api_key
    Rails.application.credentials.dig(:open_weather_api,
                                      :api_key) || raise(WeatherServiceError, 'Weather API key is missing')
  end

  def validate_response(body)
    raise WeatherServiceError, 'OpenWeather response body failed' unless body
  end

  def format_weather_data(body)
    {
      temperature: body.dig('main', 'temp'),
      temperature_min: body.dig('main', 'temp_min'),
      temperature_max: body.dig('main', 'temp_max'),
      description: body.dig('weather', 0, 'main'),
      date: body['dt'],
      next_days: body['list'].map(&format_next_day)
    }
  end

  def format_next_day
    lambda do |day|
      {
        date: day['dt'],
        temperature: day.dig('temp', 'day'),
        description: day.dig('weather', 0, 'main'),
        temperature_min: day.dig('temp', 'min'),
        temperature_max: day.dig('temp', 'max')
      }
    end
  end

  def handle_error(error)
    raise error
  end
end
