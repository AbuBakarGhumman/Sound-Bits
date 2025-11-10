import 'dart:async';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/song_object.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Song? _currentSong;

  bool get isPlaying => _player.playing;
  Song? get currentSongObject => _currentSong;

  // ===== Play =====
  Future<void> play(Song song) async {
    _currentSong = song;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri)));
    await _player.play();
    print("AudioPlayerService: Playing ${song.title}");
  }

  Future<void> pause() async {
    await _player.pause();
    print("AudioPlayerService: Paused");
  }

  Future<void> resume() async {
    await _player.play();
    print("AudioPlayerService: Resumed");
  }

  void seek(Duration position) => _player.seek(position);

  Future<void> setRepeatMode(int mode) async {
    // Disable internal just_audio loop mode – handled manually
    await _player.setLoopMode(LoopMode.off);
    print("AudioPlayerService: Repeat mode set (manual) => $mode");
  }


  Future<void> restoreSong(Song song, {bool isPlaying = false}) async {
    _currentSong = song;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri)));
    if (isPlaying) await _player.play();
    else await _player.pause();
    print("AudioPlayerService: Restored ${song.title}, playing: $isPlaying");
  }

  Future<Map<String, dynamic>?> getRestoredSongData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('lastPlayedSong');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        final Song restoredSong = Song.fromMap(map['song']);
        final List<Song> restoredQueue =
        (map['queue'] as List<dynamic>).map((s) => Song.fromMap(s as Map<String, dynamic>)).toList();
        return {
          'song': restoredSong,
          'queue': restoredQueue,
          'folderName': map['folderName'] ?? "Unknown",
        };
      } catch (e) {
        print("Error decoding lastPlayedSong from SharedPreferences: $e");
        await prefs.remove('lastPlayedSong');
        return null;
      }
    }
    return null;
  }

  Future<void> saveCurrentSong({List<Song>? queue, String? folderName}) async {
    if (_currentSong == null) {
      print("AudioPlayerService: No current song to save.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final songMap = _currentSong!.toMap();

    final Map<String, dynamic> saveMap = {
      'song': songMap,
      'queue': (queue ?? [_currentSong!]).map((s) => s.toMap()).toList(),
      'folderName': folderName ?? "Unknown",
    };

    await prefs.setString('lastPlayedSong', jsonEncode(saveMap));
    print("AudioPlayerService: Session saved for ${songMap['title']}");
  }

  Future<void> dispose() async {
    await _player.dispose();
    print("AudioPlayerService: Disposed player.");
  }
}
