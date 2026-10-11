import 'package:flutter/material.dart';

abstract final class RideTheme {
  static const background = Color(0xFF101211),
      surface = Color(0xFF1E2220),
      muted = Color(0xFFAFB8B2),
      accent = Color(0xFFB9F5CE);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'RideRoboto',
    fontFamilyFallback: const ['RideBengali'],
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF166B46),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F8F5),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
  static ThemeData get dark => ThemeData(
    fontFamily: 'RideRoboto',
    fontFamilyFallback: const ['RideBengali'],
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: background,
      surface: surface,
      onSurface: Color(0xFFF4F6F4),
      secondary: accent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF343B36)),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: background,
      indicatorColor: surface,
      height: 76,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: const Color(0xFFF4F6F4),
        foregroundColor: background,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -.8,
      ),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    ),
  );
}

IconData productIcon(String name) => switch (name) {
  'Bike' => Icons.two_wheeler_rounded,
  'CNG' => Icons.electric_rickshaw_rounded,
  'XL' => Icons.airport_shuttle_rounded,
  _ => Icons.directions_car_filled_rounded,
};

class RouteIllustration extends StatelessWidget {
  final double height;
  final String label;
  const RouteIllustration({
    super.key,
    this.height = 220,
    this.label = 'Dhaka · route preview',
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Illustrative route. $label',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RideTheme.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: RideTheme.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF202A25), BlendMode.src);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .66,
          size.height * .1,
          size.width * .2,
          size.height * .58,
        ),
        const Radius.circular(22),
      ),
      Paint()..color = const Color(0xFF2D4035),
    );
    final road = Paint()
      ..color = const Color(0xFF3D4942)
      ..strokeWidth = 10;
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(i * size.width / 6 - 40, 0),
        Offset(i * size.width / 6 + 60, size.height),
        road,
      );
    }
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(0, i * size.height / 4 - 20),
        Offset(size.width, i * size.height / 4 + 25),
        road,
      );
    }
    final start = Offset(size.width * .24, size.height * .73),
        end = Offset(size.width * .72, size.height * .28);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(size.width * .38, start.dy)
      ..lineTo(size.width * .43, size.height * .45)
      ..lineTo(end.dx - 15, size.height * .5)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = RideTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(start, 9, Paint()..color = const Color(0xFFF4F6F4));
    canvas.drawCircle(start, 4, Paint()..color = RideTheme.background);
    canvas.drawCircle(end, 9, Paint()..color = RideTheme.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
