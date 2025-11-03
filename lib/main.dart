import 'package:flutter/material.dart';
import 'Constants/app_constants.dart';
import 'UI/Components/now_playing_bar.dart';
import 'UI/Pages/splash.dart';
import 'UI/Pages/mHome.dart';
import 'UI/Pages/mLibrary.dart';
import 'UI/Pages/mPlaylists.dart';
import 'UI/Pages/mDrive.dart';
import 'dart:ui'; // Needed for lerpDouble

// ✅ main() and MyApp are included here
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

      /// 🌞 Light Theme
      theme: ThemeData.light().copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),

      /// 🌙 Dark Theme
      darkTheme: ThemeData.dark().copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),

      home: const MSplashPage(),

      /// Named routes
      routes: {
        '/mHome': (context) => const MMainNavBar(),
      },
    );
  }
}

/// ----------------------
/// 🎵 Music App Main NavBar
/// ----------------------
class MMainNavBar extends StatefulWidget {
  const MMainNavBar({super.key});

  @override
  State<MMainNavBar> createState() => _MMainNavBarState();
}

// ✅ 1. Add SingleTickerProviderStateMixin to handle animations
class _MMainNavBarState extends State<MMainNavBar>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isPlaying = false;

  // ✅ 2. Declare the AnimationController
  late final AnimationController _playerAnimationController;

  final List<Widget> _pages = const [
    MHomePage(),
    MPlaylistsPage(),
    MLibraryPage(),
    MDrivePage(),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ 3. Initialize the controller
    _playerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Snap animation speed
      value: 0.0, // Start in the "down" position
    );
  }

  @override
  void dispose() {
    // ✅ 4. Don't forget to dispose the controller!
    _playerAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // ✅ 5. Gesture handler for when the user drags the player bar
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // The total distance the panel can travel. We subtract all the static UI elements.
    final fullDragDistance = MediaQuery.of(context).size.height -
        kToolbarHeight - // Approximate height of a top app bar
        kBottomNavigationBarHeight - // Height of the bottom nav
        MediaQuery.of(context).padding.top - // Status bar
        MediaQuery.of(context).padding.bottom; // Bottom system gesture area

    // Invert the delta (swiping up is negative) and normalize it to the 0.0-1.0 range
    _playerAnimationController.value -= details.primaryDelta! / fullDragDistance;
  }

  // ✅ 6. Gesture handler for when the user releases their finger
  void _onVerticalDragEnd(DragEndDetails details) {
    // Fling velocity threshold (how fast the user must swipe)
    const flingVelocityThreshold = 1000;

    // If the swipe was fast, fling it open or closed regardless of position
    if (details.primaryVelocity!.abs() > flingVelocityThreshold) {
      // Negative velocity means swiping UP
      if (details.primaryVelocity! < 0) {
        _playerAnimationController.fling(velocity: 1.0); // Fling up
      } else {
        _playerAnimationController.fling(velocity: -1.0); // Fling down
      }
    } else {
      // If the swipe was slow, snap to the nearest position based on the current value
      if (_playerAnimationController.value > 0.5) {
        _playerAnimationController.fling(velocity: 1.0); // Snap up
      } else {
        _playerAnimationController.fling(velocity: -1.0); // Snap down
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeArea = MediaQuery.of(context).padding;

    // ✅ 7. Define the min and max positions for the player bar
    const double minPlayerBottom = kBottomNavigationBarHeight - 2;
    final double maxPlayerBottom = screenHeight - kToolbarHeight - safeArea.top;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          _pages[_selectedIndex],

          // ✅ 8. Use AnimatedBuilder to rebuild the Positioned widget on every animation tick
          AnimatedBuilder(
            animation: _playerAnimationController,
            builder: (context, child) {
              // lerpDouble smoothly interpolates between two numbers based on the controller's value
              final currentBottom = lerpDouble(
                minPlayerBottom,
                maxPlayerBottom,
                _playerAnimationController.value,
              );

              return Positioned(
                left: 0,
                right: 0,
                bottom: currentBottom,
                child: GestureDetector(
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: NowPlayingBar(
                    songTitle: 'Let Me Love You',
                    artistName: 'DJ Snake ft. Justin Bieber',
                    isPlaying: _isPlaying,
                    coverUrl: 'https://i.imgur.com/ZKDPB.jpg',
                    onPlayPause: _togglePlayPause,
                    onTap: () {
                      // Tapping the bar now animates it to the top position
                      if (_playerAnimationController.value < 0.5) {
                        _playerAnimationController.fling(velocity: 1.0);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),

      /// ⚙️ Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: (isDark ? Colors.black : Colors.white),
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