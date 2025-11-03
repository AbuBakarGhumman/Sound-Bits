import 'package:flutter/material.dart';

class PlaylistItem extends StatelessWidget {
  final String playlistName;
  final int songCount;
  final bool isDark;
  final VoidCallback onTap;
  final String? coverUrl; // Optional for future use with actual images

  const PlaylistItem({
    super.key,
    required this.playlistName,
    required this.songCount,
    required this.isDark,
    required this.onTap,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use InkWell for tap effects, wrapping a Column
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Padding for the main content
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
            child: Row(
              children: [
                // 1. Leading Icon/Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: coverUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(coverUrl!, fit: BoxFit.cover),
                  )
                      : const Icon(Icons.queue_music_rounded, size: 28),
                ),
                const SizedBox(width: 15),

                // 2. Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlistName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$songCount songs',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Trailing Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),

          // 4. The Divider Line with indentation
          Padding(
            // Indent = Outer Padding (16) + Icon Width (50) + Space (15) = 81
            padding: const EdgeInsets.only(left: 81.0, right: 16.0),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
          )
        ],
      ),
    );
  }
}