import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showMenuButton;
  final bool showAvatar;
  final VoidCallback? onLeadingTap;

  const AppTopBar({
    super.key,
    this.title = 'QAYDA TAXI',
    this.showBackButton = false,
    this.showMenuButton = true,
    this.showAvatar = true,
    this.onLeadingTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: context.colors.background.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: onLeadingTap ?? () => Navigator.of(context).pop(),
                  child: Icon(Icons.arrow_back, color: context.colors.primary),
                )
              else if (showMenuButton)
                GestureDetector(
                  onTap: onLeadingTap,
                  child: Icon(Icons.menu, color: context.colors.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (showAvatar)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                    color: context.colors.surfaceContainerHighest,
                  ),
                  child: Icon(Icons.person, color: context.colors.onSurfaceVariant, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
