import 'dart:ui';

enum LocationAsset {
  auto,
  finland,
  germany,
  unitedStates,
  fallback;

  factory LocationAsset.fromValue(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'AUTO' => LocationAsset.auto,
      'FI' || 'FINLAND' => LocationAsset.finland,
      'DE' || 'GERMANY' => LocationAsset.germany,
      'US' || 'USA' || 'UNITED STATES' => LocationAsset.unitedStates,
      _ => LocationAsset.fallback,
    };
  }

  String get countryImageAsset => switch (this) {
    LocationAsset.auto => 'assets/pug_countries/pug_auto.png',
    LocationAsset.finland => 'assets/pug_countries/pug_finland.png',
    LocationAsset.germany => 'assets/pug_countries/pug_germany.png',
    LocationAsset.unitedStates => 'assets/pug_countries/pug_usa.png',
    LocationAsset.fallback => 'assets/pug_countries/pug_auto.png',
  };

  String get flagAsset => switch (this) {
    LocationAsset.auto => 'assets/images/pug_icon.png',
    LocationAsset.finland => 'assets/flags/finland_flag.png',
    LocationAsset.germany => 'assets/flags/germany_flag.png',
    LocationAsset.unitedStates => 'assets/flags/usa_flag.png',
    LocationAsset.fallback => 'assets/images/pug_icon.png',
  };
}

class LocationItem {
  const LocationItem({
    required this.country,
  });

  final String country;

  bool get isPremium => switch (country) {
    'Germany' || 'United States' => true,
    _ => false,
  };

  String get subtitle => isPremium ? 'Premium' : '';

  String get imageAsset => switch (country) {
    'Auto' => 'assets/images/pug_icon.png',
    'Finland' => 'assets/flags/finland_flag.png',
    'Germany' => 'assets/flags/germany_flag.png',
    'United States' => 'assets/flags/usa_flag.png',
    _ => 'assets/flags/finland_flag.png',
  };

  Color get accent => switch (country) {
    'Auto' => const Color(0xFF56F2C4),
    'Finland' => const Color(0xFFB9EA8B),
    'United States' => const Color(0xFF8EE7A8),
    _ => const Color(0xFF9BCBFF),
  };
}
