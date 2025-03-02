import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioMessage extends StatefulWidget {
  final String audioPath;
  final bool isFromMe;

  const AudioMessage({
    Key? key,
    required this.audioPath,
    required this.isFromMe,
  }) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    try {
      // Set up audio source
      await _audioPlayer.setSource(DeviceFileSource(widget.audioPath));

      // Get duration after source is set
      final duration = await _audioPlayer.getDuration();
      if (duration != null && _mounted) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      }

      _durationSubscription =
          _audioPlayer.onDurationChanged.listen((Duration d) {
        if (_mounted) {
          setState(() => _duration = d);
        }
      });

      _positionSubscription =
          _audioPlayer.onPositionChanged.listen((Duration p) {
        if (_mounted) {
          setState(() => _position = p);
        }
      });

      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (_mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      _playerStateSubscription =
          _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (_mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
    } catch (e) {
      print('Error setting up audio player: $e');
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath));
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isFromMe ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _playPause,
                  color: widget.isFromMe ? Colors.white : Colors.black,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        max: _duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isFromMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
