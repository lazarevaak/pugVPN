import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE8EEF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7DA2E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050D18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF56F2C4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}

class AppPalette {
  const AppPalette({
    required this.backgroundGradient,
    required this.cardGradient,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.tabShadow,
    required this.tabTop,
    required this.tabBottom,
    required this.activeTab,
    required this.inactiveTab,
    required this.softFill,
  });

  final List<Color> backgroundGradient;
  final List<Color> cardGradient;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color tabShadow;
  final Color tabTop;
  final Color tabBottom;
  final Color activeTab;
  final Color inactiveTab;
  final Color softFill;

  bool get isDark => primaryText == Colors.white;

  static AppPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return AppPalette(
        backgroundGradient: const <Color>[
          Color(0xFF1E2C3F),
          Color(0xFF0A1625),
          Color(0xFF050D18),
        ],
        cardGradient: <Color>[
          Colors.white.withValues(alpha: 0.08),
          const Color(0xFF101B2A).withValues(alpha: 0.82),
        ],
        border: Colors.white.withValues(alpha: 0.08),
        primaryText: Colors.white,
        secondaryText: Colors.white70,
        tertiaryText: Colors.white54,
        tabShadow: Colors.black.withValues(alpha: 0.42),
        tabTop: Colors.white.withValues(alpha: 0.08),
        tabBottom: const Color(0xFF09111B).withValues(alpha: 0.88),
        activeTab: const Color(0xFFC5DEFF),
        inactiveTab: Colors.white.withValues(alpha: 0.72),
        softFill: Colors.white.withValues(alpha: 0.08),
      );
    }

    return AppPalette(
      backgroundGradient: const <Color>[
        Color(0xFFF6F9FD),
        Color(0xFFE8F0FA),
        Color(0xFFDCE8F7),
      ],
      cardGradient: const <Color>[
        Color(0xFFFFFFFF),
        Color(0xFFF0F5FB),
      ],
      border: const Color(0xFFD7E2F0),
      primaryText: const Color(0xFF22344E),
      secondaryText: const Color(0xFF5E7393),
      tertiaryText: const Color(0xFF8091A7),
      tabShadow: const Color(0xFF9AACC7),
      tabTop: Colors.white.withValues(alpha: 0.82),
      tabBottom: const Color(0xFFE3ECF8).withValues(alpha: 0.95),
      activeTab: const Color(0xFF7091C7),
      inactiveTab: const Color(0xFF6B7E98),
      softFill: const Color(0xFFF3F7FC),
    );
  }
}
