import 'package:flutter/material.dart';
import 'amplifier_animation.dart'; // Make sure this import is correct

class TrackItem extends StatelessWidget {
  final String songTitle;
  final String artistName;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final bool isSelected; // Is this the currently selected track?
  final bool isPlaying;  // Is the player currently playing?

  const TrackItem({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.isDark,
    required this.onTap,
    required this.onMoreTap,
    this.isSelected = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFD8512B);
    final Color defaultIconColor = isDark ? Colors.white : Colors.black;
    final Color defaultTitleColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: isSelected ? activeColor : defaultIconColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                songTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? activeColor : defaultTitleColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                artistName == "<unknown>" ? "Unknown Artist" : artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? activeColor : defaultIconColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ✅ NEW SIMPLIFIED LOGIC
              // We only check if the item is selected.
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  // We ALWAYS show the AmplifierAnimation, and just pass the
                  // `isPlaying` flag to it. The animation widget itself
                  // will decide whether to animate or show a static state.
                  child: AmplifierAnimation(
                    color: activeColor,
                    isPlaying: isPlaying, // Pass the flag directly
                  ),
                ),

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

        Padding(
          padding: const EdgeInsets.only(left: 81.0, right: 16.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
        )
      ],
    );
  }
}