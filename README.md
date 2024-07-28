# Meteo

Meteo is a Ruby on Rails application that provides real-time and 3 day weather information for any given address. The application uses [OpenWeatherMap API](https://openweathermap.org/api) to fetch weather data and [Nominatim API](https://nominatim.openstreetmap.org/) for geocoding addresses.

## Features

- Converts addresses to geographical coordinates.
- Fetches weather data based on geographical coordinates.
- Caches location and weather data to increase speed and reduce API calls
- Displays weather information including temperature, min temperature, max temperature and forecast.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- Ruby version 3.3.0

## Installation

Follow these steps to install **Meteo**:

1. Clone the repository:

   ```bash
   git clone https://github.com/chilno/meteo.git
   cd meteo
   ```

   ## Docker (Includes Memcached)


   1. Run docker-compose:

      ```bash
      docker-compose up -d
      ```
   2. Navigate to `127.0.0.1:3000`

   ## Development (Uses memory store for caching)

   1. Install dependencies:

      ```bash
      bundle install
      ```
   2. Start server

      ```bash
      rails s
      ```
   3. Navigate  to `127.0.0.1:3000`

## Testing

Run `bundle exec rspec`
