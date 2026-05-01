import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/collection_item.dart';


/// Image-top card ~160dp wide for horizontal carousels.
class LargeCard extends StatelessWidget {
  final CollectionItem data;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const LargeCard({super.key, required this.data, this.onTap, this.margin, this.width});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final double defaultWidth = isTablet ? 400.0 : screenWidth * 0.85;
    final double actualWidth = width ?? defaultWidth;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: actualWidth,
        margin: margin ?? const EdgeInsets.only(right: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            _buildImage(context),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Text Content Overlay
            if (data.title != null || data.subtitle != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.badge != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data.badge!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (data.title != null)
                      Text(
                        data.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                    if (data.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final imagePath = data.imageUrl ?? data.image;
    
    Widget placeholder() => Container(
          color: Colors.grey[100],
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
          ),
        );

    if (imagePath != null) {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[100]),
          errorWidget: (context, url, error) => placeholder(),
        );
      } else {
        return Image.asset(
          'movies_example/$imagePath',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        );
      }
    }
    return placeholder();
  }
}
