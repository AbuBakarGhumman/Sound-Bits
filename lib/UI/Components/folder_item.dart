import 'package:flutter/material.dart';

class FolderItem extends StatelessWidget {
  final String folderName;
  final int trackCount;
  final bool isDark;
  final VoidCallback onTap;

  const FolderItem({
    super.key,
    required this.folderName,
    required this.trackCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use InkWell for the ripple effect on tap
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            // Padding for the main content row
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Row(
              children: [
                // 1. Leading Icon in a styled Container
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200], // Adjusted color for better contrast
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    size: 28.0,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 16.0),

                // 2. Title and Subtitle in an Expanded Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '$trackCount tracks',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Trailing chevron icon
                Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
          ),

          // 4. The Divider Line with indentation
          Padding(
            // The left padding aligns the divider with the text content
            padding: const EdgeInsets.only(left: 84.0, right: 16.0),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[600],
            ),
          )
        ],
      ),
    );
  }
}