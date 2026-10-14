import 'package:flutter/material.dart';

/// Keeps all tab children alive like [IndexedStack], with a soft fade/slide
/// when the active index changes.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
    this.slideOffset = 0.018,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;
  final double slideOffset;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  late int _displayedIndex;

  @override
  void initState() {
    super.initState();
    _displayedIndex = widget.index;
  }

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      setState(() => _displayedIndex = widget.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          IgnorePointer(
            ignoring: i != _displayedIndex,
            child: AnimatedOpacity(
              opacity: i == _displayedIndex ? 1 : 0,
              duration: widget.duration,
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: i == _displayedIndex ? Offset.zero : Offset(0, widget.slideOffset),
                duration: widget.duration,
                curve: Curves.easeOutCubic,
                child: TickerMode(
                  enabled: i == _displayedIndex,
                  child: widget.children[i],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
