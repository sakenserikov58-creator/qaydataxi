import 'package:flutter/material.dart';
import '../core/theme.dart';

class TripRouteDisplay extends StatelessWidget {
  final String origin;
  final String destination;

  const TripRouteDisplay({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.primary,
                boxShadow: [BoxShadow(color: context.colors.primary.withValues(alpha: 0.8), blurRadius: 8)],
              ),
            ),
            Container(width: 1, height: 32, color: context.colors.outlineVariant.withValues(alpha: 0.4)),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: context.colors.secondary,
                boxShadow: [BoxShadow(color: context.colors.secondary.withValues(alpha: 0.8), blurRadius: 8)],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ОТКУДА', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: context.colors.onSurfaceVariant.withValues(alpha: 0.8))),
              const SizedBox(height: 2),
              Text(origin, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 20),
              Text('КУДА', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: context.colors.onSurfaceVariant.withValues(alpha: 0.8))),
              const SizedBox(height: 2),
              Text(destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
