import 'package:flutter/material.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/widgets/app_top_bar.dart';
import 'package:qayda_taxi_app/widgets/glass_card.dart';

class PromoCodesScreen extends StatelessWidget {
  const PromoCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const promos = [
      _Promo('QAYDA20', 'Скидка 20% на Бизнес класс', 'до 31 дек'),
      _Promo('NEWUSER', 'Первая поездка бесплатно', 'до 15 янв'),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppTopBar(title: 'Промокоды', showBackButton: true, showAvatar: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Промокоды',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 24),
            GlassCard(
              borderRadius: BorderRadius.circular(24),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Введите промокод',
                      hintStyle:
                          TextStyle(color: context.colors.onSurfaceVariant),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: context.colors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Применить',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Text('АКТИВНЫЕ',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...promos.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    borderRadius: BorderRadius.circular(20),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.sell_outlined,
                            color: context.colors.secondary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.code,
                                  style: TextStyle(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1)),
                              Text(p.desc,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              Text(p.valid,
                                  style: TextStyle(
                                      color: context.colors.onSurfaceVariant,
                                      fontSize: 10)),
                            ]),
                      ),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Promo {
  final String code, desc, valid;
  const _Promo(this.code, this.desc, this.valid);
}
