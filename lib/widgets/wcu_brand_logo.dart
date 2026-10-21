import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An animated, tappable WCU Gibi Gubae mark that follows the app's navy and
/// liturgical-gold palette. The optional callback lets the host open a home or
/// about screen without coupling the logo to app navigation.
class WcuBrandLogo extends StatefulWidget {
  const WcuBrandLogo({
    super.key,
    this.markSize = 68,
    this.onTap,
    this.showName = true,
    this.showAmharic = true,
    this.compact = false,
  });

  final double markSize;
  final VoidCallback? onTap;
  final bool showName;
  final bool showAmharic;
  final bool compact;

  @override
  State<WcuBrandLogo> createState() => _WcuBrandLogoState();
}

class _WcuBrandLogoState extends State<WcuBrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final mark = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        return CustomPaint(
          size: Size.square(widget.markSize),
          painter: _WcuMarkPainter(pulse: pulse),
        );
      },
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        if (widget.showName) ...[
          SizedBox(width: widget.compact ? 10 : 14),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WCU Gibi Gubae',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'serif',
                    fontSize: widget.compact ? 15 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.25,
                  ),
                ),
                if (widget.showAmharic) ...[
                  const SizedBox(height: 3),
                  Text(
                    'የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'serif',
                      fontSize: widget.compact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );

    if (widget.onTap == null) {
      return Semantics(
        image: true,
        label: 'WCU Gibi Gubae, Wachemo University Orthodox Fellowship',
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: 'WCU Gibi Gubae, about the fellowship',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.markSize),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _WcuMarkPainter extends CustomPainter {
  const _WcuMarkPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 320;
    canvas.save();
    canvas.scale(scale);

    final center = const Offset(160, 160);
    final radius = 148.0;
    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.04 + pulse * 0.09)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + pulse * 8);
    canvas.drawCircle(center, radius * (0.7 + pulse * 0.1), glowPaint);

    canvas.drawCircle(
      center,
      166,
      Paint()..color = const Color(0xFF070F1E),
    );
    canvas.drawCircle(
      center,
      166,
      Paint()
        ..color = const Color(0xFFD6AE55).withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFD6AE55).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final rayPaint = Paint()
      ..color = const Color(0xFFF5C75E).withOpacity(0.25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inner = Offset(
        center.dx + math.cos(angle) * 128,
        center.dy + math.sin(angle) * 128,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * 140,
        center.dy + math.sin(angle) * 140,
      );
      canvas.drawLine(inner, outer, rayPaint);
    }

    final cross = Path()
      ..moveTo(169, 60)
      ..lineTo(180, 48)
      ..lineTo(191, 60)
      ..lineTo(191, 113)
      ..lineTo(233, 113)
      ..lineTo(245, 125)
      ..lineTo(233, 137)
      ..lineTo(191, 137)
      ..lineTo(191, 215)
      ..lineTo(180, 227)
      ..lineTo(169, 215)
      ..lineTo(169, 137)
      ..lineTo(127, 137)
      ..lineTo(115, 125)
      ..lineTo(127, 113)
      ..lineTo(169, 113)
      ..close();
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE8A3), Color(0xFFF5B83D), Color(0xFFB86C12)],
      ).createShader(const Rect.fromLTWH(100, 40, 150, 200));
    canvas.drawPath(
      cross,
      Paint()
        ..color = const Color(0xFF74440D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(cross, goldPaint);

    canvas.drawCircle(
      const Offset(180, 125),
      13,
      Paint()..color = const Color(0xFF0B1530),
    );
    canvas.drawCircle(
      const Offset(180, 125),
      13,
      Paint()
        ..color = const Color(0xFFFFE8A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final book = Path()
      ..moveTo(113, 250)
      ..cubicTo(136, 240, 157, 243, 178, 256)
      ..cubicTo(199, 243, 220, 240, 243, 250)
      ..lineTo(243, 280)
      ..cubicTo(220, 272, 199, 275, 178, 288)
      ..cubicTo(157, 275, 136, 272, 113, 280)
      ..close();
    canvas.drawPath(
      book,
      Paint()
        ..color = const Color(0xFF0B1530)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      book,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE8A3), Color(0xFFB86C12)],
        ).createShader(const Rect.fromLTWH(110, 240, 140, 50))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    final pagePaint = Paint()
      ..color = const Color(0xFFF5C75E).withOpacity(0.88)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(180, 256), const Offset(180, 287), pagePaint);
    canvas.drawLine(const Offset(125, 256), const Offset(163, 262), pagePaint);
    canvas.drawLine(const Offset(235, 256), const Offset(197, 262), pagePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WcuMarkPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
