import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable interactive fellowship card with:
/// - Subtle press-down scale transition (1.0 -> 0.97)
/// - Tactile haptic feedback (HapticFeedback.selectionClick)
/// - Smooth 200ms color & shadow interpolation across theme changes
/// - Faint 4% opacity Ethiopian / Axumite Cross watermark in bottom-right corner
class InteractiveFellowshipCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final bool showWatermark;
  final double watermarkSize;
  final List<BoxShadow>? customShadow;
  final Gradient? gradient;

  const InteractiveFellowshipCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.showWatermark = true,
    this.watermarkSize = 90.0,
    this.customShadow,
    this.gradient,
  });

  @override
  State<InteractiveFellowshipCard> createState() => _InteractiveFellowshipCardState();
}

class _InteractiveFellowshipCardState extends State<InteractiveFellowshipCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      HapticFeedback.selectionClick();
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardRadius = widget.borderRadius ?? BorderRadius.circular(18);
    final cardBg = widget.color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = widget.borderColor ?? theme.dividerColor;
    final primaryAccent = theme.colorScheme.primary;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: Colors.transparent,
          borderRadius: cardRadius,
          child: InkWell(
            onTap: widget.onTap != null ? _handleTap : null,
            onLongPress: widget.onLongPress != null
                ? () {
                    HapticFeedback.mediumImpact();
                    widget.onLongPress!();
                  }
                : null,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            borderRadius: cardRadius,
            splashColor: primaryAccent.withOpacity(0.08),
            highlightColor: primaryAccent.withOpacity(0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.gradient == null ? cardBg : null,
                gradient: widget.gradient,
                borderRadius: cardRadius,
                border: Border.all(color: borderCol, width: widget.borderWidth),
                boxShadow: widget.customShadow ??
                    [
                      BoxShadow(
                        color: theme.brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.35)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // Subtle Ethiopian Cross Watermark Accent (4% Opacity)
                  if (widget.showWatermark)
                    Positioned(
                      right: -14,
                      bottom: -14,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.04,
                          child: CustomPaint(
                            size: Size(widget.watermarkSize, widget.watermarkSize),
                            painter: EthiopianAxumiteCrossPainter(
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Main Card Content
                  widget.child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom vector painter rendering an Ethiopian / Axumite Orthodox Cross
class EthiopianAxumiteCrossPainter extends CustomPainter {
  final Color color;

  EthiopianAxumiteCrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final armLen = size.width * 0.38;
    final armWidth = size.width * 0.08;

    // Center Diamond
    final diamondPath = Path()
      ..moveTo(cx, cy - armWidth * 1.2)
      ..lineTo(cx + armWidth * 1.2, cy)
      ..lineTo(cx, cy + armWidth * 1.2)
      ..lineTo(cx - armWidth * 1.2, cy)
      ..close();
    canvas.drawPath(diamondPath, fillPaint);

    // Main Vertical Beam
    canvas.drawLine(
      Offset(cx, cy - armLen),
      Offset(cx, cy + armLen),
      paint,
    );

    // Main Horizontal Beam
    canvas.drawLine(
      Offset(cx - armLen, cy),
      Offset(cx + armLen, cy),
      paint,
    );

    // Trefoil / Ornamentation on 4 tips
    final offsets = [
      Offset(cx, cy - armLen), // Top
      Offset(cx, cy + armLen), // Bottom
      Offset(cx - armLen, cy), // Left
      Offset(cx + armLen, cy), // Right
    ];

    for (final pt in offsets) {
      canvas.drawCircle(pt, size.width * 0.055, fillPaint);
      canvas.drawCircle(Offset(pt.dx - 4, pt.dy - 4), size.width * 0.03, paint);
      canvas.drawCircle(Offset(pt.dx + 4, pt.dy + 4), size.width * 0.03, paint);
    }

    // Concentric halo ring
    canvas.drawCircle(Offset(cx, cy), size.width * 0.22, paint);
  }

  @override
  bool shouldRepaint(covariant EthiopianAxumiteCrossPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
