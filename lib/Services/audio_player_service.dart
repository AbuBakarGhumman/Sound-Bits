import 'dart:async';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _startPositionSaver();
  }

  final AudioPlayer _player = AudioPlayer();

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get currentPosition => _player.position;
  Duration get totalDuration => _player.duration ?? Duration.zero;

  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;
  Timer? _positionSaverTimer;

  // =========================
  // Play a song
  // =========================
  Future<void> play(Map<String, dynamic> song) async {
    _currentSong = song;
    _isPlaying = true;

    await _player.setAudioSource(AudioSource.uri(Uri.parse(song['uri'])));
    await _player.play();

    // Save immediately when a new song starts
    _saveCurrentSong();
  }

  Future<void> pause() async {
    _isPlaying = false;
    await _player.pause();
  }

  Future<void> resume() async {
    _isPlaying = true;
    await _player.play();
  }

  void seek(Duration position) => _player.seek(position);

  void setRepeatMode(int mode) {
    if (mode == 0) {
      _player.setLoopMode(LoopMode.off);
    } else if (mode == 1) {
      _player.setLoopMode(LoopMode.all);
    } else {
      _player.setLoopMode(LoopMode.one);
    }
  }

  // =========================
  // Restore last played song position
  // =========================
  Future<void> restoreLastPlayedPosition(Duration position, Duration duration) async {
    if (_player.audioSource != null && duration.inMilliseconds > 0) {
      await _player.seek(position);
      // Do not auto-play, just restore
    }
  }

  // 🔹 New method to restore entire song
  Future<void> restoreSong(Map<String, dynamic> song) async {
    _currentSong = song;
    _isPlaying = song['isPlaying'] ?? false;

    await _player.setAudioSource(AudioSource.uri(Uri.parse(song['uri'])));
    await _player.seek(Duration(milliseconds: song['position'] ?? 0));

    if (_isPlaying) {
      await _player.play();
    }
  }

  // =========================
  // Continuous position saving
  // =========================
  void _startPositionSaver() {
    _positionSaverTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentSong != null) {
        _saveCurrentSong();
      }
    });
  }

  Future<void> _saveCurrentSong() async {
    if (_currentSong == null) return;

    final prefs = await SharedPreferences.getInstance();
    final song = Map<String, dynamic>.from(_currentSong!);

    song['isPlaying'] = _isPlaying;
    song['position'] = currentPosition.inMilliseconds;
    song['duration'] = totalDuration.inMilliseconds;

    await prefs.setString('lastPlayedSong', jsonEncode(song));
  }

  void dispose() {
    _positionSaverTimer?.cancel();
    _player.dispose();
  }
}
