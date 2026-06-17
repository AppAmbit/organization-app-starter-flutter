import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/styles/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/collection_item.dart';

class SingleLargeCard extends StatelessWidget {
  final CollectionItem data;
  final VoidCallback? onTap;

  const SingleLargeCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = (screenWidth - 40) * 0.6; // 40 is horizontal padding (20 * 2)

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
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
                      AppColors.black.withValues(alpha: 0.2),
                      AppColors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Text Content Overlay
            if (data.title != null || data.subtitle != null)
              Padding(
                padding: const EdgeInsets.all(20),
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
                          color: AppColors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data.badge!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.white,
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
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                    if (data.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        data.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 14,
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
          color: AppColors.gray100,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: AppColors.gray500, size: 48),
          ),
        );

    if (imagePath != null) {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: AppColors.gray100),
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
