import 'package:flutter/material.dart';
import '../../Models/song_object.dart';
import '../Components/track_item.dart';

class TracksListPage extends StatelessWidget {
  final String name;
  final String title; // Album / Folder / Playlist name
  final List<Song> tracks;
  final Song? currentlyPlayingSong;
  final bool isPlaying;
  final Function(Song song, List<Song> allSongs, String albumName, int index)
  onPlaySong;
  final VoidCallback onGoBack; // ✅ Callback to go back to Library

  const TracksListPage({
    super.key,
    required this.name,
    required this.title,
    required this.tracks,
    required this.currentlyPlayingSong,
    required this.isPlaying,
    required this.onPlaySong,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Custom AppBar replacement (no Scaffold)
          Padding(
            padding: const EdgeInsets.only(
              left: 0,
              right: 16,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  onPressed: onGoBack, // Uses callback to return to Library
                ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (name == "Playlist")
                      GestureDetector(
                        onTap: () {},
                        child: Icon(
                          Icons.add_rounded,
                          color: isDark ? Colors.white : Colors.black,
                          size: 27,
                        ),
                      ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Icon(
                        Icons.search,
                        color: isDark ? Colors.white : Colors.black,
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ Header section (shuffle + track count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${tracks.length} tracks",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      onPlaySong(tracks.first, tracks, title, 0);
                    },
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Track List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 100.0, // Leaves space for NowPlayingBar
                ),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final song = tracks[index];
                  final isSelected = currentlyPlayingSong?.uri == song.uri;

                  return TrackItem(
                    songTitle: song.title,
                    artistName: (song.artist == "<unknown>" ||
                        song.artist.trim().isEmpty)
                        ? "Unknown Artist"
                        : song.artist,
                    thumbnail: song.thumbnail,
                    isDark: isDark,
                    isSelected: isSelected,
                    isPlaying: isSelected && isPlaying,
                    onTap: () {
                      onPlaySong(song, tracks, title, index);
                    },
                    onMoreTap: () {print("More Tapped");},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
