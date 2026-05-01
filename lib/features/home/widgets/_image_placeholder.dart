import 'package:flutter/material.dart';

/// Neutral placeholder shown when a card has no image or the image fails to load.
/// Uses a soft grey background with a centered movie icon.
class ImagePlaceholder extends StatelessWidget {
  final double size;
  const ImagePlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: size,
          color: Colors.grey[350],
        ),
      ),
    );
  }
}
