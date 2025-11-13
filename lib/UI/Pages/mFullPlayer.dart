import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import '../../Services/audio_player_service.dart';
import '../../Services/volume_controller_service.dart';
import '../../Models/song_object.dart';
import '../../Services/engine_service.dart';
import '../Components/track_item.dart'; // Import TrackItem

class FullPlayerPage extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final List<Song>? queue;
  final String? folder;

  const FullPlayerPage({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    this.queue,
    this.folder,
  });

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final EngineService _engine = EngineService();

  bool isShuffle = false;
  int repeatMode = 0;
  bool isFavorite = false;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  Song? currentSong;
  List<Song> currentQueue = [];
  bool isPlayingLocal = false;

  bool showQueue = false; // ✅ toggle queue visibility

  StreamSubscription<NowPlayingData>? _nowPlayingSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  @override
  void initState() {
    super.initState();

    currentSong = widget.song;
    isPlayingLocal = widget.isPlaying;
    currentQueue = widget.queue ?? [];

    _nowPlayingSub = _engine.nowPlayingStream.listen((data) {
      if (mounted) {
        setState(() {
          currentSong = data.currentSong;
          currentQueue = data.queue;
        });
      }
    });

    _playerStateSub = _engine.playerStateStream.listen((state) {
      if (mounted) setState(() => isPlayingLocal = state.playing);
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      if (mounted) setState(() => currentPosition = pos);
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => totalDuration = dur);
    });

    _loadPlayerSettings();
  }

  Future<void> _loadPlayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isShuffle = prefs.getBool('isShuffle') ?? false;
      repeatMode = prefs.getInt('repeatMode') ?? 0;
    });
    _engine.setRepeatMode(repeatMode);
  }

  Future<void> _savePlayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isShuffle', isShuffle);
    await prefs.setInt('repeatMode', repeatMode);
  }

  @override
  void dispose() {
    _nowPlayingSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  void handlePlayPause() => widget.onPlayPause();
  void handleNext() => widget.onNext();
  void handlePrevious() => widget.onPrevious();

  void toggleShuffle() {
    setState(() => isShuffle = !isShuffle);
    _savePlayerSettings();
  }

  void toggleRepeat() {
    setState(() => repeatMode = (repeatMode + 1) % 3);
    _engine.setRepeatMode(repeatMode);
    _savePlayerSettings();
  }

  void toggleFavorite() => setState(() => isFavorite = !isFavorite);

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = const Color(0xFFD8512B);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double value) => value * screenWidth / 400;
    double h(double value) => value * screenHeight / 800;
    double fs(double value) => value * screenWidth / 400;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : Colors.white, // Solid color, no transparency
        elevation: 0, // Remove shadow
        scrolledUnderElevation: 0, // Prevent color change on scroll
        surfaceTintColor: Colors.transparent, // Prevent automatic tint overlay
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: w(32)),
          color: isDark ? Colors.white70 : Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Now Playing",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fs(18)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up_rounded, size: w(28)),
            color: isDark ? Colors.white70 : Colors.black87,
            onPressed: () => VolumeControllerService.openSystemVolumePanel(),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, size: w(28)),
            color: isDark ? Colors.white70 : Colors.black87,
            onPressed: () {},
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w(20), vertical: h(15)),
        child: Column(
          children: [
            SizedBox(height: h(20)),

            // ✅ Conditional display — either album art + title OR queue list
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showQueue
                    ? ListView.builder(
                  key: const ValueKey('queueView'),
                  itemCount: currentQueue.length,
                  itemBuilder: (context, index) {
                    final song = currentQueue[index];
                    return TrackItem(
                      songTitle: song.title,
                      artistName: song.artist,
                      isDark: isDark,
                      thumbnail: song.thumbnail,
                      isSelected: currentSong?.uri == song.uri,
                      isPlaying: currentSong?.uri == song.uri && isPlayingLocal,
                      onTap: () {
                        _engine.playFromFolder(
                          songs: currentQueue,
                          index: index,
                          folderName: widget.folder ?? "Unknown",
                        );
                      },
                      onMoreTap: () {},
                    );
                  },
                )
                    : Column(
                  key: const ValueKey('mainView'),
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(w(20)),
                      child: Container(
                        height: MediaQuery.of(context).size.width * 0.75,
                        width: MediaQuery.of(context).size.width * 0.75,
                        color: Colors.black12,
                        child: currentSong != null &&
                            currentSong!.thumbnail != null
                            ? Image.memory(
                          currentSong!.thumbnail!,
                          fit: BoxFit.cover,
                        )
                            : Icon(Icons.music_note,
                            size: w(100), color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: h(25)),

                    // Title / Marquee
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(20)),
                      child: SizedBox(
                        height: h(30),
                        child: currentSong != null &&
                            currentSong!.title.length > 25
                            ? Marquee(
                          text: currentSong!.title,
                          style: TextStyle(
                              fontSize: fs(22),
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black),
                          blankSpace: w(40),
                          velocity: 35.0,
                          pauseAfterRound:
                          const Duration(seconds: 1),
                          startPadding: w(10),
                          accelerationDuration:
                          const Duration(seconds: 1),
                          decelerationDuration:
                          const Duration(milliseconds: 500),
                        )
                            : Text(
                          currentSong?.title ?? "",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: fs(22),
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(height: h(6)),

                    // Artist
                    Text(
                      currentSong == null ||
                          currentSong!.artist.isEmpty ||
                          currentSong!.artist == "<unknown>"
                          ? "Unknown Artist"
                          : currentSong!.artist,
                      style: TextStyle(
                          fontSize: fs(15),
                          color:
                          isDark ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Bottom controls stay always visible
            SizedBox(height: h(20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.queue_music, size: w(28)),
                  color: showQueue ? color :  Colors.grey,
                  onPressed: () {
                    setState(() => showQueue = !showQueue);
                  },
                ),
                IconButton(
                    icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: w(28)),
                    color: isFavorite ? const Color(0xFF8C0D0D) : Colors.grey,
                    onPressed: toggleFavorite),
                IconButton(
                    icon: Icon(Icons.add_rounded, size: w(28)),
                    color: Colors.grey,
                    onPressed: () {}),
              ],
            ),

            // ✅ Keep slider & controls visible even in queue view
            SizedBox(height: h(20)),
            Slider(
              value: currentPosition.inMilliseconds.toDouble().clamp(
                  0.0,
                  totalDuration.inMilliseconds
                      .toDouble()
                      .clamp(0.0, 999999999.0)),
              max: totalDuration.inMilliseconds.toDouble() == 0
                  ? 1
                  : totalDuration.inMilliseconds.toDouble(),
              activeColor: color,
              inactiveColor: Colors.grey.shade700,
              onChanged: (value) => setState(
                      () => currentPosition = Duration(milliseconds: value.toInt())),
              onChangeEnd: (value) =>
                  _audioService.seek(Duration(milliseconds: value.toInt())),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(25)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTime(currentPosition),
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: fs(13))),
                  Text(formatTime(totalDuration),
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: fs(13))),
                ],
              ),
            ),
            SizedBox(height: h(20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: Icon(Icons.shuffle_rounded,
                        color: isShuffle ? color : Colors.grey),
                    iconSize: w(28),
                    onPressed: toggleShuffle),
                IconButton(
                    icon: Icon(Icons.skip_previous_rounded),
                    iconSize: w(36),
                    color: color,
                    onPressed: handlePrevious),
                IconButton(
                    icon: Icon(
                        isPlayingLocal
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded),
                    iconSize: w(70),
                    color: color,
                    onPressed: handlePlayPause),
                IconButton(
                    icon: Icon(Icons.skip_next_rounded),
                    iconSize: w(36),
                    color: color,
                    onPressed: handleNext),
                IconButton(
                  icon: Icon(
                    repeatMode == 2
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: repeatMode == 0 ? Colors.grey : color,
                  ),
                  iconSize: w(28),
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
