import 'package:flutter/material.dart';
import '../../../../core/styles/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/constants.dart';
import '../models/collection_item.dart';
import '../models/content_detail.dart';
import '../providers/home_feed_providers.dart';

class ContentDetailScreen extends ConsumerWidget {
  final CollectionItem item;

  const ContentDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildBody(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iconTheme: const IconThemeData(color: AppColors.black),
      title: item.title != null 
          ? Text(
              item.title!, 
              style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ) 
          : const SizedBox.shrink(),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    if (item.contentId == null) {
      return _buildCenteredMessage(context, Icons.info_outline, 'Content not available.');
    }

    final asyncDetail = ref.watch(contentDetailProvider(item.contentId!));

    return asyncDetail.when(
      data: (detail) {
        if (detail == null || detail.contentBlocks.isEmpty) {
          return _buildCenteredMessage(context, Icons.search_off, 'Content not found.');
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detail.contentBlocks.map((block) => _buildBlock(context, block)).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        debugPrint('Error: $error');
        return _buildCenteredMessage(
          context,
          Icons.wifi_off_rounded,
          'Connection error.\nCould not load content.',
        );
      },
    );
  }

  Widget _buildCenteredMessage(BuildContext context, IconData icon, String message) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.gray600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ContentDetailBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: () {
        switch (block.type) {
          case ContentBlockType.text:
            if (block.text == null || block.text!.isEmpty) return const SizedBox.shrink();
            return HtmlWidget(
              block.text!,
              textStyle: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.overlayDark),
            );
          case ContentBlockType.video:
            final videoUrlStr = block.bannerVideoUrl;
            if (videoUrlStr == null || videoUrlStr.isEmpty) return const SizedBox.shrink();
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _VideoBlockPlayer(videoUrl: videoUrlStr),
            );
          case ContentBlockType.image:
            final imageUrl = block.bannerImageUrl;
            if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppColors.gray100,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppColors.gray100,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.gray500)),
                ),
              ),
            );
          case ContentBlockType.button:
            final buttonText = block.buttonText ?? 'Click Here';
            final buttonUrl = block.buttonUrl;
            Color? buttonColor;
            if (block.buttonColor != null && block.buttonColor!.startsWith('#')) {
              try {
                buttonColor = Color(int.parse(block.buttonColor!.substring(1), radix: 16) + 0xFF000000);
              } catch (_) {}
            }

            return SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () async {
                  if (buttonUrl != null) {
                    final uri = Uri.parse(buttonUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: buttonColor ?? Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      }(),
    );
  }
}

class _VideoBlockPlayer extends StatefulWidget {
  final String videoUrl;
  const _VideoBlockPlayer({required this.videoUrl});

  @override
  State<_VideoBlockPlayer> createState() => _VideoBlockPlayerState();
}

class _VideoBlockPlayerState extends State<_VideoBlockPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: false,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Icon(Icons.error_outline, color: AppColors.white, size: 48),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() { _isError = true; });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.overlayDark,
          child: const Center(child: Icon(Icons.error_outline, color: AppColors.white, size: 48)),
        ),
      );
    }
    
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoPlayerController.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.overlayDark,
          child: const Center(child: CircularProgressIndicator(color: AppColors.white)),
        ),
      );
    }
  }
}
