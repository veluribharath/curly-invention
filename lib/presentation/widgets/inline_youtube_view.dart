import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A YouTube player drawn in place, inside the scroll view that holds it.
///
/// YoutubePlayer draws its web view in the app overlay on iOS and Android, so
/// it sits outside any scroll view around it: a drag that starts on the video
/// never scrolls the page (a fast vertical one opens full screen instead), and
/// while the page scrolls the video floats over the app bar. Here the web view
/// is an ordinary child, so the scroll view wins vertical drags and the player
/// still gets taps. With [interactive] off it takes no touches at all.
class InlineYoutubeView extends StatefulWidget {
  final YoutubePlayerController controller;
  final bool interactive;

  const InlineYoutubeView({super.key, required this.controller, this.interactive = true});

  @override
  State<InlineYoutubeView> createState() => _InlineYoutubeViewState();
}

class _InlineYoutubeViewState extends State<InlineYoutubeView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(InlineYoutubeView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) _load();
  }

  // What YoutubePlayer does on mount.
  // ignore: invalid_use_of_internal_member
  void _load() => unawaited(widget.controller.init());

  @override
  Widget build(BuildContext context) {
    final view = WebViewWidget(controller: widget.controller.webViewController);
    return widget.interactive ? view : IgnorePointer(child: view);
  }
}
