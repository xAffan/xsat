import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service for handling sound effects in the quiz app
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  /// Whether sound effects are enabled
  bool get soundEnabled => _soundEnabled;

  /// Enable or disable sound effects
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Play correct answer sound
  Future<void> playCorrectSound() async {
    if (!_soundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing correct sound: $e');
      }
      // Fallback to haptic feedback if sound fails
      await HapticFeedback.lightImpact();
    }
  }

  /// Play wrong answer sound
  Future<void> playWrongSound() async {
    if (!_soundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing wrong sound: $e');
      }
      // Fallback to haptic feedback if sound fails
      await HapticFeedback.heavyImpact();
    }
  }

  /// Dispose of the audio player resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
