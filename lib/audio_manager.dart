import 'package:just_audio/just_audio.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'constant.dart';

/// ===== AUDIO MANAGER CLASS =====
// Shared singleton so stopAll always targets the players that are actually audible.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  final List<AudioPlayer> audioPlayers;
  final List<int> _playGeneration;

  AudioManager._internal()
      : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer()),
        _playGeneration = List.filled(audioPlayerNumber, 0);

  ProcessingState playerState(int index) => audioPlayers[index].processingState;

  String playerTitle(int index) =>
      "${["warning", "left train", "right train", "emergency", "effect"][index]}Player";

  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    final generation = ++_playGeneration[index];
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.setLoopMode(LoopMode.all);
      await player.setAsset(asset);
      if (generation != _playGeneration[index]) return;
      await player.play();
      "Loop ${playerTitle(index)}: ${player.processingState}".debugPrint();
    } catch (e) {
      "Error playing ${playerTitle(index)}: $e".debugPrint();
    }
  }

  Future<void> playEffectSound(String asset) async {
    final player = audioPlayers[4];
    final generation = ++_playGeneration[4];
    try {
      await player.stop();
      await player.setVolume(effectVolume);
      await player.setLoopMode(LoopMode.off);
      await player.setAsset(asset);
      if (generation != _playGeneration[4]) return;
      await player.play();
      "Play effect sound: ${player.processingState}".debugPrint();
    } catch (e) {
      "Error playing effect sound: $e".debugPrint();
    }
  }

  Future<void> stopSound(int index) async {
    _playGeneration[index]++;
    try {
      await audioPlayers[index].stop();
      "Stop ${playerTitle(index)}: ${audioPlayers[index].processingState}".debugPrint();
    } catch (e) {
      "Error stopping ${playerTitle(index)}: $e".debugPrint();
    }
  }

  Future<void> stopAll() async {
    "stopAll called".debugPrint();
    for (var i = 0; i < audioPlayers.length; i++) {
      _playGeneration[i]++;
    }
    await Future.wait(List.generate(audioPlayers.length, (i) async {
      try {
        await audioPlayers[i].stop();
        "Stop all: ${playerTitle(i)}".debugPrint();
      } catch (e) {
        "Error in stopAll ${playerTitle(i)}: $e".debugPrint();
      }
    }));
  }

  Future<void> playWarningSound(String asset) async =>
      playLoopSound(index: 0, asset: asset, volume: warningVolume);

  Future<void> playLeftTrainSound() async =>
      playLoopSound(index: 1, asset: soundTrain, volume: trainVolume);
  Future<void> playRightTrainSound() async =>
      playLoopSound(index: 2, asset: soundTrain, volume: trainVolume);

  Future<void> playEmergencySound() async =>
      playLoopSound(index: 3, asset: soundEmergency, volume: emergencyVolume);

  Future<void> stopWarningSound() async => stopSound(0);
  Future<void> stopLeftTrainSound() async => stopSound(1);
  Future<void> stopRightTrainSound() async => stopSound(2);
  Future<void> stopEmergencySound() async => stopSound(3);

  PlayerState getPlayerState(int index) => audioPlayers[index].playerState;
  bool isPlaying(int index) => audioPlayers[index].playing;
  bool isStopped(int index) =>
      audioPlayers[index].processingState == ProcessingState.idle;
  bool isCompleted(int index) =>
      audioPlayers[index].processingState == ProcessingState.completed;

  Future<void> dispose() async {
    await stopAll();
  }
}
