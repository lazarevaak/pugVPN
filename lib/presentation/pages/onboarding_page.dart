import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/pages/root_page.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/theme_viewmodel.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const RootPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeViewModel>().isDarkMode;
    final palette = AppPalette.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const <Color>[
                    Color(0xFF132235),
                    Color(0xFF09121F),
                    Color(0xFF050D18),
                  ]
                : const <Color>[
                    Color(0xFFF0F5FD),
                    Color(0xFFE3EDF8),
                    Color(0xFFD6E3F6),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: _OnboardingStarsPainter()),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/onboarding_pug.png',
                        width: 290,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'PugVPN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Secure. Fast. Private.',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFA8B5CC)
                              : palette.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final stars = <Offset>[
      Offset(size.width * 0.18, size.height * 0.16),
      Offset(size.width * 0.32, size.height * 0.10),
      Offset(size.width * 0.77, size.height * 0.14),
      Offset(size.width * 0.84, size.height * 0.24),
      Offset(size.width * 0.14, size.height * 0.34),
      Offset(size.width * 0.72, size.height * 0.39),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 1.7, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
