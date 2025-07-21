// import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'constant.dart';

/// ===== AUDIO MANAGER CLASS =====
// Audio Manager Class - Handles audio playback for railway crossing simulation
class AudioManager {

  /// ===== AUDIO PLAYER INITIALIZATION =====
  // Audio player instances for different sound types
  final List<AudioPlayer> audioPlayers;
  static const audioPlayerNumber = 5;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());

  /// ===== PLAYER STATE MANAGEMENT =====
  // Get current state of specific audio player
  ProcessingState playerState(int index) => audioPlayers[index].processingState;

  // Get descriptive title for audio player based on index
  String playerTitle(int index) => "${["warning", "left train", "right train", "emergency", "effect"][index]}Player";

  /// ===== CORE AUDIO PLAYBACK METHODS =====
  // Play loop sound with specified volume and asset
  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setLoopMode(LoopMode.all);
    await player.setAsset(asset);
    player.play();
    "Loop ${playerTitle(index)}: ${audioPlayers[index].processingState}".debugPrint();
  }

  // Play one-time effect sound with default volume
  Future<void> playEffectSound(String asset) async {
    final player = audioPlayers[4];
    await player.setVolume(effectVolume);
    await player.setLoopMode(LoopMode.off);
    await player.setAsset(asset);
    player.play();
    "Play effect sound: ${audioPlayers[4].processingState}".debugPrint();
  }

  // Stop specific audio player
  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].processingState}".debugPrint();
  }

  // Stop all audio players safely
  Future<void> stopAll() async {
    for (final player in audioPlayers) {
      try {
        if (player.playing) {
          await player.stop();
          "Stop all players".debugPrint();
        }
      } catch (_) {}
    }
  }

  /// ===== WARNING SOUND METHODS =====
  // Play warning sound in loop mode
  Future<void> playWarningSound(String asset) async =>
    playLoopSound(index: 0, asset: asset, volume: warningVolume);

  /// ===== TRAIN SOUND METHODS =====
  // Play left and right train sound in loop mode
  Future<void> playLeftTrainSound() async  =>
    playLoopSound(index: 1, asset: soundTrain, volume: trainVolume);
  Future<void> playRightTrainSound() async =>
    playLoopSound(index: 2, asset: soundTrain, volume: trainVolume);
  
  /// ===== EMERGENCY SOUND METHODS =====
  // Play emergency sound in loop mode
  Future<void> playEmergencySound() async =>
    playLoopSound(index: 3, asset: soundEmergency, volume: emergencyVolume);

  /// ===== SOUND STOPPING METHODS =====
  // Stop warning sound playback
  Future<void> stopWarningSound() async => stopSound(0);
  // Stop left train sound playback
  Future<void> stopLeftTrainSound() async => stopSound(1);
  // Stop right train sound playback
  Future<void> stopRightTrainSound() async => stopSound(2);
  // Stop emergency sound playback
  Future<void> stopEmergencySound() async => stopSound(3);

  /// ===== PLAYER STATE CHECKING METHODS =====
  // Get current state of specific audio player
  PlayerState getPlayerState(int index) => audioPlayers[index].playerState;
  // Check if specific player is currently playing
  bool isPlaying(int index) => audioPlayers[index].playing;
  // Check if specific player is currently stopped
  bool isStopped(int index) => audioPlayers[index].processingState == ProcessingState.idle;
  // Check if specific player has completed playback
  bool isCompleted(int index) => audioPlayers[index].processingState == ProcessingState.completed;

  /// ===== RESOURCE CLEANUP METHODS =====
  // Dispose all audio players and release resources
  Future<void> dispose() async {
    "Disposing AudioManager".debugPrint();
    try {
      // Stop all audio players first
      await stopAll();
      
      // Dispose each audio player
      for (int i = 0; i < audioPlayers.length; i++) {
        try {
          await audioPlayers[i].dispose();
          "Disposed ${playerTitle(i)}".debugPrint();
        } catch (e) {
          "Error disposing ${playerTitle(i)}: $e".debugPrint();
        }
      }
      "AudioManager disposed successfully".debugPrint();
    } catch (e) {
      "Error during AudioManager disposal: $e".debugPrint();
    }
  }
}