import 'package:flutter/material.dart';
import 'Constants/app_constants.dart';
import 'UI/Components/now_playing_bar.dart';
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

class MMainNavBar extends StatefulWidget {
  const MMainNavBar({super.key});

  @override
  State<MMainNavBar> createState() => _MMainNavBarState();
}

class _MMainNavBarState extends State<MMainNavBar> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _currentlyPlayingSong;
  bool _isPlaying = false;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ✅ ENHANCED LOGIC: Handles both switching tracks and toggling play/pause
  void _onTrackSelected(Map<String, dynamic> song) {
    setState(() {
      // Check if the tapped song is the same as the currently playing one
      if (_currentlyPlayingSong != null && _currentlyPlayingSong!['title'] == song['title']) {
        // If it is, just toggle the play/pause state
        _isPlaying = !_isPlaying;
      } else {
        // If it's a new song, switch to it and start playing
        _currentlyPlayingSong = song;
        _isPlaying = true;
      }
      _buildPages(); // Rebuild pages to pass down the new state
    });
  }

  // This is called by NowPlayingBar
  void _togglePlayPause() {
    if (_currentlyPlayingSong != null) {
      setState(() {
        _isPlaying = !_isPlaying;
        _buildPages(); // Rebuild pages to update the amplifier/pause icon in the list
      });
    }
  }

  // Helper to rebuild the list of pages with the latest state
  void _buildPages() {
    _pages = [
      const MHomePage(),
      const MPlaylistsPage(),
      // Pass all the necessary state down to the library page
      MLibraryPage(
        currentlyPlayingSong: _currentlyPlayingSong,
        isPlaying: _isPlaying,
        onTrackSelected: _onTrackSelected,
      ),
      const MDrivePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          if (_currentlyPlayingSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: kBottomNavigationBarHeight - 2,
              child: NowPlayingBar(
                songTitle: _currentlyPlayingSong!['title'] as String,
                artistName: _currentlyPlayingSong!['artist'] as String,
                isPlaying: _isPlaying,
                onPlayPause: _togglePlayPause,
                onTap: () { /* TODO: open full player screen */ },
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