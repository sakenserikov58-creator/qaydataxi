import 'package:flutter/material.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/widgets/app_top_bar.dart';
import 'package:qayda_taxi_app/widgets/glass_card.dart';
import 'package:qayda_taxi_app/widgets/gradient_button.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _Card('Kaspi Gold', '8842', 'Visa', true),
      const _Card('Halyk', '3310', 'Mastercard', false),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppTopBar(title: 'Оплата', showBackButton: true, showAvatar: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Мои карты',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 24),
          ...cards.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(24),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13)),
                      child: Icon(Icons.credit_card,
                          color: context.colors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.bank} •••• ${c.last4}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            Text(c.type,
                                style: TextStyle(
                                    color: context.colors.onSurfaceVariant,
                                    fontSize: 11)),
                          ]),
                    ),
                    if (c.active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Активна',
                            style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                ),
              )),
          const SizedBox(height: 16),
          const GradientButton(label: '+ Добавить карту', height: 52),
        ],
      ),
    );
  }
}

class _Card {
  final String bank, last4, type;
  final bool active;
  const _Card(this.bank, this.last4, this.type, this.active);
}
