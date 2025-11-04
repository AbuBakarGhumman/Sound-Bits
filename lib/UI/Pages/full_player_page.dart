import 'dart:async';
import 'package:flutter/material.dart';

class FullPlayerPage extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const FullPlayerPage({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  bool isShuffle = false;
  int repeatMode = 0; // 0 = off, 1 = repeat all, 2 = repeat one
  late bool isPlayingLocal;
  bool isFavorite = false;

  double currentPosition = 0;
  double totalDuration = 158; // example: 2:38 min
  Timer? progressTimer;

  @override
  void initState() {
    super.initState();
    isPlayingLocal = widget.isPlaying;
    if (isPlayingLocal) startProgressTimer();
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    super.dispose();
  }

  void startProgressTimer() {
    progressTimer?.cancel();
    progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPlayingLocal) {
        setState(() {
          if (currentPosition < totalDuration) {
            currentPosition++;
          } else {
            if (repeatMode == 2) {
              // repeat one
              currentPosition = 0;
            } else if (repeatMode == 1) {
              // repeat all - reset to start
              currentPosition = 0;
            } else {
              // stop at end
              isPlayingLocal = false;
              timer.cancel();
            }
          }
        });
      }
    });
  }

  void toggleShuffle() => setState(() => isShuffle = !isShuffle);
  void toggleRepeat() => setState(() => repeatMode = (repeatMode + 1) % 3);
  void toggleFavorite() => setState(() => isFavorite = !isFavorite);

  void handlePlayPause() {
    setState(() {
      isPlayingLocal = !isPlayingLocal;
    });

    widget.onPlayPause();

    if (isPlayingLocal) {
      startProgressTimer();
    } else {
      progressTimer?.cancel();
    }
  }

  String formatTime(double seconds) {
    int m = (seconds ~/ 60);
    int s = (seconds % 60).toInt();
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = const Color(0xFFD8512B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          color: isDark ? Colors.white70 : Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            color: isDark ? Colors.white70 : Colors.black87,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            color: isDark ? Colors.white70 : Colors.black87,
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        title: const Text(
          "Now Playing",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: MediaQuery.of(context).size.width * 0.75,
                width: MediaQuery.of(context).size.width * 0.75,
                color: Colors.black12,
                child: const Icon(Icons.music_note, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              widget.songTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.artistName == "<unknown>" ? "Unknown Artist" : widget.artistName,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 25),

            // Top action row (music icon, heart, add)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.music_note_outlined),
                  color: Colors.grey,
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                  color: isFavorite ? color : Colors.grey,
                  onPressed: toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: Colors.grey,
                  onPressed: () {},
                ),
              ],
            ),

            // Progress bar
            Slider(
              value: currentPosition,
              max: totalDuration,
              activeColor: color,
              inactiveColor: Colors.grey.shade700,
              onChanged: (value) {
                setState(() => currentPosition = value);
              },
              onChangeStart: (_) => progressTimer?.cancel(),
              onChangeEnd: (_) {
                if (isPlayingLocal) startProgressTimer();
              },
            ),

            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(currentPosition),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatTime(totalDuration),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: isShuffle ? color : Colors.grey,
                  ),
                  iconSize: 28,
                  onPressed: toggleShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 36,
                  color: color,
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    isPlayingLocal
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  iconSize: 70,
                  color: color,
                  onPressed: handlePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 36,
                  color: color,
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    repeatMode == 0
                        ? Icons.repeat_rounded
                        : repeatMode == 1
                        ? Icons.repeat_rounded
                        : Icons.repeat_one_rounded,
                    color: repeatMode == 0 ? Colors.grey : color,
                  ),
                  iconSize: 28,
                  onPressed: toggleRepeat,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
