import 'package:flutter/material.dart';

class AmplifierAnimation extends StatefulWidget {
  final Color color;
  final bool isPlaying;

  const AmplifierAnimation({
    super.key,
    required this.color,
    required this.isPlaying,
  });

  @override
  State<AmplifierAnimation> createState() => _AmplifierAnimationState();
}

class _AmplifierAnimationState extends State<AmplifierAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ✅ 1. We now animate DOUBLES (pixel heights) instead of INTS (dot counts)
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;
  late final Animation<double> _animation3;
  late final Animation<double> _animation4;

  // Define dot dimensions to make calculations easier
  static const double dotHeight = 4.0;
  static const double dotMargin = 2.0;
  static const double totalDotHeight = dotHeight + dotMargin;

  // Helper to convert a number of dots to a pixel height
  double dotsToHeight(int count) {
    if (count <= 0) return 0;
    // The height is the sum of dot heights plus the margins between them
    return (count * dotHeight) + ((count - 1) * dotMargin);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // ✅ 2. SLOW DOWN the animation for a more natural feel
      duration: const Duration(milliseconds: 2000), // Was 1200
    );

    // The tweens now animate between pixel heights calculated by our helper
    _animation1 = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(1), end: dotsToHeight(4)), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(dotsToHeight(2)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(2), end: dotsToHeight(5)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(5), end: dotsToHeight(1)), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _animation2 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(dotsToHeight(1)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(1), end: dotsToHeight(7)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(7), end: dotsToHeight(2)), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _animation3 = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(3), end: dotsToHeight(6)), weight: 50),
      TweenSequenceItem(tween: ConstantTween<double>(dotsToHeight(2)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(2), end: dotsToHeight(4)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(4), end: dotsToHeight(1)), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _animation4 = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(2), end: dotsToHeight(5)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: dotsToHeight(5), end: dotsToHeight(1)), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(dotsToHeight(1)), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));


    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AmplifierAnimation oldWidget) {
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

  Widget _buildDot() {
    return Container(
      width: dotHeight,
      height: dotHeight,
      margin: const EdgeInsets.only(top: dotMargin),
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ✅ 3. REWORKED LOGIC: This now takes a continuous height
  Widget _buildDotColumn(double height) {
    // Calculate how many full dots can fit in the current animated height
    // The formula (height + margin) / (dotHeight + margin) correctly handles the math
    final int dotCount = (height + dotMargin) ~/ totalDotHeight;

    return SizedBox(
      height: 45, // Fixed height to prevent layout shifts
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(dotCount, (index) => _buildDot()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 45,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // When playing, use the animated height value.
              // When paused, use the pre-calculated pixel height for the static dots.
              _buildDotColumn(widget.isPlaying ? _animation1.value : dotsToHeight(2)),
              _buildDotColumn(widget.isPlaying ? _animation2.value : dotsToHeight(4)),
              _buildDotColumn(widget.isPlaying ? _animation3.value : dotsToHeight(3)),
              _buildDotColumn(widget.isPlaying ? _animation4.value : dotsToHeight(1)),
            ],
          );
        },
      ),
    );
  }
}