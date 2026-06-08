import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qayda_taxi_app/core/theme.dart';

/// GlassCard — glassmorphism card.
/// From Stitch sources:
///   background: rgba(38, 38, 39, 0.4)
///   backdrop-filter: blur(40px)
///   border: 1px solid rgba(72,72,73,0.15)  [outline-variant/15]
class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  /// Use [isPanelStyle] for driver screens which use rgba(22,22,23,0.4)
  final bool isPanelStyle;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.isPanelStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(32);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.glass, sigmaY: AppBlur.glass),
        child: Container(
          decoration: BoxDecoration(
            color: isPanelStyle ? context.colors.glassPanelColor : context.colors.glassColor,
            borderRadius: radius,
            border: Border.all(
              color: context.colors.outlineVariant.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}
