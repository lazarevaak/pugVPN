import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Корневой виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

/// Главный экран
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool isConnecting = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  Future<void> _onPugTap() async {
    if (isConnecting || isConnected) return;

    setState(() {
      isConnecting = true;
    });

    _controller.repeat(reverse: true);

    await Future.delayed(const Duration(seconds: 2));

    _controller
      ..stop()
      ..value = 1.0;

    setState(() {
      isConnecting = false;
      isConnected = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6F7FB),
              Color(0xFFEDEBFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Заголовок
                const Text(
                  'Introduction to',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFF6B6E7A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Secure\nConnection',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Color(0xFF2E3140),
                  ),
                ),

                const SizedBox(height: 40),

                // 🐶 Мопс с анимацией
                Center(
                  child: GestureDetector(
                    onTap: _onPugTap,
                    child: ScaleTransition(
                      scale: _controller,
                      child: Image.asset(
                        'assets/images/pug_vpn.png',
                        height: 220,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Статус
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isConnected
                          ? 'Connected'
                          : isConnecting
                              ? 'Connecting…'
                              : 'Tap the pug to connect',
                      key: ValueKey('$isConnected-$isConnecting'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isConnected
                            ? Colors.green
                            : const Color(0xFF6B6E7A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
