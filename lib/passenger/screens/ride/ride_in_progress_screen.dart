import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';
import 'package:qayda_taxi_app/widgets/app_top_bar.dart';
import 'package:qayda_taxi_app/widgets/glass_card.dart';
import 'package:qayda_taxi_app/widgets/map_mock.dart';
import 'package:url_launcher/url_launcher.dart';

class RideInProgressScreen extends StatelessWidget {
  const RideInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideNotifier>(
      builder: (ctx, ride, _) {
        final driver = ride.assignedDriver;
        final order = ride.currentOrder;
        final isAccepted = ride.status.index <= 3; // accepted/arrived
        final statusLabel = isAccepted ? 'ПОДЪЕЗЖАЕТ' : 'В ПУТИ';

        return Scaffold(
          backgroundColor: context.colors.background,
          extendBodyBehindAppBar: true,
          appBar: const AppTopBar(title: 'QAYDA TAXI', showMenuButton: false),
          body: Stack(
            children: [
              const Positioned.fill(child: MapMock()),

              // ── SOS + Share FABs ──────────────────────────────────────────
              Positioned(
                top: 100, right: 16,
                child: Column(children: [
                  _SosFab(driver: driver),
                  const SizedBox(height: 8),
                  _ShareFab(driver: driver),
                ]),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHigh.withValues(alpha: 0.92),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.outlineVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status row
                      Row(children: [
                        _StatusBadge(label: statusLabel),
                        const Spacer(),
                        Text(
                          '≈ ${driver != null ? '3 мин' : '...'}',
                          style: TextStyle(
                              color: context.colors.onSurfaceVariant, fontSize: 13),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // Driver info
                      Row(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.surfaceContainerHighest,
                            border: Border.all(
                                color: context.colors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.person,
                              color: context.colors.onSurfaceVariant, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver?.name ?? '...',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              ),
                              Row(children: [
                                Icon(Icons.star,
                                    color: context.colors.primary, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  driver != null
                                      ? '${driver.displayRating} • ${driver.vehicleInfo}'
                                      : 'Загрузка...',
                                  style: TextStyle(
                                      color: context.colors.onSurfaceVariant,
                                      fontSize: 11),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        _ActionBtn(
                            icon: Icons.chat_bubble_outline,
                            onTap: () => context.push('/chat')),
                        const SizedBox(width: 8),
                        _ActionBtn(
                            icon: Icons.call_outlined,
                            onTap: () async {
                              // Номер водителя из модели (по умолчанию — мок-номер)
                              final driverPhone = driver?.govPlate != null
                                  ? '+77001234567'
                                  : '+77001234567';
                              final uri = Uri(scheme: 'tel', path: driverPhone);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }),
                      ]),
                      const SizedBox(height: 20),
                      GlassCard(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _EtaItem(label: 'Прибытие', value: '14:38'),
                            const _EtaItem(label: 'Маршрут', value: '12.4 км'),
                            _EtaItem(
                                label: 'Стоимость',
                                value: order?.formattedPrice ?? '—'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Кнопка «Завершить» (для demo)
                      TextButton(
                        onPressed: () {
                          ride.completeRide();
                          context.go('/rate');
                        },
                        child: Text(
                          'Завершить поездку (демо)',
                          style: TextStyle(
                              color: context.colors.onSurfaceVariant,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: context.colors.primary, size: 22),
      ),
    );
  }
}

class _EtaItem extends StatelessWidget {
  final String label;
  final String value;
  const _EtaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 8,
            color: context.colors.onSurfaceVariant,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
    ]);
  }
}

// ── SOS FAB ────────────────────────────────────────────────────────────────────────────────

class _SosFab extends StatelessWidget {
  final dynamic driver;
  const _SosFab({required this.driver});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(children: [
              const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 10),
              Text('Вћзов 102',
                style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.onSurface)),
            ]),
            content: Text(
              'Аварийные службы поведомлены о вашем местоположении '
              'и данных поездки.\n\n'
              'Водитель: ${driver?.name ?? "неизвестен"}\n'
              'Авто: ${driver?.vehicleInfo ?? "неизвестен"}',
              style: TextStyle(color: context.colors.onSurfaceVariant, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Отмена',
                  style: TextStyle(color: context.colors.onSurfaceVariant)),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Вызвать 102',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
      child: Container(
        width: 48, height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x40EF4444), blurRadius: 12, spreadRadius: 2)],
        ),
        child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ShareFab extends StatelessWidget {
  final dynamic driver;
  const _ShareFab({required this.driver});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Ссылка на поездку скопирована',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: context.colors.cardShadow,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Icon(Icons.ios_share_rounded,
            color: context.colors.primary, size: 20),
      ),
    );
  }
}

