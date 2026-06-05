import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../config/app_palette.dart';
import '../../../config/constants.dart';

class RoomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;

  const RoomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title = 'Video giới thiệu',
    this.subtitle,
  });

  @override
  State<RoomVideoPlayer> createState() => _RoomVideoPlayerState();
}

class _RoomVideoPlayerState extends State<RoomVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(RoomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    final token = ++_loadToken;
    final rawUrl = widget.videoUrl.trim();
    final uri = Uri.tryParse(rawUrl);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _setError('Link video không hợp lệ.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _videoController = controller;

      await controller.initialize();
      if (!mounted || token != _loadToken) {
        controller.dispose();
        return;
      }

      final aspectRatio = controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 16 / 9;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        aspectRatio: aspectRatio,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.25),
          backgroundColor: AppColors.outlineVariant,
        ),
        bufferingBuilder: (_) => _buildLoadingBody(),
        errorBuilder: (_, errorMessage) => _buildErrorBody(errorMessage),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      _disposeControllers();
      _setError('Không thể phát video này.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở video bằng ứng dụng ngoài.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _disposeControllers() {
    _loadToken++;
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.outlineVariant),
        boxShadow: const [AppShadows.card],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, color: palette.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.titleSM.copyWith(
                          color: palette.onSurface,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.bodySM.copyWith(
                            color: palette.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Mở video ngoài ứng dụng',
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new, size: 20),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayerBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBody() {
    if (_isLoading) return _buildLoadingBody();
    if (_errorMessage != null) return _buildErrorBody(_errorMessage!);

    final chewieController = _chewieController;
    if (chewieController == null) {
      return _buildErrorBody('Video chưa sẵn sàng.');
    }

    return Chewie(controller: chewieController);
  }

  Widget _buildLoadingBody() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorBody(String message) {
    final palette = context.palette;
    return Container(
      color: palette.surfaceLow,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_file_outlined,
              size: 40,
              color: palette.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMD.copyWith(
                color: palette.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Mở bằng ứng dụng ngoài'),
            ),
          ],
        ),
      ),
    );
  }
}
