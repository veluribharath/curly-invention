import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// M0 spike: five trailers in a vertical feed, muted autoplay from an
/// offset, one live player at a time. Run it on real phones to check that
/// inline playback, swiping and memory hold up (see docs/08-spike.md).
class ReelsSpikeScreen extends StatefulWidget {
  const ReelsSpikeScreen({super.key});

  @override
  State<ReelsSpikeScreen> createState() => _ReelsSpikeScreenState();
}

class _SpikeClip {
  final String title;
  final String videoId;
  final double start;

  const _SpikeClip(this.title, this.videoId, this.start);
}

class _ReelsSpikeScreenState extends State<ReelsSpikeScreen> {
  static const _clips = [
    _SpikeClip('Dune: Part Two', 'Way9Dexny3w', 30),
    _SpikeClip('Interstellar', 'zSWdZVtXT7E', 40),
    _SpikeClip('Inception', 'YoHD9XEInc0', 25),
    _SpikeClip('Oppenheimer', 'uYPbbksJxIg', 35),
    _SpikeClip('Top Gun: Maverick', 'giXco2jaZ_4', 30),
  ];
  static const _clipLength = 25.0;

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Reels spike'), backgroundColor: Colors.transparent),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _clips.length,
        onPageChanged: (index) => setState(() => _current = index),
        itemBuilder: (context, index) {
          final clip = _clips[index];
          // Only the card on screen gets a player; neighbors show a thumbnail.
          final live = index == _current;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10.5,
                    child: live
                        ? _SpikePlayer(key: ValueKey(clip.videoId), clip: clip, length: _clipLength)
                        : Image.network(YoutubePlayerController.getThumbnail(videoId: clip.videoId), fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  Text(clip.title, style: Theme.of(context).textTheme.headlineSmall),
                  Text('Card ${index + 1} of ${_clips.length} · from ${clip.start.toInt()}s'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpikePlayer extends StatefulWidget {
  final _SpikeClip clip;
  final double length;

  const _SpikePlayer({super.key, required this.clip, required this.length});

  @override
  State<_SpikePlayer> createState() => _SpikePlayerState();
}

class _SpikePlayerState extends State<_SpikePlayer> {
  late final YoutubePlayerController _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.clip.videoId,
    autoPlay: true,
    startSeconds: widget.clip.start,
    endSeconds: widget.clip.start + widget.length,
    params: const YoutubePlayerParams(mute: true, showControls: false, loop: true, playsInline: true),
  );
  bool _muted = true;

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The mute toggle sits below the player: YouTube's terms forbid
    // covering it.
    return Column(
      children: [
        Expanded(child: YoutubePlayer(controller: _controller)),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              _muted ? _controller.unMute() : _controller.mute();
              setState(() => _muted = !_muted);
            },
          ),
        ),
      ],
    );
  }
}
