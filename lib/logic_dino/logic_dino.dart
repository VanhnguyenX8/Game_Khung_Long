import 'dart:math';

import 'package:flutter/material.dart';
import 'package:khung_long/dino/cactus.dart';
import 'package:khung_long/dino/cloud.dart';
import 'package:khung_long/dino/constants.dart';
import 'package:khung_long/dino/dino.dart';
import 'package:khung_long/dino/game_object.dart';
import 'package:khung_long/dino/ground.dart';

class DinoRunWidget extends StatefulWidget {
  const DinoRunWidget({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _DinoRunWidgetState createState() => _DinoRunWidgetState();
}

class _DinoRunWidgetState extends State<DinoRunWidget>
    with SingleTickerProviderStateMixin {
  Dino dino = Dino();
  double runVelocity = initialVelocity;
  double runDistance = 0;
  int highScore = 0;
  TextEditingController gravityController =
      TextEditingController(text: gravity.toString());
  TextEditingController accelerationController =
      TextEditingController(text: acceleration.toString());
  TextEditingController jumpVelocityController =
      TextEditingController(text: jumpVelocity.toString());
  TextEditingController runVelocityController =
      TextEditingController(text: initialVelocity.toString());
  TextEditingController dayNightOffestController =
      TextEditingController(text: dayNightOffest.toString());

  late AnimationController worldController;
  Duration lastUpdateCall = const Duration();

  List<Cactus> cacti = [Cactus(worldLocation: const Offset(200, 0))];

  List<Ground> ground = [
    Ground(worldLocation: const Offset(0, 0)),
    Ground(worldLocation: Offset(groundSprite.imageWidth / 10, 0))
  ];

  List<Cloud> clouds = [
    Cloud(worldLocation: const Offset(100, 20)),
    Cloud(worldLocation: const Offset(200, 10)),
    Cloud(worldLocation: const Offset(350, -10)),
  ];

  @override
  void initState() {
    super.initState();
    worldController =
        AnimationController(vsync: this, duration: const Duration(days: 99));
    worldController.addListener(_update);
    // worldController.forward();
    _die();
  }

  void _die() {
    setState(() {
      worldController.stop();
      dino.die();
    });
  }

  void _newGame() {
    setState(() {
      highScore = max(highScore, runDistance.toInt());
      runDistance = 0;
      runVelocity = initialVelocity;
      dino.state = DinoState.running;
      dino.dispY = 0;
      worldController.reset();
      cacti = [
        Cactus(worldLocation: const Offset(200, 0)),
        Cactus(worldLocation: const Offset(300, 0)),
        Cactus(worldLocation: const Offset(450, 0)),
      ];

      ground = [
        Ground(worldLocation: const Offset(0, 0)),
        Ground(worldLocation: Offset(groundSprite.imageWidth / 10, 0))
      ];

      clouds = [
        Cloud(worldLocation: const Offset(100, 20)),
        Cloud(worldLocation: const Offset(200, 10)),
        Cloud(worldLocation: const Offset(350, -15)),
        Cloud(worldLocation: const Offset(500, 10)),
        Cloud(worldLocation: const Offset(550, -10)),
      ];

      worldController.forward();
    });
  }

  _update() {
    try {
      double elapsedTimeSeconds;
      dino.update(lastUpdateCall, worldController.lastElapsedDuration);
      try {
        elapsedTimeSeconds =
            (worldController.lastElapsedDuration! - lastUpdateCall)
                    .inMilliseconds /
                1000;
      } catch (_) {
        elapsedTimeSeconds = 0;
      }

      runDistance += runVelocity * elapsedTimeSeconds;
      if (runDistance < 0) runDistance = 0;
      runVelocity += acceleration * elapsedTimeSeconds;

      Size screenSize = MediaQuery.of(context).size;

      Rect dinoRect = dino.getRect(screenSize, runDistance);
      for (Cactus cactus in cacti) {
        Rect obstacleRect = cactus.getRect(screenSize, runDistance);
        if (dinoRect.overlaps(obstacleRect.deflate(20))) {
          _die();
        }

        if (obstacleRect.right < 0) {
          setState(() {
            cacti.remove(cactus);
            cacti.add(Cactus(
                worldLocation: Offset(
                    runDistance +
                        Random().nextInt(100) +
                        MediaQuery.of(context).size.width / worlToPixelRatio,
                    0)));
          });
        }
      }

      for (Ground groundlet in ground) {
        if (groundlet.getRect(screenSize, runDistance).right < 0) {
          setState(() {
            ground.remove(groundlet);
            ground.add(
              Ground(
                worldLocation: Offset(
                  ground.last.worldLocation.dx + groundSprite.imageWidth / 10,
                  0,
                ),
              ),
            );
          });
        }
      }

      for (Cloud cloud in clouds) {
        if (cloud.getRect(screenSize, runDistance).right < 0) {
          setState(() {
            clouds.remove(cloud);
            clouds.add(
              Cloud(
                worldLocation: Offset(
                  clouds.last.worldLocation.dx +
                      Random().nextInt(200) +
                      MediaQuery.of(context).size.width / worlToPixelRatio,
                  Random().nextInt(50) - 25.0,
                ),
              ),
            );
          });
        }
      }

      lastUpdateCall = worldController.lastElapsedDuration!;
    } catch (e) {
      //
    }
  }

  @override
  void dispose() {
    gravityController.dispose();
    accelerationController.dispose();
    jumpVelocityController.dispose();
    runVelocityController.dispose();
    dayNightOffestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    List<Widget> children = [];

    for (GameObject object in [...clouds, ...ground, ...cacti, dino]) {
      children.add(
        AnimatedBuilder(
          animation: worldController,
          builder: (context, _) {
            Rect objectRect = object.getRect(screenSize, runDistance);
            return Positioned(
              left: objectRect.left,
              top: objectRect.top,
              width: objectRect.width,
              height: objectRect.height,
              child: object.render(),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 5000),
        color: (runDistance ~/ dayNightOffest) % 2 == 0
            ? Colors.white
            : Colors.black,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (dino.state != DinoState.dead) {
              dino.jump();
            }
            if (dino.state == DinoState.dead) {
              _newGame();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...children,
              AnimatedBuilder(
                animation: worldController,
                builder: (context, _) {
                  return Positioned(
                    left: screenSize.width / 2 - 30,
                    top: 100,
                    child: Text(
                      'Điểm số của bạn: ' + runDistance.toInt().toString(),
                      style: TextStyle(
                        color: (runDistance ~/ dayNightOffest) % 2 == 0
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: worldController,
                builder: (context, _) {
                  return Positioned(
                    left: screenSize.width / 2 - 50,
                    top: 120,
                    child: Text(
                      'Điểm số cao nhất: ' + highScore.toString(),
                      style: TextStyle(
                        color: (runDistance ~/ dayNightOffest) % 2 == 0
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 20,
                top: 20,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    _die();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Thay đổi thông số"),
                          actions: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 25,
                                width: 280,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Trọng lực:"),
                                    SizedBox(
                                      child: TextField(
                                        controller: gravityController,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      height: 25,
                                      width: 75,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 25,
                                width: 280,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Tăng tốc:"),
                                    SizedBox(
                                      child: TextField(
                                        controller: accelerationController,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      height: 25,
                                      width: 75,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 25,
                                width: 280,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Vận tốc ban đầu:"),
                                    SizedBox(
                                      child: TextField(
                                        controller: runVelocityController,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      height: 25,
                                      width: 75,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 25,
                                width: 280,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Vận tốc nhảy:"),
                                    SizedBox(
                                      child: TextField(
                                        controller: jumpVelocityController,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      height: 25,
                                      width: 75,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 25,
                                width: 280,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Độ lệch ngày đêm"),
                                    SizedBox(
                                      height: 25,
                                      width: 75,
                                      child: TextField(
                                        controller: dayNightOffestController,
                                        key: UniqueKey(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                gravity = int.parse(gravityController.text);
                                acceleration =
                                    double.parse(accelerationController.text);
                                initialVelocity =
                                    double.parse(runVelocityController.text);
                                jumpVelocity =
                                    double.parse(jumpVelocityController.text);
                                dayNightOffest =
                                    int.parse(dayNightOffestController.text);
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "Chấp Nhận",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 10,
                child: TextButton(
                  onPressed: () {
                    _die();
                  },
                  child: const Text(
                    "Giết Khủng Long",
                    style: TextStyle(color: Colors.red),
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
