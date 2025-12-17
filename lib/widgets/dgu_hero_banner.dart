import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DGU Hero Banner med golfbane illustration (code-based graphics)
/// Inspireret af moderne golf apps men med DGU branding
class DguHeroBanner extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final double height;
  final bool showFlag;
  final bool showClubhouse;
  final bool showSun;
  
  const DguHeroBanner({
    super.key,
    this.title,
    this.subtitle,
    this.content,
    this.height = 220,
    this.showFlag = true,
    this.showClubhouse = false,
    this.showSun = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // Background illustration
          Positioned.fill(
            child: CustomPaint(
              painter: DguGolfCoursePainter(
                showClubhouse: showClubhouse,
                showSun: showSun,
              ),
            ),
          ),
          
          // Flag
          if (showFlag)
            Positioned(
              bottom: 50,
              right: 70,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          
          // Content overlay
          if (title != null || subtitle != null || content != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 12),
                      content!,
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter til at tegne golfbane (code-based graphics)
class DguGolfCoursePainter extends CustomPainter {
  final bool showClubhouse;
  final bool showSun;
  
  DguGolfCoursePainter({
    this.showClubhouse = false,
    this.showSun = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Himmel gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: showSun 
          ? [AppTheme.heroSkyLight, AppTheme.heroSkyBlue, AppTheme.heroGreenLight]
          : [AppTheme.heroSkyBlue, AppTheme.heroGreenLight],
        stops: showSun ? [0.0, 0.3, 1.0] : [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
    
    // Sol (hvis enabled)
    if (showSun) {
      final sunPaint = Paint()
        ..color = const Color(0xFFFDD835)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.15),
        30,
        sunPaint,
      );
    }
    
    // Bageste bakker (mørke træer)
    final treePaint = Paint()
      ..color = AppTheme.heroGreenDark
      ..style = PaintingStyle.fill;
    _drawTreeLine(canvas, size, treePaint, startY: size.height * 0.25);
    
    // Mellem bakker
    final hillPaint1 = Paint()..color = AppTheme.heroGreenMedium;
    final path1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.3, size.height * 0.35,
        size.width * 0.6, size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.8, size.height * 0.5,
        size.width, size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, hillPaint1);
    
    // Forreste green
    final hillPaint2 = Paint()..color = AppTheme.heroGreenForeground;
    final path2 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.55,
        size.width * 0.5, size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.7,
        size.width, size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, hillPaint2);
    
    // Klubhus (hvis enabled)
    if (showClubhouse) {
      _drawClubhouse(canvas, size.width * 0.15, size.height * 0.4);
    }
  }
  
  void _drawTreeLine(Canvas canvas, Size size, Paint paint, {required double startY}) {
    // Simplified tree silhouettes
    for (double x = 0; x < size.width; x += 50) {
      final path = Path()
        ..moveTo(x, startY + 30)
        ..lineTo(x + 15, startY)
        ..lineTo(x + 30, startY + 30)
        ..close();
      canvas.drawPath(path, paint);
    }
  }
  
  void _drawClubhouse(Canvas canvas, double x, double y) {
    // Hus
    final housePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, 50, 35), housePaint);
    
    // Tag
    final roofPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(x - 5, y)
      ..lineTo(x + 25, y - 15)
      ..lineTo(x + 55, y)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

