import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final IO.Socket socket = IO.io('http://localhost:8080');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('실시간 스케치 공동 작업'),
        ),
        body: Center(
          child: SketchArea(socket: socket),
        ),
      ),
    );
  }
}

class SketchArea extends StatefulWidget {
  final IO.Socket socket;

  SketchArea({required this.socket});

  @override
  _SketchAreaState createState() => _SketchAreaState();
}

class _SketchAreaState extends State<SketchArea> {
  List<Offset> _points = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      color: Colors.grey,
      child: GestureDetector(
        onPanUpdate: (details) {
          _handlePanUpdate(details);
        },
        onPanEnd: (details) {
          _handlePanEnd(details);
        },
        child: CustomPaint(
          painter: SketchPainter(points: _points),
        ),
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      RenderBox renderBox = context.findRenderObject() as RenderBox;
      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
      _points.add(localPosition);
    });

    Future.microtask(() {
      widget.socket.emit('sketchData', {
        'x': details.globalPosition.dx,
        'y': details.globalPosition.dy,
      });
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _points.add(Offset.infinite);
    });
  }
}

class SketchPainter extends CustomPainter {
  final List<Offset> points;

  SketchPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SketchPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.points.contains(Offset.infinite) ||
        points.contains(Offset.infinite);
  }
}
