import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/core/theme.dart';

/// SplashScreen — pixel-exact from splash_screen/code.html
///
/// Layout:
///   Background: map image opacity-20, grayscale, brightness-50, scale-110
///   Overlay: bg-gradient-to-b from-background via-transparent to-background
///   Center:
///     - Glowing ring: absolute -inset-16 glass-glow blur-3xl opacity-60
///     - Logo shell: w-32 h-32 rounded-full bg-surface-container-highest/40
///                   backdrop-blur-3xl border border-outline-variant/15
///     - Icon: local_taxi text-5xl brand-gradient (gradient text clip)
///   Typography:
///     h1: text-4xl font-black tracking-tighter text-zinc-50 → "MIDNIGHT"
///     p:  text-sm tracking-[0.2em] text-on-surface-variant uppercase
///         → "Премиальный сервис • Алматы"
///   Loading bar: w-48 h-[2px] bg-surface-container-highest
///     inner: absolute w-1/3 bg-primary animate loading 2s infinite linear
///     @keyframes: 0%{translateX(-100%)} 100%{translateX(300%)}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadCtrl;
  late final Animation<double> _loadAnim;

  @override
  void initState() {
    super.initState();
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadAnim = Tween<double>(begin: -1.0, end: 3.0).animate(_loadCtrl);

    // Auto-navigate to login after display
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Map background ─────────────────────────────────────────────────
          // opacity-20, grayscale, brightness-50, scale-110
          Transform.scale(
            scale: 1.1,
            child: Opacity(
              opacity: 0.2,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  // grayscale + brightness-50 (multiply values by 0.5)
                  0.107, 0.358, 0.036, 0, -40,
                  0.107, 0.358, 0.036, 0, -40,
                  0.107, 0.358, 0.036, 0, -40,
                  0,     0,     0,     1,   0,
                ]),
                child: Container(
                  color: const Color(0xFF1A191B),
                  child: CustomPaint(painter: _MinimalMapPainter()),
                ),
              ),
            ),
          ),

          // ── Tonal gradient overlay ─────────────────────────────────────────
          // bg-gradient-to-b from-background via-transparent to-background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colors.background,
                  Colors.transparent,
                  context.colors.background,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Logo cluster
                _LogoCluster(),
                const SizedBox(height: 48),
                // Typography cluster
                _Typography(),
                const SizedBox(height: 48),
                // Loading bar — w-48 h-[2px]
                _LoadingBar(animation: _loadAnim),
                const Spacer(),
                // Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Text(
                    'КОНФИДЕНЦИАЛЬНОСТЬ ОБЕСПЕЧЕНА',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3 * 10,
                      color: Color(0xFF52525B), // zinc-600
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoCluster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128 + 128, // space for glow
      height: 128 + 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow: absolute -inset-16 glass-glow blur-3xl opacity-60
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    radius: 0.7,
                  ),
                ),
              ),
            ),
          ),
          // Logo shell: w-32 h-32 rounded-full bg-surface-container-highest/40
          //             backdrop-blur-3xl border border-outline-variant/15
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: Border.all(
                    color: context.colors.outlineVariant.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        context.colors.brandGradient.createShader(bounds),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Typography extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) => context.colors.brandGradient.createShader(b),
          child: const Text(
            'QAYDA TAXI',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ПРЕМИУМ ТАКСИ • АЛМАТЫ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final Animation<double> animation;
  const _LoadingBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    // w-48 h-[2px] bg-surface-container-highest
    return Container(
      width: 192,
      height: 2,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9999),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          // bar is 1/3 of 192 = 64px wide
          // translateX: from -100% to 300%
          // position: animation.value * 192
          const barW = 64.0;
          final left = animation.value * 192;
          return Stack(
            children: [
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: barW,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: const BorderRadius.all(Radius.circular(9999)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MinimalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E0F);
    canvas.drawRect(Offset.zero & size, bg);
    final p = Paint()
      ..color = const Color(0xFF131314)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    for (var x = 0.0; x < w; x += w / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), p);
    }
    for (var y = 0.0; y < h; y += h / 16) {
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
