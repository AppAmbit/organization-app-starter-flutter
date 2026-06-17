import 'package:flutter/material.dart';
import '../../../../core/styles/app_colors.dart';

/// Neutral placeholder shown when a card has no image or the image fails to load.
/// Uses a soft grey background with a centered movie icon.
class ImagePlaceholder extends StatelessWidget {
  final double size;
  const ImagePlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: size,
          color: AppColors.gray350,
        ),
      ),
    );
  }
}
