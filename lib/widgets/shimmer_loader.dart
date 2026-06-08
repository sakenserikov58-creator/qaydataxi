import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:qayda_taxi_app/core/theme.dart';

/// ShimmerLoader — Скелетон для мягкой загрузки (Glassmorphism + Shimmer).
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.outlineVariant.withValues(alpha: 0.2),
      highlightColor: context.colors.onSurface.withValues(alpha: 0.05),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
