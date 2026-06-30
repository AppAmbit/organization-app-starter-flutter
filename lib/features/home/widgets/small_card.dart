import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';
import 'card_image.dart';


/// Compact thumbnail-left card ~260dp wide for horizontal carousels.
class SmallCard extends StatelessWidget {
  final CollectionItem data;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const SmallCard({super.key, required this.data, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= AppLayout.tabletBreakpoint;
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
                borderRadius: BorderRadius.zero,
                child: CardImage(imageUrl: data.imageUrl, imagePath: data.image),
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
                        color: AppColors.gray600,
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

}
