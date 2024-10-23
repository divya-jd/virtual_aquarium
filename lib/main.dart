import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VirtualAquarium(),
    );
  }
}

class Fish {
  Color color;
  double speed;
  Offset position;
  double dx;
  double dy;
  double size;
  bool scaling;

  Fish({required this.color, required this.speed})
      : dx = (Random().nextDouble() - 0.5) * speed,
        dy = (Random().nextDouble() - 0.5) * speed,
        position = const Offset(150, 150),
        size = 1.0,
        scaling = true;

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AnimatedScale(
        scale: scaling ? 1.2 : 1.0,
        duration: const Duration(seconds: 1),
        onEnd: () {
          scaling = false;
        },
        child: CustomPaint(
          size: Size(50 * size, 30 * size),
          painter: FishPainter(color: color),
        ),
      ),
    );
  }

  void moveFish() {
    position = Offset(position.dx + dx, position.dy + dy);

    if (position.dx <= 0 || position.dx >= 280) dx = -dx;
    if (position.dy <= 0 || position.dy >= 280) dy = -dy;
  }
}

class FishPainter extends CustomPainter {
  final Color color;

  FishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Fish body
    canvas.drawOval(
      Rect.fromLTWH(0, size.height / 4, size.width * 0.7, size.height * 0.5),
      paint,
    );

    // Fish tail
    var tailPath = Path();
    tailPath.moveTo(size.width * 0.7, size.height / 2);
    tailPath.lineTo(size.width * 0.9, size.height * 0.3);
    tailPath.lineTo(size.width * 0.9, size.height * 0.7);
    tailPath.close();
    canvas.drawPath(tailPath, paint);

    // Fish eye
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 2, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class VirtualAquarium extends StatefulWidget {
  @override
  _VirtualAquariumState createState() => _VirtualAquariumState();
}

class _VirtualAquariumState extends State<VirtualAquarium>
    with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  double selectedSpeed = 1.0;
  Color selectedColor = Colors.blue;
  late AnimationController _controller;
  bool collisionEnabled = true;
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..addListener(() {
        _moveFish();
      });
    _controller.repeat();
    _dbHelper = DatabaseHelper();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getSettings();
    if (settings != null) {
      setState(() {
        selectedSpeed = settings['fishSpeed'];
        selectedColor = Color(int.parse(settings['fishColor']));
        fishList = List.generate(settings['fishCount'], (index) {
          return Fish(color: selectedColor, speed: selectedSpeed);
        });
      });
    } else {
      // If no saved settings, initialize with defaults
      fishList = List.generate(3, (index) {
        return Fish(color: selectedColor, speed: selectedSpeed);
      });
    }
  }

  Future<void> _saveSettings() async {
    await _dbHelper.saveSettings({
      'fishCount': fishList.length,
      'fishSpeed': selectedSpeed,
      'fishColor': selectedColor.value.toString(),
    });
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        Fish newFish = Fish(color: selectedColor, speed: selectedSpeed);
        newFish.scaling = true;
        fishList.add(newFish);
      });
    }
  }

  void _moveFish() {
    for (Fish fish in fishList) {
      fish.moveFish();
    }
    setState(() {});

    if (collisionEnabled) {
      _checkForCollisions();
    }
  }

  void _checkForCollisions() {
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        Fish fish1 = fishList[i];
        Fish fish2 = fishList[j];

        if ((fish1.position.dx - fish2.position.dx).abs() < 40 &&
            (fish1.position.dy - fish2.position.dy).abs() < 30) {
          fish1.dx = -fish1.dx;
          fish2.dx = -fish2.dx;

          setState(() {
            fish1.color = _randomColor();
            fish2.color = _randomColor();
          });
        }
      }
    }
  }

  Color _randomColor() {
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              color: Colors.lightBlue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: fishList.map((fish) => fish.buildFish()).toList(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              ElevatedButton(onPressed: _saveSettings, child: Text('Save Settings')),
            ],
          ),
          Slider(
            value: selectedSpeed,
            onChanged: (newSpeed) {
              setState(() {
                selectedSpeed = newSpeed;
              });
            },
            min: 1.0,
            max: 5.0,
            divisions: 10,
            label: '${selectedSpeed.toStringAsFixed(1)}x Speed',
          ),
          DropdownButton<Color>(
            value: selectedColor,
            onChanged: (newColor) {
              setState(() {
                selectedColor = newColor!;
              });
            },
            items: [
              DropdownMenuItem(value: Colors.red, child: Text('Red')),
              DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
              DropdownMenuItem(value: Colors.green, child: Text('Green')),
            ],
          ),
          SwitchListTile(
            title: Text("Collision Effects"),
            value: collisionEnabled,
            onChanged: (value) {
              setState(() {
                collisionEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _dbHelper.close();
    super.dispose();
  }
}
