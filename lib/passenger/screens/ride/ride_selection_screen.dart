import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_bloc.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_event_state.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/services/sound_service.dart';
import 'package:qayda_taxi_app/widgets/app_map_widget.dart';
import 'package:qayda_taxi_app/widgets/bottom_nav_bar.dart';
import 'package:qayda_taxi_app/widgets/kaspi_payment_dialog.dart';

/// RideSelectionScreen — Light Mode + реальная карта с маршрутом
class RideSelectionScreen extends StatefulWidget {
  const RideSelectionScreen({super.key});

  @override
  State<RideSelectionScreen> createState() => _RideSelectionScreenState();
}

class _RideSelectionScreenState extends State<RideSelectionScreen> {
  int _selected = 1; // Комфорт по умолчанию

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBloc, RideBlocState>(
      listener: (context, state) {
        if (state is RideSearchingState) {
          context.go('/searching');
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(children: [
          // ── Top bar ──────────────────────────────────────────────────────
          _TopBar(),
          // ── Map + Content ─────────────────────────────────────────────────
          Expanded(
            child: Stack(children: [
              // Карта с маршрутом А→Б
              const Positioned.fill(
                child: AppMapWidget(
                  center: kAlmatyCenter,
                  zoom: 13,
                  originPoint: AlmatyPoints.dostyk,
                  destinationPoint: AlmatyPoints.esentai,
                  showRoute: true,
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: SlideInUp(
                  duration: const Duration(milliseconds: 600),
                  child: _ContentPanel(
                    selected: _selected,
                    onTariffSelect: (i) {
                      // 💗 Тариф Pink — только для женщин
                      if (i == 4) {
                        final user = context.read<AuthService>().currentUser;
                        if (user == null || !user.isFemale) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: [
                                const Icon(Icons.woman_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(
                                  'ride.pink_error'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                )),
                              ]),
                              backgroundColor: const Color(0xFFFF69B4),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return; // Не меняем выбор
                        }
                      }
                      SoundService.selectionHaptic();
                      setState(() => _selected = i);
                      context.read<RideBloc>().add(TariffSelected(i));
                    },
                    onOrder: () async {
                      SoundService.mediumTap();
                      const prices = [1250.0, 1800.0, 3400.0, 4200.0, 1500.0];
                      const origins = [
                        'пр. Достык, 105',
                        'пр. Достык, 105',
                        'пр. Достык, 105',
                        'пр. Достык, 105',
                        'пр. Достык, 105',
                      ];
                      const dests = [
                        'ТРЦ Mega Alma-Ata',
                        'Esentai Tower',
                        'ул. Фурманова, 100',
                        'Аэропорт Алматы',
                        'мкр. Самал-2, 111',
                      ];
                      final tariffs = [
                        RideTariff.economy,
                        RideTariff.comfort,
                        RideTariff.business,
                        RideTariff.minivan,
                        RideTariff.pink,
                      ];

                      // Final Deep Logic Check for Pink
                      if (tariffs[_selected] == RideTariff.pink) {
                        final u = context.read<AuthService>().currentUser;
                        if (u == null || !u.isFemale) return;
                      }

                      // 💳 Сначала Kaspi оплата, потом поиск водителя
                      final paid = await KaspiPaymentDialog.show(
                        context,
                        amount: prices[_selected],
                        destination: dests[_selected],
                        driverName: 'Qayda Taxi',
                      );
                      if (paid == true && context.mounted) {
                        context.read<RideBloc>().add(RideRequested(
                              origin: origins[_selected],
                              destination: dests[_selected],
                              originPoint: AlmatyPoints.dostyk,
                              destinationPoint: AlmatyPoints.esentai,
                              tariff: tariffs[_selected],
                            ));
                      }
                    },
                  ),
                ),
              ),
            ]),
          ),
          AppBottomNavBar(currentIndex: 0, onTap: (i) {
            if (i == 0) context.go('/home');
            if (i == 1) context.go('/history');
            if (i == 2) context.go('/profile');
          }),
        ]),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
        boxShadow: context.colors.cardShadow,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 16, right: 16, bottom: 12,
      ),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.primary),
          onPressed: () => context.go('/home'),
          style: IconButton.styleFrom(
            backgroundColor: context.colors.primaryContainer,
            minimumSize: const Size(40, 40),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ride.select_title'.tr(),
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                  letterSpacing: -0.3)),
          Text('пр. Достык → Esentai Tower',
              style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text('~12 км',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary)),
        ),
      ]),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTariffSelect;
  final VoidCallback onOrder;
  const _ContentPanel({
    required this.selected,
    required this.onTariffSelect,
    required this.onOrder,
  });

  static const _tariffs = [
    _TariffData('Эконом', 'Accent / Rio (белые)', '4 мин', '1 250 ₸', 'ДЕШЕВЛЕ'),
    _TariffData('Комфорт', 'Camry 55/70 · K5', '6 мин', '1 800 ₸', 'ТОП-1'),
    _TariffData('Бизнес', 'S-Class · BMW 7', '9 мин', '3 400 ₸', 'PREMIUM'),
    _TariffData('Минивэн', 'Hyundai Staria', '12 мин', '4 200 ₸', 'ДЛЯ СЕМЬИ'),
    _TariffData('Pink', 'Водитель-женщина', '5 мин', '1 500 ₸', 'БЕЗОПАСНО'),
  ];

  @override
  Widget build(BuildContext context) {
    final tariff = _tariffs[selected];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: context.colors.elevatedShadow,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Label
          FadeInDown(
            child: Text('ride.select_class'.tr(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontFamily: 'Montserrat',
                    color: context.colors.onSurfaceVariant)),
          ),
          const SizedBox(height: 12),

          // Tariff cards
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tariffs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _TariffCard(
                data: _tariffs[i],
                index: i,
                isSelected: selected == i,
                onTap: () => onTariffSelect(i),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Route info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Row(children: [
              Column(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: context.colors.primary)),
                Container(width: 1, height: 28,
                    color: context.colors.outlineVariant,
                    margin: const EdgeInsets.symmetric(vertical: 3)),
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: context.colors.secondary)),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('пр. Достык, 105',
                        style: TextStyle(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text('Esentai Tower',
                        style: TextStyle(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(tariff.price,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.colors.primary,
                        letterSpacing: -0.5)),
                Text(tariff.eta,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // Action row
          Row(children: [
            // Payment button
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.outlineVariant),
                boxShadow: context.colors.cardShadow,
              ),
              child: Icon(Icons.credit_card_rounded,
                  color: context.colors.onSurfaceVariant, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onOrder,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: context.colors.brandGradientH,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: context.colors.primaryGlow,
                  ),
                  child: Center(
                    child: Text(
                      'ride.order_btn'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  final _TariffData data;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  const _TariffCard({
    required this.data,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = index == 0
        ? Icons.local_taxi_rounded          // Economy: yellow taxi
        : index == 1
            ? Icons.directions_car_rounded  // Comfort: standard car
            : index == 2
                ? Icons.car_rental_rounded  // Business: luxury/premium
                : index == 3
                    ? Icons.airport_shuttle_rounded // Minivan
                    : Icons.woman_rounded;  // Pink: female driver
    final accentColor = index == 0
        ? const Color(0xFFEAB308)           // Economy: amber
        : index == 1
            ? context.colors.primary        // Comfort: brand blue/purple
            : index == 2
                ? const Color(0xFF1E293B)   // Business: dark/black (premium)
                : index == 3
                    ? Colors.deepOrange     // Minivan: orange
                    : const Color(0xFFFF69B4); // Pink: hot pink

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : context.colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)]
              : context.colors.cardShadow,
        ),
        child: Stack(children: [
          if (isSelected)
            Positioned(
              top: -2, right: -2,
              child: Icon(Icons.check_circle_rounded,
                  color: accentColor, size: 18),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(data.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(data.car,
                  style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        context.colors.brandGradientH.createShader(bounds),
                    child: Text(data.price,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data.badge,
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? Colors.white
                                : context.colors.onSurfaceVariant)),
                  ),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _TariffData {
  final String name, car, eta, price, badge;
  const _TariffData(this.name, this.car, this.eta, this.price, this.badge);
}
