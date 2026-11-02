import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../router.dart';
import '../services/error_reporter.dart';
import '../services/platform_services.dart';
import '../services/weather_service.dart';
import '../theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/menu_widgets.dart';
import '../widgets/page_scaffold.dart';

class _WmoInfo {
  const _WmoInfo(this.icon, this.color);
  final FaIconData icon;
  final Color color;
}

/// WMO-Wettercodes → Symbol/Farbe (Text kommt aus `wetter.code_<n>`).
const Map<int, _WmoInfo> _wmo = {
  0: _WmoInfo(FontAwesomeIcons.sun, Color(0xFFF1C40F)),
  1: _WmoInfo(FontAwesomeIcons.cloudSun, Color(0xFFF1C40F)),
  2: _WmoInfo(FontAwesomeIcons.cloudSun, Color(0xFF95A5A6)),
  3: _WmoInfo(FontAwesomeIcons.cloud, Color(0xFF7F8C8D)),
  45: _WmoInfo(FontAwesomeIcons.smog, Color(0xFF95A5A6)),
  48: _WmoInfo(FontAwesomeIcons.smog, Color(0xFFBDC3C7)),
  51: _WmoInfo(FontAwesomeIcons.cloudRain, Color(0xFF3498DB)),
  53: _WmoInfo(FontAwesomeIcons.cloudRain, Color(0xFF2980B9)),
  55: _WmoInfo(FontAwesomeIcons.cloudShowersHeavy, Color(0xFF2980B9)),
  61: _WmoInfo(FontAwesomeIcons.cloudRain, Color(0xFF3498DB)),
  63: _WmoInfo(FontAwesomeIcons.cloudRain, Color(0xFF2980B9)),
  65: _WmoInfo(FontAwesomeIcons.cloudShowersHeavy, Color(0xFF2980B9)),
  71: _WmoInfo(FontAwesomeIcons.snowflake, Color(0xFFECF0F1)),
  73: _WmoInfo(FontAwesomeIcons.snowflake, Color(0xFFBDC3C7)),
  75: _WmoInfo(FontAwesomeIcons.snowflake, Color(0xFFECF0F1)),
  77: _WmoInfo(FontAwesomeIcons.snowflake, Color(0xFFECF0F1)),
  80: _WmoInfo(FontAwesomeIcons.cloudSunRain, Color(0xFF3498DB)),
  81: _WmoInfo(FontAwesomeIcons.cloudShowersHeavy, Color(0xFF2980B9)),
  82: _WmoInfo(FontAwesomeIcons.cloudShowersWater, Color(0xFF2980B9)),
  85: _WmoInfo(FontAwesomeIcons.snowflake, Color(0xFFECF0F1)),
  86: _WmoInfo(FontAwesomeIcons.snowflake, Color(0xFFBDC3C7)),
  95: _WmoInfo(FontAwesomeIcons.boltLightning, Color(0xFFF39C12)),
  96: _WmoInfo(FontAwesomeIcons.cloudBolt, Color(0xFFE67E22)),
  99: _WmoInfo(FontAwesomeIcons.cloudBolt, Color(0xFFE74C3C)),
};

const _unknownInfo = _WmoInfo(FontAwesomeIcons.cloud, Colors.white);

/// Zahl ohne überflüssige Nachkommastelle (`0.0` → `0`, `1.5` → `1.5`).
String formatNumber(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherData? _data;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    final service = context.read<WeatherService>();
    final reporter = context.read<ErrorReporter>();
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await service.fetch();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      debugPrint('Wetter konnte nicht geladen werden: $e');
      reporter.reportSubmissionFailure('wetter', e);
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return PageScaffold(
      title: context.t('wetter.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.groupHour),
      action: HeaderAction(
        icon: FontAwesomeIcons.rotateRight,
        size: 18,
        spinning: _loading,
        onPressed: _loading ? null : _load,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(data: data?.current, loading: _loading, failed: _failed),
          const SizedBox(height: 20),
          SectionTitle(context.t('wetter.hourly_title')),
          _HourlyForecast(data: data),
          SectionTitle(context.t('wetter.daily_title')),
          _DailyForecast(data: data),
          _Source(current: data?.current),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.data,
    required this.loading,
    required this.failed,
  });

  final CurrentWeather? data;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final current = data;
    final info = current == null
        ? _unknownInfo
        : (_wmo[current.weatherCode] ?? _unknownInfo);

    final String description;
    if (current != null) {
      final key = 'wetter.code_${current.weatherCode}';
      description = context.i18n.has(key)
          ? context.t(key)
          : context.t('wetter.unknown');
    } else if (failed) {
      description = context.t('wetter.error_load');
    } else {
      description = context.t('wetter.loading');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 30, 15, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          children: [
            SizedBox(
              height: 74,
              child: current == null && !failed
                  ? const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : Center(
                      child: FaIcon(
                        failed && current == null
                            ? FontAwesomeIcons.cloud
                            : info.icon,
                        size: 64,
                        color: current == null
                            ? Colors.white70
                            : (info.color == Colors.white
                                  ? const Color(0xFFFFD700)
                                  : info.color),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              current == null ? '--°' : '${current.temperature.round()}°',
              key: const Key('weather-temp'),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              key: const Key('weather-description'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                children: [
                  _Detail(
                    icon: FontAwesomeIcons.wind,
                    label: context.t('wetter.wind'),
                    value: current == null
                        ? '-- km/h'
                        : '${current.windSpeed.round()} km/h',
                  ),
                  _Detail(
                    icon: FontAwesomeIcons.droplet,
                    label: context.t('wetter.humidity'),
                    value: current == null
                        ? '--%'
                        : '${formatNumber(current.humidity)}%',
                  ),
                  _Detail(
                    icon: FontAwesomeIcons.cloudRain,
                    label: context.t('wetter.precipitation'),
                    value: current == null
                        ? '-- mm'
                        : '${formatNumber(current.precipitation)} mm',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(icon, size: 11, color: Colors.white70),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourlyForecast extends StatelessWidget {
  const _HourlyForecast({required this.data});
  final WeatherData? data;

  @override
  Widget build(BuildContext context) {
    final hours = data?.next24Hours();
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration,
      child: hours == null
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                context.t('wetter.loading_preview'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final h in hours)
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: _HourlyItem(hour: h),
                    ),
                ],
              ),
            ),
    );
  }
}

class _HourlyItem extends StatelessWidget {
  const _HourlyItem({required this.hour});
  final HourlyWeather hour;

  @override
  Widget build(BuildContext context) {
    final info = _wmo[hour.weatherCode] ?? _unknownInfo;
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          Text(
            '${pad2(hour.time.hour)}:${pad2(hour.time.minute)}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          FaIcon(
            info.icon,
            size: 20,
            color: info.color == Colors.white ? AppColors.primary : info.color,
          ),
          const SizedBox(height: 8),
          Text(
            '${hour.temperature.round()}°',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyForecast extends StatelessWidget {
  const _DailyForecast({required this.data});
  final WeatherData? data;

  @override
  Widget build(BuildContext context) {
    final days = data?.daily;
    if (days == null) {
      return ListBlock(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
              child: Text(
                context.t('wetter.loading_forecast'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ),
        ],
      );
    }
    return ListBlock(
      children: [
        for (var i = 0; i < days.length; i++)
          _DailyItem(day: days[i], isToday: i == 0),
      ],
    );
  }
}

class _DailyItem extends StatelessWidget {
  const _DailyItem({required this.day, required this.isToday});
  final DailyWeather day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final info = _wmo[day.weatherCode] ?? _unknownInfo;
    // DateTime.weekday: Mo=1 … So=7 → Index 0 = So wie in `wetter.days_short_N`.
    final name = isToday
        ? context.t('wetter.today')
        : context.t('wetter.days_short_${day.date.weekday % 7}');
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: FaIcon(
                info.icon,
                size: 18,
                color: info.color == Colors.white
                    ? AppColors.primary
                    : info.color,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const FaIcon(
                  FontAwesomeIcons.droplet,
                  size: 11,
                  color: Color(0xFF3498DB),
                ),
                const SizedBox(width: 4),
                Text(
                  '${formatNumber(day.rain)} mm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3498DB),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${day.max.round()}°',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${day.min.round()}°',
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.current});
  final CurrentWeather? current;

  @override
  Widget build(BuildContext context) {
    final c = current;
    final status = c == null
        ? context.t('wetter.data_status_default')
        : context.t('wetter.data_status', {
            'date': formatDate(c.time),
            'time': '${pad2(c.time.hour)}:${pad2(c.time.minute)}',
          });
    return Padding(
      padding: const EdgeInsets.all(15),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        textAlign: TextAlign.center,
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(context.t('wetter.source')),
                InkWell(
                  onTap: () => context.read<UrlOpener>().open(
                    Uri.parse('https://open-meteo.com/'),
                  ),
                  child: const Text(
                    'Open-Meteo',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(status, key: const Key('weather-updated')),
          ],
        ),
      ),
    );
  }
}

final BoxDecoration _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: const [
    BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
  ],
);
