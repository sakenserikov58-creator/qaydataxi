import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// ConnectivityService — мониторинг сети + Overlay-баннер.
///
/// Подключается один раз в _RouterWrapper через [attach()].
/// Показывает цветной баннер вверху экрана:
///   - Красный  "Нет интернета"  — при потере сети
///   - Зелёный  "Соединение восстановлено"  — при возврате (3 сек, затем скрывается)
///
/// Также вызывает [onReconnect] — коллбэк для перезапуска BLoC/refresh.
class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  OverlayEntry? _banner;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;
  VoidCallback? _onReconnect;

  /// Прикрепить к корневому Overlay и задать callback на reconnect.
  void attach({
    required OverlayState overlayState,
    VoidCallback? onReconnect,
  }) {
    _onReconnect = onReconnect;
    _sub?.cancel();
    _sub = Connectivity()
        .onConnectivityChanged
        .listen((results) => _handleChange(results, overlayState));
  }

  void detach() {
    _sub?.cancel();
    _banner?.remove();
    _banner = null;
  }

  void _handleChange(
    List<ConnectivityResult> results,
    OverlayState overlayState,
  ) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);

    if (!hasNetwork && _isOnline) {
      // Сеть пропала
      _isOnline = false;
      _showBanner(overlayState, _OfflineBanner());
    } else if (hasNetwork && !_isOnline) {
      // Сеть вернулась
      _isOnline = true;
      _showBanner(overlayState, _OnlineBanner(), autoDismiss: true);
      _onReconnect?.call();
    }
  }

  void _showBanner(
    OverlayState overlayState,
    Widget child, {
    bool autoDismiss = false,
  }) {
    _banner?.remove();
    _banner = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(color: Colors.transparent, child: child),
      ),
    );
    overlayState.insert(_banner!);

    if (autoDismiss) {
      Future.delayed(const Duration(seconds: 3), () {
        _banner?.remove();
        _banner = null;
      });
    }
  }
}

// ─── Banner Widgets ───────────────────────────────────────────────────────────

class _OfflineBanner extends StatefulWidget {
  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFD32F2F),
            boxShadow: [
              BoxShadow(
                  color: Color(0x33D32F2F),
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: const Row(children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Нет подключения к интернету',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OnlineBanner extends StatefulWidget {
  @override
  State<_OnlineBanner> createState() => _OnlineBannerState();
}

class _OnlineBannerState extends State<_OnlineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF388E3C),
            boxShadow: [
              BoxShadow(
                  color: Color(0x33388E3C),
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: const Row(children: [
            Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Соединение восстановлено',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ),
    );
  }
}
