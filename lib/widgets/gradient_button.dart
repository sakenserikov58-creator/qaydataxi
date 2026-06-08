import 'package:flutter/material.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/services/sound_service.dart';

/// GradientButton — from Stitch ride_selection source:
///   bg-gradient-to-br from-primary to-secondary
///   rounded-2xl, h-14
///   shadow-[0_12px_24px_rgba(163,166,255,0.25)]
///   tracking-[0.15em] font-black uppercase text-[12px]
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 56,
    this.borderRadius = 9999,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        SoundService.selectionHaptic();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
        child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: context.colors.brandGradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40A3A6FF), // rgba(163,166,255,0.25)
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: context.colors.onPrimaryFixed, // #000000
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.15 * 12, // tracking-[0.15em]
            ),
          ),
        ),
        ),
      ),
    );
  }
}
