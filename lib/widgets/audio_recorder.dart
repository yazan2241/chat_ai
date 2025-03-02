import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioRecorder extends StatefulWidget {
  final Function(String path) onAudioSaved;

  const AudioRecorder({Key? key, required this.onAudioSaved}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  StreamSubscription? _recorderSubscription;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }

      await _recorder.openRecorder();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized) return;

    try {
      if (!_isRecording) {
        await _startRecording();
      } else {
        await _stopRecording();
      }
    } catch (e) {
      print('Error toggling recording: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );

      if (_mounted) {
        setState(() {
          _isRecording = true;
          _duration = Duration.zero;
        });
      }

      // Update duration while recording
      _recorderSubscription?.cancel();
      _recorderSubscription = _recorder.onProgress?.listen((e) {
        if (_mounted) {
          setState(() {
            _duration = e.duration;
          });
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recorderSubscription?.cancel();
      final path = await _recorder.stopRecorder();

      if (_mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      if (path != null) {
        widget.onAudioSaved(path);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _mounted = false;
    _stopRecordingAndCleanup();
    super.dispose();
  }

  Future<void> _stopRecordingAndCleanup() async {
    try {
      _recorderSubscription?.cancel();
      if (_isRecording) {
        await _recorder.stopRecorder();
      }
      await _recorder.closeRecorder();
    } catch (e) {
      print('Error cleaning up recorder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDuration(_duration),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        IconButton(
          onPressed: _toggleRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          color: _isRecording ? Colors.red : Colors.blue,
        ),
      ],
    );
  }
}
