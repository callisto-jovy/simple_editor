import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';

class TimeStampPainter extends CustomPainter {
  //

  final double width = 2.5;

  final List<double> timeStamps;
  final double audioLength;
  final Offset? hitOffset;

  final Function(double) newTimeStamp;
  final Function(List<double>) hitTimeStamp;

  TimeStampPainter(
      {super.repaint,
      required this.timeStamps,
      required this.audioLength,
      required this.hitOffset,
      required this.newTimeStamp,
      required this.hitTimeStamp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = width
      ..strokeCap = StrokeCap.square;

    final List<double> markedForRemoval = [];

    for (final double timeStamp in timeStamps) {
      // dx = duration * width / length
      final double dx = timeStamp * size.width / audioLength;
      final Offset p0 = Offset(dx, 0);
      final Offset p1 = Offset(dx, size.height);

      // intersection hit with the offset, remove the timestamp

      if (hitOffset != null && (dx - hitOffset!.dx).abs() <= 2) {
        markedForRemoval.add(timeStamp);
      } else {
        canvas.drawLine(p0, p1, paint);

        final TextPainter indexTp = TextPainter(
            text: TextSpan(text: '${timeStamps.indexOf(timeStamp)}'),
            textDirection: TextDirection.ltr);
        indexTp.layout();
        indexTp.paint(canvas, p0.translate(-indexTp.width * 0.5, -indexTp.height));

        final TextPainter stampTp = TextPainter(
            text: TextSpan(text: Duration(milliseconds: timeStamp.round()).label()),
            textDirection: TextDirection.ltr);
        stampTp.layout();
        stampTp.paint(canvas, p1.translate(-stampTp.width * 0.5, 0)); // Center text
      }
    }

    // add new timestamp if no timestamps were hit & a hit offset exists
    if (markedForRemoval.isEmpty && hitOffset != null) {
      final double dx = hitOffset!.dx;
      // Just perform the calculation for d instead of x

      final double timeStampTime = (dx * audioLength) / size.width;
      // Add the new timestamp to the list of timestamps
      newTimeStamp.call(timeStampTime);

      // Draw timestamp
      final Offset p0 = Offset(dx, 0);
      final Offset p1 = Offset(dx, size.height);

      canvas.drawLine(p0, p1, paint);
    }

    // Remove hit timestamp(s)
    hitTimeStamp.call(markedForRemoval);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
