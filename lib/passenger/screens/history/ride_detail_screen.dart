import 'package:flutter/material.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/widgets/app_top_bar.dart';
import 'package:qayda_taxi_app/widgets/glass_card.dart';
import 'package:qayda_taxi_app/widgets/map_mock.dart';
import 'package:qayda_taxi_app/widgets/trip_route_display.dart';

class RideDetailScreen extends StatelessWidget {
  const RideDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppTopBar(title: '12 октября', showBackButton: true, showAvatar: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: const SizedBox(height: 200, child: MapMock()),
          ),
          const SizedBox(height: 20),
          GlassCard(
            borderRadius: BorderRadius.circular(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Бизнес класс',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                ShaderMask(
                  shaderCallback: (b) =>
                      context.colors.brandGradient.createShader(b),
                  child: const Text('2 850 ₸',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 16),
              const TripRouteDisplay(
                origin: 'ул. Абылай Хана, 79',
                destination: 'ТРЦ Dostyk Plaza',
              ),
              const SizedBox(height: 16),
              Divider(color: context.colors.outlineVariant.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              const _Row('Водитель', 'Елена'),
              const _Row('Автомобиль', 'Mercedes-Benz S-Class'),
              const _Row('Время в пути', '22 мин'),
              const _Row('Дистанция', '14.2 км'),
              const _Row('Оплата', 'Kaspi Gold •••• 8842'),
            ]),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderRadius: BorderRadius.circular(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < 4
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < 4
                        ? context.colors.primary
                        : context.colors.outlineVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Ваша оценка',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Text('Чистый салон, Вежливость',
                  style:
                      TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style:
                TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
