import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable caching image widget that avoids re-downloading images from Firebase Storage
/// or external URLs, provides offline disk cache, and includes accessibility semantics.
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final Widget? fallback;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.zero;
    final fallbackWidget = fallback ??
        Container(
          width: width,
          height: height,
          color: AppTheme.surfaceElevated,
          child: const Center(
            child: Icon(Icons.image_outlined, color: AppTheme.textSecondary, size: 28),
          ),
        );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: fallbackWidget,
      );
    }

    return Semantics(
      label: semanticLabel ?? 'Orthodox fellowship image',
      image: true,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: CachedNetworkImage(
          imageUrl: imageUrl!.trim(),
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: AppTheme.surfaceElevated,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.gold,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => fallbackWidget,
        ),
      ),
    );
  }
}
