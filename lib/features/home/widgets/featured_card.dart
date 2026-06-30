import 'dart:async';

import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';
import 'card_image.dart';

class FeaturedCard extends StatefulWidget {
  final CollectionItem data;
  final VoidCallback? onTap;

  const FeaturedCard({super.key, required this.data, this.onTap});

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  // The overlay label is "transient": visible on appear, then fades out.
  static const _overlayVisibleFor = Duration(seconds: 3);
  static const _overlayFade = Duration(milliseconds: 500);

  bool _overlayVisible = true;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _armOverlay();
  }

  @override
  void didUpdateWidget(FeaturedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-show the overlay when the slide changes to a different item.
    if (oldWidget.data.id != widget.data.id) {
      _overlayVisible = true;
      _armOverlay();
    }
  }

  void _armOverlay() {
    _overlayTimer?.cancel();
    if (widget.data.overlayText == null) return;
    _overlayTimer = Timer(_overlayVisibleFor, () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColor = isDark ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Full-width image
              AspectRatio(
                aspectRatio: 16 / 10,
                child: CardImage(imageUrl: data.imageUrl, imagePath: data.image),
              ),
              // Bottom gradient — blends into background color
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        gradientColor.withValues(alpha: 0.15),
                        gradientColor.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // Badge — bottom-left, outlined only
              if (data.badge != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? AppColors.white : AppColors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      data.badge!.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              // Transient overlay label — fades out
              if (data.overlayText != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedOpacity(
                    opacity: _overlayVisible ? 1 : 0,
                    duration: _overlayFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.overlayText!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Title below the image
          if (data.title != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
              child: Text(
                data.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
