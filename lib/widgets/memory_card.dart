import 'dart:math';

import 'package:flutter/material.dart';

class MemoryCard extends StatefulWidget {
  final bool isFlipped;
  final String imagePath;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.isFlipped,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final bool _isFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    final isBack = _animation.value <= (pi / 2);

    return GestureDetector(
      onTap: widget.onTap,
      child: Transform(
        alignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_animation.value),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.hardEdge,
          child: Center(
            child: Image.asset(
              isBack ? 'assets/images/card_back.png' : widget.imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
