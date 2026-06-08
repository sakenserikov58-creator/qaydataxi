import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/core/theme.dart';

/// Центр Алматы
const kAlmatyCenter = LatLng(43.2380, 76.8829);

/// Модель маркера водителя на карте
class DriverMapMarker {
  final String id;
  final LatLng position;
  final double heading;
  final String tariff; 
  DriverMapMarker({
    required this.id,
    required this.position,
    this.heading = 0.0,
    required this.tariff,
  });
}

/// Класс для отрисовки маркера водителя (автомобиль)
class DriverMarkerPainter extends CustomPainter {
  final Color color;
  final double heading;

  DriverMarkerPainter({required this.color, this.heading = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(heading * math.pi / 180);

    final path = ui.Path();
    path.moveTo(0, -size.height / 2);
    path.lineTo(size.width / 2, size.height / 2);
    path.lineTo(-size.width / 2, size.height / 2);
    path.close();

    canvas.drawShadow(path.shift(const Offset(0, 2)), Colors.black, 4, true);
    canvas.drawPath(path, paint);

    final lightPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width / 4, -size.height / 4), 2, lightPaint);
    canvas.drawCircle(Offset(-size.width / 4, -size.height / 4), 2, lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Основной виджет карты для приложения
class AppMapWidget extends StatelessWidget {
  final LatLng? center;
  final double zoom;
  final List<DriverMapMarker>? driverMarkers;
  final LatLng? driverPosition;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final bool showRoute;
  final bool autoCenter;
  final bool isBlurred;
  final MapController? controller;
  final List<Polyline>? polylines;

  const AppMapWidget({
    super.key,
    this.center,
    this.zoom = 13.0,
    this.driverMarkers,
    this.driverPosition,
    this.originPoint,
    this.destinationPoint,
    this.showRoute = false,
    this.autoCenter = false,
    this.isBlurred = false,
    this.controller,
    this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    Widget map = FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center ?? kAlmatyCenter,
        initialZoom: zoom,
        backgroundColor: context.colors.background,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.qayda.app',
        ),
        if (polylines != null)
          PolylineLayer(polylines: polylines!),
        if (driverMarkers != null)
          MarkerLayer(
            markers: driverMarkers!.map((d) => Marker(
              point: d.position,
              width: 30,
              height: 30,
              child: CustomPaint(
                painter: DriverMarkerPainter(
                  color: _getTariffColor(context, d.tariff),
                  heading: d.heading,
                ),
              ),
            )).toList(),
          ),
        if (driverPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: driverPosition!,
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: DriverMarkerPainter(
                    color: context.colors.primary,
                    heading: 0,
                  ),
                ),
              ),
            ],
          ),
        if (showRoute && originPoint != null && destinationPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: originPoint!,
                width: 32,
                height: 32,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
              ),
              Marker(
                point: destinationPoint!,
                width: 32,
                height: 32,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
      ],
    );

    if (isBlurred) {
      map = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: map,
      );
    }

    return map;
  }

  Color _getTariffColor(BuildContext context, String tariff) {
    switch (tariff.toLowerCase()) {
      case 'pink': return const Color(0xFFFF69B4);
      case 'business': return const Color(0xFFFFD700);
      case 'comfort': return context.colors.primary;
      default: return Colors.white70;
    }
  }
}

/// Список демо-водителей вокруг центра Алматы для HomeScreen
List<DriverMapMarker> generateNearbyDrivers() {
  return [
    DriverMapMarker(id: 'd1', position: const LatLng(43.2420, 76.8750), tariff: 'comfort'),
    DriverMapMarker(id: 'd2', position: const LatLng(43.2350, 76.9010), tariff: 'economy'),
    DriverMapMarker(id: 'd3', position: const LatLng(43.2290, 76.8680), tariff: 'business'),
    DriverMapMarker(id: 'd4', position: const LatLng(43.2460, 76.8950), tariff: 'minivan'),
    DriverMapMarker(id: 'd5', position: const LatLng(43.2310, 76.9120), tariff: 'comfort'),
  ];
}

/// Алматы демо-координаты
class AlmatyPoints {
  static const dostyk  = LatLng(43.2356, 76.9071);
  static const esentai = LatLng(43.2226, 76.8927);
  static const airport = LatLng(43.3521, 77.0406);
  static const medeu   = LatLng(43.1630, 77.0194);
  static const mega    = LatLng(43.2150, 76.8820);
}
