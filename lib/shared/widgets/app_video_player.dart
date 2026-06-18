import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';

/// Isolated wrapper for video_player + chewie.
/// If either package changes API, only this file changes.
class AppVideoPlayer extends StatefulWidget {
  final String url;
  const AppVideoPlayer({super.key, required this.url});

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        aspectRatio: _videoController.value.aspectRatio,
        autoPlay: false,
        looping: false,
        errorBuilder: (context, _) =>
            const Center(child: Icon(Icons.error_outline, color: AppColors.white, size: 48)),
      );
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('[AppVideoPlayer] init failed: $e\n$st');
      if (mounted) setState(() => _isError = true);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
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
          child: const Center(
              child: Icon(Icons.error_outline, color: AppColors.white, size: 48)),
        ),
      );
    }
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: AppColors.overlayDark,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.white)),
      ),
    );
  }
}
