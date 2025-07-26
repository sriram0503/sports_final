import 'dart:io';
import 'package:flutter/material.dart';
import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sports_c/Reusable/text_styles.dart';
import 'package:sports_c/Reusable/color.dart';

class VoiceRecorderBox extends StatefulWidget {
  const VoiceRecorderBox({super.key});

  @override
  State<VoiceRecorderBox> createState() => _VoiceRecorderBoxState();
}

class _VoiceRecorderBoxState extends State<VoiceRecorderBox> {
  AnotherAudioRecorder? _recorder;
  bool _isRecording = false;
  File? _recordedFile;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _checkAndRequestPermission();
    }
  }

  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      await _startRecording();
    } else if (status.isDenied) {
      final result = await Permission.microphone.request();
      if (result.isGranted) {
        await _startRecording();
      }
    } else {
      openAppSettings();
    }
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _recorder = AnotherAudioRecorder(path, audioFormat: AudioFormat.AAC);
      await _recorder!.initialized;
      await _recorder!.start();

      setState(() => _isRecording = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording failed: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder != null && _isRecording) {
      final result = await _recorder!.stop();
      if (result?.path != null) {
        setState(() => _recordedFile = File(result!.path!));
      }
      setState(() => _isRecording = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else if (_recordedFile != null) {
      await _player.setFilePath(_recordedFile!.path);
      await _player.play();
      setState(() => _isPlaying = true);

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  void _deleteRecording() {
    setState(() {
      _recordedFile = null;
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Keep width as per original, assuming it's part of the design
      width: MediaQuery.of(context).size.width * 0.85,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15), // Rounded corners like the image
      ),
      // Crucial change for alignment: Adjusted horizontal padding
      // This padding, combined with the mic button's padding, should
      // align the "Tap mic to record" text with the input text of other fields.
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced from 16 to 4
      child: Row(
        children: [
          // Microphone button - toggle on tap
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              // Mic icon container padding also reduced/adjusted if necessary
              padding: const EdgeInsets.all(8), // Keep this as it styles the button itself
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                color: _isRecording ? Colors.red : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Text(
              _isRecording
                  ? "Recording..."
                  : _recordedFile != null
                  ? "Audio recorded"
                  : "Tap mic to record",
              style: MyTextStyle.f14(greyColor),
            ),
          ),

          // Play/Delete buttons (only show when recording exists)
          if (_recordedFile != null) ...[
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 24,
              ),
              color: Colors.teal,
              onPressed: _togglePlayback,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 24),
              color: Colors.grey,
              onPressed: _deleteRecording,
            ),
          ],
        ],
      ),
    );
  }
}
