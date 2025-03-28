import 'package:flutter/material.dart';

class PreviewCountdownWidget extends StatefulWidget {
  final int secondsLeft;

  const PreviewCountdownWidget({super.key, required this.secondsLeft});

  @override
  State<PreviewCountdownWidget> createState() => _PreviewCountdownWidgetState();
}

class _PreviewCountdownWidgetState extends State<PreviewCountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.secondsLeft),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F25),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🕒', style: TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(width: 4),
          Text(
            '${widget.secondsLeft}초',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
