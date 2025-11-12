import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/song_object.dart';

/// Singleton service integrating audio_service + just_audio
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioHandler? _audioHandler; // nullable now
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false; // Prevent double init

  Song? _currentSong;

  // ===== STREAMS =====
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  Song? get currentSongObject => _currentSong;

  // ===== INIT AUDIO SERVICE =====
  Future<void> init() async {
    if (_initialized) return; // Prevent double init

    // ❌ Don't call AudioService.init() when using just_audio_background
    _audioHandler = _MyAudioHandler(_player); // Just wrap player in handler

    _initialized = true;
    print("✅ AudioPlayerService initialized");
  }

  AudioHandler? get handler => _audioHandler;

  // ===== PLAY =====
  Future<void> play(Song song) async {
    _currentSong = song;

    if (_audioHandler == null) {
      print("⚠️ AudioHandler not initialized yet");
      return;
    }

    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist ?? "Unknown Artist",
      album: song.album ?? "Unknown Album",
      artUri: song.thumbnail != null && song.thumbnail!.isNotEmpty
          ? Uri.parse(song.thumbnail!)
          : null,
    );

    await (_audioHandler as _MyAudioHandler).updateMediaItem(mediaItem);
    await _audioHandler!.play();
    print("🎶 Now Playing: ${song.title}");
  }

  // ===== PAUSE =====
  Future<void> pause() async {
    if (_audioHandler == null) return;
    await _audioHandler!.pause();
    print("⏸️ AudioPlayerService: Paused");
  }

  // ===== RESUME =====
  Future<void> resume() async {
    if (_audioHandler == null) return;
    await _audioHandler!.play();
    print("▶️ AudioPlayerService: Resumed");
  }

  // ===== SEEK =====
  Future<void> seek(Duration position) async {
    if (_audioHandler == null) return;
    await _audioHandler!.seek(position);
  }

  // ===== REPEAT MODE =====
  Future<void> setRepeatMode(int mode) async {
    await _player.setLoopMode(LoopMode.off); // manual handling
    print("🔁 Repeat mode (manual): $mode");
  }

  // ===== RESTORE LAST SONG =====
  Future<void> restoreSong(Song song, {bool isPlaying = false}) async {
    _currentSong = song;

    if (_audioHandler == null) return;

    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist ?? "Unknown Artist",
      album: song.album ?? "Unknown Album",
      artUri: song.thumbnail != null && song.thumbnail!.isNotEmpty
          ? Uri.parse(song.thumbnail!)
          : null,
    );

    await (_audioHandler as _MyAudioHandler).updateMediaItem(mediaItem);

    if (isPlaying) {
      await _audioHandler!.play();
    } else {
      await _audioHandler!.pause();
    }

    print("🎧 Restored: ${song.title}, playing: $isPlaying");
  }

  // ===== SAVE CURRENT SONG =====
  Future<void> saveCurrentSong({List<Song>? queue, String? folderName}) async {
    if (_currentSong == null) return;

    final prefs = await SharedPreferences.getInstance();
    final songMap = _currentSong!.toMap();
    final saveMap = {
      'song': songMap,
      'queue': (queue ?? [_currentSong!]).map((s) => s.toMap()).toList(),
      'folderName': folderName ?? "Unknown",
    };

    await prefs.setString('lastPlayedSong', jsonEncode(saveMap));
    print("💾 Session saved for: ${songMap['title']}");
  }

  // ===== RESTORE SAVED SESSION =====
  Future<Map<String, dynamic>?> getRestoredSongData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('lastPlayedSong');

    if (jsonStr != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        final Song restoredSong = Song.fromMap(map['song']);
        final List<Song> restoredQueue =
        (map['queue'] as List<dynamic>).map((s) => Song.fromMap(s)).toList();

        return {
          'song': restoredSong,
          'queue': restoredQueue,
          'folderName': map['folderName'] ?? "Unknown",
        };
      } catch (e) {
        print("⚠️ Error decoding saved song: $e");
        await prefs.remove('lastPlayedSong');
        return null;
      }
    }
    return null;
  }

  // ===== DISPOSE =====
  Future<void> dispose() async {
    await _audioHandler?.stop();
    await _player.dispose();
    print("🧹 AudioPlayerService: Disposed");
  }
}

/// Custom AudioHandler connecting just_audio to audio_service
class _MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;

  _MyAudioHandler(this._player) {
    _notifyAudioPlayerEvents();
  }

  void _notifyAudioPlayerEvents() {
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ));
    });
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id), tag: item));
  }
}
