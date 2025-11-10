import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../Models/song_object.dart';

class MusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _isFetching = false;

  // --- Singleton Pattern ---
  MusicService._internal();
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;

  // 🔥 Request storage/audio permissions (for Android 13+ too)
  Future<bool> _checkAndRequestPermission() async {
    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    final status = await [
      Permission.audio,
      Permission.storage,
      Permission.mediaLibrary,
    ].request();

    bool granted = status.values.any((s) => s.isGranted);
    if (!granted) {
      print("❌ Permission not granted to access audio files.");
    }
    return granted;
  }

  // ✅ Fetch all songs safely (returns List<Song>)
  Future<List<Song>> fetchSongs() async {
    if (_isFetching) {
      print("⚠️ A song fetch is already in progress. Aborting.");
      return [];
    }

    bool hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      print("❌ Cannot fetch songs: permission denied.");
      return [];
    }

    try {
      _isFetching = true;
      final songModels = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      print("✅ Found ${songModels.length} songs on the device.");
      if (songModels.isEmpty) {
        print("⚠️ No songs returned by OnAudioQuery. Check file formats or permissions.");
      }

      // 🔄 Convert SongModel → Song object
      final List<Song> songs = songModels.map((song) {
        return Song(
          title: song.title,
          artist: song.artist ?? "Unknown Artist",
          uri: song.data, // full file path
          album: song.album ?? "Unknown Album",
          thumbnail: null, // artwork can be queried separately when needed
        );
      }).toList();

      // Optional: print first few songs for debug
      for (var song in songs.take(5)) {
        print("🎵 ${song.title} - ${song.uri}");
      }

      return songs;
    } catch (e) {
      print("❌ Error fetching songs: $e");
      return [];
    } finally {
      _isFetching = false;
    }
  }

  // ✅ Fetch songs grouped by folder (returns Map<String, List<Song>>)
  Future<Map<String, List<Song>>> fetchFolders() async {
    final allSongs = await fetchSongs();
    if (allSongs.isEmpty) {
      print("⚠️ No songs found, so no folders will be returned.");
      return {};
    }

    final Map<String, List<Song>> folders = {};
    for (var song in allSongs) {
      final directoryPath = p.dirname(song.uri);
      folders.putIfAbsent(directoryPath, () => []).add(song);
    }

    print("📂 Processed songs into ${folders.length} folders.");
    return folders;
  }

  void exitApp() {
    SystemNavigator.pop();
  }
}
