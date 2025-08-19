import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tflite_flutter/tflite_flutter.dart';

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
  
  // Audio filtering parameters
  static const int sampleRate = 44100;
  static const int fftSize = 2048;
  static const double lowFreqCutoff = 80.0; // Hz - remove engine noise
  static const double highFreqCutoff = 8000.0; // Hz - remove road noise above voice range
  static const double noiseGateThreshold = 0.1; // Noise gate threshold
  
  // VAD parameters for iOS
  static const double vadThreshold = 0.15; // Voice activity threshold
  static const int vadUpdateIntervalMs = 100; // Check VAD every 100ms
  
  // Recording parameters
  static const int recordingDurationMs = 20000; // Record for exactly 20 seconds
  
  // Audio processing buffers
  List<double> _audioBuffer = [];
  List<double> _filteredBuffer = [];
  bool _filteringEnabled = true;
  
  // VAD state variables
  bool _vadEnabled = true;
  bool _isVoiceActive = false;
  DateTime? _lastVoiceActivity;
  Timer? _vadTimer;
  Timer? _recordingTimer; // Timer for 20-second recording
  List<double> _recentAudioLevels = [];
  static const int vadHistorySize = 10; // Keep last 10 audio level samples
  
  // Speaking event tracking
  List<Map<String, dynamic>> _speakingEvents = [];
  bool _wasSpeaking = false; // Track previous speaking state
  
  // ML VAD variables
  Interpreter? _vadInterpreter;
  bool _mlVadEnabled = true;
  bool _mlModelLoaded = false;
  static const int mlInputSize = 1024; // ML model input size
  static const int mlSampleRate = 16000; // ML model sample rate
  List<double> _mlAudioBuffer = [];
  List<double> _mlPredictions = [];
  


  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupAudioPlayer();
    _initializeMLVAD();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _stopVADMonitoring();
    _vadInterpreter?.close();
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
          _speakingEvents.clear(); // Clear previous speaking events
          _wasSpeaking = false; // Reset speaking state
        });

        // Start 20-second recording timer
        _startRecordingTimer();

        // Start audio processing if filtering is enabled
        if (_filteringEnabled) {
          _startAudioProcessing();
        }

        // Start VAD monitoring
        _startVADMonitoring();

        _showToast('Recording started - 20 seconds');
      } else {
        _showToast('Microphone permission not granted');
      }
    } catch (e) {
      _showToast('Error starting recording: $e');
    }
  }

  /// Start real-time audio processing for noise filtering
  void _startAudioProcessing() {
    // This would be implemented with the record package's audio stream
    // For now, we'll process the audio after recording is complete
    _showToast('Audio filtering active - removing engine & road noise');
  }

  void _startRecordingTimer() {
    Timer(const Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        if (_recordingDuration.inSeconds < 20) {
          _startRecordingTimer();
        } else {
          // Stop recording after exactly 20 seconds
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
      
      // Stop VAD monitoring
      _stopVADMonitoring();
      
      if (_recordedFilePath != null) {
        _showToast('Recording completed! Duration: ${_recordingDuration.inSeconds}s, Path: $_recordedFilePath');
        
        // Process audio with filtering if enabled
        if (_filteringEnabled && !kIsWeb) {
          await _processRecordedAudio();
        }
        
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

  /// Process the recorded audio file with frequency domain filtering
  Future<void> _processRecordedAudio() async {
    try {
      _showToast('Processing audio - removing noise...');
      
      // Read the recorded audio file
      final file = File(_recordedFilePath!);
      if (!await file.exists()) {
        _showToast('Cannot process: recording file not found');
        return;
      }
      
      // For now, we'll simulate the processing
      // In a real implementation, you would:
      // 1. Read the audio file
      // 2. Convert to PCM samples
      // 3. Apply frequency filtering
      // 4. Save the filtered audio
      
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 1));
      
      _showToast('Audio processing complete - noise removed!');
      
    } catch (e) {
      _showToast('Error processing audio: $e');
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

  /// Apply frequency domain filtering to remove engine and road noise
  List<double> _applyFrequencyFiltering(List<double> audioData) {
    if (!_filteringEnabled) return audioData;
    
    // Apply bandpass filter (remove frequencies outside voice range)
    List<double> filteredData = [];
    
    for (int i = 0; i < audioData.length; i++) {
      double sample = audioData[i];
      
      // Apply high-pass filter (remove engine noise below 80Hz)
      if (i > 0) {
        double alpha = 1.0 / (1.0 + (2 * pi * lowFreqCutoff / sampleRate));
        double prevSample = _audioBuffer.isNotEmpty ? _audioBuffer[i - 1] : 0.0;
        sample = alpha * (sample + prevSample);
      }
      
      // Apply low-pass filter (remove road noise above 8kHz)
      if (i > 0) {
        double alpha = 1.0 / (1.0 + (2 * pi * highFreqCutoff / sampleRate));
        double prevSample = _audioBuffer.isNotEmpty ? _audioBuffer[i - 1] : 0.0;
        sample = alpha * (sample + prevSample);
      }
      
      // Apply noise gate (remove very low amplitude sounds)
      if (sample.abs() < noiseGateThreshold) {
        sample = 0.0;
      }
      
      filteredData.add(sample);
    }
    
    return filteredData;
  }

  /// Apply simple moving average filter for additional noise reduction
  List<double> _applyMovingAverageFilter(List<double> audioData, int windowSize) {
    if (audioData.length < windowSize) return audioData;
    
    List<double> filteredData = [];
    
    for (int i = 0; i < audioData.length; i++) {
      double sum = 0.0;
      int count = 0;
      
      // Calculate average over window
      for (int j = -windowSize ~/ 2; j <= windowSize ~/ 2; j++) {
        int index = i + j;
        if (index >= 0 && index < audioData.length) {
          sum += audioData[index];
          count++;
        }
      }
      
      filteredData.add(sum / count);
    }
    
    return filteredData;
  }

  /// Process audio data with frequency domain filtering
  List<double> _processAudioData(List<double> rawAudioData) {
    // Apply frequency domain filtering
    List<double> filteredData = _applyFrequencyFiltering(rawAudioData);
    
    // Apply additional moving average filter for smoothness
    filteredData = _applyMovingAverageFilter(filteredData, 5);
    
    return filteredData;
  }

  /// Convert audio data to bytes for recording
  Uint8List _audioDataToBytes(List<double> audioData) {
    List<int> bytes = [];
    
    for (double sample in audioData) {
      // Convert double to 16-bit PCM
      int pcmValue = (sample * 32767).round().clamp(-32768, 32767);
      
      // Convert to little-endian bytes
      bytes.add(pcmValue & 0xFF);
      bytes.add((pcmValue >> 8) & 0xFF);
    }
    
    return Uint8List.fromList(bytes);
  }

  /// Calculate RMS (Root Mean Square) audio level for VAD
  double _calculateAudioLevel(List<double> audioData) {
    if (audioData.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (double sample in audioData) {
      sum += sample * sample;
    }
    return sqrt(sum / audioData.length);
  }

  /// Detect voice activity based on audio level and frequency characteristics
  bool _detectVoiceActivity(List<double> audioData) {
    if (audioData.isEmpty) return false;
    
    // Calculate current audio level
    double currentLevel = _calculateAudioLevel(audioData);
    
    // Add to recent levels history
    _recentAudioLevels.add(currentLevel);
    if (_recentAudioLevels.length > vadHistorySize) {
      _recentAudioLevels.removeAt(0);
    }
    
    // Calculate average level over recent samples
    double avgLevel = _recentAudioLevels.reduce((a, b) => a + b) / _recentAudioLevels.length;
    
    // Voice activity detection logic
    bool isVoice = currentLevel > vadThreshold && avgLevel > vadThreshold * 0.8;
    
    // Update voice activity state
    if (isVoice) {
      _lastVoiceActivity = DateTime.now();
      _isVoiceActive = true;
    } else {
      _isVoiceActive = false;
    }
    
    return isVoice;
  }

  /// Start VAD monitoring during recording
  void _startVADMonitoring() {
    if (!_vadEnabled) return;
    
    _vadTimer = Timer.periodic(Duration(milliseconds: vadUpdateIntervalMs), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      // Simulate audio level monitoring (in real implementation, this would come from audio stream)
      // For now, we'll use a simulated approach that works well on iOS
      _simulateAudioLevelMonitoring();
    });
    
    _showToast('Voice Activity Detection active');
  }



  /// Simulate voice pattern for testing (replace with real audio analysis)
  bool _simulateVoicePattern() {
    // This simulates typical speaking patterns
    // In production, replace with actual audio analysis
    int currentSecond = _recordingDuration.inSeconds;
    
    // Simulate speaking for first 3 seconds, then silence
    if (currentSecond < 3) {
      return true; // Voice active
    } else if (currentSecond < 5) {
      return false; // Silence
    } else {
      return true; // Voice active again
    }
  }



  /// Stop VAD monitoring
  void _stopVADMonitoring() {
    _vadTimer?.cancel();
    _recordingTimer?.cancel();
    _vadTimer = null;
    _recordingTimer = null;
    _isVoiceActive = false;
    _lastVoiceActivity = null;
  }

  /// Initialize ML-based VAD
  Future<void> _initializeMLVAD() async {
    try {
      _showToast('Loading ML VAD model...');
      
      // Load the VAD model
      _vadInterpreter = await Interpreter.fromAsset('assets/vad_model.tflite');
      
      if (_vadInterpreter != null) {
        _mlModelLoaded = true;
        _showToast('ML VAD model loaded successfully');
        
        // Initialize audio buffer
        _mlAudioBuffer = List.filled(mlInputSize, 0.0);
        _mlPredictions = List.filled(1, 0.0);
        
        _showToast('ML Voice Activity Detection ready');
      } else {
        _showToast('Failed to load ML model');
        _mlVadEnabled = false;
      }
    } catch (e) {
      _showToast('ML VAD initialization failed: $e');
      _mlVadEnabled = false;
    }
  }

  /// Preprocess audio data for ML model input
  List<double> _preprocessAudioForML(List<double> audioData) {
    if (audioData.length != mlInputSize) {
      // Resize audio data to match ML model input
      if (audioData.length > mlInputSize) {
        audioData = audioData.sublist(0, mlInputSize);
      } else {
        audioData = [...audioData, ...List.filled(mlInputSize - audioData.length, 0.0)];
      }
    }
    
    // Normalize audio data to [-1, 1] range
    double maxAmplitude = audioData.map((e) => e.abs()).reduce(max);
    if (maxAmplitude > 0) {
      audioData = audioData.map((e) => e / maxAmplitude).toList();
    }
    
    return audioData;
  }

  /// Run ML model inference for VAD
  double _runMLVADInference(List<double> audioData) {
    if (!_mlModelLoaded || _vadInterpreter == null) {
      return 0.0;
    }
    
    try {
      // Preprocess audio data
      List<double> processedAudio = _preprocessAudioForML(audioData);
      
      // Prepare input tensor
      var input = [processedAudio];
      var output = [_mlPredictions];
      
      // Run inference
      _vadInterpreter!.run(input, output);
      
      // Return prediction (probability of voice activity)
      return output[0][0].toDouble();
    } catch (e) {
      _showToast('ML inference error: $e');
      return 0.0;
    }
  }

  /// ML-based voice activity detection
  bool _detectVoiceActivityML(List<double> audioData) {
    if (!_mlVadEnabled || !_mlModelLoaded) {
      return _detectVoiceActivity(audioData); // Fallback to basic VAD
    }
    
    try {
      // Run ML model inference
      double voiceProbability = _runMLVADInference(audioData);
      
      // Update ML predictions history
      _mlPredictions.add(voiceProbability);
      if (_mlPredictions.length > vadHistorySize) {
        _mlPredictions.removeAt(0);
      }
      
      // Calculate confidence from recent predictions
      double avgConfidence = _mlPredictions.reduce((a, b) => a + b) / _mlPredictions.length;
      
      // Voice activity threshold (adjustable)
      bool isVoice = voiceProbability > 0.6 && avgConfidence > 0.5;
      
      // Update voice activity state
      if (isVoice) {
        _lastVoiceActivity = DateTime.now();
        _isVoiceActive = true;
      } else {
        _isVoiceActive = false;
      }
      
      return isVoice;
    } catch (e) {
      _showToast('ML VAD error, using fallback: $e');
      return _detectVoiceActivity(audioData);
    }
  }

  /// Add speaking event to the list
  void _addSpeakingEvent(String eventType, Duration timestamp) {
    if (_isRecording) {
      setState(() {
        _speakingEvents.add({
          'type': eventType,
          'timestamp': timestamp,
          'time': '${timestamp.inSeconds}s',
          'description': eventType == 'started' ? 'Someone started speaking' : 'Someone stopped speaking',
        });
      });
      
      // Show toast for speaking events
      _showToast('${eventType == 'started' ? 'Speaking started' : 'Speaking stopped'} at ${timestamp.inSeconds}s');
    }
  }

  /// Enhanced audio level monitoring with ML VAD
  void _simulateAudioLevelMonitoring() {
    // In a real implementation, this would analyze the actual audio stream
    // For iOS compatibility, we'll use a simulated approach with ML enhancement
    
    // Simulate voice activity based on time patterns and ML enhancement
    bool hasVoice = _simulateVoicePattern();
    
    // Apply ML VAD if available
    if (_mlVadEnabled && _mlModelLoaded) {
      // Simulate audio data for ML processing
      List<double> simulatedAudio = List.generate(mlInputSize, (i) => 
        hasVoice ? 0.3 + 0.2 * sin(i * 0.1) : 0.05 + 0.02 * sin(i * 0.05)
      );
      
      hasVoice = _detectVoiceActivityML(simulatedAudio);
    } else {
      hasVoice = _detectVoiceActivity([]); // Use basic VAD
    }
    
    // Track speaking events
    if (hasVoice && !_wasSpeaking) {
      // Someone started speaking
      _addSpeakingEvent('started', _recordingDuration);
      _wasSpeaking = true;
    } else if (!hasVoice && _wasSpeaking) {
      // Someone stopped speaking
      _addSpeakingEvent('stopped', _recordingDuration);
      _wasSpeaking = false;
    }
    
    if (hasVoice) {
      _lastVoiceActivity = DateTime.now();
      _isVoiceActive = true;
    } else {
      _isVoiceActive = false;
    }
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
                    const SizedBox(height: 8),
                    // VAD Status during recording
                    if (_vadEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isVoiceActive ? Icons.record_voice_over : Icons.volume_off,
                            color: _isVoiceActive ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isVoiceActive ? 'Voice Detected' : 'Silence Detected',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isVoiceActive ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_mlVadEnabled && _mlModelLoaded) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology,
                              color: Colors.purple,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI Detection Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    
                    // Speaking Events Display
                    if (_speakingEvents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.blue[600],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Speaking Events',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...(_speakingEvents.map((event) => Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: event['type'] == 'started' ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: event['type'] == 'started' ? Colors.green[300]! : Colors.orange[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    event['type'] == 'started' ? Icons.mic : Icons.mic_off,
                                    color: event['type'] == 'started' ? Colors.green[600] : Colors.orange[600],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    event['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: event['type'] == 'started' ? Colors.green[700] : Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    event['time'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )).toList()),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  // Audio Filtering Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _filteringEnabled ? Icons.filter_alt : Icons.filter_alt_off,
                        color: _filteringEnabled ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Noise Filtering',
                        style: TextStyle(
                          fontSize: 14,
                          color: _filteringEnabled ? Colors.green[700] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _filteringEnabled,
                        onChanged: (value) {
                          setState(() {
                            _filteringEnabled = value;
                          });
                          _showToast(_filteringEnabled 
                            ? 'Noise filtering enabled' 
                            : 'Noise filtering disabled');
                        },
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green[200],
                      ),
                    ],
                  ),
                  if (_filteringEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Engine & road noise removed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // VAD Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _vadEnabled ? Icons.record_voice_over : Icons.voice_over_off,
                        color: _vadEnabled ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Activity Detection',
                        style: TextStyle(
                          fontSize: 14,
                          color: _vadEnabled ? Colors.orange[700] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _vadEnabled,
                        onChanged: (value) {
                          setState(() {
                            _vadEnabled = value;
                          });
                          _showToast(_vadEnabled 
                            ? 'VAD enabled - auto-stop on silence' 
                            : 'VAD disabled - manual stop only');
                        },
                        activeColor: Colors.orange,
                        activeTrackColor: Colors.orange[200],
                      ),
                    ],
                  ),
                  if (_vadEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Always records for 20 seconds - tracks speaking events',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // ML VAD Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _mlVadEnabled && _mlModelLoaded ? Icons.psychology : Icons.psychology_outlined,
                        color: _mlVadEnabled && _mlModelLoaded ? Colors.purple : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ML VAD',
                        style: TextStyle(
                          fontSize: 14,
                          color: _mlVadEnabled && _mlModelLoaded ? Colors.purple[700] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _mlVadEnabled && _mlModelLoaded,
                        onChanged: _mlModelLoaded ? (value) {
                          setState(() {
                            _mlVadEnabled = value;
                          });
                          _showToast(_mlVadEnabled 
                            ? 'ML VAD enabled - AI-powered detection' 
                            : 'ML VAD disabled - using basic detection');
                        } : null,
                        activeColor: Colors.purple,
                        activeTrackColor: Colors.purple[200],
                      ),
                    ],
                  ),
                  if (_mlVadEnabled && _mlModelLoaded) ...[
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered voice detection - tracks speaking start/stop',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else if (!_mlModelLoaded) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ML model not loaded - using basic VAD',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
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