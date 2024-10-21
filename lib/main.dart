import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
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

  Fish({required this.color, required this.speed})
      : dx = (Random().nextDouble() - 0.5) * speed,
        dy = (Random().nextDouble() - 0.5) * speed,
        position = Offset(150, 150);

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: CustomPaint(
        size: Size(50, 30),
        painter: FishPainter(color: color),
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

class _VirtualAquariumState extends State<VirtualAquarium> with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  double selectedSpeed = 1.0;
  Color selectedColor = Colors.blue;
  late AnimationController _controller;

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
  }

  void _moveFish() {
    for (Fish fish in fishList) {
      fish.moveFish();
    }
    setState(() {});
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
              ElevatedButton(
                onPressed: () {
                  if (fishList.length < 10) {
                    setState(() {
                      fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
                    });
                  }
                },
                child: Text('Add Fish'),
              ),
              SizedBox(width: 10),
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
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Speed: ${selectedSpeed.toStringAsFixed(1)}x'),
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
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
