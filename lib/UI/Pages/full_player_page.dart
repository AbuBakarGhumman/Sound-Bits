import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Services/audio_player_service.dart';
import 'package:marquee/marquee.dart';

import '../../Services/volume_controller_service.dart';
import '../../Models/song_object.dart'; // ✅ Import Song object

class FullPlayerPage extends StatefulWidget {
  final Song song; // ✅ Accept Song object
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const FullPlayerPage({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  final AudioPlayerService _audioService = AudioPlayerService();

  bool isShuffle = false;
  int repeatMode = 0; // 0 = off, 1 = repeat all, 2 = repeat one
  bool isFavorite = false;
  bool isPlayingLocal = false;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  @override
  void initState() {
    super.initState();
    isPlayingLocal = widget.isPlaying;

    _loadPlayerSettings(); // 🔸 Load saved shuffle & repeat states

    _positionSub = _audioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() => currentPosition = pos);
      }
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() => totalDuration = dur);
      }
    });
  }

  // 🔸 Load shuffle and repeat states from SharedPreferences
  Future<void> _loadPlayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isShuffle = prefs.getBool('isShuffle') ?? false;
      repeatMode = prefs.getInt('repeatMode') ?? 0;
    });
    _audioService.setRepeatMode(repeatMode);
  }

  // 🔸 Save shuffle and repeat states to SharedPreferences
  Future<void> _savePlayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isShuffle', isShuffle);
    await prefs.setInt('repeatMode', repeatMode);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  void toggleShuffle() {
    setState(() => isShuffle = !isShuffle);
    _savePlayerSettings(); // 🔸 Save on change
  }

  void toggleRepeat() {
    setState(() {
      repeatMode = (repeatMode + 1) % 3;
    });
    _audioService.setRepeatMode(repeatMode);
    _savePlayerSettings(); // 🔸 Save on change
  }

  void toggleFavorite() => setState(() => isFavorite = !isFavorite);

  void handlePlayPause() {
    setState(() => isPlayingLocal = !isPlayingLocal);
    widget.onPlayPause();
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
        centerTitle: true,
        title: const Text(
          "Now Playing",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            color: isDark ? Colors.white70 : Colors.black87,
            onPressed: () {
              VolumeControllerService.openSystemVolumePanel();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            color: isDark ? Colors.white70 : Colors.black87,
            onPressed: () {},
          ),
        ],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                height: 30,
                child: widget.song.title.length > 25
                    ? Marquee(
                  text: widget.song.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  blankSpace: 40.0,
                  velocity: 35.0,
                  pauseAfterRound: const Duration(seconds: 1),
                  startPadding: 10.0,
                  accelerationDuration: const Duration(seconds: 1),
                  decelerationDuration: const Duration(milliseconds: 500),
                )
                    : Text(
                  widget.song.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.song.artist == "<unknown>" || widget.song.artist.isEmpty
                  ? "Unknown Artist"
                  : widget.song.artist,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 65),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.music_note_outlined),
                  color: Colors.grey,
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                  color: isFavorite ? const Color(0xFF8C0D0D) : Colors.grey,
                  onPressed: toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: Colors.grey,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            Slider(
              value: currentPosition.inMilliseconds.toDouble().clamp(
                  0.0, totalDuration.inMilliseconds.toDouble().clamp(0.0, 999999999.0)),
              max: totalDuration.inMilliseconds.toDouble() == 0
                  ? 1
                  : totalDuration.inMilliseconds.toDouble(),
              activeColor: color,
              inactiveColor: Colors.grey.shade700,
              onChanged: (value) {
                setState(() {
                  currentPosition = Duration(milliseconds: value.toInt());
                });
              },
              onChangeEnd: (value) {
                _audioService.seek(Duration(milliseconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
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
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          ],
        ),
      ),
    );
  }
}
