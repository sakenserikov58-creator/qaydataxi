import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/services/location_service.dart';
import 'package:qayda_taxi_app/widgets/app_map_widget.dart';
import 'package:qayda_taxi_app/widgets/bottom_nav_bar.dart';

/// HomeScreen — Light Mode (белый фон, карточки с тенями)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIndex = 0;
  final _mapController = MapController();
  bool _locating = false;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some animations for the latlong and zoom
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    setState(() => _navIndex = i);
    switch (i) {
      case 0: context.go('/home'); break;
      case 1: context.go('/history'); break;
      case 2: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final driverMarkers = generateNearbyDrivers();

    return Scaffold(
      backgroundColor: context.colors.background,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Карта (OSM) ────────────────────────────────────────────────────
          AppMapWidget(
            center: kAlmatyCenter,
            zoom: 14,
            driverMarkers: driverMarkers,
            controller: _mapController,
          ),

          // ── Top bar ────────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopBar(userName: user?.name ?? 'Пользователь'),
          ),

          // ── FAB: my location ────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 340,
            child: _FabButton(
              icon: _locating ? Icons.my_location_rounded : Icons.gps_fixed_rounded,
              isLoading: _locating,
              onTap: () async {
                HapticFeedback.lightImpact();
                setState(() => _locating = true);
                
                // ── REAL GPS INJECTION ─────────────────────────────────────
                final pos = await LocationService.requestAndGetPosition(context);
                
                if (mounted) {
                  setState(() => _locating = false);
                  if (pos != null) {
                    _animatedMapMove(pos, 16);
                  }
                }
              },
            ),
          ),

          // ── DEV: Switch to Driver ──────────────────────────────────────────
          Positioned(
            left: 16,
            bottom: 340,
            child: _FabButton(
              icon: Icons.swap_horiz_rounded,
              bgColor: Colors.redAccent,
              iconColor: Colors.white,
              onTap: () async {
                HapticFeedback.heavyImpact();
                await context.read<AuthService>().switchRole(UserRole.driver);
                if (context.mounted) context.go('/splash');
              },
            ),
          ),

          // ── Bottom sheet + nav ────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: _BottomSheet(
                    onOrder: () {
                      HapticFeedback.mediumImpact();
                      context.go('/ride-select');
                    },
                  ),
                ),
                AppBottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String userName;
  const _TopBar({required this.userName});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.xl, sigmaY: AppBlur.xl),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.topBarColor,
            border: Border(
              bottom: BorderSide(
                color: context.colors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            bottom: 14,
          ),
          child: Row(children: [
            // Brand
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: context.colors.primaryGlow,
              ),
              child: const Icon(Icons.local_taxi_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QAYDA',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: context.colors.onSurface)),
              Text('Добро пожаловать, ${userName.split(' ').first}',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
            ]),
            const Spacer(),
            // Notifications
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
                boxShadow: context.colors.cardShadow,
              ),
              child: Icon(Icons.notifications_outlined,
                  color: context.colors.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 8),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _FabButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? bgColor;
  final Color? iconColor;

  const _FabButton({
    required this.icon, 
    required this.onTap, 
    this.isLoading = false,
    this.bgColor,
    this.iconColor,
  });

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

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final VoidCallback onOrder;
  const _BottomSheet({required this.onOrder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: context.colors.elevatedShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Куда поедем?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 14),

          // Search field
          _SearchField(
            onTap: () => context.go('/ride-select'),
          ),
          const SizedBox(height: 12),

          // Quick destinations
          Row(children: [
            Expanded(child: _QuickChip(
              icon: Icons.home_rounded,
              label: 'Домой',
              sublabel: 'пр. Аль-Фараби, 77',
              color: context.colors.primary,
              onTap: () {},
            )),
            const SizedBox(width: 10),
            Expanded(child: _QuickChip(
              icon: Icons.work_rounded,
              label: 'Работа',
              sublabel: 'ул. Фурманова, 100',
              color: context.colors.secondary,
              onTap: () {},
            )),
          ]),
          const SizedBox(height: 10),

          // Last rides
          _HistoryItem(
            icon: Icons.history_rounded,
            title: 'ТРЦ Dostyk Plaza',
            subtitle: 'мкр. Самал-2, 111',
            color: context.colors.tertiary,
            onTap: () {},
          ),
          const SizedBox(height: 12),

          // Popular destinations chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PopChip('🏔 Медеу', context.colors.tertiary, () {}),
                const SizedBox(width: 8),
                _PopChip('✈️ Аэропорт', context.colors.secondary, () {}),
                const SizedBox(width: 8),
                _PopChip('🛍 MEGA', context.colors.primary, () {}),
                const SizedBox(width: 8),
                _PopChip('🏥 Больница', context.colors.tertiary, () {}),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // CTA
          GestureDetector(
            onTap: onOrder,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradientH,
                borderRadius: BorderRadius.circular(16),
                boxShadow: context.colors.primaryGlow,
              ),
              child: const Center(
                child: Text(
                  'Заказать поездку',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, color: context.colors.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            'Куда вы едете?',
            style: TextStyle(
              color: context.colors.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label,
      required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text(sublabel,
                    style: TextStyle(
                        color: context.colors.onSurfaceVariant, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _HistoryItem({required this.icon, required this.title,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(
                        color: context.colors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant, size: 18),
        ]),
      ),
    );
  }
}

class _PopChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PopChip(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
