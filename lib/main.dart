import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
        scaling = true; // Initially set scaling to true to trigger grow/shrink effect

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AnimatedScale(
        scale: scaling ? 1.2 : 1.0, // Scale slightly larger when added
        duration: const Duration(seconds: 1),
        onEnd: () {
          scaling = false; // Reset scaling after animation ends
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

// Custom Painter class to draw a fish
class FishPainter extends CustomPainter {
  final Color color;

  FishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw fish body (oval shape)
    canvas.drawOval(
      Rect.fromLTWH(0, size.height / 4, size.width * 0.7, size.height * 0.5),
      paint,
    );

    // Draw tail (triangle shape)
    var tailPath = Path();
    tailPath.moveTo(size.width * 0.7, size.height / 2);
    tailPath.lineTo(size.width * 0.9, size.height * 0.3);
    tailPath.lineTo(size.width * 0.9, size.height * 0.7);
    tailPath.close();
    canvas.drawPath(tailPath, paint);

    // Draw eye (small circle)
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
  Database? _database;

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
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings (id INTEGER PRIMARY KEY, fishCount INTEGER, fishSpeed REAL, fishColor TEXT)',
        );
      },
      version: 1,
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final List<Map<String, dynamic>> settings = await _database!.query('settings');
    if (settings.isNotEmpty) {
      setState(() {
        selectedSpeed = settings[0]['fishSpeed'];
        selectedColor = Color(int.parse(settings[0]['fishColor']));
        fishList = List.generate(settings[0]['fishCount'], (index) {
          return Fish(color: selectedColor, speed: selectedSpeed);
        });
      });
    }
  }

  Future<void> _saveSettings() async {
    await _database!.insert('settings', {
      'fishCount': fishList.length,
      'fishSpeed': selectedSpeed,
      'fishColor': selectedColor.value.toString(),
    });
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        Fish newFish = Fish(color: selectedColor, speed: selectedSpeed);
        newFish.scaling = true; // Enable scaling effect for new fish
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
          // Collision detected, change direction and random color
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
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
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
          // Aquarium Container
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              color: Colors.lightBlue[100], // Simulates water
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: fishList.map((fish) => fish.buildFish()).toList(),
            ),
          ),
          SizedBox(height: 20),
          // Control Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              ElevatedButton(onPressed: _saveSettings, child: Text('Save Settings')),
            ],
          ),
          // Speed Slider
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
          // Color Picker (can be a dropdown or custom color picker)
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
    _database?.close();
    super.dispose();
  }
}
