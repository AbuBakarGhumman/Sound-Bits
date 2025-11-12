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
    await _currentSongController.close();
    print("🧹 AudioPlayerService: Disposed");
  }
}

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
