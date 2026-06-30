import 'package:flutter/material.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:organization_app_starter/shared/services/url_launcher_service.dart';
import 'package:organization_app_starter/shared/widgets/app_network_image.dart';
import 'package:organization_app_starter/shared/widgets/app_video_player.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';
import 'package:organization_app_starter/features/home/models/content_detail.dart';
import 'package:organization_app_starter/features/home/providers/home_feed_providers.dart';

class ContentDetailScreen extends ConsumerWidget {
  static const double _emptyStateHeight = 300.0;

  final CollectionItem item;

  const ContentDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildBody(context, ref)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      title: item.title != null
          ? Text(
              item.title!,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            )
          : const SizedBox.shrink(),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    if (item.contentId == null) {
      return _buildInlineContent(context);
    }

    final asyncDetail = ref.watch(contentDetailProvider(item.contentId!));

    return asyncDetail.when(
      data: (detail) {
        if (detail == null || detail.contentBlocks.isEmpty) {
          return _buildInlineContent(context);
        }
        return Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detail.contentBlocks
                    .map((block) => _buildBlock(context, block))
                    .toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: _emptyStateHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        debugPrint('[ContentDetail] Error: $error\n$stack');
        return _buildInlineContent(context);
      },
    );
  }

  Widget _buildInlineContent(BuildContext context) {
    final legacy = item.body ?? item.subtitle;
    if (legacy != null && legacy.isNotEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: HtmlWidget(
              legacy,
              textStyle: const TextStyle(
                  fontSize: 16, height: 1.6, color: AppColors.overlayDark),
            ),
          ),
        ),
      );
    }
    return _buildCenteredMessage(
        context, Icons.info_outline, 'Content not available.');
  }

  Widget _buildCenteredMessage(
      BuildContext context, IconData icon, String message) {
    return SizedBox(
      height: _emptyStateHeight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 16, color: AppColors.gray600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ContentDetailBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: _buildBlockContent(context, block),
    );
  }

  Widget _buildBlockContent(BuildContext context, ContentDetailBlock block) {
    switch (block.type) {
      case ContentBlockType.text:
        if (block.text == null || block.text!.isEmpty) {
          return const SizedBox.shrink();
        }
        return HtmlWidget(
          block.text!,
          textStyle: const TextStyle(
              fontSize: 16, height: 1.6, color: AppColors.overlayDark),
        );
      case ContentBlockType.video:
        final videoUrl = block.bannerVideoUrl;
        if (videoUrl == null || videoUrl.isEmpty) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AppVideoPlayer(url: videoUrl),
        );
      case ContentBlockType.image:
        final imageUrl = block.bannerImageUrl ?? block.bannerImage;
        if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
        );
      case ContentBlockType.button:
        final buttonText = block.buttonText ?? 'Click Here';
        final buttonUrl = block.buttonUrl;
        Color? buttonColor;
        if (block.buttonColor != null && block.buttonColor!.startsWith('#')) {
          try {
            final hex = block.buttonColor!.substring(1);
            final value = int.parse(hex, radix: 16);
            buttonColor = Color(hex.length == 8 ? value : value + 0xFF000000);
          } catch (_) {}
        }
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () async {
              if (buttonUrl != null) await UrlLauncherService.launch(buttonUrl);
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  buttonColor ?? Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonText,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
