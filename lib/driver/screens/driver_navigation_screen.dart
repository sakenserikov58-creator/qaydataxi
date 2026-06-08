import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/widgets/map_mock.dart';
import 'package:qayda_taxi_app/widgets/bottom_nav_bar.dart';

/// DriverNavigationScreen — pixel-exact from driver_navigation/code.html
///
/// Map: opacity-60 grayscale contrast-125
/// Gradient overlay: linear-gradient(to bottom, rgba(14,14,15,0.8) 0%, transparent 25%, transparent 75%, rgba(14,14,15,0.9) 100%)
/// Top bar: "Маршрут активен" subtext + h1 "пр. Аль-Фараби, 77" + "ON AIR" badge
///
/// Maneuver card (top-left): glass-panel rounded-[32px] p-6
///   bg-primary/20 p-4 rounded-2xl + turn_right icon text-5xl
///   h2: text-4xl font-black "450 м"
///   p: text-on-surface-variant "Поворот направо на улицу Фурманова"
///
/// Speedometer (center-left): w-32 h-32
///   Circle SVG: outer track + primary-dim arc stroke-dashoffset=120
///   Center: "72" km/h
///   Speed badge: bg-white border-4 border-error w-10 h-10 rounded-full "60" text-black
///
/// Bottom trip card: glass-panel rounded-[40px] p-8
///   "Текущий заказ" / "ул. Тимирязева, 42"
///   Business Class badge + price
///   CTA: "Написать" (outline) + "Позвонить" (gradient)
///
/// FABs right column: my_location, layers, warning
class DriverNavigationScreen extends StatelessWidget {
  const DriverNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(fit: StackFit.expand, children: [
        // Map: opacity-60 grayscale contrast-125
        const MapMock(),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0E0E0F), // 0.8 opacity
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xE60E0E0F), // 0.9 opacity
                ],
                stops: [0, 0.25, 0.75, 1],
              ),
            ),
          ),
        ),

        // FABs: right column, top: 24+appbar_height
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          right: 24,
          child: Column(children: [
            _NavFab(Icons.my_location_rounded, context.colors.onSurface),
            const SizedBox(height: 16),
            _NavFab(Icons.layers_rounded, context.colors.onSurface),
            const SizedBox(height: 16),
            _NavFab(Icons.warning_rounded, context.colors.error),
          ]),
        ),

        // Main content (column layout)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(children: [
              // Top bar
              _NavTopBar(),
              const SizedBox(height: 24),

              // Maneuver card
              _ManeuverCard(),
              const SizedBox(height: 24),

              // Row: speedometer (left) + spacer (right)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Speedometer(),
                const Spacer(),
              ]),

              const Spacer(),

              // Trip card
              _TripCard(onChat: () {}, onCall: () {}),
              const SizedBox(height: 8),

              // Bottom nav
              AppBottomNavBar(currentIndex: 0, onTap: (_) {}),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _NavTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        // Menu
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Icon(Icons.menu_rounded, color: context.colors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Opacity(
            opacity: 0.6,
            child: Text('Маршрут активен',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFFFAFAFA),
                    fontWeight: FontWeight.w500)),
          ),
          Text('пр. Аль-Фараби, 77',
              style: TextStyle(
                  fontSize: 20, color: Color(0xFFFAFAFA),
                  fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ]),
        const Spacer(),
        // "ON AIR" badge
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                    color: context.colors.outlineVariant.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('ON AIR',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                        letterSpacing: 2)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.3), width: 2),
            color: context.colors.surfaceContainerHighest,
          ),
          child: Icon(Icons.person_rounded,
              color: context.colors.onSurfaceVariant, size: 22),
        ),
      ]),
    );
  }
}

class _ManeuverCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.glassPanelColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            // Turn icon: bg-primary/20 p-4 rounded-2xl + turn_right text-5xl
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.turn_right_rounded,
                  color: context.colors.primary, size: 48),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('450 м',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: context.colors.onSurface)),
                Text('Поворот направо на улицу Фурманова',
                    style: TextStyle(
                        fontSize: 16,
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Speedometer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128, height: 128,
      child: Stack(alignment: Alignment.center, children: [
        // SVG-like circle with arc
        CustomPaint(painter: _SpeedPainter(context.colors)),
        // Value
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('72',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: context.colors.onSurface)),
          Text('КМ/Ч',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: context.colors.onSurfaceVariant)),
        ]),
        // Speed limit badge: bg-white border-4 border-error w-10 h-10
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: context.colors.error, width: 4),
            ),
            child: const Center(
              child: Text('60',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SpeedPainter extends CustomPainter {
  final AppColors colors;
  _SpeedPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 58.0;
    const stroke = 8.0;

    // Track: surface-container-high
    canvas.drawCircle(c, r,
        Paint()
          ..color = colors.surfaceContainerHigh
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);

    // Arc: primary-dim, stroke-dashoffset=120 out of circumference=364
    // Fill = (364 - 120) / 364 * 2π
    const filled = (364 - 120) / 364 * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -3.14159 / 2, // -90 degrees (top)
      filled,
      false,
      Paint()
        ..color = colors.primaryDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _TripCard extends StatelessWidget {
  final VoidCallback onChat, onCall;
  const _TripCard({required this.onChat, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: context.colors.glassPanelColor,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.15)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x990000000),
                blurRadius: 60,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // dot + gradient line
                      Column(children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.primaryFixed,
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33A3A6FF), blurRadius: 8,
                                  spreadRadius: 4),
                            ],
                          ),
                        ),
                        Container(
                          width: 2, height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [context.colors.primary, Colors.transparent],
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('ТЕКУЩИЙ ЗАКАЗ',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: context.colors.onSurfaceVariant)),
                        Text('ул. Тимирязева, 42',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface)),
                      ]),
                    ]),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Row(children: [
                        // Business Class badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: context.colors.secondary.withValues(alpha: 0.2)),
                          ),
                          child: Text('Business Class',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.secondary)),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.payments_rounded,
                            color: context.colors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text('2 450 ₸',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface,
                                fontSize: 14)),
                      ]),
                    ),
                  ],
                ),
              ),
              // CTA buttons column
              Column(children: [
                // "Написать" - outline button with gradient border
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: context.colors.brandGradient,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(children: [
                        Icon(Icons.chat_bubble_rounded,
                            color: context.colors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text('Написать',
                            style: TextStyle(
                                color: context.colors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // "Позвонить" - gradient button
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: context.colors.brandGradient,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33A3A6FF),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Icon(Icons.call_rounded,
                          color: context.colors.onPrimaryFixed, size: 18),
                      const SizedBox(width: 6),
                      Text('Позвонить',
                          style: TextStyle(
                              color: context.colors.onPrimaryFixed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _NavFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _NavFab(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.glassPanelColor,
            border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
