import 'package:flutter/material.dart';

class RecentlyPlayedCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isDark;
  final VoidCallback onTap;

  const RecentlyPlayedCard({
    super.key,
    required this.title,
    this.imageUrl,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      // Use a SizedBox to constrain the width of the entire component
      child: SizedBox(
        width: screenWidth * 0.3, // A bit smaller for a cleaner look
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
          mainAxisSize: MainAxisSize.min, // Take up minimum vertical space
          children: [
            // 1. The square "card" is now just the image/icon area
            AspectRatio(
              aspectRatio: 1 / 1, // This makes it perfectly square
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  color: isDark ? Colors.grey[850] : Colors.grey[200],
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.music_note_rounded,
                    size: screenWidth * 0.12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. The Text is now outside the colored container
            Padding(
              padding: const EdgeInsets.only(left: 4.0), // Slight indent for text
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}