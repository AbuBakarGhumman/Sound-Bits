import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'amplifier_animation.dart'; // Make sure this import is correct

class TrackItem extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final bool isDark;
  final Uint8List? thumbnail; // ✅ Added thumbnail
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final bool isSelected; // Is this the currently selected track?
  final bool isPlaying;  // Is the player currently playing?

  const TrackItem({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.isDark,
    this.thumbnail,
    required this.onTap,
    required this.onMoreTap,
    this.isSelected = false,
    this.isPlaying = false,
  });

  @override
  State<TrackItem> createState() => _TrackItemState();
}

class _TrackItemState extends State<TrackItem> {
  File? _thumbnailFile;

  @override
  void initState() {
    super.initState();
    _prepareThumbnail();
  }

  @override
  void didUpdateWidget(covariant TrackItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnail != widget.thumbnail) {
      _prepareThumbnail();
    }
  }

  Future<void> _prepareThumbnail() async {
    if (widget.thumbnail == null || widget.thumbnail!.isEmpty) {
      _thumbnailFile = null;
      setState(() {});
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.songTitle.hashCode}.jpg');
      await file.writeAsBytes(widget.thumbnail!);
      setState(() {
        _thumbnailFile = file;
      });
    } catch (e) {
      print("❌ Failed to create thumbnail file: $e");
      _thumbnailFile = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFD8512B);
    final Color defaultIconColor = widget.isDark ? Colors.white : Colors.black;
    final Color defaultTitleColor = widget.isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _thumbnailFile != null
                                ? Image.file(
                              _thumbnailFile!,
                              fit: BoxFit.cover,
                            )
                                : Icon(
                              Icons.music_note_rounded,
                              color: widget.isSelected ? activeColor : defaultIconColor,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.songTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isSelected ? activeColor : defaultTitleColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.artistName == "<unknown>" || widget.artistName.isEmpty
                                    ? "Unknown Artist"
                                    : widget.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.isSelected ? activeColor : defaultIconColor,
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

              if (widget.isSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AmplifierAnimation(
                    color: activeColor,
                    isPlaying: widget.isPlaying,
                  ),
                ),

              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: widget.isDark ? Colors.white54 : Colors.black45,
                ),
                onPressed: widget.onMoreTap,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 81.0, right: 16.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
          ),
        )
      ],
    );
  }
}
