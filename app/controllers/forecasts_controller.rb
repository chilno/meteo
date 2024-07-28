# frozen_string_literal: true

# Forecasts Controller
class ForecastsController < ApplicationController
  ADDRESS_CACHE = 'geocode/'
  WEATHER_CACHE = 'weather/'

  def show
    @address_cache_exists = Rails.cache.exist? "#{ADDRESS_CACHE}#{address}"
    @geocode = fetch_geocode
    @weather_cache_exists = Rails.cache.exist? "#{WEATHER_CACHE}#{@geocode[:country_code]}/#{@geocode[:postal_code]}"
    @weather = fetch_weather(@geocode)
  rescue LocationService::LocationServiceError, WeatherService::WeatherServiceError => e
    flash.now[:alert] = e.message
  end

  private

  def address
    @address ||= params[:address].presence || '10503 N Tantau Ave, Cupertino, CA 95014'
  end

  def fetch_geocode
    Rails.cache.fetch("#{ADDRESS_CACHE}#{address}", expires_in: cache_time) do
      LocationService.call(address)
    end
  end

  def fetch_weather(geocode)
    # cache weather data by postal code if available
    if geocode[:postal_code].nil?
      WeatherService.call(geocode[:latitude], geocode[:longitude])
    else
      Rails.cache.fetch("#{WEATHER_CACHE}#{geocode[:country_code]}/#{geocode[:postal_code]}", expires_in: cache_time) do
        WeatherService.call(geocode[:latitude], geocode[:longitude])
      end
    end
  end

  def cache_time(time = 30.minutes)
    time
  end
end
