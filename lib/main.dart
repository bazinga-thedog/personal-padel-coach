import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Padel Coach',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VoiceRecorderDemo(),
    );
  }
}

class VoiceRecorderDemo extends StatefulWidget {
  const VoiceRecorderDemo({Key? key}) : super(key: key);

  @override
  _VoiceRecorderDemoState createState() => _VoiceRecorderDemoState();
}

class _VoiceRecorderDemoState extends State<VoiceRecorderDemo> {
  final TextEditingController _textController = TextEditingController();
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // On web, only request microphone permission
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
      ].request();
      
      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        _showToast('Microphone permission is required for voice recording');
      }
    } else {
      // On mobile, request both microphone and storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();
      
      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        _showToast('Microphone permission is required for voice recording');
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _playbackPosition = position;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _playbackDuration = duration;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        if (kIsWeb) {
          // On web, use simple filename
          await _audioRecorder.start(
            path: fileName,
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
          );
        } else {
          // On mobile, use app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final recordingPath = '${appDir.path}/$fileName';
          
          await _audioRecorder.start(
            path: recordingPath,
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
          );
          
          // Store the path for later use
          _recordedFilePath = recordingPath;
        }

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });

        // Start recording timer
        _startRecordingTimer();

        _showToast('Recording started...');
      } else {
        _showToast('Microphone permission not granted');
      }
    } catch (e) {
      _showToast('Error starting recording: $e');
    }
  }

  void _startRecordingTimer() {
    Timer(const Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        if (_recordingDuration.inSeconds < 5) {
          _startRecordingTimer();
        } else {
          // Call _stopRecording without awaiting since this is a void function
          _stopRecording();
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        // Use the path we set during start, or fall back to the returned path
        if (_recordedFilePath == null && path != null) {
          _recordedFilePath = path;
        }
      });
      
      if (_recordedFilePath != null) {
        _showToast('Recording completed! Duration: ${_recordingDuration.inSeconds}s, Path: $_recordedFilePath');
        
        // Debug: Check if file exists
        if (!kIsWeb) {
          try {
            final file = File(_recordedFilePath!);
            if (await file.exists()) {
              final size = await file.length();
              _showToast('File exists, size: ${size} bytes');
            } else {
              _showToast('File does not exist at path: $_recordedFilePath');
            }
          } catch (e) {
            _showToast('Error checking file: $e');
          }
        }
      } else {
        _showToast('Recording stopped but no path available');
      }
    } catch (e) {
      _showToast('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) {
      _showToast('No recording available to play');
      return;
    }

    _showToast('Attempting to play: $_recordedFilePath');

    // Check if file exists (only on mobile)
    if (!kIsWeb) {
      try {
        final file = File(_recordedFilePath!);
        if (await file.exists()) {
          final size = await file.length();
          _showToast('File found, size: ${size} bytes');
        } else {
          _showToast('File not found at: $_recordedFilePath');
          return;
        }
      } catch (e) {
        _showToast('Error checking file: $e');
        return;
      }
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      } else {
        _showToast('Starting playback...');
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
        setState(() {
          _isPlaying = true;
        });
        _showToast('Playing recording...');
      }
    } catch (e) {
      _showToast('Error playing recording: $e');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Padel Coach'),
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Recording Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    size: 48,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? 'Recording...' : 'Ready to Record',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red : Colors.grey[700],
                    ),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Recording Controls
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isRecording ? null : _startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Record (5s)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _recordedFilePath != null ? _playRecording : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? 'Stop' : 'Play',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Playback Progress
            if (_recordedFilePath != null && (kIsWeb || File(_recordedFilePath!).existsSync())) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _playbackDuration.inMilliseconds > 0
                          ? _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds
                          : 0.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_playbackPosition),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDuration(_playbackDuration),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 30),
            
            // Text Input Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Add notes about your recording...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Show Toast Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  String message = _textController.text.trim();
                  if (message.isEmpty) {
                    message = 'Please enter a message!';
                  }
                  _showToast(message);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Show Toast',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}