import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';
import 'package:qayda_taxi_app/widgets/gradient_button.dart';

/// Экран оценки поездки. Показывается после завершения поездки.
class RateTripScreen extends StatefulWidget {
  const RateTripScreen({super.key});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 5;
  final _selectedTags = <String>{'Вежливый водитель', 'Чистый салон'};
  final _commentCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _tags = [
    ('😊', 'Вежливый водитель'),
    ('✨', 'Чистый салон'),
    ('🎵', 'Хорошая музыка'),
    ('🚀', 'Быстрая езда'),
    ('🛣️', 'Знает дороги'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1: return 'Ужасно 😤';
      case 2: return 'Плохо 😕';
      case 3: return 'Нормально 😐';
      case 4: return 'Хорошо 😊';
      default: return 'Отлично! 🤩';
    }
  }

  void _submit() {
    HapticFeedback.heavyImpact();
    context.read<RideNotifier>().reset();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.read<RideNotifier>();
    final driver = ride.assignedDriver;
    final order = ride.currentOrder;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Header ────────────────────────────────────────────────────
                Row(children: [
                  GestureDetector(
                    onTap: () {
                      ride.reset();
                      context.go('/home');
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.outlineVariant),
                      ),
                      child: Icon(Icons.close, color: context.colors.onSurfaceVariant, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Row(children: [
                    Icon(Icons.local_taxi_rounded, color: context.colors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('Qayda Taxi',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: context.colors.onSurface,
                            letterSpacing: 0.5)),
                  ]),
                  const Spacer(),
                  const SizedBox(width: 40),
                ]),
                const SizedBox(height: 24),

                // ── Trip completed badge ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                    SizedBox(width: 6),
                    Text('Поездка завершена',
                        style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 20),

                Text('Как прошла поездка?',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: context.colors.onSurface)),
                const SizedBox(height: 4),
                Text('Ваш отзыв помогает Qayda стать лучше',
                    style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),

                // ── Driver card ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: context.colors.elevatedShadow,
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                  child: Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: context.colors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(driver?.name ?? 'Водитель',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: context.colors.onSurface)),
                        const SizedBox(height: 2),
                        Text(driver?.vehicleInfo ?? '—',
                            style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
                        if (driver != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                            const SizedBox(width: 3),
                            Text(driver.displayRating,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.onSurface)),
                          ]),
                        ],
                      ]),
                    ),
                    if (order != null)
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('СТОИМОСТЬ',
                            style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(order.formattedPrice,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: context.colors.primary)),
                      ]),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Stars ─────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: context.colors.cardShadow,
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                  child: Column(children: [
                    Text(_ratingLabel,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _rating = i + 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: i < _rating ? const Color(0xFFEAB308) : context.colors.outlineVariant,
                            size: 46,
                          ),
                        ),
                      )),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Quick tags ────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: context.colors.cardShadow,
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ЧТО ПОНРАВИЛОСЬ?',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((t) {
                        final (emoji, label) = t;
                        final active = _selectedTags.contains(label);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (active) {
                                _selectedTags.remove(label);
                              } else {
                                _selectedTags.add(label);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: active
                                  ? context.colors.primaryContainer
                                  : context.colors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                  color: active
                                      ? context.colors.primary
                                      : context.colors.outlineVariant),
                            ),
                            child: Text('$emoji $label',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? context.colors.primary
                                        : context.colors.onSurface)),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Comment ───────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                  child: TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    style: TextStyle(color: context.colors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Оставить комментарий водителю...',
                      hintStyle: TextStyle(color: context.colors.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Submit ────────────────────────────────────────────────────
                GradientButton(label: 'Отправить отзыв', onTap: _submit),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    ride.reset();
                    context.go('/home');
                  },
                  child: Text('Пропустить',
                      style: TextStyle(color: context.colors.onSurfaceVariant)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
