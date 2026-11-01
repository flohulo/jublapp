import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_client.dart';

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
    required this.precipitation,
  });

  final DateTime time;
  final double temperature;
  final double humidity;
  final int weatherCode;
  final double windSpeed;
  final double precipitation;
}

class HourlyWeather {
  const HourlyWeather(this.time, this.temperature, this.weatherCode);
  final DateTime time;
  final double temperature;
  final int weatherCode;
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.max,
    required this.min,
    required this.rain,
  });
  final DateTime date;
  final int weatherCode;
  final double max;
  final double min;
  final double rain;
}

class WeatherData {
  const WeatherData(this.current, this.hourly, this.daily);
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  /// Die nächsten 24 Stunden ab der aktuellen Stunde.
  List<HourlyWeather> next24Hours() {
    final start = hourly.indexWhere(
      (h) => !h.time.isBefore(
        DateTime(
          current.time.year,
          current.time.month,
          current.time.day,
          current.time.hour,
        ),
      ),
    );
    if (start < 0) return const [];
    return hourly.skip(start).take(24).toList();
  }
}

/// Wetterdaten von Open-Meteo (Wald/ZH, Zeitzone Europe/Zurich).
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static Uri get _url => Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '${AppConfig.weatherLat}',
    'longitude': '${AppConfig.weatherLon}',
    'current':
        'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation',
    'hourly': 'temperature_2m,weather_code',
    'daily': 'weather_code,temperature_2m_max,temperature_2m_min,rain_sum',
    'timezone': 'Europe/Zurich',
  });

  Future<WeatherData> fetch() async {
    final http.Response response;
    try {
      response = await _client.get(_url).timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
    if (response.statusCode != 200) {
      throw ApiException(
        'Weather request failed',
        statusCode: response.statusCode,
      );
    }
    return parse(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  static WeatherData parse(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    double d(Object? v) => (v as num?)?.toDouble() ?? 0;

    final hourlyTimes = (hourly['time'] as List).cast<String>();
    final hourlyTemps = hourly['temperature_2m'] as List;
    final hourlyCodes = hourly['weather_code'] as List;
    final dailyTimes = (daily['time'] as List).cast<String>();

    return WeatherData(
      CurrentWeather(
        time: DateTime.parse(current['time'] as String),
        temperature: d(current['temperature_2m']),
        humidity: d(current['relative_humidity_2m']),
        weatherCode: (current['weather_code'] as num).toInt(),
        windSpeed: d(current['wind_speed_10m']),
        precipitation: d(current['precipitation']),
      ),
      [
        for (var i = 0; i < hourlyTimes.length; i++)
          HourlyWeather(
            DateTime.parse(hourlyTimes[i]),
            d(hourlyTemps[i]),
            (hourlyCodes[i] as num? ?? 0).toInt(),
          ),
      ],
      [
        for (var i = 0; i < dailyTimes.length; i++)
          DailyWeather(
            date: DateTime.parse(dailyTimes[i]),
            weatherCode: ((daily['weather_code'] as List)[i] as num? ?? 0)
                .toInt(),
            max: d((daily['temperature_2m_max'] as List)[i]),
            min: d((daily['temperature_2m_min'] as List)[i]),
            rain: d((daily['rain_sum'] as List)[i]),
          ),
      ],
    );
  }
}
