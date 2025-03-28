import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_page.dart';
import 'widgets/math_challenge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final bool debug = false;
  int lives = 3;
  int successCount = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lives = prefs.getInt('lives') ?? 3;
      successCount = prefs.getInt('successCount') ?? 0;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lives', lives);
    await prefs.setInt('successCount', successCount);
  }

  void _startGame() async {
    if (lives <= 0) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Color(0xFF1F1F25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '하트가 다 소진 되었습니다',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 45),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => MathChallengeDialog(),
                        ).then((result) {
                          if (result == true) {
                            _loadState(); // 하트 리셋 반영
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3478F6),
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '수학 문제 풀고 하트 얻기',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
      return;
    }

    setState(() {
      lives--;
    });
    await _saveState();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GamePage(level: 1)),
    ).then((_) => _loadState());
  }

  Widget _buildHeartRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isAlive = index < lives;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Image.asset(
            isAlive
                ? 'assets/images/heart.png'
                : 'assets/images/heart_empty.png',
            width: 24,
            height: 24,
          ),
        );
      }),
    );
  }

  Widget _buildMedalBox() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              '성공한 횟수',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: List.generate(
                successCount.clamp(0, 20),
                (_) =>
                    Center(child: Text('🏅', style: TextStyle(fontSize: 28))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF18171C),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _buildHeartRow(),
              ),
            ),
            SizedBox(height: 120),
            if (debug)
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('lives', 3);
                  await prefs.setInt('successCount', 0);
                  setState(() {
                    lives = 3;
                    successCount = 0;
                  });
                },
                child: Text(
                  '카드\n메모리 게임',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NeoDunggeunmo',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 48,
                    height: 1.1,
                  ),
                ),
              )
            else
              Text(
                '카드\n메모리 게임',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NeoDunggeunmo',
                  //fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 48,
                  height: 1.1,
                ),
              ),
            SizedBox(height: 32),
            _buildMedalBox(),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3478F6),
                  padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '도전하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'NeoDunggeunmo',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
