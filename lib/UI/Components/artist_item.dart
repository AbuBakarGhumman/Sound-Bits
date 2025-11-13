import 'package:flutter/material.dart';

class ArtistItem extends StatelessWidget {
  final String albumTitle;
  final String? coverUrl; // Optional: for album art
  final bool isDark;
  final VoidCallback onTap;

  const ArtistItem({
    super.key,
    required this.albumTitle,
    this.coverUrl,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Art
          AspectRatio(
            aspectRatio: 1 / 1, // Makes the cover perfectly square
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: coverUrl != null
                  ? Image.network(
                coverUrl!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: isDark ? Colors.grey[600] : Colors.white,
                child: Icon(
                  Icons.person,
                  size: 88.0,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Album Info
          Text(
            albumTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2.0),
        ],
      ),
    );
  }
}