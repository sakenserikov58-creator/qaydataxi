import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_bloc.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_event_state.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/services/ride_persistence.dart';
import 'package:qayda_taxi_app/widgets/app_map_widget.dart';

/// SearchingDriverScreen — Blurred map + animated driver marker + error handling.
/// Использует AnimatedDriverMap для плавного движения маркера водителя.
class SearchingDriverScreen extends StatelessWidget {
  const SearchingDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RideBloc, RideBlocState>(
      listenWhen: (prev, curr) =>
          curr is RideInProgressBlocState ||
          curr is RideIdleState ||
          curr is RideCompletedState ||
          curr is RideErrorBlocState,
      listener: (context, state) {
        if (state is RideInProgressBlocState) {
          context.go('/ride-active');
        }
        if (state is RideIdleState) {
          context.go('/home');
        }
        if (state is RideCompletedState) {
          context.go('/rate-trip');
        }
        if (state is RideErrorBlocState) {
          _showErrorSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        // Извлекаем позицию водителя если есть
        LatLng? driverPos;
        if (state is RideDriverFoundState) {
          driverPos = LatLng(state.driverLat, state.driverLng);
          // Сохраняем прогресс поездки
          RidePersistence.save(state.order);
        }
        if (state is RideSearchingState) {
          RidePersistence.save(state.order);
        }

        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Анимированная карта с водителем ─────────────────────────
              AppMapWidget(
                driverPosition: driverPos,
                isBlurred: true,
              ),

              // ── Top bar ──────────────────────────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: _SearchTopBar(state: state),
              ),

              // ── Центральная анимация ─────────────────────────────────────
              Center(child: _CenterContent(state: state)),

              // ── Нижняя панель ────────────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _BottomInfoPanel(state: state),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.error,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Повторить',
          textColor: Colors.white,
          onPressed: () {
            // Retry: перезапустить поиск с теми же данными
            context.go('/ride-select');
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _SearchTopBar extends StatelessWidget {
  final RideBlocState state;
  const _SearchTopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final isFound =
        state is RideDriverFoundState || state is RideDriverArrivedState;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.xl, sigmaY: AppBlur.xl),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.topBarColor,
            border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20, right: 20, bottom: 14,
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_taxi_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('QAYDA',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: context.colors.onSurface)),
            const Spacer(),
            _StatusBadge(isFound: isFound),
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatefulWidget {
  final bool isFound;
  const _StatusBadge({required this.isFound});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isFound ? context.colors.tertiary : context.colors.primary;
    final label = widget.isFound ? 'НАЙДЕН' : 'ПОИСК';
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
              color: color.withValues(alpha: 0.3 + 0.2 * _ctrl.value)),
        ),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.4 + 0.6 * _ctrl.value)),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}

// ─── Center Content ───────────────────────────────────────────────────────────

class _CenterContent extends StatefulWidget {
  final RideBlocState state;
  const _CenterContent({required this.state});

  @override
  State<_CenterContent> createState() => _CenterContentState();
}

class _CenterContentState extends State<_CenterContent>
    with TickerProviderStateMixin {
  late final AnimationController _ping;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _ping = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ping.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFound = widget.state is RideDriverFoundState ||
        widget.state is RideDriverArrivedState;
    final color = isFound ? context.colors.tertiary : context.colors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220, height: 220,
          child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(
              animation: _ping,
              builder: (_, __) => Transform.scale(
                scale: 1 + _ping.value * 0.6,
                child: Opacity(
                  opacity: (1 - _ping.value).clamp(0, 1) * 0.55,
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15)),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color
                        .withValues(alpha: 0.07 + 0.07 * _pulse.value)),
              ),
            ),
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
                boxShadow: context.colors.elevatedShadow,
                border: Border.all(
                    color: color.withValues(alpha: 0.2), width: 2),
              ),
              child: Icon(
                isFound
                    ? Icons.directions_car_rounded
                    : Icons.local_taxi_rounded,
                color: color,
                size: 42,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildStatusText(widget.state),
        ),
        const SizedBox(height: 20),
        if (widget.state is RideDriverFoundState)
          _EtaCard(state: widget.state as RideDriverFoundState),
        if (widget.state is RideDriverArrivedState)
          _ArrivedCard(state: widget.state as RideDriverArrivedState),
      ],
    );
  }

  Widget _buildStatusText(RideBlocState state) {
    if (state is RideSearchingState) {
      return Column(key: const ValueKey('searching'), children: [
        Text('Ищем водителя...',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: context.colors.onSurface)),
        const SizedBox(height: 8),
        Text('Подбираем лучший вариант для вас',
            style: TextStyle(
                color: context.colors.onSurfaceVariant, fontSize: 14)),
      ]);
    }
    if (state is RideDriverFoundState) {
      return Column(key: const ValueKey('found'), children: [
        Text('Водитель найден! 🎉',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: context.colors.onSurface)),
        const SizedBox(height: 8),
        Text('${state.driver.name} едет к вам',
            style: TextStyle(
                color: context.colors.onSurfaceVariant, fontSize: 14)),
      ]);
    }
    if (state is RideDriverArrivedState) {
      return Column(key: const ValueKey('arrived'), children: [
        Text('Водитель прибыл! 📍',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: context.colors.onSurface)),
        const SizedBox(height: 8),
        Text('${state.driver.name} ждёт вас',
            style: TextStyle(
                color: context.colors.tertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ]);
    }
    return const SizedBox.shrink();
  }
}

// ─── ETA & Arrived Cards ──────────────────────────────────────────────────────

class _EtaCard extends StatelessWidget {
  final RideDriverFoundState state;
  const _EtaCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.colors.elevatedShadow,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                gradient: context.colors.brandGradient, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.driver.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: context.colors.onSurface)),
              Text(state.driver.vehicleInfo,
                  style: TextStyle(
                      fontSize: 12, color: context.colors.onSurfaceVariant)),
              Row(children: [
                Icon(Icons.star_rounded, color: context.colors.tertiary, size: 14),
                const SizedBox(width: 2),
                Text(state.driver.displayRating,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.tertiary)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(state.etaFormatted,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: context.colors.primary)),
            Text('до подачи',
                style: TextStyle(
                    fontSize: 11, color: context.colors.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}

class _ArrivedCard extends StatelessWidget {
  final RideDriverArrivedState state;
  const _ArrivedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.tertiary.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.location_on_rounded, color: context.colors.tertiary, size: 24),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Водитель у вас',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                    fontSize: 14)),
            Text('${state.driver.vehicle} · ${state.driver.plate}',
                style: TextStyle(
                    fontSize: 12, color: context.colors.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _BottomInfoPanel extends StatelessWidget {
  final RideBlocState state;
  const _BottomInfoPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    RideOrder? order;
    if (state is RideSearchingState)     order = (state as RideSearchingState).order;
    if (state is RideDriverFoundState)   order = (state as RideDriverFoundState).order;
    if (state is RideDriverArrivedState) order = (state as RideDriverArrivedState).order;

    final canCancel = state is RideSearchingState;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (order != null) _RouteChip(order: order),
          if (canCancel) ...[
            const SizedBox(height: 10),
            _CancelButton(onCancel: () {
              HapticFeedback.lightImpact();
              context.read<RideBloc>().add(const RideCancelRequested());
              RidePersistence.clear();
            }),
          ],
        ]),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onCancel;
  const _CancelButton({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.outlineVariant),
          boxShadow: context.colors.cardShadow,
        ),
        child: Center(
          child: Text('Отменить поездку',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                  fontSize: 15)),
        ),
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  final RideOrder order;
  const _RouteChip({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: context.colors.cardShadow,
      ),
      child: Row(children: [
        Icon(Icons.route_rounded, color: context.colors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${order.origin} → ${order.destination}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(order.formattedPrice,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: context.colors.primary)),
        ),
      ]),
    );
  }
}
