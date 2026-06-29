import 'package:flutter/material.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/shared/widgets/app_network_image.dart';
import '_image_placeholder.dart';

class CardImage extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final BoxFit fit;

  const CardImage({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = imageUrl ?? imagePath;
    if (resolved == null || resolved.isEmpty) {
      return Container(
        color: AppColors.gray100,
        child: const Center(child: ImagePlaceholder(size: 48)),
      );
    }
    if (resolved.startsWith('http')) {
      return AppNetworkImage(url: resolved, fit: fit);
    }
    return Image.asset(
      'movies_example/$resolved',
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.gray100,
        child: const Center(child: ImagePlaceholder(size: 48)),
      ),
    );
  }
}
