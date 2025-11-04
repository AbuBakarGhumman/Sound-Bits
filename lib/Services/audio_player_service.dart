import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  // The core audio player instance.
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- Singleton Pattern ---
  // This ensures we have only one instance of the player service in the whole app,
  // preventing multiple songs from playing at once.
  AudioPlayerService._internal();
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() {
    return _instance;
  }

  /// A stream that the UI can listen to. It emits the player's current state
  /// (e.g., playing, paused, completed) whenever it changes.
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Plays a given song from a Map.
  /// The Map is expected to have a 'uri' key with the path to the song.
  Future<void> play(Map<String, dynamic> song) async {
    // Extract the URI from the map. A safe cast is used.
    final String? songUri = song['uri'] as String?;

    if (songUri != null) {
      try {
        print("▶️ Playing: ${song['title']}");
        // Tell the player the new audio source and start playing.
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(songUri)));
        _audioPlayer.play();
      } catch (e) {
        print("❌ Error playing song: $e");
      }
    } else {
      // This is an important debug message if the map is missing the 'uri'.
      print("⚠️ Cannot play song: 'uri' key is missing or null in the provided map.");
    }
  }

  /// Pauses the currently playing song.
  void pause() {
    print("⏸️ Pausing player.");
    _audioPlayer.pause();
  }

  /// Resumes the currently paused song.
  void resume() {
    print("⏯️ Resuming player.");
    _audioPlayer.play();
  }

  /// Stops the player completely.
  void stop() {
    print("⏹️ Stopping player.");
    _audioPlayer.stop();
  }

  /// Releases all resources associated with the player.
  /// This should be called when the app is permanently closing to prevent memory leaks.
  void dispose() {
    _audioPlayer.dispose();
  }
}