import 'package:flutter/material.dart';

class TimeStampPainter extends CustomPainter {
  //

  final List<double> timeStamps;
  final int audioLength;

  TimeStampPainter(this.timeStamps, this.audioLength);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    for (final double timeStamp in timeStamps) {
      final Offset p0 = Offset(timeStamp * size.width / audioLength, 0);
      final Offset p1 = Offset(timeStamp * size.width / audioLength, size.height);

      canvas.drawLine(p0, p1, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}
