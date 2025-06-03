import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FloatingYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onClose;

  const FloatingYoutubePlayer({
    super.key,
    required this.videoUrl,
    required this.onClose,
  });

  @override
  State<FloatingYoutubePlayer> createState() => _FloatingYoutubePlayerState();
}

class _FloatingYoutubePlayerState extends State<FloatingYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _isDragging = false;
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId == null) {
      print('Video ID bulunamadı! URL: ${widget.videoUrl}');
      return;
    }

    print('Video ID: $videoId'); // ID'yi konsola yazdır

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'tr',
        forceHD: true,
        disableDragSeek: false,
        // useHybridComposition: true, // Bu satırı kaldırın
      ),
    );
  }

  void _listener() {
    if (_controller.value.hasError) {
      print('Player state: ${_controller.value.playerState}');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          print('Player is ready');
          _controller.addListener(_listener);
        },
      ),
      builder: (context, player) {
        return GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (details) => setState(() => _position += details.delta),
          onPanEnd: (_) => setState(() => _isDragging = false),
          child: Stack(
            children: [
              Positioned(
                left: _position.dx,
                top: _position.dy,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: player,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
