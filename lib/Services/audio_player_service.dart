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

  AudioHandler? _audioHandler;
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Song? _currentSong;
  List<Song> _currentQueue = [];

  /// Stream controller for song change callback
  final _currentSongController = StreamController<Song?>.broadcast();
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  // ===== STREAMS =====
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  Song? get currentSongObject => _currentSong;

  // ===== INIT AUDIO SERVICE =====
  Future<void> init() async {
    if (_initialized) return;
    _audioHandler = _MyAudioHandler(_player);
    _initialized = true;

    // ✅ Listen for song index changes to notify UI via stream
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _currentQueue.length) {
        _currentSong = _currentQueue[index];
        _currentSongController.add(_currentSong);
      }
    });
  }

  AudioHandler? get handler => _audioHandler;

  // ===== PLAY SINGLE SONG =====
  Future<void> play(Song song) async {
    _currentSong = song;

    if (_audioHandler == null) {
      print("⚠️ AudioHandler not initialized yet");
      return;
    }

    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist == "<unknown>" ? "Unknown Artist" : song.artist,
      album: song.album ?? "Unknown Album",
      artUri: song.thumbnail != null && song.thumbnail!.isNotEmpty
          ? Uri.parse(song.thumbnail!)
          : null,
    );

    await (_audioHandler as _MyAudioHandler).updateMediaItem(mediaItem);
    await _audioHandler!.play();
    print("🎶 Now Playing: ${song.title}");
  }

  // ===== PLAY QUEUE (for skip support) =====
  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _currentQueue = songs;
    _currentSong = songs[startIndex];

    final playlist = ConcatenatingAudioSource(
      children: songs.map((s) {
        return AudioSource.uri(
          Uri.parse(s.uri),
          tag: MediaItem(
            id: s.uri,
            title: s.title,
            artist: s.artist == "<unknown>" ? "UnKnown Artist": s.artist,
            album: s.album ?? "Unknown Album",
            artUri: s.thumbnail != null && s.thumbnail!.isNotEmpty
                ? Uri.parse(s.thumbnail!)
                : null,
          ),
        );
      }).toList(),
    );

    await _player.setAudioSource(playlist, initialIndex: startIndex);
    await _player.play();

    // ✅ Trigger initial song broadcast
    _currentSongController.add(_currentSong);
    print("🎧 Playing queue (index: $startIndex)");
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
    await _player.setLoopMode(LoopMode.off);
    print("🔁 Repeat mode (manual): $mode");
  }

  // ===== RESTORE LAST SONG (Show notification even if paused) =====
  Future<void> restoreSong(Song song, {bool isPlaying = false}) async {
    _currentSong = song;
    if (_audioHandler == null) return;

    // ✅ Build MediaItem
    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist == "<unknown>" ? "Unknown Artist": song.artist,
      album: song.album ?? "Unknown Album",
      artUri: song.thumbnail != null && song.thumbnail!.isNotEmpty
          ? Uri.parse(song.thumbnail!)
          : null,
    );

    // ✅ Restore queue if available
    if (_currentQueue.isNotEmpty) {
      final playlist = ConcatenatingAudioSource(
        children: _currentQueue.map((s) {
          return AudioSource.uri(
            Uri.parse(s.uri),
            tag: MediaItem(
              id: s.uri,
              title: s.title,
              artist: s.artist=="<unknown>"? "UnKnown Artist": s.artist,
              album: s.album ?? "Unknown Album",
              artUri: s.thumbnail != null && s.thumbnail!.isNotEmpty
                  ? Uri.parse(s.thumbnail!)
                  : null,
            ),
          );
        }).toList(),
      );

      final currentIndex =
      _currentQueue.indexWhere((s) => s.uri == song.uri);
      await _player.setAudioSource(
        playlist,
        initialIndex: currentIndex >= 0 ? currentIndex : 0,
      );
    } else {
      await (_audioHandler as _MyAudioHandler).updateMediaItem(mediaItem);
    }

    // ✅ Force show notification even if paused
    await (_audioHandler as _MyAudioHandler).showNotification(mediaItem);

    // ✅ Play or pause based on flag
    if (isPlaying) {
      await _audioHandler!.play();
    } else {
      await _audioHandler!.pause();
    }

    _currentSongController.add(_currentSong);

    print("🎧 Restored: ${song.title}, playing: $isPlaying (notification forced)");
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
    await _currentSongController.close();
    print("🧹 AudioPlayerService: Disposed");
  }
}

// ===============================================================
// 🔽 INTERNAL HANDLER
// ===============================================================
class _MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  _MyAudioHandler(this._player) {
    _notifyAudioPlayerEvents();
  }

  // ✅ Listen to player events and update notification
  void _notifyAudioPlayerEvents() {
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
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
      ));
    });
  }

  // ✅ Force-show notification even if playback is paused
  Future<void> showNotification(MediaItem item) async {
    mediaItem.add(item);
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ),
    );
    print("🔔 Notification forced (paused state)");
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await AudioService.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(item.id), tag: item),
    );
  }
}
