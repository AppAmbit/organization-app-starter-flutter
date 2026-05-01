import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/collection_item.dart';


/// Full-bleed hero card for the featured PageView carousel.
class FeaturedCard extends StatelessWidget {
  final CollectionItem data;
  final VoidCallback? onTap;

  const FeaturedCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (data.imageUrl != null || data.image != null)
              (data.imageUrl ?? data.image!).startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: data.imageUrl ?? data.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 48)),
                      ),
                    )
                  : Image.asset(
                      'movies_example/${data.imageUrl ?? data.image!}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[100],
                        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 48)),
                      ),
                    )
            else
              Container(
                color: Colors.grey[100],
                child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 48)),
              ),

            // Premium Gradient overlay fading to white at the bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.badge != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data.badge!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  if (data.title != null)
                    Text(
                      data.title!,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle!,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
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
}
