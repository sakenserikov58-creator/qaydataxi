import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/widgets/app_top_bar.dart';
import 'package:qayda_taxi_app/widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    HapticFeedback.mediumImpact();
    setState(() => _editingName = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Имя обновлено',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppTopBar(title: 'profile.title'.tr()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // Hero
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('profile.cabinet'.tr(),
                style: TextStyle(
                    fontSize: 9,
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            // Editable name row
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: _editingName
                    ? TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            height: 1.05,
                            color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ваше имя',
                          hintStyle: TextStyle(color: context.colors.onSurfaceVariant),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _saveName(),
                      )
                    : Text(
                        user?.name ?? 'Пользователь',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.05),
                      ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_editingName) { _saveName(); } else { setState(() => _editingName = true); }
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _editingName ? Icons.check_rounded : Icons.edit_rounded,
                    color: context.colors.primary,
                    size: 16,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(user?.phone ?? '—',
                style: TextStyle(
                    color: context.colors.primaryFixed,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            // Rating + Premium row
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFEAB308).withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                  const SizedBox(width: 4),
                  const Text('4.95',
                      style: TextStyle(
                          color: Color(0xFFEAB308),
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                  Text(' • ${_getPassengerRatingLabel(context)}',
                      style: TextStyle(
                          color: context.colors.onSurfaceVariant, fontSize: 11)),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                      color: context.colors.outlineVariant.withValues(alpha: 0.15)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.stars_rounded, color: context.colors.secondary, size: 14),
                  const SizedBox(width: 4),
                  Text('Premium',
                      style: TextStyle(
                          color: context.colors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ]),
              ),
            ]),
          ]),
          const SizedBox(height: 24),

          // ── Стать водителем ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/profile/become-driver');
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: context.colors.brandGradientH,
                borderRadius: BorderRadius.circular(20),
                boxShadow: context.colors.primaryGlow,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_taxi_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('profile.become_driver'.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                    Text('profile.become_driver_subtitle'.tr(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12)),
                  ],
                )),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Bento
          Row(children: [
            Expanded(
              child: _BentoCard(
                icon: Icons.credit_card_outlined,
                iconColor: context.colors.primary,
                title: 'Мои карты',
                subtitle: 'Kaspi Gold •••• 8842',
                onTap: () => context.push('/profile/payment'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoCard(
                icon: Icons.sell_outlined,
                iconColor: context.colors.secondary,
                title: 'Промокоды',
                subtitle: '2 активных бонуса',
                onTap: () => context.push('/profile/promo'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _ListItem(
            icon: Icons.support_agent_outlined,
            color: context.colors.tertiary,
            title: 'Поддержка 24/7',
            subtitle: 'Помощь в любой ситуации',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ListItem(
            icon: Icons.settings_outlined,
            color: context.colors.onSurfaceVariant,
            title: 'Настройки',
            subtitle: 'Язык, уведомления, приватность',
            onTap: () => context.push('/profile/settings'),
          ),
          const SizedBox(height: 32),
          // Logout
          GestureDetector(
            onTap: () {
              context.read<AuthService>().logout();
              context.go('/login');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: context.colors.outlineVariant.withValues(alpha: 0.1)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout, color: context.colors.error, size: 20),
                const SizedBox(width: 10),
                Text('profile.logout'.tr(),
                    style: TextStyle(
                        color: context.colors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getPassengerRatingLabel(BuildContext context) {
    final isKk = context.locale.languageCode == 'kk';
    return isKk ? 'Жақсы жолаушы' : 'Хороший пассажир';
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Icon(Icons.arrow_forward,
                    color: context.colors.onSurfaceVariant, size: 17),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(subtitle,
                    style: TextStyle(
                        color: context.colors.onSurfaceVariant, fontSize: 11)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  const _ListItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text(subtitle,
                  style: TextStyle(
                      color: context.colors.onSurfaceVariant, fontSize: 11)),
            ]),
          ),
          Icon(Icons.chevron_right,
              color: context.colors.outlineVariant, size: 20),
        ]),
      ),
    );
  }
}
