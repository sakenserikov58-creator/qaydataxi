import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/widgets/map_mock.dart';
import 'package:qayda_taxi_app/widgets/bottom_nav_bar.dart';

/// DriverRequestScreen — pixel-exact from driver_incoming_request/code.html
///
/// Header: "Luxe" (from source) + "Premium Status" + driver name
/// Map background + gradient-to-t from-background overlay
/// Ping rings: w-32 h-32 bg-primary/20 animate-ping + w-20 bg-primary/40 pulse
/// Center dot: w-12 h-12 bg-primary rounded-full shadow-[0_0_30px_rgba(163,166,255,0.6)]
///
/// Request card: glass-card rounded-xl p-6  border border-white/5
///   Glowing accent line: h-1 bg-gradient-to-r from-primary via-secondary to-primary opacity-50
///   Price: "4 250 ₸" text-4xl font-black italic + timer badge (4 мин)
///   Locations bento: primary dot → gradient line → secondary dot outline
///   Details 2×2 grid: payment, client rating
///   Actions: "Отклонить" glass-card + "ПРИНЯТЬ" gradient with trending_flat icon
///
/// Bottom nav
class DriverRequestScreen extends StatefulWidget {
  const DriverRequestScreen({super.key});

  @override
  State<DriverRequestScreen> createState() => _DriverRequestScreenState();
}

class _DriverRequestScreenState extends State<DriverRequestScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pingCtrl;
  late final Animation<double> _pingAnim;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _pingAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pingCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(fit: StackFit.expand, children: [
        // Map + gradient overlay
        const MapMock(),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [context.colors.background, Colors.transparent],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ),

        // Decorative glow corners (-10%/-10%, 40%/40%, blur-[120px])
        Positioned(
          top: -MediaQuery.of(context).size.height * 0.1,
          left: -MediaQuery.of(context).size.width * 0.1,
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.height * 0.4,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.primary.withValues(alpha: 0.1),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Top bar: "Luxe" / Premium Status
        Positioned(
          top: 0, left: 0, right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                // tonal-shift-no-border: rgba(14,14,15,0.6) blur(32px)
                color: context.colors.topBarColor,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 24, right: 24, bottom: 16,
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_rounded,
                          color: context.colors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LUXE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFFFAFAFA),
                    ),
                  ),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('PREMIUM STATUS',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: context.colors.primary)),
                    const Text('Константин',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ]),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.3)),
                      color: context.colors.surfaceContainerHighest,
                    ),
                    child: Icon(Icons.person_rounded,
                        color: context.colors.onSurfaceVariant, size: 22),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // Center: ping rings + dot (top-1/3)
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 80,
          top: MediaQuery.of(context).size.height / 3 - 80,
          width: 160, height: 160,
          child: Stack(alignment: Alignment.center, children: [
            // Ping ring w-32 bg-primary/20
            AnimatedBuilder(
              animation: _pingAnim,
              builder: (_, __) => Transform.scale(
                scale: 1 + _pingAnim.value * 0.5,
                child: Opacity(
                  opacity: (1 - _pingAnim.value).clamp(0.0, 1.0),
                  child: Container(
                    width: 128, height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            // Pulse ring w-20 bg-primary/40
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.5 + 0.5 * _pulseCtrl.value,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            // Center dot: bg-primary shadow-[0_0_30px_rgba(163,166,255,0.6)]
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.primary,
                boxShadow: const [
                  BoxShadow(color: Color(0x99A3A6FF), blurRadius: 30),
                ],
              ),
              child: Icon(Icons.local_taxi_rounded,
                  color: context.colors.onPrimary, size: 22),
            ),
          ]),
        ),

        // Main request card (bottom)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: _RequestCard(onAccept: () => context.go('/driver/navigate'),
                  onDecline: () => context.go('/driver/home')),
            ),
            AppBottomNavBar(currentIndex: 0, onTap: (_) {}),
          ]),
        ),
      ]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final VoidCallback onAccept, onDecline;
  const _RequestCard({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.glassColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x0DFFFFFF)), // border-white/5
          ),
          child: Stack(children: [
            // Accent line at top
            Positioned(
              top: -24, left: -24, right: -24,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    context.colors.primary,
                    context.colors.secondary,
                    context.colors.primary,
                  ]),
                ),
              ),
            ),

            Column(children: [
              // Price + timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('НОВЫЙ ЗАКАЗ',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: context.colors.onSurfaceVariant)),
                    // italic price
                    Text('4 250 ₸',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          fontStyle: FontStyle.italic,
                          color: context.colors.onSurface,
                        )),
                  ]),
                  // Timer badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                          color: context.colors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.timer_rounded,
                          color: context.colors.tertiary, size: 16),
                      const SizedBox(width: 6),
                      Text('4 мин',
                          style: TextStyle(
                              color: context.colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Locations
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Dot + line + ring
                Column(children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary,
                      boxShadow: const [
                        BoxShadow(color: Color(0xCCA3A6FF), blurRadius: 10),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [context.colors.primary, context.colors.secondary],
                      ),
                    ),
                  ),
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.secondary, width: 2),
                    ),
                  ),
                ]),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ОТКУДА',
                        style: TextStyle(
                            fontSize: 9, color: context.colors.onSurfaceVariant,
                            letterSpacing: 2, fontWeight: FontWeight.w700)),
                    Text('Аль-Фараби, 77/7',
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface)),
                    Text('Esentai Tower • 1.2 км от вас',
                        style: TextStyle(fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Text('КУДА',
                        style: TextStyle(
                            fontSize: 9, color: context.colors.onSurfaceVariant,
                            letterSpacing: 2, fontWeight: FontWeight.w700)),
                    Text('Медеу, Ледовый каток',
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface)),
                    Text('Ул. Горная • 12 км (15 мин)',
                        style: TextStyle(fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ],
                )),
              ]),
              const SizedBox(height: 16),

              // Metadata 2×2
              const Row(children: [
                Expanded(child: _MetaCell(
                    Icons.credit_card_rounded, 'ОПЛАТА', 'Карта •• 4402')),
                SizedBox(width: 12),
                Expanded(child: _MetaCell(
                    Icons.stars_rounded, 'КЛИЕНТ', '4.98 • Бизнес')),
              ]),
              const SizedBox(height: 20),

              // Buttons
              Row(children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: onDecline,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: context.colors.glassColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.colors.outlineVariant.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Center(
                            child: Text('Отклонить',
                                style: TextStyle(
                                    color: context.colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: context.colors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66A3A6FF),
                            blurRadius: 25,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ПРИНЯТЬ',
                              style: TextStyle(
                                  color: context.colors.onPrimaryFixed,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 2)),
                          const SizedBox(width: 8),
                          Icon(Icons.trending_flat_rounded,
                              color: context.colors.onPrimaryFixed, size: 22),
                        ],
                      ),
                    ),
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

class _MetaCell extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _MetaCell(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.onSurfaceVariant, size: 17),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 8, color: context.colors.onSurfaceVariant,
                  letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          Text(value,
              style: TextStyle(
                  fontSize: 11, color: context.colors.onSurface,
                  fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}
