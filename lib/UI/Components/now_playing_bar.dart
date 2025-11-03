import 'package:flutter/material.dart';
import 'dart:math' as math;

class NowPlayingBar extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String? coverUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onTap;

  const NowPlayingBar({
    super.key,
    required this.songTitle,
    required this.artistName,
    this.coverUrl,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onTap,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isCollapsed = false;
  bool _collapseToRight = false;
  double _dragStartX = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(NowPlayingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition.dx - _dragStartX;

    if (delta < -10 && !_isCollapsed) {
      setState(() {
        _isCollapsed = true;
        _collapseToRight = false;
      });
    } else if (delta > 10 && !_isCollapsed) {
      setState(() {
        _isCollapsed = true;
        _collapseToRight = true;
      });
    } else if (delta.abs() > 10 && _isCollapsed) {
      setState(() => _isCollapsed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final collapsedWidth = screenWidth * 0.38;
    final expandedWidth = screenWidth - 20;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedAlign(
            alignment: _isCollapsed
                ? (_collapseToRight
                ? Alignment.centerRight
                : Alignment.centerLeft)
                : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: _isCollapsed ? collapsedWidth : expandedWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: const [
                            Color(0xFFD8512B),
                            Colors.purple,
                            Colors.cyan,
                            Colors.green,
                            Color(0xFFD8512B),
                          ],
                          stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                          transform: GradientRotation(
                              _controller.value * 2 * math.pi),
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.coverUrl != null
                              ? Image.network(
                            widget.coverUrl!,
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            color: isDark
                                ? Colors.white24
                                : Colors.black12,
                            child: Icon(
                              Icons.music_note_rounded,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // ✅ FIX 1: Add a SizedBox for consistent spacing.
                        const SizedBox(width: 12),

                        // ✅ FIX 2: The AnimatedSwitcher is NOT wrapped in Expanded.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                axis: Axis.horizontal,
                                child: child,
                              ),
                            );
                          },
                          child: !_isCollapsed
                              ? Column(
                            key: const ValueKey("expanded"),
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.songTitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.artistName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.033,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          )
                              : const SizedBox(
                            key: ValueKey("collapsed"),
                          ),
                        ),

                        // ✅ FIX 3: Add a Spacer() to push the button to the end.
                        const Spacer(),

                        IconButton(
                          icon: Icon(
                            widget.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: screenWidth * 0.09,
                            color: const Color(0xFFD8512B),
                          ),
                          onPressed: widget.onPlayPause,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}