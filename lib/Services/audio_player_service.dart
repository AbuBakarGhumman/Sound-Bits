import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../Models/song_object.dart';
import 'db_service.dart';

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

  /*Future<void> playFilePath(String filePath) async {
    try {
      final filePlayer = AudioPlayer(); // Separate player instance
      await filePlayer.setFilePath(filePath);
      await filePlayer.play();

      // Optional: listen for completion and dispose automatically
      filePlayer.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          await filePlayer.dispose();
        }
      });
    } catch (e) {
      print("⚠️ Error playing file $filePath: $e");
    }
  }*/

  AudioHandler? get handler => _audioHandler;

  // ===== HELPER: Save thumbnail bytes to temporary file =====
  Future<String?> _getThumbnailPath(Uint8List? thumbnail) async {
    try {
      final dir = await getTemporaryDirectory();

      // If a real thumbnail exists → save and return it
      if (thumbnail != null && thumbnail.isNotEmpty) {
        final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(thumbnail);
        return file.path;
      }

      // No thumbnail → use default image
      final defaultImage = await rootBundle.load('Asserts/Thumbnail.jpeg');
      final defaultBytes = defaultImage.buffer.asUint8List();

      final file = File('${dir.path}/default_art.jpg');
      await file.writeAsBytes(defaultBytes, flush: true);
      return file.path;

    } catch (e) {
      print("⚠️ Failed to load thumbnail, returning null → $e");
      return null;
    }
  }


  // ===== PLAY SINGLE SONG =====
  Future<void> play(Song song) async {
    _currentSong = song;

    if (_audioHandler == null) {
      return;
    }

    final artUriPath = await _getThumbnailPath(song.thumbnail);

    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist == "<unknown>" ? "Unknown Artist" : song.artist,
      album: song.album ?? "Unknown Album",
      artUri: artUriPath != null ? Uri.file(artUriPath) : null, // <-- FIXED
    );

    await (_audioHandler as _MyAudioHandler).updateMediaItem(mediaItem);
    await _audioHandler!.play();
  }

  // ===== PLAY QUEUE (for skip support) =====
  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _currentQueue = songs;
    _currentSong = songs[startIndex];

    final playlist = ConcatenatingAudioSource(
      children: await Future.wait(songs.map((s) async {
        final artUriPath = await _getThumbnailPath(s.thumbnail);
        return AudioSource.uri(
          Uri.parse(s.uri),
          tag: MediaItem(
            id: s.uri,
            title: s.title,
            artist: s.artist == "<unknown>" ? "Unknown Artist" : s.artist,
            album: s.album ?? "Unknown Album",
            artUri: artUriPath != null ? Uri.file(artUriPath) : null, // <-- FIXED
          ),
        );
      })),
    );

    await _player.setAudioSource(playlist, initialIndex: startIndex);
    await _player.play();

    // ✅ Trigger initial song broadcast
    _currentSongController.add(_currentSong);
  }

  // ===== PAUSE =====
  Future<void> pause() async {
    if (_audioHandler == null) return;
    await _audioHandler!.pause();
  }

  // ===== RESUME =====
  Future<void> resume() async {
    if (_audioHandler == null) return;
    await _audioHandler!.play();
  }

  // ===== SEEK =====
  Future<void> seek(Duration position) async {
    if (_audioHandler == null) return;
    await _audioHandler!.seek(position);
  }

  // ===== REPEAT MODE =====
  Future<void> setRepeatMode(int mode) async {
    if (mode == 2) {
      await _player.setLoopMode(LoopMode.one);
    } else if (mode == 1) {
      await _player.setLoopMode(LoopMode.all);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  // ===== RESTORE LAST SONG (Show notification even if paused) =====
  Future<void> restoreSong(Song song, {bool isPlaying = false}) async {
    _currentSong = song;
    if (_audioHandler == null) return;

    final artUriPath = await _getThumbnailPath(song.thumbnail);

    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist == "<unknown>" ? "Unknown Artist" : song.artist,
      album: song.album ?? "Unknown Album",
      artUri: artUriPath != null ? Uri.file(artUriPath) : null,
    );

    if (_currentQueue.isNotEmpty) {
      final playlist = ConcatenatingAudioSource(
        children: await Future.wait(_currentQueue.map((s) async {
          final artUriPath = await _getThumbnailPath(s.thumbnail);
          return AudioSource.uri(
            Uri.parse(s.uri),
            tag: MediaItem(
              id: s.uri,
              title: s.title,
              artist: s.artist == "<unknown>" ? "Unknown Artist" : s.artist,
              album: s.album ?? "Unknown Album",
              artUri: artUriPath != null ? Uri.file(artUriPath) : null,
            ),
          );
        })),
      );

      final currentIndex = _currentQueue.indexWhere((s) => s.uri == song.uri);
      await _player.setAudioSource(
        playlist,
        initialIndex: currentIndex >= 0 ? currentIndex : 0,
      );
    } else {
      await (_audioHandler as _MyAudioHandler).updateMediaItem(mediaItem);
    }

    await (_audioHandler as _MyAudioHandler).showNotification(mediaItem);

    if (isPlaying) {
      await _audioHandler!.play();
    } else {
      await _audioHandler!.pause();
    }

    _currentSongController.add(_currentSong);
  }

  // ===== SAVE CURRENT SONG =====
  // ===== SAVE CURRENT SONG SESSION =====
  Future<void> saveCurrentSong({List<Song>? queue, String? folderName}) async {
    if (_currentSong == null) return;

    try {
      //await DBHelper.instance.clearSession();

      await DBHelper.instance.saveSession(
        currentSong: _currentSong!,
        queue: queue ?? [_currentSong!],
        folderName: folderName ?? "Unknown",
      );
    } catch (e) {
      print("⚠️ Error saving session: $e");
    }
  }

// ===== RESTORE SAVED SESSION =====
  Future<Map<String, dynamic>?> getRestoredSongData() async {
    try {
      final sessionData = await DBHelper.instance.getSession();

      if (sessionData != null) {
        return sessionData;
      }
    } catch (e) {
      print("⚠️ Error restoring session: $e");
    }
    return null;
  }

  // ===== DISPOSE =====
  Future<void> dispose() async {
    await _audioHandler?.stop();
    await _player.dispose();
    await _currentSongController.close();
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

  // ✅ Listen to player events and update notification safely
  void _notifyAudioPlayerEvents() {
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
          playing: false,
        ));
        return;
      }

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

  // ===== PLAY AUDIO FILE DIRECTLY (Separate Player, Does NOT affect app's main player) =====
  Future<void> playFilePath(String filePath) async {
    try {
      final filePlayer = AudioPlayer(); // Separate player instance
      await filePlayer.setFilePath(filePath);
      await filePlayer.play();

      // Optional: listen for completion and dispose automatically
      filePlayer.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          await filePlayer.dispose();
        }
      });
    } catch (e) {
      print("⚠️ Error playing file $filePath: $e");
    }
  }


}
