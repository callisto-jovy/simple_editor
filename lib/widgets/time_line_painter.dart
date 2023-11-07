import 'package:flutter/material.dart';
import 'package:video_editor/utils/model/abstract_clip.dart';

class TimeLinePainter<T extends AbstractClip> extends CustomPainter {
  final List<T> clips;
  final T? draggingClip;
  final String Function(T) textFunction;

  TimeLinePainter(
      {super.repaint, required this.draggingClip, required this.clips, required this.textFunction});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..color = Colors.redAccent;
    final paintSelected = Paint()..color = Colors.blue;

    for (final T clip in clips) {
      final Rect paintRect = clip.paintingBounds(size);

      if (clip == draggingClip) {
        canvas.drawRect(paintRect, paintSelected);
      } else {
        canvas.drawRect(paintRect, paint);
      }

      final TextPainter indexTp =
          TextPainter(text: TextSpan(text: textFunction(clip)), textDirection: TextDirection.ltr);
      indexTp.layout();
      indexTp.paint(canvas, paintRect.center.translate(-indexTp.width * 0.5, -indexTp.height / 2));
    }
  }




  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
