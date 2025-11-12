import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator.pop
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart'; // Keep for PlayerState
import 'Constants/app_constants.dart';
import 'Models/song_object.dart';
import 'Services/volume_controller_service.dart';
import 'Services/engine_service.dart';
import 'UI/Components/now_playing_bar.dart';
import 'UI/Pages/full_player_page.dart';
import 'UI/Pages/splash.dart';
import 'UI/Pages/mHome.dart';
import 'UI/Pages/mLibrary.dart';
import 'UI/Pages/mPlaylists.dart';
import 'UI/Pages/mDrive.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VolumeControllerService.init();
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

  final EngineService _engine = EngineService();
  StreamSubscription<Song?>? _nowPlayingSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  int _selectedIndex = 0;
  Song? _currentlyPlayingSong;
  bool _isPlaying = false;
  final bool _showNowPlayingBar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToEngineStreams();
    _checkPermissionsAndRestore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _engine.saveCurrentSession(); // Save session on background
      // Dispose engine and stop player cleanly
    }
    super.didChangeAppLifecycleState(state);
  }

  void _listenToEngineStreams() {
    _nowPlayingSubscription = _engine.nowPlayingStream.listen((song) {
      if (mounted) setState(() => _currentlyPlayingSong = song);
    });
    _playerStateSubscription = _engine.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _checkPermissionsAndRestore() async {
    PermissionStatus statusManage = PermissionStatus.denied;
    PermissionStatus statusStorage = PermissionStatus.denied;
    PermissionStatus statusAudio = PermissionStatus.denied;

    if (Platform.isAndroid) {
      final sdkInt = await _getSdkInt() ?? 0;

      // ✅ Always request MANAGE_EXTERNAL_STORAGE for all versions
      statusManage = await Permission.manageExternalStorage.status;
      if (!statusManage.isGranted) {
        statusManage = await Permission.manageExternalStorage.request();
      }

      if (sdkInt >= 33) {
        // ✅ Android 13+ → use READ_MEDIA_AUDIO
        statusAudio = await Permission.audio.status;
        if (!statusAudio.isGranted) {
          statusAudio = await Permission.audio.request();
        }
      } else {
        // ✅ Android 12 and below → use READ/WRITE_EXTERNAL_STORAGE
        statusStorage = await Permission.storage.status;
        if (!statusStorage.isGranted) {
          statusStorage = await Permission.storage.request();
        }
      }
    }

    // ✅ Combine all permission states
    final allGranted = statusManage.isGranted &&
        (statusAudio.isGranted || statusStorage.isGranted);

    if (!mounted) return;

    setState(() {
      _permissionStatus = allGranted
          ? PermissionStatusState.granted
          : PermissionStatusState.denied;
    });

    if (_permissionStatus == PermissionStatusState.granted) {
      await _engine.restoreLastSession();
      if (mounted) {
        setState(() {
          _currentlyPlayingSong = _engine.currentSong;
          _isPlaying = _engine.isPlaying;
        });
      }
    }
  }

// ✅ Helper: Get Android SDK version safely
  Future<int> _getSdkInt() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nowPlayingSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _engine.dispose(); // Cleanly stop player and release resources
    super.dispose();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _onPlaySong(
      Song song, List<Song> allSongs, String folderName, int index) async {
    await _engine.playFromFolder(
        songs: allSongs, index: index, folderName: folderName);
  }

  void _togglePlayPause() => _engine.togglePlayPause();
  void _skipNext() => _engine.skipNext();
  void _skipPrevious() => _engine.skipPrevious();

  Future<void> _handleAppExit() async {
    print("App exit requested! Stopping player, saving session, and closing app...");
    await _engine.pause(); // Pause playback
    await _engine.saveCurrentSession(); // Save queue and info
    await _engine.dispose(); // Stop and clean audio resources
    SystemNavigator.pop(); // Exit the app cleanly
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_permissionStatus) {
      case PermissionStatusState.checking:
        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          body: const Center(child: CircularProgressIndicator(color: Color(0xFFD8512B),)),
        );

      case PermissionStatusState.denied:
        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Permission Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This app needs file access to find and play music.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _checkPermissionsAndRestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD8512B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          ),
        );

      case PermissionStatusState.granted:
        return WillPopScope(
          onWillPop: () async {
            if (_selectedIndex == 0) {
              await _handleAppExit(); // Clean exit
              return false;
            }
            return true;
          },
          child: Scaffold(
            extendBody: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            body: Stack(
              children: [
                IndexedStack(
                  index: _selectedIndex,
                  children: [
                    const MHomePage(),
                    const MPlaylistsPage(),
                    MLibraryPage(
                      currentlyPlayingSong: _currentlyPlayingSong,
                      isPlaying: _isPlaying,
                      onPlaySong: _onPlaySong,
                      onGoHome: () => setState(() => _selectedIndex = 0),
                    ),
                    const MDrivePage(),
                  ],
                ),
                if (_showNowPlayingBar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: kBottomNavigationBarHeight - 2,
                    child: NowPlayingBar(
                      song: _currentlyPlayingSong ??
                          Song(title: 'Loading...', artist: '', uri: ''),
                      isPlaying: _isPlaying,
                      onPlayPause: _togglePlayPause,
                      onNext: _skipNext,
                      onPrevious: _skipPrevious,
                      onOpenFullPlayer: () {
                        if (_currentlyPlayingSong == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullPlayerPage(
                              song: _currentlyPlayingSong!,
                              isPlaying: _isPlaying,
                              onPlayPause: _togglePlayPause,
                              onNext: _skipNext,
                              onPrevious: _skipPrevious,
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
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.queue_music), label: "Playlists"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.library_music_outlined), label: "Library"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.cloud_off), label: "Drive"),
              ],
            ),
          ),
        );
    }
  }

}
