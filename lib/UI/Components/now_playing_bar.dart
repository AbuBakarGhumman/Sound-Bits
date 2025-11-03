import 'package:flutter/material.dart';
import 'dart:math' as math; // Needed for pi (for rotation)

class NowPlayingBar extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String? coverUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onTap;

  const NowPlayingBar({
    super.key,
    required this.songTitle,
    required this.artistName,
    this.coverUrl,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onTap,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of one full rotation
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(NowPlayingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop(); // This freezes the animation value
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // ✅ CHANGED: The gradient is now always visible.
                // The controller's `stop()` method will freeze its rotation.
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFFD8512B),
                    Colors.purple,
                    Colors.cyan,
                    Colors.green,
                    Color(0xFFD8512B),
                  ],
                  stops: const [0.0, 0.25, 0.50, 0.75,1.0],
                  transform: GradientRotation(
                      _controller.value * 2 * math.pi),
                ),
              ),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.coverUrl != null
                      ? Image.network(
                    widget.coverUrl!,
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    fit: BoxFit.fill,
                  )
                      : Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    color: isDark ? Colors.white24 : Colors.black12,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.songTitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        widget.artistName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth * 0.033,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    widget.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: screenWidth * 0.09,
                    color: const Color(0xFFD8512B),
                  ),
                  onPressed: widget.onPlayPause,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'dart:math' as math; // Needed for pi (for rotation)

// 1. Convert to a StatefulWidget to manage the animation
class NowPlayingBar extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String? coverUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onTap;

  const NowPlayingBar({
    super.key,
    required this.songTitle,
    required this.artistName,
    this.coverUrl,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onTap,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

// 2. Create the State class with a TickerProvider
class _NowPlayingBarState extends State<NowPlayingBar>
    with SingleTickerProviderStateMixin {

  // 3. Declare the AnimationController
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of one full rotation
    );

    // If the song is already playing when the widget is built, start the animation
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  // 4. Listen for changes in the isPlaying property to start/stop the animation
  @override
  void didUpdateWidget(NowPlayingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  // 5. Dispose the controller to prevent memory leaks
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16), // Slightly larger to match border
        child: AnimatedBuilder(
          // 6. Use AnimatedBuilder to rebuild only the gradient on each frame
          animation: _controller,
          builder: (context, child) {
            return Container(
              // This is the OUTER container that creates the border effect
              padding: const EdgeInsets.all(2.0), // This padding becomes the border thickness
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Only show the gradient if music is playing
                gradient: widget.isPlaying
                    ? LinearGradient(
                  colors: const [
                    Color(0xFFD8512B),
                    Colors.purple,
                    Colors.cyan,
                    Color(0xFFD8512B),
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                  // 7. Animate the gradient's transform property for rotation
                  transform: GradientRotation(
                      _controller.value * 2 * math.pi),
                )
                    : null, // No gradient when paused
                // Add a subtle border when paused
                border: widget.isPlaying
                    ? null
                    : Border.all(color: Colors.transparent, width: 2.0),
              ),
              child: child, // The actual content goes here
            );
          },
          // 8. The 'child' of the builder is the original content, which doesn't need to rebuild
          child: Container(
            // This is the INNER container with your content
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // 🎵 Album Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.coverUrl != null
                      ? Image.network(
                    widget.coverUrl!,
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    color: isDark ? Colors.white24 : Colors.black12,
                    child: Icon(
                      Icons.music_note,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 🎧 Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.songTitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        widget.artistName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth * 0.033,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // ▶️ Play / Pause Button
                IconButton(
                  icon: Icon(
                    widget.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: screenWidth * 0.09,
                    color: const Color(0xFFD8512B),
                  ),
                  onPressed: widget.onPlayPause,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/