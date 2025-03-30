import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnimation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class MathChallengeDialog extends StatefulWidget {
  const MathChallengeDialog({super.key});

  @override
  State<MathChallengeDialog> createState() => _MathChallengeDialogState();
}

class _MathChallengeDialogState extends State<MathChallengeDialog> {
  final TextEditingController _controller = TextEditingController();
  late int a, b, c, answer;
  int currentIndex = 1;
  Color _buttonColor = const Color(0xFF3478F6);
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadProgress(); // Load progress when app starts
    _generateQuestion();
  }

  // Load progress from SharedPreferences
  void _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentIndex =
          prefs.getInt('currentIndex') ?? 1; // Default to 1 if not found
    });
  }

  void _generateQuestion() {
    final rand = Random();
    while (true) {
      a = rand.nextInt(90) + 10;
      b = rand.nextInt(90) + 10;
      c = rand.nextBool() ? rand.nextInt(9) + 1 : -(rand.nextInt(9) + 1);
      answer = a + b + c;
      if (answer >= 0 && answer <= 50) break;
    }
  }

  void _submit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == answer) {
      setState(() {
        _buttonColor = Colors.green;
      });
      Future.delayed(Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _buttonColor = const Color(0xFF3478F6);
        });
      });

      if (currentIndex < 5) {
        setState(() {
          currentIndex++;
          _controller.clear();
          _generateQuestion();
        });
        _saveProgress(); // Save progress after every step
      } else {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('lives', 3);
        });
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _buttonColor = Colors.red;
        _controller.clear();
      });
      _shakeKey.currentState?.shake();
      Future.delayed(Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _buttonColor = const Color(0xFF3478F6);
        });
      });
    }
  }

  // Save progress to SharedPreferences
  void _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('currentIndex', currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ShakeWidget(
      key: _shakeKey,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Color(0xFF2A2A30),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '수학 문제 도전',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '5문제 중 $currentIndex문제',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 24),
              Text(
                '$a + $b ${c >= 0 ? '+' : '-'} ${c.abs()} =',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white24,
                        hintText: '입력하기',
                        hintStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          color: Colors.white54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
