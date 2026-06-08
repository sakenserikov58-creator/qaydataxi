import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/blocs/driver/driver_bloc.dart';
import 'package:qayda_taxi_app/blocs/driver/driver_event_state.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/widgets/app_map_widget.dart';

/// DriverHomeScreen — Light Mode, полный DriverBloc.
/// Входящий заказ всплывает как BottomSheet.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    // ── КРИТИЧЕСКИЙ ФИX: автоматически переводим водителя в онлайн ──────────
    // Без этого DriverBloc остаётся в DriverOfflineState и никогда не слушает
    // SystemDispatcher().incomingOrders — заказ пассажира не доходит.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<DriverBloc>();
      if (bloc.state is DriverOfflineState) {
        bloc.add(const DriverGoOnline());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverBloc, DriverState>(
      listener: (context, state) {
        // Входящий заказ → BottomSheet
        if (state is DriverHasOrderState) {

          _showOrderSheet(context, state.order);
        }
        // Поездка завершена → краткий итог
        if (state is DriverTripDoneState) {
          _showTripSummary(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Карта ───────────────────────────────────────────────────────
              _DriverMap(state: state),

              // ── Top bar ─────────────────────────────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: _DriverTopBar(state: state),
              ),

              // ── Центральный контент ─────────────────────────────────────────
              if (state is DriverEnRouteState || state is DriverArrivedState ||
                  state is DriverInTripState)
                _TripStatusOverlay(state: state),

              // ── DEV: Switch to Passenger ──────────────────────────────────────────
              Positioned(
                left: 16,
                bottom: 340,
                child: _DevFabButton(
                  icon: Icons.swap_horiz_rounded,
                  bgColor: Colors.redAccent,
                  iconColor: Colors.white,
                  onTap: () async {
                    HapticFeedback.heavyImpact();
                    await context.read<AuthService>().switchRole(UserRole.passenger);
                    if (context.mounted) context.go('/splash');
                  },
                ),
              ),

              // ── Bottom panel ────────────────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _DriverBottomPanel(state: state),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderSheet(BuildContext ctx, RideOrder order) {
    showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _IncomingOrderSheet(
        order: order,
        onAccept: () {
          HapticFeedback.heavyImpact();
          Navigator.pop(sheetCtx);
          ctx.read<DriverBloc>().add(const DriverOrderAccepted());
        },
        onDecline: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(sheetCtx);
          ctx.read<DriverBloc>().add(const DriverOrderDeclined());
        },
      ),
    );
  }

  void _showTripSummary(BuildContext ctx, DriverTripDoneState state) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TripSummarySheet(
        state: state,
        onContinue: () {
          Navigator.pop(sheetCtx);
          ctx.read<DriverBloc>().continueOnline();
        },
      ),
    );
  }
}

// ─── Driver Map ───────────────────────────────────────────────────────────────

class _DriverMap extends StatelessWidget {
  final DriverState state;
  const _DriverMap({required this.state});

  @override
  Widget build(BuildContext context) {
    LatLng? origin;
    LatLng? destination;
    bool showRoute = false;

    if (state is DriverEnRouteState || state is DriverInTripState) {
      origin = kAlmatyCenter;
      destination = AlmatyPoints.esentai;
      showRoute = true;
    }

    return AppMapWidget(
      center: kAlmatyCenter,
      zoom: 14,
      driverMarkers: const [],
      originPoint: origin,
      destinationPoint: destination,
      showRoute: showRoute,
    );
  }
}

// ─── Driver Top Bar ───────────────────────────────────────────────────────────

class _DriverTopBar extends StatelessWidget {
  final DriverState state;
  const _DriverTopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final isOnline = state is! DriverOfflineState;

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
            left: 16, right: 16, bottom: 12,
          ),
          child: Row(children: [
            // Driver avatar + name
            GestureDetector(
              onTap: () => context.push('/driver/profile'),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: context.colors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.name ?? 'Водитель',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface)),
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? context.colors.tertiary : context.colors.outlineVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'В сети' : 'Не в сети',
                  style: TextStyle(
                      fontSize: 12,
                      color: isOnline
                          ? context.colors.tertiary
                          : context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ]),
            const Spacer(),
            // Rating if online
            if (state is DriverOnlineState)
              _StatChip(
                '⭐ ${user?.rating.toStringAsFixed(2) ?? '4.97'}',
                context.colors.tertiary,
              ),
            const SizedBox(width: 8),
            // Toggle online/offline
            _OnlineToggle(
              isOnline: isOnline,
              onChanged: (v) {
                HapticFeedback.mediumImpact();
                if (v) {
                  context.read<DriverBloc>().add(const DriverGoOnline());
                } else {
                  context.read<DriverBloc>().add(const DriverGoOffline());
                }
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;
  const _OnlineToggle({required this.isOnline, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isOnline ? context.colors.brandGradientH : null,
          color: isOnline ? null : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isOnline ? context.colors.primaryGlow : null,
        ),
        child: Text(
          isOnline ? 'В СЕТИ' : 'ОФФЛАЙН',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isOnline ? Colors.white : context.colors.onSurface),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _DriverBottomPanel extends StatelessWidget {
  final DriverState state;
  const _DriverBottomPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: context.colors.elevatedShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, DriverState state) {
    if (state is DriverOfflineState) {
      return _OfflineContent(
        onGoOnline: () {
          HapticFeedback.mediumImpact();
          context.read<DriverBloc>().add(const DriverGoOnline());
        },
      );
    }
    if (state is DriverOnlineState) {
      return _OnlineContent(state: state);
    }
    if (state is DriverEnRouteState) {
      return _EnRouteContent(state: state, onArrived: () {
        context.read<DriverBloc>().add(const DriverArrivedAtPickup());
      });
    }
    if (state is DriverArrivedState) {
      return _ArrivedContent(state: state, onStart: () {
        HapticFeedback.mediumImpact();
        context.read<DriverBloc>().add(const DriverTripStarted());
      });
    }
    if (state is DriverInTripState) {
      return _InTripContent(state: state);
    }
    return const SizedBox.shrink();
  }
}

class _OfflineContent extends StatelessWidget {
  final VoidCallback onGoOnline;
  const _OfflineContent({required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Handle(),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Column(children: [
          Icon(Icons.power_settings_new_rounded,
              color: context.colors.onSurfaceVariant, size: 48),
          const SizedBox(height: 12),
          Text('Вы не в сети',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface)),
          const SizedBox(height: 6),
          Text('Нажмите кнопку, чтобы начать\nполучать заказы',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onGoOnline,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradientH,
                borderRadius: BorderRadius.circular(14),
                boxShadow: context.colors.primaryGlow,
              ),
              child: const Center(
                child: Text('🟢  Выйти в сеть',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _OnlineContent extends StatelessWidget {
  final DriverOnlineState state;
  const _OnlineContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Handle(),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _EarningsTile(
            label: 'Сегодня',
            value: '${state.todayEarnings.toStringAsFixed(0)} ₸',
            icon: Icons.account_balance_wallet_rounded,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EarningsTile(
            label: 'Поездок',
            value: '${state.tripsCount}',
            icon: Icons.directions_car_rounded,
            color: context.colors.tertiary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EarningsTile(
            label: 'Рейтинг',
            value: state.rating.toStringAsFixed(2),
            icon: Icons.star_rounded,
            color: context.colors.secondary,
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _SearchingAnimation(),
    ]);
  }
}

class _EarningsTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _EarningsTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: context.colors.onSurface)),
        Text(label,
            style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant)),
      ]),
    );
  }
}

class _SearchingAnimation extends StatefulWidget {
  @override
  State<_SearchingAnimation> createState() => _SearchingAnimationState();
}

class _SearchingAnimationState extends State<_SearchingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.primaryContainer
              .withValues(alpha: 0.5 + 0.5 * _ctrl.value),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text('Ожидаем входящие заказы...',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary)),
        ]),
      ),
    );
  }
}

class _EnRouteContent extends StatelessWidget {
  final DriverEnRouteState state;
  final VoidCallback onArrived;
  const _EnRouteContent({required this.state, required this.onArrived});

  @override
  Widget build(BuildContext context) {
    final minutes = state.etaSeconds ~/ 60;
    final seconds = state.etaSeconds % 60;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Handle(),
      const SizedBox(height: 14),
      Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.navigation_rounded, color: context.colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Едем к клиенту',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: context.colors.onSurface)),
            Text(state.order.origin,
                style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$minutes:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.colors.primary)),
          Text('осталось', style: TextStyle(fontSize: 11,
              color: context.colors.onSurfaceVariant)),
        ]),
      ]),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: onArrived,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Center(
            child: Text('Я прибыл к точке подачи',
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: context.colors.onSurface, fontSize: 15)),
          ),
        ),
      ),
    ]);
  }
}

class _ArrivedContent extends StatelessWidget {
  final DriverArrivedState state;
  final VoidCallback onStart;
  const _ArrivedContent({required this.state, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Handle(),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.tertiary.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.location_on_rounded, color: context.colors.tertiary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Вы прибыли!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: context.colors.onSurface)),
              Text(state.order.origin,
                  style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onStart,
        child: Container(
          width: double.infinity, height: 56,
          decoration: BoxDecoration(
            gradient: context.colors.brandGradientH,
            borderRadius: BorderRadius.circular(14),
            boxShadow: context.colors.primaryGlow,
          ),
          child: const Center(
            child: Text('▶  Начать поездку',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ),
      ),
    ]);
  }
}

class _InTripContent extends StatelessWidget {
  final DriverInTripState state;
  const _InTripContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final min = state.elapsedSeconds ~/ 60;
    final sec = state.elapsedSeconds % 60;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Handle(),
      const SizedBox(height: 14),
      Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: context.colors.brandGradient,
            shape: BoxShape.circle,
            boxShadow: context.colors.primaryGlow,
          ),
          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Поездка идёт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: context.colors.onSurface)),
            Text('До: ${state.order.destination}',
                style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Text('$min:${sec.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                color: context.colors.primary)),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Маршрут: ${state.order.origin} → ${state.order.destination}',
                style: TextStyle(fontSize: 11, color: context.colors.primary,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            Text(state.order.formattedPrice,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                    color: context.colors.primary)),
          ],
        ),
      ),
    ]);
  }
}

// ─── Trip Status Overlay ──────────────────────────────────────────────────────

class _TripStatusOverlay extends StatelessWidget {
  final DriverState state;
  const _TripStatusOverlay({required this.state});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // map shows status
}

// ─── Incoming Order Bottom Sheet ──────────────────────────────────────────────

class _IncomingOrderSheet extends StatelessWidget {
  final RideOrder order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _IncomingOrderSheet({
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: context.colors.elevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accent top bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: context.colors.brandGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: context.colors.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: context.colors.primaryGlow,
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('НОВЫЙ ЗАКАЗ',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: context.colors.primary)),
                      Text(order.formattedPrice,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: context.colors.onSurface)),
                    ]),
                  ),
                  // Tariff badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(order.tariff.name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary)),
                  ),
                ]),
                const SizedBox(height: 16),

                // Route
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                  child: Row(children: [
                    Column(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: context.colors.primary)),
                      Container(width: 1, height: 32,
                          color: context.colors.outlineVariant,
                          margin: const EdgeInsets.symmetric(vertical: 4)),
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: context.colors.secondary)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.origin,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: context.colors.onSurface),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text(order.destination,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: context.colors.onSurface),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Accept / Decline
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onDecline,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.colors.outlineVariant),
                        ),
                        child: Center(
                          child: Text('Отклонить',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.onSurfaceVariant,
                                  fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: onAccept,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: context.colors.brandGradientH,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: context.colors.primaryGlow,
                        ),
                        child: const Center(
                          child: Text('✓  Принять',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAB для Dev ─────────────────────────────────────────────────────────────

class _DevFabButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? bgColor;
  final Color? iconColor;

  const _DevFabButton({
    required this.icon, 
    required this.onTap,
    this.bgColor,
    this.iconColor,
  }) : isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor ?? context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: context.colors.elevatedShadow,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.colors.primary),
                ),
              )
            : Icon(icon, color: iconColor ?? context.colors.primary, size: 22),
      ),
    );
  }
}

// ─── Trip Summary Sheet ───────────────────────────────────────────────────────

class _TripSummarySheet extends StatelessWidget {
  final DriverTripDoneState state;
  final VoidCallback onContinue;
  const _TripSummarySheet({required this.state, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: context.colors.elevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: context.colors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: context.colors.primaryGlow,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Поездка завершена!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                  color: context.colors.onSurface)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: context.colors.brandGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: context.colors.primaryGlow,
            ),
            child: Text(
              '+${state.earnings.toStringAsFixed(0)} ₸',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text('Всего сегодня: ${state.totalEarnings.toStringAsFixed(0)} ₸ · ${state.totalTrips} поездок',
              style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradientH,
                borderRadius: BorderRadius.circular(14),
                boxShadow: context.colors.primaryGlow,
              ),
              child: const Center(
                child: Text('Продолжить работу',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class Handle extends StatelessWidget {
  const Handle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: context.colors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
