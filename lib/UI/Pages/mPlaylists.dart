import 'package:flutter/material.dart';
import '../../Constants/app_constants.dart';
import '../Components/playlist_item.dart'; // Import the updated component
import '../Components/splash_title.dart';

class MPlaylistsPage extends StatelessWidget {
  const MPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dummy data for the list of playlists
    final List<Map<String, dynamic>> playlists = List.generate(
      15,
          (i) => {'name': 'Playlist Name ${i + 1}', 'songs': (i + 1) * 3},
    );

    return SafeArea(
      bottom: false,
      // ✅ The Padding widget has been removed from here.
      // The Column is now the direct child, making it full-width.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ✅ The Padding widget now ONLY wraps the header Row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SplashTitle("My Playlists", screenWidth * 0.08),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: InkWell(
                      onTap: () {
                        // TODO: Add new playlist logic
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.add,
                          color: isDark ? Colors.white : Colors.black,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// 📜 Playlist List
          // This Expanded widget will now take the full width of the screen.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return PlaylistItem(
                      playlistName: playlist['name'] as String,
                      songCount: playlist['songs'] as int,
                      isDark: isDark,
                      onTap: () {
                        // TODO: Navigate to playlist details
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}