import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qayda_taxi_app/core/theme.dart';

/// MapMock — dark, grayscale map background with ping markers.
///
/// From home_screen_1 source:
///   Map img: opacity-60 grayscale brightness-[0.3]
///   Ping marker: absolute top-1/2 left-1/3
///     outer: w-12 h-12 bg-primary/20 animate-ping
///     inner: w-4 h-4 bg-primary rounded-full shadow-[0_0_15px_rgba(163,166,255,0.8)]
///   Secondary dot: top-[45%] right-[25%]  w-3 h-3 bg-tertiary-dim opacity-80
///
/// From ride_selection_1, overlays SVG route path.
class MapMock extends StatefulWidget {
  /// Set true for ride_selection to show SVG route overlay
  final bool showRoute;
  /// Set true for searching_driver (blur + extra-dark)
  final bool isBlurred;

  const MapMock({super.key, this.showRoute = false, this.isBlurred = false});

  @override
  State<MapMock> createState() => _MapMockState();
}

class _MapMockState extends State<MapMock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pingCtrl;
  late final Animation<double> _pingAnim;

  @override
  void initState() {
    super.initState();
    _pingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _pingAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Map base ───────────────────────────────────────────────────────
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              // grayscale
              0.2126, 0.7152, 0.0722, 0, -80,
              0.2126, 0.7152, 0.0722, 0, -80,
              0.2126, 0.7152, 0.0722, 0, -80,
              0,      0,      0,      1,   0,
            ]),
            child: Opacity(
              opacity: widget.isBlurred ? 0.15 : 0.6,
              child: const CustomPaint(
                painter: _CityMapPainter(),
              ),
            ),
          ),

          // ── Blur (searching_driver) ────────────────────────────────────────
          if (widget.isBlurred)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),

          // ── Radial overlay ─────────────────────────────────────────────────
          if (!widget.isBlurred)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1,
                  colors: [Colors.transparent, Color(0x660E0E0F)],
                ),
              ),
            ),

          // ── SVG route (ride_selection) ─────────────────────────────────────
          if (widget.showRoute)
            const CustomPaint(painter: _RoutePainter()),

          // ── Primary ping marker ────────────────────────────────────────────
          if (!widget.isBlurred)
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.33 - 24,
              top: MediaQuery.sizeOf(context).height * 0.5 - 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: AnimatedBuilder(
                  animation: _pingAnim,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ping ring
                      Transform.scale(
                        scale: 1 + _pingAnim.value * 1.5,
                        child: Opacity(
                          opacity: (1 - _pingAnim.value).clamp(0.0, 1.0),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      // Inner dot  w-4 h-4
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.primary,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xCC9396FF), // rgba(163,166,255,0.8)
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Secondary dot top-[45%] right-[25%] ───────────────────────────
          if (!widget.isBlurred)
            Positioned(
              right: MediaQuery.sizeOf(context).width * 0.25,
              top: MediaQuery.sizeOf(context).height * 0.45,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.tertiaryDim.withValues(alpha: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x9917A8EC), // rgba(23,168,236,0.6)
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Minimal city-grid painter (static – shouldRepaint = false)
class _CityMapPainter extends CustomPainter {
  const _CityMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E0F);
    canvas.drawRect(Offset.zero & size, bg);

    final road = Paint()
      ..color = const Color(0xFF1A191B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final mainRoad = Paint()
      ..color = const Color(0xFF201F21)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Grid
    for (var x = 0.0; x < w; x += w / 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), road);
    }
    for (var y = 0.0; y < h; y += h / 20) {
      canvas.drawLine(Offset(0, y), Offset(w, y), road);
    }

    // Main arteries
    canvas.drawLine(Offset(0, h * 0.35), Offset(w, h * 0.35), mainRoad);
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), mainRoad);
    canvas.drawLine(Offset(w * 0.3, 0), Offset(w * 0.3, h), mainRoad);
    canvas.drawLine(Offset(w * 0.65, 0), Offset(w * 0.65, h), mainRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// SVG-like route painter for ride_selection
class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA3A6FF), Color(0xFFC180FF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Bezier from bottom-center to top-center (matching SVG: M200,600 Q150,450 250,350 T200,150)
    final path = Path()
      ..moveTo(w * 0.5, h * 0.75)
      ..quadraticBezierTo(w * 0.375, h * 0.5625, w * 0.625, h * 0.4375)
      ..quadraticBezierTo(w * 0.75, h * 0.3, w * 0.5, h * 0.1875);

    // Dashed stroke  stroke-dasharray="10 15"
    const dashLen = 10.0;
    const gapLen  = 15.0;
    _drawDashedPath(canvas, path, paint, dashLen, gapLen);

    // Origin dot (primary)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.75),
      8,
      Paint()..color = const Color(0xFFA3A6FF),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.75),
      16,
      Paint()..color = const Color(0x33A3A6FF),
    );

    // Destination dot (secondary)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.1875),
      8,
      Paint()..color = const Color(0xFFC180FF),
    );
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = 0;
      while (dist < m.length) {
        final end = (dist + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(dist, end), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
