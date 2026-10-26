import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/video.dart';
import 'package:reel/domain/usecases/pick_clip.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/poster_image.dart';

/// A hand-picked start time for a title, if there is one.
final clipOverrideProvider = FutureProvider.autoDispose.family<ClipOverride?, TitleId>((ref, id) async => null);

/// The reel's video: a window of the title's best clip, muted by default,
/// looping. Only a [live] card gets a player; the rest show a still. When
/// no video plays, a slow pan over the backdrop stands in.
///
/// Nothing is drawn over the player: YouTube's terms forbid covering it.
class ReelClipPlayer extends ConsumerStatefulWidget {
  final MediaTitle title;
  final bool live;
  final bool muted;

  /// A hand-picked window, which beats the defaults.
  final ClipOverride? clipOverride;

  /// Called once, the first time the whole window has played.
  final VoidCallback? onClipWatched;

  const ReelClipPlayer({
    super.key,
    required this.title,
    required this.live,
    required this.muted,
    this.clipOverride,
    this.onClipWatched,
  });

  @override
  ConsumerState<ReelClipPlayer> createState() => _ReelClipPlayerState();
}

class _ReelClipPlayerState extends ConsumerState<ReelClipPlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _valueSub;
  StreamSubscription<YoutubeVideoState>? _positionSub;
  List<Video> _candidates = const [];
  int _index = 0;
  ClipWindow? _window;
  bool _windowFromDuration = false;
  bool _reportedWatched = false;
  bool _failed = false;

  ClipOverride? get _override => widget.clipOverride;

  @override
  void initState() {
    super.initState();
    _candidates = clipCandidates(widget.title, override: _override);
    if (widget.live) _start();
  }

  @override
  void didUpdateWidget(ReelClipPlayer old) {
    super.didUpdateWidget(old);
    if (old.title.videos.length != widget.title.videos.length ||
        old.title.id != widget.title.id ||
        old.clipOverride != widget.clipOverride) {
      _candidates = clipCandidates(widget.title, override: _override);
      _index = 0;
      _failed = false;
      _stop();
    }
    if (widget.live && _controller == null) {
      _start();
    } else if (!widget.live && _controller != null) {
      _stop();
    }
    if (old.muted != widget.muted) {
      widget.muted ? _controller?.mute() : _controller?.unMute();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    if (!ref.read(videoEmbedsEnabledProvider) || _index >= _candidates.length) return;
    final video = _candidates[_index];
    final window = clipWindow(video, override: _override);
    _window = window;
    _windowFromDuration = false;
    final controller = YoutubePlayerController.fromVideoId(
      videoId: video.key,
      autoPlay: true,
      startSeconds: window.start,
      params: YoutubePlayerParams(
        mute: widget.muted,
        showControls: false,
        showFullscreenButton: false,
        playsInline: true,
        strictRelatedVideos: true,
        showVideoAnnotations: false,
        enableCaption: false,
      ),
    );
    _valueSub = controller.stream.listen((value) => _onValue(video, value));
    _positionSub = controller.videoStateStream.listen(_onPosition);
    setState(() => _controller = controller);
  }

  void _stop() {
    _valueSub?.cancel();
    _positionSub?.cancel();
    _valueSub = null;
    _positionSub = null;
    final controller = _controller;
    _controller = null;
    controller?.close();
  }

  void _onValue(Video video, YoutubePlayerValue value) {
    if (value.error != YoutubeError.none) {
      // Blocked from embedding or region locked: try the next video.
      _stop();
      _index++;
      if (_index < _candidates.length) {
        _start();
      } else if (mounted) {
        setState(() => _failed = true);
      }
      return;
    }
    final duration = value.metaData.duration.inMilliseconds / 1000;
    if (!_windowFromDuration && duration > 0) {
      _windowFromDuration = true;
      final window = clipWindow(video, durationSeconds: duration, override: _override);
      if ((window.start - (_window?.start ?? 0)).abs() > 1) {
        _controller?.seekTo(seconds: window.start, allowSeekAhead: true);
      }
      _window = window;
    }
  }

  void _onPosition(YoutubeVideoState state) {
    final window = _window;
    if (window == null) return;
    final position = state.position.inMilliseconds / 1000;
    if (position >= window.end - 0.25) {
      _controller?.seekTo(seconds: window.start, allowSeekAhead: true);
      if (!_reportedWatched) {
        _reportedWatched = true;
        widget.onClipWatched?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: controller != null && !_failed
            ? YoutubePlayer(controller: controller, aspectRatio: 16 / 9)
            : _Still(
                title: widget.title,
                // No pan without a web view (widget tests) or with reduced
                // motion.
                animate:
                    widget.live && ref.watch(videoEmbedsEnabledProvider) && !MediaQuery.disableAnimationsOf(context),
                videoKey: _failed ? null : _candidates.firstOrNull?.key,
              ),
      ),
    );
  }
}

/// What shows without a live player: the video's thumbnail, or a slow pan
/// over the backdrop when there's no video.
class _Still extends StatefulWidget {
  final MediaTitle title;
  final bool animate;
  final String? videoKey;

  const _Still({required this.title, required this.animate, this.videoKey});

  @override
  State<_Still> createState() => _StillState();
}

class _StillState extends State<_Still> with SingleTickerProviderStateMixin {
  late final AnimationController _pan = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Still old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final pans = widget.animate && widget.videoKey == null;
    if (pans && !_pan.isAnimating) {
      _pan.repeat(reverse: true);
    } else if (!pans && _pan.isAnimating) {
      _pan.stop();
    }
  }

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.videoKey;
    if (key != null) {
      return Image.network(
        YoutubePlayerController.getThumbnail(videoId: key, quality: ThumbnailQuality.high),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => BackdropImage(path: widget.title.backdropPath),
      );
    }
    final path = widget.title.backdropPath;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: AnimatedBuilder(
        animation: _pan,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_pan.value);
          return Transform.scale(scale: 1.05 + 0.1 * t, alignment: Alignment(-0.6 + 1.2 * t, 0), child: child);
        },
        child: path != null ? BackdropImage(path: path) : Center(child: PosterImage(title: widget.title, width: 120)),
      ),
    );
  }
}
