import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/widgets/app_map_widget.dart';
import 'package:qayda_taxi_app/widgets/shimmer_loader.dart' as import_shimmer;
import 'package:qayda_taxi_app/widgets/trip_route_display.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  bool _isLoading = true;
  String _filter = 'Все';
  List<_TripData> trips = [];
  List<_TripData> get _filtered => _filter == 'Все'
      ? trips
      : trips.where((t) => t.tier == _filter).toList();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          trips = [
            const _TripData(
              date: '21 АПРЕЛЯ, 22:15',
              tier: 'Бизнес',
              price: '2 850 ₸',
              origin: 'ул. Абылай Хана, 79',
              dest: 'ТРЦ Dostyk Plaza, Алматы',
              driver: 'Елена',
              rating: 5,
              km: '8.2 км',
              duration: '18 мин',
              originLatLng: LatLng(43.2580, 76.9290),
              destLatLng: LatLng(43.2200, 76.9500),
            ),
            const _TripData(
              date: '19 АПРЕЛЯ, 09:40',
              tier: 'Комфорт',
              price: '1 600 ₸',
              origin: 'Мкр. Орбита-3, 21',
              dest: 'БЦ Нурлы Тау, Медеу',
              driver: 'Арман',
              rating: 4,
              km: '6.7 км',
              duration: '14 мин',
              originLatLng: LatLng(43.2480, 76.8700),
              destLatLng: LatLng(43.2319, 76.9425),
            ),
            const _TripData(
              date: '17 АПРЕЛЯ, 14:20',
              tier: 'Бизнес',
              price: '4 200 ₸',
              origin: 'Аэропорт Алматы (ALA)',
              dest: 'Отель Ritz-Carlton, Есентай',
              driver: 'Мадияр',
              rating: 5,
              km: '23.4 км',
              duration: '41 мин',
              originLatLng: LatLng(43.3521, 77.0405),
              destLatLng: LatLng(43.2138, 76.9291),
            ),
            const _TripData(
              date: '15 АПРЕЛЯ, 11:00',
              tier: 'Эконом',
              price: '980 ₸',
              origin: 'пр. Сейфуллина, 458',
              dest: 'MEGA, Алатауский р-н',
              driver: 'Серик',
              rating: 4,
              km: '4.1 км',
              duration: '9 мин',
              originLatLng: LatLng(43.2580, 76.9290),
              destLatLng: LatLng(43.2200, 76.8800),
            ),
          ];
        });
      }
    });
  }

  void _openDetail(_TripData trip) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDetailsSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Text('История',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: context.colors.onSurface)),
            const SizedBox(height: 4),
            Text('Ваши поездки по Алматы',
                style: TextStyle(
                    color: context.colors.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 20),

            // ── Filters ─────────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Все', 'Эконом', 'Комфорт', 'Бизнес']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 7),
                              decoration: BoxDecoration(
                                color: _filter == f
                                    ? context.colors.primary
                                    : context.colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                    color: _filter == f
                                        ? context.colors.primary
                                        : context.colors.outlineVariant),
                              ),
                              child: Text(f,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _filter == f
                                          ? Colors.white
                                          : context.colors.onSurface)),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Trip list ─────────────────────────────────────────────────────
            if (_isLoading)
              ...List.generate(
                3,
                (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: import_shimmer.ShimmerLoader(
                      width: double.infinity, height: 170, borderRadius: 24),
                ),
              )
            else if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.outlineVariant),
                      ),
                      child: Icon(Icons.history_rounded, size: 44,
                          color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    Text('Нет поездок',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: context.colors.onSurface)),
                    const SizedBox(height: 6),
                    Text('Ни одной поездки в выбранной категории',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.colors.onSurfaceVariant)),
                  ]),
                ),
              )
            else
              ..._filtered.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () => _openDetail(t),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: context.colors.cardShadow,
                        border:
                            Border.all(color: context.colors.outlineVariant),
                      ),
                      child: Column(children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tier icon
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: context.colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_tierIcon(t.tier),
                                    size: 20, color: context.colors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.date,
                                          style: TextStyle(
                                              fontSize: 10,
                                              letterSpacing: 1.2,
                                              fontWeight: FontWeight.w700,
                                              color: context
                                                  .colors.onSurfaceVariant)),
                                      const SizedBox(height: 3),
                                      Text(t.tier,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: context.colors.onSurface)),
                                    ]),
                              ),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(t.price,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: context.colors.primary)),
                                    const SizedBox(height: 4),
                                    _PaidBadge(),
                                  ]),
                            ]),
                        const SizedBox(height: 14),
                        TripRouteDisplay(
                            origin: t.origin, destination: t.dest),
                        const SizedBox(height: 12),
                        Divider(
                            height: 1,
                            color: context.colors.outlineVariant
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Row(children: [
                          _StarRow(t.rating),
                          const SizedBox(width: 8),
                          Container(
                            width: 1, height: 12,
                            color: context.colors.outlineVariant,
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.person_rounded,
                              size: 14,
                              color: context.colors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(t.driver,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.onSurface)),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: context.colors.onSurfaceVariant),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _tierIcon(String tier) {
    switch (tier) {
      case 'Бизнес': return Icons.car_rental_rounded;
      case 'Комфорт': return Icons.directions_car_rounded;
      case 'Минивэн': return Icons.airport_shuttle_rounded;
      default: return Icons.local_taxi_rounded;
    }
  }
}

// ─── Trip Details Bottom Sheet ────────────────────────────────────────────────

class _TripDetailsSheet extends StatelessWidget {
  final _TripData trip;
  const _TripDetailsSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: context.colors.elevatedShadow,
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ────────────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          color: context.colors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Детали поездки',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onSurface)),
                            Text(trip.date,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.onSurfaceVariant,
                                    letterSpacing: 1.0)),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Mini Map ─────────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 180,
                      child: AppMapWidget(
                        center: trip.originLatLng,
                        zoom: 12.5,
                        originPoint: trip.originLatLng,
                        destinationPoint: trip.destLatLng,
                        showRoute: true,
                        autoCenter: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Route ────────────────────────────────────────────────
                  TripRouteDisplay(origin: trip.origin, destination: trip.dest),
                  const SizedBox(height: 20),

                  // ── Stats ─────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Дистанция', value: trip.km,
                            icon: Icons.route_rounded),
                        _Divider(),
                        _StatItem(label: 'Время', value: trip.duration,
                            icon: Icons.timer_rounded),
                        _Divider(),
                        _StatItem(label: 'Тариф', value: trip.tier,
                            icon: Icons.local_taxi_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Price Row ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: context.colors.brandGradientH,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Итоговая стоимость',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text(trip.price,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                        ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Driver ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: context.colors.brandGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip.driver,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: context.colors.onSurface)),
                            const SizedBox(height: 2),
                            _StarRow(trip.rating, showLabel: true),
                          ]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ОПЛАЧЕНО',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: Color(0xFF22C55E))),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── CTA ───────────────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: context.colors.outlineVariant),
                      ),
                      child: Center(
                        child: Text('Закрыть',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: context.colors.onSurface)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _PaidBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: const Text('Оплачено',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Color(0xFF22C55E))),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final bool showLabel;
  const _StarRow(this.rating, {this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ...List.generate(
          5,
          (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: const Color(0xFFEAB308),
              )),
      if (showLabel) ...[
        const SizedBox(width: 4),
        Text('$rating.0',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface)),
      ],
    ]);
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 18, color: context.colors.primary),
      const SizedBox(height: 6),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 40, color: context.colors.outlineVariant);
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _TripData {
  final String date, tier, price, origin, dest, driver, km, duration;
  final int rating;
  final LatLng originLatLng, destLatLng;

  const _TripData({
    required this.date, required this.tier, required this.price,
    required this.origin, required this.dest, required this.driver,
    required this.rating, required this.km, required this.duration,
    required this.originLatLng, required this.destLatLng,
  });
}
