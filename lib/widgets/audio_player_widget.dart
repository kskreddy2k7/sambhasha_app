import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const AudioPlayerWidget({super.key, required this.audioUrl, required this.isMe});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.audioUrl);
    } catch (e) {
      debugPrint("Audio Player Error: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
              } else if (playing != true) {
                return IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.blueAccent),
                  onPressed: _player.play,
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.pause, color: Colors.blueAccent),
                  onPressed: _player.pause,
                );
              }
            },
          ),
          Expanded(
            child: StreamBuilder<Duration?>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, snap) {
                    final duration = snap.data ?? Duration.zero;
                    return ProgressBar(
                      progress: position,
                      total: duration,
                      onSeek: (duration) {
                        _player.seek(duration);
                      },
                      barHeight: 3,
                      baseBarColor: Colors.grey[800],
                      progressBarColor: Colors.blueAccent,
                      thumbColor: Colors.blueAccent,
                      thumbRadius: 6,
                      timeLabelTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
