import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/collection_item.dart';


/// Compact thumbnail-left card ~260dp wide for horizontal carousels.
class SmallCard extends StatelessWidget {
  final CollectionItem data;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const SmallCard({super.key, required this.data, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final double cardWidth = isTablet ? 220.0 : 160.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: margin ?? const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Image with rounded corners
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImage(context),
              ),
            ),
            const SizedBox(height: 8),
            
            // Text area below
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.title != null)
                    Text(
                      data.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        letterSpacing: -0.1,
                      ),
                    ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
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
            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 24),
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
