import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.details,
  });

  final String location;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF21344A), Color(0xFF162434)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/pug_countries/pug_russia.png',
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: 28,
          ),
        ],
      ),
    );
  }
}
