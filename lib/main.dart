import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants/app_constants.dart';
import 'Services/audio_player_service.dart';
import 'UI/Components/now_playing_bar.dart';
import 'UI/Pages/full_player_page.dart';
import 'UI/Pages/splash.dart';
import 'UI/Pages/mHome.dart';
import 'UI/Pages/mLibrary.dart';
import 'UI/Pages/mPlaylists.dart';
import 'UI/Pages/mDrive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      darkTheme: ThemeData.dark().copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const MSplashPage(),
      routes: {
        '/mHome': (context) => const MMainNavBar(),
      },
    );
  }
}

enum PermissionStatusState { checking, granted, denied }

class MMainNavBar extends StatefulWidget {
  const MMainNavBar({super.key});

  @override
  State<MMainNavBar> createState() => _MMainNavBarState();
}

class _MMainNavBarState extends State<MMainNavBar> with WidgetsBindingObserver {
  PermissionStatusState _permissionStatus = PermissionStatusState.checking;

  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  StreamSubscription<PlayerState>? _playerStateSubscription;

  int _selectedIndex = 0;
  Map<String, dynamic>? _currentlyPlayingSong;
  bool _isPlaying = false;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [];
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndLoad();
    _listenToPlayerState();
    _loadLastPlayedSong();
  }

  // 🔹 Load last played song for display only, do not auto-play
  Future<void> _loadLastPlayedSong() async {
    final prefs = await SharedPreferences.getInstance();
    final songData = prefs.getString('lastPlayedSong');
    if (songData != null) {
      final Map<String, dynamic> song = jsonDecode(songData);

      // 🔹 Show Now Playing Bar immediately
      setState(() {
        _currentlyPlayingSong = song;
        _isPlaying = false; // show paused
      });
      _buildPages();

      // 🔹 Load the song in background without blocking UI
      final songToRestore = Map<String, dynamic>.from(song);
      songToRestore['isPlaying'] = false;
      unawaited(_audioPlayerService.restoreSong(songToRestore));
    }
  }


  Future<void> _checkPermissionsAndLoad() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    if (mounted) {
      setState(() {
        _permissionStatus =
        status.isGranted ? PermissionStatusState.granted : PermissionStatusState.denied;
      });
      if (status.isGranted) {
        _buildPages();
      }
    }
  }

  void _listenToPlayerState() {
    _playerStateSubscription = _audioPlayerService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
          }
        });
        _buildPages();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerStateSubscription?.cancel();
    _audioPlayerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No manual save needed; service handles auto-saving
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onTrackSelected(Map<String, dynamic> song) {
    setState(() {
      if (_currentlyPlayingSong != null && _currentlyPlayingSong!['id'] == song['id']) {
        _togglePlayPause();
      } else {
        _currentlyPlayingSong = song;
        _audioPlayerService.play(song);
      }
      _buildPages();
    });
  }

  void _togglePlayPause() {
    if (_currentlyPlayingSong != null) {
      if (_isPlaying) {
        _audioPlayerService.pause();
      } else {
        _audioPlayerService.resume();
      }
    }
  }

  void _buildPages() {
    _pages = [
      const MHomePage(),
      const MPlaylistsPage(),
      MLibraryPage(
        currentlyPlayingSong: _currentlyPlayingSong,
        isPlaying: _isPlaying,
        onTrackSelected: _onTrackSelected,
      ),
      const MDrivePage(),
    ];
    if (mounted) setState(() {});
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Permission Required',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'This app needs file access to find and play music. Please grant the permission to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermissionsAndLoad,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_permissionStatus) {
      case PermissionStatusState.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case PermissionStatusState.denied:
        return _buildPermissionDeniedScreen();
      case PermissionStatusState.granted:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          extendBody: true,
          backgroundColor: isDark ? Colors.black : Colors.white,
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: _pages.isNotEmpty
                    ? _pages
                    : [const Center(child: CircularProgressIndicator())],
              ),
              if (_currentlyPlayingSong != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: kBottomNavigationBarHeight - 2,
                  child: NowPlayingBar(
                    songTitle: _currentlyPlayingSong?['title'] ?? "No Song",
                    artistName: (_currentlyPlayingSong?['artist'] == null ||
                        _currentlyPlayingSong?['artist'] == "<unknown>")
                        ? "Unknown Artist"
                        : _currentlyPlayingSong!['artist'],
                    isPlaying: _isPlaying,
                    onPlayPause: _togglePlayPause,
                    onOpenFullPlayer: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullPlayerPage(
                            songTitle: _currentlyPlayingSong?['title'] ?? "No Song",
                            artistName: (_currentlyPlayingSong?['artist'] == null ||
                                _currentlyPlayingSong?['artist'] == "<unknown>")
                                ? "Unknown Artist"
                                : _currentlyPlayingSong!['artist'],
                            isPlaying: _isPlaying,
                            onPlayPause: _togglePlayPause,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFFD8512B),
            unselectedItemColor: isDark ? Colors.white70 : Colors.black87,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: "Playlists"),
              BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), label: "Library"),
              BottomNavigationBarItem(icon: Icon(Icons.cloud_off), label: "Drive"),
            ],
          ),
        );
    }
  }
}
