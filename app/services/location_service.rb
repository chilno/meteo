# frozen_string_literal: true

# Location Service takes an address and returns the latitude and longitude
class LocationService
  include HTTParty

  base_uri 'https://nominatim.openstreetmap.org'

  class LocationServiceError < StandardError; end

  def self.call(address)
    new(address).call
  end

  def initialize(address)
    @address = address
  end

  def call
    response_body = fetch_geocode
    validate_response(response_body)
    format_response(response_body.first)
  end

  private

  def fetch_geocode
    response = self.class.get('/search', query_params)
    raise LocationServiceError, "Error fetching geocode: #{response['error']}" unless response.success?

    response.parsed_response
  end

  def query_params
    {
      headers: { 'User-Agent' => 'Httparty' },
      query: { q: @address, format: 'json', addressdetails: 1, limit: 1 }
    }
  end

  def validate_response(body)
    location = body.first
    validate_location_present(location)
    validate_coordinates_present(location)
    validate_country_code_present(location)
  end

  def validate_location_present(location)
    raise LocationServiceError, 'Location not found' unless location
  end

  def validate_coordinates_present(location)
    raise LocationServiceError, 'Missing coordinates' unless location.values_at('lat', 'lon', 'address').all?
  end

  def validate_country_code_present(location)
    raise LocationServiceError, 'Missing country code' unless location.dig('address', 'country_code')
  end

  def format_response(location)
    {
      latitude: location['lat'].to_f,
      longitude: location['lon'].to_f,
      country_code: location.dig('address', 'country_code'),
      postal_code: location.dig('address', 'postcode'),
      full_address: location['display_name']
    }
  end
end
