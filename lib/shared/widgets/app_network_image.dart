import 'package:flutter/material.dart';
import 'package:organization_app_starter/features/home/widgets/_image_placeholder.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : (placeholder ?? Container(color: AppColors.gray100)),
      errorBuilder: (_, _, _) =>
          errorWidget ?? const ImagePlaceholder(size: 48),
    );
  }
}
