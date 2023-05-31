import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final WebSocketChannel channel =
  WebSocketChannel.connect(Uri.parse('ws://localhost:8080'));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('실시간 스케치 공동 작업'),
        ),
        body: Center(
          child: SketchArea(channel: channel),
        ),
      ),
    );
  }
}

class SketchArea extends StatefulWidget {
  final WebSocketChannel channel;
  SketchArea({required this.channel});

  @override
  _SketchAreaState createState() => _SketchAreaState();
}

class _SketchAreaState extends State<SketchArea> {
  List<Offset> _points = [];

  @override
  void initState() {
    super.initState();
    widget.channel.stream.listen((message) {
      // 브로드캐스트된 데이터를 수신하여 처리
      print('Received broadcast data: $message');
    });
  }

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
      Map<String, dynamic> data = {
        'x': details.globalPosition.dx,
        'y': details.globalPosition.dy,
      };
      String jsonData = json.encode(data);
      widget.channel.sink.add(jsonData);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _points.add(Offset.infinite);
    });
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
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
