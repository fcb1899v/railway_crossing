import 'package:audioplayers/audioplayers.dart';
import 'package:railroad_crossing/common_extension.dart';

/// For Audio
class AudioManager {

  final List<AudioPlayer> audioPlayers;
  static const audioPlayerNumber = 5;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());
  PlayerState playerState(int index) => audioPlayers[index].state;
  String playerTitle(int index) => "${["warning", "left train", "right train", "emergency", "effectSound"][index]}Player";

  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(asset));
    "Loop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> playEffectSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(asset));
    "Play effect sound: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> stopAll() async {
    for (final player in audioPlayers) {
      try {
        if (player.state == PlayerState.playing) {
          await player.stop();
          "Stop all players".debugPrint();
        }
      } catch (_) {}
    }
  }
}