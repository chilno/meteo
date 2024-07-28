module ForecastsHelper
  def day_of_week(date, current)
    current ? 'Current' : Time.zone.at(date).strftime('%A')
  end

  def date_format(date, current)
    Time.zone.at(date - 25_200).strftime(current ? '%H:%M:%S' : '%m-%d')
  end

  def formatted_temperature(temperature)
    temperature.presence.round
  end

  def next_days(days)
    days[1..]
  end
end
