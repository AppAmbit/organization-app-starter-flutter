import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:organization_app_starter/core/constants.dart';

/// ʻŌiwi TV brand wordmark (white SVG — designed for dark backgrounds).
///
/// Responsive: when [height] is omitted, the logo scales with screen width and
/// is clamped to sensible bounds for phone vs. tablet.
class OiwiLogo extends StatelessWidget {
  /// Explicit height override. When null, height adapts to the screen width.
  final double? height;

  const OiwiLogo({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= AppLayout.tabletBreakpoint;
    final resolved = height ??
        (isTablet
            ? (width * 0.05).clamp(34.0, 48.0)
            : (width * 0.085).clamp(26.0, 38.0));

    return SvgPicture.asset(
      'assets/oiwi_logo.svg',
      height: resolved,
      semanticsLabel: 'ʻŌiwi TV',
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
