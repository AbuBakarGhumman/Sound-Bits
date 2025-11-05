import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:marquee/marquee.dart';

class NowPlayingBar extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String? coverUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onOpenFullPlayer;

  const NowPlayingBar({
    super.key,
    required this.songTitle,
    required this.artistName,
    this.coverUrl,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onOpenFullPlayer,
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

  bool _pendingCollapsed = false;
  bool _pendingCollapseToRight = false;

  bool _isOverflowing = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant NowPlayingBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }

    if (oldWidget.songTitle != widget.songTitle ||
        oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.isPlaying != widget.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    if (!mounted || _isCollapsed) return;
    final textContext = _textKey.currentContext;
    if (textContext != null) {
      final renderBox = textContext.findRenderObject() as RenderBox;
      final titleWidth = renderBox.size.width;

      // ✅ FIXED: use a more stable available width (previous formula undercounted space)
      final availableWidth =
          (context.findRenderObject() as RenderBox?)?.size.width ?? MediaQuery.of(context).size.width;
      final usableWidth = availableWidth * 0.55; // adjust proportionally

      setState(() {
        _isOverflowing = titleWidth > usableWidth;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition.dx - _dragStartX;

    if (delta < -10 && !_isCollapsed) {
      _pendingCollapsed = true;
      _pendingCollapseToRight = false;
    } else if (delta > 10 && !_isCollapsed) {
      _pendingCollapsed = true;
      _pendingCollapseToRight = true;
    } else if (delta.abs() <= 10) {
      _pendingCollapsed = false;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_pendingCollapsed != _isCollapsed ||
        _pendingCollapseToRight != _collapseToRight) {
      setState(() {
        _isCollapsed = _pendingCollapsed;
        _collapseToRight = _pendingCollapseToRight;
      });
      if (!_isCollapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final expandedWidth = screenWidth - 20;

    final barContent = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              color: isDark ? Colors.white24 : Colors.black12,
              child: Icon(
                Icons.music_note_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!_isCollapsed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Offstage(
                    offstage: true,
                    child: Text(
                      widget.songTitle,
                      key: _textKey,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  SizedBox(
                    height: screenWidth * 0.05,
                    child: _isOverflowing
                        ? Marquee(
                      key: ValueKey(widget.songTitle), // ✅ ensures refresh
                      text: widget.songTitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                      blankSpace: 40.0,
                      velocity: 35.0,
                      pauseAfterRound: const Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration:
                      const Duration(seconds: 1),
                      decelerationDuration:
                      const Duration(milliseconds: 500),
                    )
                        : Text(
                      widget.songTitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    widget.artistName == "<unknown>"
                        ? "Unknown Artist"
                        : widget.artistName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: screenWidth * 0.033,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
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
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: InkWell(
          onTap: widget.onOpenFullPlayer,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedAlign(
            alignment: _isCollapsed
                ? (_collapseToRight
                ? Alignment.centerRight
                : Alignment.centerLeft)
                : Alignment.center,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              width: _isCollapsed ? null : expandedWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    child: barContent,
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
