import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/platform_store.dart';

final Future<Record> _roads = rootBundle
    .loadString('assets/maps/dhaka-roads.json')
    .then((s) => record(jsonDecode(s)));

/// Bundled geographic road data. No tile server, geocoder or third-party runtime request.
class RoadMap extends StatelessWidget {
  final List<Record> route, pins;
  final Record? driver;
  final double height;
  final void Function(Record)? onSelect;
  const RoadMap({
    super.key,
    this.route = const [],
    this.pins = const [],
    this.driver,
    this.height = 220,
    this.onSelect,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Dhaka road map. Pickup and destination also appear in the text itinerary. Pin selection has a coordinate alternative.',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FutureBuilder<Record>(
              future: _roads,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Map unavailable. Use the text itinerary.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Loading road map…'));
                }
                return LayoutBuilder(
                  builder: (context, box) {
                    final painter = _RoadPainter(
                      records(snapshot.data!['roads']),
                      route,
                      pins,
                      driver,
                      Size(box.maxWidth, box.maxHeight),
                    );
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 6,
                      child: GestureDetector(
                        onTapUp: onSelect == null
                            ? null
                            : (d) {
                                final p = painter.unproject(d.localPosition);
                                onSelect!({
                                  'name': 'Selected map point',
                                  'address':
                                      'Confirm the road and meeting point',
                                  'lat': p.dy,
                                  'lng': p.dx,
                                });
                              },
                        child: CustomPaint(
                          size: Size(box.maxWidth, box.maxHeight),
                          painter: painter,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const Positioned(
              left: 8,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xDD12221F)),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    '© OpenStreetMap contributors · ODbL 1.0',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ),
            if (onSelect != null)
              const Positioned(
                left: 12,
                top: 10,
                child: Text(
                  'Tap a road to place the pin',
                  style: TextStyle(
                    backgroundColor: Color(0xDD12221F),
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RoadPainter extends CustomPainter {
  final List<Record> roads, route, pins;
  final Record? driver;
  final Size size;
  late double left, right, bottom, top;
  _RoadPainter(this.roads, this.route, this.pins, this.driver, this.size) {
    final points = [
      ...route,
      ...pins,
      ?driver,
    ].where((p) => p['lat'] is num && p['lng'] is num).toList();
    left = points.isEmpty
        ? 90.35
        : points.map((p) => (p['lng'] as num).toDouble()).reduce(math.min) -
              .004;
    right = points.isEmpty
        ? 90.45
        : points.map((p) => (p['lng'] as num).toDouble()).reduce(math.max) +
              .004;
    bottom = points.isEmpty
        ? 23.70
        : points.map((p) => (p['lat'] as num).toDouble()).reduce(math.min) -
              .004;
    top = points.isEmpty
        ? 23.82
        : points.map((p) => (p['lat'] as num).toDouble()).reduce(math.max) +
              .004;
    final ratio = size.width / size.height;
    final cosine = math.cos((top + bottom) / 2 * math.pi / 180);
    if ((right - left) * cosine / (top - bottom) < ratio) {
      final width = (top - bottom) * ratio / cosine;
      final center = (right + left) / 2;
      left = center - width / 2;
      right = center + width / 2;
    } else {
      final height = (right - left) * cosine / ratio;
      final center = (top + bottom) / 2;
      bottom = center - height / 2;
      top = center + height / 2;
    }
  }
  Offset project(double lng, double lat) => Offset(
    (lng - left) / (right - left) * size.width,
    (top - lat) / (top - bottom) * size.height,
  );
  Offset unproject(Offset p) => Offset(
    left + p.dx / size.width * (right - left),
    top - p.dy / size.height * (top - bottom),
  );
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1C322D),
    );
    canvas.clipRect(Offset.zero & size);
    for (final road in roads) {
      final bounds = road['bounds'] as List?;
      if (bounds != null &&
          (bounds[2] < left ||
              bounds[0] > right ||
              bounds[3] < bottom ||
              bounds[1] > top)) {
        continue;
      }
      final points = road['points'] as List;
      final p = Path();
      bool visible = false;
      for (var i = 0; i < points.length; i++) {
        final xy = points[i] as List;
        final q = project((xy[0] as num).toDouble(), (xy[1] as num).toDouble());
        if (q.dx >= -20 &&
            q.dx <= size.width + 20 &&
            q.dy >= -20 &&
            q.dy <= size.height + 20) {
          visible = true;
        }
        if (i == 0) {
          p.moveTo(q.dx, q.dy);
        } else {
          p.lineTo(q.dx, q.dy);
        }
      }
      if (visible) {
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth =
                {
                  'motorway',
                  'trunk',
                  'primary',
                  'secondary',
                }.contains(road['kind'])
                ? 2.5
                : 1
            ..color = const Color(0xFF496158),
        );
      }
    }
    final path = Path();
    for (var i = 0; i < route.length; i++) {
      final q = project(
        (route[i]['lng'] as num).toDouble(),
        (route[i]['lat'] as num).toDouble(),
      );
      if (i == 0) {
        path.moveTo(q.dx, q.dy);
      } else {
        path.lineTo(q.dx, q.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9BF3CB),
    );
    for (var i = 0; i < pins.length; i++) {
      final p = pins[i];
      if (p['lng'] is! num || p['lat'] is! num) continue;
      final q = project(
        (p['lng'] as num).toDouble(),
        (p['lat'] as num).toDouble(),
      );
      canvas.drawCircle(
        q,
        8,
        Paint()..color = i == 0 ? Colors.white : const Color(0xFF9BF3CB),
      );
      canvas.drawCircle(q, 3, Paint()..color = Colors.black);
    }
    if (driver?['lng'] is num && driver?['lat'] is num) {
      final q = project(
        (driver!['lng'] as num).toDouble(),
        (driver!['lat'] as num).toDouble(),
      );
      canvas.drawCircle(q, 9, Paint()..color = const Color(0xFFFFC75C));
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}
