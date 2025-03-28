import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/card_model.dart';
import 'widgets/memory_card.dart';
import 'widgets/preview_countdown_widget.dart';
import 'home_page.dart';
import 'widgets/game_timer_bar.dart';

class GamePage extends StatefulWidget {
  final int level;
  const GamePage({super.key, required this.level});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late List<CardModel> cards;
  int timeLeft = 23;
  int previewTimeLeft = 5;
  double previewProgress = 1.0;
  Timer? gameTimer;
  Timer? showAllTimer;
  bool canFlip = false;
  bool isPreviewing = true;
  List<int> flippedIndices = [];
  bool debugMode = false; // manually enable or disable

  Map<int, Size> levelGrid = {
    1: Size(2, 2),
    2: Size(2, 3),
    3: Size(2, 4),
    4: Size(3, 4),
    5: Size(4, 4),
    6: Size(4, 5),
    7: Size(4, 6),
    8: Size(5, 6),
  };

  Map<int, Size> levelCardSize = {
    1: Size(140, 180),
    2: Size(120, 160),
    3: Size(110, 150),
    4: Size(100, 140),
    5: Size(90, 130),
    6: Size(85, 125),
    7: Size(75, 110),
    8: Size(75, 110),
  };

  @override
  void initState() {
    super.initState();
    startLevel();
  }

  void startLevel() {
    final grid = levelGrid[widget.level]!;
    final pairCount = (grid.width * grid.height ~/ 2).toInt();
    const List<String> allImages = [
      'assets/images/card_cake.png',
      'assets/images/card_chocolate.png',
      'assets/images/card_cookie.png',
      'assets/images/card_cupIcecream.png',
      'assets/images/card_doughnut.png',
      'assets/images/card_drink.png',
      'assets/images/card_honey.png',
      'assets/images/card_icecream.png',
      'assets/images/card_icecreamCone.png',
      'assets/images/card_moonbread.png',
      'assets/images/card_muffin.png',
      'assets/images/card_pancake.png',
      'assets/images/card_popcorn.png',
      'assets/images/card_pudding.png',
      'assets/images/card_waffle.png',
    ];
    final selectedImages = allImages.sublist(0, pairCount);

    List<CardModel> tempCards = [];
    for (var path in selectedImages) {
      tempCards.add(CardModel(imagePath: path));
      tempCards.add(CardModel(imagePath: path));
    }
    tempCards.shuffle(Random());

    setState(() {
      cards = tempCards;
      canFlip = false;
      isPreviewing = true;
      previewTimeLeft = 5;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        for (var card in cards) {
          card.isFlipped = true;
        }
      });

      Timer.periodic(Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          previewTimeLeft--;
        });

        if (previewTimeLeft <= 0) {
          timer.cancel();
          if (!mounted) return;
          setState(() {
            for (var card in cards) {
              card.isFlipped = false;
            }
            isPreviewing = false;
            canFlip = true;
            startGameTimer();
          });
        }
      });
    });
  }

  void startGameTimer() {
    timeLeft = 23;
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          gameTimer?.cancel();
          canFlip = false;
          showDialog(
            context: context,
            barrierDismissible: false,
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
                          '8단계 중 ${widget.level}단계 실패',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '다음엔 꼭 맞춰보라용',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        const Text('😿', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 28),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3478F6),
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => HomePage()),
                            );
                          },
                          child: Text(
                            '다시하기',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          );
        }
      });
    });
  }

  void onCardTap(int index) {
    if (!canFlip) return;
    final tapped = cards[index];
    if (tapped.isFlipped || tapped.isMatched) return;

    setState(() {
      tapped.isFlipped = true;
      flippedIndices.add(index);
    });

    if (flippedIndices.length == 2) {
      canFlip = false;

      Future.delayed(Duration(milliseconds: 300), () {
        final first = cards[flippedIndices[0]];
        final second = cards[flippedIndices[1]];

        if (first.imagePath == second.imagePath) {
          setState(() {
            first.isMatched = true;
            second.isMatched = true;
          });
        } else {
          setState(() {
            first.isFlipped = false;
            second.isFlipped = false;
          });
        }

        flippedIndices.clear();
        setState(() {
          canFlip = true;
        });

        if (cards.every((c) => c.isMatched)) {
          gameTimer?.cancel();

          if (widget.level == 8) {
            SharedPreferences.getInstance().then((prefs) {
              final currentSuccess = prefs.getInt('successCount') ?? 0;
              prefs.setInt('successCount', currentSuccess + 1);
            });
            showDialog(
              context: context,
              barrierDismissible: false,
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
                            '축하합니다!',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '당신은 상위 1%입니다',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 28),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3478F6),
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => HomePage()),
                              );
                            },
                            child: Text(
                              '돌아가기',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            );
          } else if (widget.level < 8) {
            // 기존 단계 성공 다이얼로그
            showDialog(
              context: context,
              barrierDismissible: false,
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
                            '8단계 중 ${widget.level}단계 성공',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '${widget.level + 1}단계도 도전해보라냥!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          const Text('😺✨', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 28),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3478F6),
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder:
                                      (_) => GamePage(level: widget.level + 1),
                                ),
                              );
                            },
                            child: Text(
                              '도전하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    showAllTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grid = levelGrid[widget.level]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = grid.width.toInt();
    final crossSpacing = 6.0;
    final mainSpacing = 1.0;
    // final availableWidth =
    // screenWidth - 24; // accounting for horizontal padding
    final cardSize = levelCardSize[widget.level]!;
    final cardWidth = cardSize.width;
    final cardHeight = cardSize.height;
    final totalCardWidth =
        cardWidth * crossAxisCount + crossSpacing * (crossAxisCount - 1);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: GestureDetector(
          onTap:
              debugMode
                  ? () {
                    gameTimer?.cancel();
                    if (widget.level == 8) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
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
                                      '축하합니다!',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '당신은 상위 1%입니다',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 28),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF3478F6),
                                        minimumSize: Size(double.infinity, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => HomePage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        '돌아가기',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
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
                                      '8단계 중 ${widget.level}단계 성공',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '${widget.level + 1}단계도 도전해보라냥!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    const Text(
                                      '😺✨',
                                      style: TextStyle(fontSize: 48),
                                    ),
                                    SizedBox(height: 28),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF3478F6),
                                        minimumSize: Size(double.infinity, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => GamePage(
                                                  level: widget.level + 1,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        '도전하기',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      );
                    }
                  }
                  : null,
          child: Text(
            '레벨 ${widget.level}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        backgroundColor: Color(0xFF1F1F25),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F1F25), Color(0xFF1F1F25)],
              ),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isPreviewing)
                        Positioned.fill(
                          child: GameTimerBar(
                            timeLeft: timeLeft,
                            totalTime: 23,
                          ),
                        ),
                      if (isPreviewing)
                        PreviewCountdownWidget(secondsLeft: previewTimeLeft),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 0,
                        bottom: 4,
                      ),
                      child: SizedBox(
                        width: totalCardWidth,
                        child: GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cards.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: crossSpacing,
                                mainAxisSpacing: mainSpacing,
                                childAspectRatio: cardWidth / cardHeight,
                              ),
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: MemoryCard(
                                isFlipped: card.isFlipped || card.isMatched,
                                imagePath: card.imagePath,
                                onTap: () => onCardTap(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
