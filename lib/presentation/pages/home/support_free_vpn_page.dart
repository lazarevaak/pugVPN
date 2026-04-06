import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:pug_vpn/presentation/theme/app_theme.dart';

class SupportFreeVpnPage extends StatefulWidget {
  const SupportFreeVpnPage({super.key});

  @override
  State<SupportFreeVpnPage> createState() => _SupportFreeVpnPageState();
}

class _SupportFreeVpnPageState extends State<SupportFreeVpnPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardsController;
  Timer? _closeTimer;
  bool _canClose = false;

  static const List<_AdCardData> _cards = <_AdCardData>[
    _AdCardData(
      title: 'Watch 15 sec to keep tunnel active',
      subtitle: 'A short rewarded clip helps cover VPN traffic costs.',
      cta: 'Watch',
      badge: 'Video',
      icon: Icons.play_circle_fill_rounded,
      accent: Color(0xFF5BE7C4),
      previewGradient: <Color>[Color(0xFF66F5D4), Color(0xFF2A445B)],
    ),
    _AdCardData(
      title: 'Try Pug Browser companion',
      subtitle: 'Cleaner browsing, lighter pages, and built-in privacy tools.',
      cta: 'Open',
      badge: 'App',
      icon: Icons.open_in_new_rounded,
      accent: Color(0xFF8CB7FF),
      previewGradient: <Color>[Color(0xFF8CB7FF), Color(0xFF304C73)],
    ),
    _AdCardData(
      title: 'Premium route with faster regions',
      subtitle: 'Unlock more countries and priority servers for streaming.',
      cta: 'Try',
      badge: 'Premium',
      icon: Icons.workspace_premium_rounded,
      accent: Color(0xFFFFD57A),
      previewGradient: <Color>[Color(0xFFFFD57A), Color(0xFF5C4421)],
    ),
    _AdCardData(
      title: 'Support free VPN with one more ad',
      subtitle: 'Keep the playful pug online without subscriptions.',
      cta: 'Watch',
      badge: 'Reward',
      icon: Icons.favorite_rounded,
      accent: Color(0xFFFF8EA1),
      previewGradient: <Color>[Color(0xFFFF8EA1), Color(0xFF583348)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _closeTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        _canClose = true;
      });
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return PopScope(
      canPop: _canClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            _Background(palette: palette),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Support Free VPN 🐶',
                                style: TextStyle(
                                  color: palette.primaryText,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Watch a short ad to keep using VPN for free',
                                style: TextStyle(
                                  color: palette.secondaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _canClose
                              ? _CloseButton(
                                  key: const ValueKey<String>('close'),
                                  palette: palette,
                                  onTap: () => Navigator.of(context).maybePop(),
                                )
                              : _CountdownPill(
                                  key: const ValueKey<String>('countdown'),
                                  palette: palette,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (BuildContext context, int index) {
                          final item = _cards[index];
                          final start = index * 0.12;
                          final end = (start + 0.42).clamp(0.0, 1.0);
                          final animation = CurvedAnimation(
                            parent: _cardsController,
                            curve: Interval(start, end, curve: Curves.easeOutCubic),
                          );
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (BuildContext context, Widget? child) {
                              final opacity = animation.value;
                              final offset = 28 * (1 - animation.value);
                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(0, offset),
                                  child: child,
                                ),
                              );
                            },
                            child: _AdCard(
                              palette: palette,
                              data: item,
                              index: index,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.65),
          radius: 1.28,
          colors: <Color>[
            const Color(0xFF203749),
            palette.backgroundGradient[1],
            palette.backgroundGradient.last,
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: -40,
            right: -20,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF56F2C4).withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: palette.isDark ? 0.06 : 0.1,
              child: Image.asset(
                'assets/images/world_map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.palette,
    required this.data,
    required this.index,
  });

  final AppPalette palette;
  final _AdCardData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.11),
                const Color(0xFF152133).withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(color: palette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 26,
                offset: const Offset(0, 14),
                spreadRadius: -18,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _PreviewTile(data: data, index: index),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: data.accent.withValues(alpha: 0.14),
                        border: Border.all(
                          color: data.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        data.badge,
                        style: TextStyle(
                          color: data.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: data.accent.withValues(alpha: 0.18),
                          border: Border.all(
                            color: data.accent.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          data.cta,
                          style: TextStyle(
                            color: data.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.data, required this.index});

  final _AdCardData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.previewGradient,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -10,
            top: 10,
            child: Icon(
              data.icon,
              size: 56,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: List<Widget>.generate(
                    3,
                    (_) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (index == 0)
                  Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  )
                else
                  Icon(
                    data.icon,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 26,
                  ),
                const Spacer(),
                Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.26),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 34,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({
    super.key,
    required this.palette,
  });

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        'Skip in 10s',
        style: TextStyle(
          color: palette.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({
    super.key,
    required this.palette,
    required this.onTap,
  });

  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
            border: Border.all(color: palette.border),
          ),
          child: Icon(
            Icons.close_rounded,
            color: palette.primaryText,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AdCardData {
  const _AdCardData({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.badge,
    required this.icon,
    required this.accent,
    required this.previewGradient,
  });

  final String title;
  final String subtitle;
  final String cta;
  final String badge;
  final IconData icon;
  final Color accent;
  final List<Color> previewGradient;
}
