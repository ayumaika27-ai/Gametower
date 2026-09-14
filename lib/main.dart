import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TowerDefenseApp());
}

class TowerDefenseApp extends StatelessWidget {
  const TowerDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tower Defense',
      theme: ThemeData.dark(),
      home: const TowerDefenseGame(),
    );
  }
}

class Enemy {
  double x;
  double y;
  final double size;
  final double speed;

  Enemy({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class Bullet {
  double x;
  double y;
  final double speed;
  final double radius;

  Bullet({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
  });
}

class TowerDefenseGame extends StatefulWidget {
  const TowerDefenseGame({super.key});

  @override
  State<TowerDefenseGame> createState() => _TowerDefenseGameState();
}

class _TowerDefenseGameState extends State<TowerDefenseGame> {
  String gameState = "start";

  int score = 0;
  int baseHp = 3;

  final List<Enemy> enemies = [];
  final List<Bullet> bullets = [];

  final Random random = Random();

  Timer? gameTimer;
  DateTime? lastTime;
  double spawnTimer = 0;

  @override
  void initState() {
    super.initState();

    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => gameLoop(),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      gameState = "playing";
      score = 0;
      baseHp = 3;
      enemies.clear();
      bullets.clear();
      spawnTimer = 0;
      lastTime = DateTime.now();
    });
  }

  void shootBullet() {
    if (gameState != "playing") return;

    setState(() {
      bullets.add(
        Bullet(
          x: 65,
          y: 0,
          speed: 400,
          radius: 6,
        ),
      );
    });
  }

  void gameLoop() {
    if (!mounted || gameState != "playing") return;

    final now = DateTime.now();

    if (lastTime == null) {
      lastTime = now;
      return;
    }

    double dt =
        now.difference(lastTime!).inMicroseconds / 1000000.0;

    lastTime = now;

    if (dt > 0.1) dt = 0.1;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height * 0.60;

    setState(() {
      // =========================
      // SPAWN MUSUH
      // =========================
      spawnTimer += dt;

      if (spawnTimer > 1.8) {
        spawnTimer = 0;

        enemies.add(
          Enemy(
            x: screenWidth,
            y: 20 + random.nextDouble() * (screenHeight - 100),
            size: 28,
            speed: 60 + random.nextDouble() * 40,
          ),
        );
      }

      // =========================
      // UPDATE PELURU
      // =========================
      for (int i = bullets.length - 1; i >= 0; i--) {
        bullets[i].x += bullets[i].speed * dt;

        if (bullets[i].x > screenWidth) {
          bullets.removeAt(i);
        }
      }

      // =========================
      // UPDATE MUSUH
      // =========================
      for (int i = enemies.length - 1; i >= 0; i--) {
        final enemy = enemies[i];

        enemy.x -= enemy.speed * dt;

        // Musuh mencapai benteng
        if (enemy.x <= 55) {
          enemies.removeAt(i);

          baseHp--;

          if (baseHp <= 0) {
            gameState = "gameover";
          }

          continue;
        }

        // =========================
        // CEK TABRAKAN PELURU
        // =========================
        for (int j = bullets.length - 1; j >= 0; j--) {
          final bullet = bullets[j];

          if (bullet.x > enemy.x &&
              bullet.x < enemy.x + enemy.size &&
              bullet.y > enemy.y &&
              bullet.y < enemy.y + enemy.size) {
            enemies.removeAt(i);
            bullets.removeAt(j);

            score += 10;
            break;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff111111),
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // AREA GAME
            // =========================
            Expanded(
              flex: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        painter: GamePainter(
                          enemies: enemies,
                          bullets: bullets,
                        ),
                      ),

                      // =========================
                      // UI
                      // =========================
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "BENTENG: ${"❤️" * baseHp}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "SKOR: $score",
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =========================
                      // START
                      // =========================
                      if (gameState == "start")
                        GameOverlay(
                          title: "PERTAHANKAN BENTENG!",
                          description:
                              "Tembak musuh yang berjalan mendekat dari kanan sebelum mereka menghancurkan bentengmu di kiri!",
                          buttonText: "MULAI GAME",
                          color: Colors.green,
                          onPressed: startGame,
                        ),

                      // =========================
                      // GAME OVER
                      // =========================
                      if (gameState == "gameover")
                        GameOverlay(
                          title: "GAME OVER",
                          description: "Skor Kamu: $score",
                          buttonText: "MAIN LAGI",
                          color: Colors.green,
                          titleColor: Colors.red,
                          onPressed: startGame,
                        ),
                    ],
                  );
                },
              ),
            ),

            // =========================
            // AREA KONTROL
            // =========================
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xff222222),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xff444444),
                      width: 4,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        onPressed: shootBullet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xffe74c3c),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "TEMBAK PELURU! 🚀",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Tekan tombol di atas untuk menembak musuh.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// PAINTER GAME
// ======================================================

class GamePainter extends CustomPainter {
  final List<Enemy> enemies;
  final List<Bullet> bullets;

  GamePainter({
    required this.enemies,
    required this.bullets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // =========================
    // BACKGROUND
    // =========================
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xff2c3e50),
          Color(0xff1a252f),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      background,
    );

    // =========================
    // TANAH
    // =========================
    final groundPaint = Paint()
      ..color = const Color(0xff1abc9c);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - 20,
        size.width,
        20,
      ),
      groundPaint,
    );

    // =========================
    // BENTENG
    // =========================
    final towerPaint = Paint()
      ..color = const Color(0xff34495e);

    canvas.drawRect(
      const Rect.fromLTWH(
        20,
        80,
        35,
        80,
      ),
      towerPaint,
    );

    // Atap benteng
    final roofPaint = Paint()
      ..color = const Color(0xfff1c40f);

    canvas.drawRect(
      const Rect.fromLTWH(
        16,
        72,
        43,
        10,
      ),
      roofPaint,
    );

    // =========================
    // PELURU
    // =========================
    final bulletPaint = Paint()
      ..color = const Color(0xffe74c3c);

    for (final bullet in bullets) {
      canvas.drawCircle(
        Offset(bullet.x, bullet.y),
        bullet.radius,
        bulletPaint,
      );
    }

    // =========================
    // MUSUH
    // =========================
    for (final enemy in enemies) {
      final enemyPaint = Paint()
        ..color = const Color(0xffe67e22);

      canvas.drawRect(
        Rect.fromLTWH(
          enemy.x,
          enemy.y,
          enemy.size,
          enemy.size,
        ),
        enemyPaint,
      );

      // Mata putih
      final eyeWhite = Paint()..color = Colors.white;

      canvas.drawRect(
        Rect.fromLTWH(
          enemy.x + 4,
          enemy.y + 6,
          6,
          6,
        ),
        eyeWhite,
      );

      // Mata hitam
      final eyeBlack = Paint()..color = Colors.black;

      canvas.drawRect(
        Rect.fromLTWH(
          enemy.x + 6,
          enemy.y + 8,
          2,
          2,
        ),
        eyeBlack,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}

// ======================================================
// OVERLAY
// ======================================================

class GameOverlay extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final Color color;
  final Color? titleColor;
  final VoidCallback onPressed;

  const GameOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.color,
    this.titleColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor ?? Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
