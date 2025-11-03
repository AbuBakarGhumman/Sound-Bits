import 'package:flutter/material.dart';

class TrackItem extends StatelessWidget {
  final String songTitle;
  final String artistName;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const TrackItem({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.isDark,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use InkWell to get the onTap functionality and ripple effect
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            // Main content padding
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Leading Icon
                Icon(
                  Icons.music_note_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 28, // Slightly larger icon
                ),
                const SizedBox(width: 16),

                // 2. Title and Subtitle in a Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Trailing Icon
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  onPressed: onMoreTap,
                ),
              ],
            ),
          ),

          // 4. The Divider Line
          Padding(
            // This padding creates the indent, aligning the start of the line
            // with the start of the text content.
            padding: const EdgeInsets.only(left: 60.0, right: 16.0),
            child: Divider(
              height: 1, // This makes the divider take up minimal vertical space
              thickness: 1,
              color: Colors.grey[600],
            ),
          )
        ],
      ),
    );
  }
}