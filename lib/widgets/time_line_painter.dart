import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/utils/model/video_clip.dart';

class TimeLinePainter extends CustomPainter {
  final List<VideoClip> videoClips;
  final VideoClip? draggingClip;

  TimeLinePainter({super.repaint, required this.draggingClip, required this.videoClips});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    for (final VideoClip clip in videoClips) {
      final Rect paintRect = clip.paintingBounds(size);

      if (clip == draggingClip) {
        canvas.drawRect(paintRect, paint..color = Colors.blueGrey);
      } else {
        canvas.drawRect(paintRect, paint);
      }

      final TextPainter indexTp = TextPainter(
          text: TextSpan(text: clip.timeStamp.start.label()), textDirection: TextDirection.ltr);
      indexTp.layout();
      indexTp.paint(canvas, paintRect.center.translate(-indexTp.width * 0.5, -indexTp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
