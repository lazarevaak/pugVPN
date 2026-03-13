import 'package:flutter/material.dart';

import 'package:pug_vpn/presentation/theme/app_theme.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.details,
    required this.imageAsset,
  });

  final String location;
  final String details;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.cardGradient,
        ),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              imageAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(color: palette.secondaryText, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: palette.secondaryText,
            size: 28,
          ),
        ],
      ),
    );
  }
}
