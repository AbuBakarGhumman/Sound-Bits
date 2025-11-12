import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/song_object.dart';
import 'audio_player_service.dart';

class EngineService {
  static final EngineService _instance = EngineService._internal();
  factory EngineService() => _instance;
  EngineService._internal() {
    _listenToPlayerState();
    _listenToSongChange();
  }

  final AudioPlayerService _audioService = AudioPlayerService();

  List<Song> _currentQueue = [];
  int _currentIndex = -1;
  String? _currentFolder;
  Song? _currentSong; // ✅ added missing field

  int _repeatMode = 0;

  final _nowPlayingController = StreamController<Song?>.broadcast();
  Stream<Song?> get nowPlayingStream => _nowPlayingController.stream;

  final _playerStateController = StreamController<PlayerState>.broadcast();
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _currentQueue.length
          ? _currentQueue[_currentIndex]
          : null;

  bool get isPlaying => _audioService.isPlaying;
  List<Song> get currentQueue => List.unmodifiable(_currentQueue);
  int get repeatMode => _repeatMode;

  // ===== Song change listener from AudioPlayerService =====
  void _listenToSongChange() {
    _audioService.currentSongStream.listen((song) {
      if (song != null) {
        _currentSong = song;
        _currentIndex = _currentQueue.indexWhere((s) => s.uri == song.uri);
        _nowPlayingController.add(song);
      }
    });
  }

  // ===== Play from folder =====
  Future<void> playFromFolder({
    required List<Song> songs,
    required int index,
    required String folderName,
    bool isResuming = false,
  }) async {
    _currentQueue = songs;
    _currentIndex = index;
    _currentFolder = folderName;
    _currentSong = _currentQueue[_currentIndex];

    if (_currentIndex < 0 || _currentIndex >= _currentQueue.length) {
      _nowPlayingController.add(null);
      return;
    }

    final songToPlay = _currentQueue[_currentIndex];
    _nowPlayingController.add(songToPlay);

    if (!isResuming) {
      await _audioService.playQueue(_currentQueue, startIndex: _currentIndex);
    } else {
      await _audioService.restoreSong(
        songToPlay,
        isPlaying: _audioService.isPlaying,
      );
    }
  }

  // ===== Restore last session =====
  Future<void> restoreLastSession() async {
    final restoredData = await _audioService.getRestoredSongData();
    if (restoredData == null) {
      print("No session to restore.");
      return;
    }

    final Song restoredSong = restoredData['song'] as Song;
    final List<Song> restoredQueue =
    List<Song>.from(restoredData['queue'] as List<dynamic>).cast<Song>();
    final String restoredFolder =
        restoredData['folderName'] as String? ?? "Unknown";

    _currentQueue = restoredQueue;
    _currentIndex = restoredQueue.indexWhere((s) => s.uri == restoredSong.uri);
    _currentFolder = restoredFolder;
    _currentSong = restoredSong;

    if (_currentIndex < 0) {
      _currentIndex = 0;
      print("Restored song not found in queue, resetting to index 0.");
    }

    await _audioService.restoreSong(restoredSong);
    _nowPlayingController.add(restoredSong);
    print("Session restored: ${restoredSong.title}");
  }

  // ===== Player state listener =====
  void _listenToPlayerState() {
    _audioService.playerStateStream.listen(
          (state) async {
        if (!_playerStateController.isClosed) {
          _playerStateController.add(state);

          if (state.processingState == ProcessingState.completed) {
            print(
                "Song completed. Repeat mode: $_repeatMode, Index: $_currentIndex");

            if (_repeatMode == 2) {
              _audioService.seek(Duration.zero);
              await _audioService.play(currentSong!);
            } else if (_repeatMode == 1) {
              int nextIndex = _currentIndex + 1;
              if (nextIndex >= _currentQueue.length) nextIndex = 0;
              _currentIndex = nextIndex;
              final songToPlay = _currentQueue[_currentIndex];
              _nowPlayingController.add(songToPlay);
              await _audioService.playQueue(_currentQueue,
                  startIndex: _currentIndex);
            } else {
              final bool isLast = _currentIndex == _currentQueue.length - 1;
              if (isLast) {
                await _audioService.pause();
                _nowPlayingController.add(null);
              } else {
                _currentIndex++;
                final songToPlay = _currentQueue[_currentIndex];
                _nowPlayingController.add(songToPlay);
                await _audioService.playQueue(_currentQueue,
                    startIndex: _currentIndex);
              }
            }
          }
        }
      },
      onError: (error) =>
          print("EngineService: Error in playerStateStream -> $error"),
      onDone: () => print("EngineService: playerStateStream done."),
      cancelOnError: true,
    );
  }

  // ===== Controls =====
  Future<void> togglePlayPause() async {
    if (_audioService.isPlaying) {
      await _audioService.pause();
    } else {
      if (_audioService.currentSongObject == null && currentSong != null) {
        await _audioService.restoreSong(currentSong!, isPlaying: true);
      } else if (_audioService.currentSongObject != null) {
        await _audioService.resume();
      }
    }
    await _audioService.saveCurrentSong(
        queue: _currentQueue, folderName: _currentFolder);
  }

  Future<void> pause() async {
    await _audioService.pause();
    await _audioService.saveCurrentSong(
        queue: _currentQueue, folderName: _currentFolder);
  }

  Future<void> resume() async {
    await _audioService.resume();
    await _audioService.saveCurrentSong(
        queue: _currentQueue, folderName: _currentFolder);
  }

  void seek(Duration position) => _audioService.seek(position);

  void setRepeatMode(int mode) async {
    _repeatMode = mode;
    await _audioService.setRepeatMode(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('repeatMode', mode);
  }

  Future<void> skipNext() async {
    await _skip(1);
    await _audioService.saveCurrentSong(
        queue: _currentQueue, folderName: _currentFolder);
  }

  Future<void> skipPrevious() async {
    await _skip(-1);
    await _audioService.saveCurrentSong(
        queue: _currentQueue, folderName: _currentFolder);
  }

  Future<void> _skip(int offset) async {
    if (_currentQueue.isEmpty) return;

    int newIndex = _currentIndex + offset;

    if (_repeatMode == 1) {
      newIndex = (newIndex + _currentQueue.length) % _currentQueue.length;
    } else {
      if (newIndex < 0 || newIndex >= _currentQueue.length) {
        await _audioService.pause();
        _currentIndex = -1;
        _nowPlayingController.add(null);
        return;
      }
    }

    _currentIndex = newIndex;
    _currentSong = _currentQueue[_currentIndex];
    final songToPlay = _currentQueue[_currentIndex];
    _nowPlayingController.add(songToPlay);
    await _audioService.playQueue(_currentQueue, startIndex: _currentIndex);
  }

  Future<void> saveCurrentSession() async {
    print("EngineService: Saving current session...");
    await _audioService.saveCurrentSong(
        queue: _currentQueue, folderName: _currentFolder);
  }

  Future<void> dispose() async {
    if (!_nowPlayingController.isClosed) await _nowPlayingController.close();
    if (!_playerStateController.isClosed) await _playerStateController.close();
    await _audioService.dispose();
    print("EngineService: Disposed.");
  }
}
