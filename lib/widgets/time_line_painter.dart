import 'package:flutter/material.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/model/abstract_clip.dart';
import 'package:video_editor/utils/model/audio_clip.dart';

class TimeLinePainter<T extends AbstractClip> extends CustomPainter {
  final List<T> clips;
  final T? draggingClip;
  final String Function(T) textFunction;

  TimeLinePainter(
      {super.repaint, required this.draggingClip, required this.clips, required this.textFunction});

  @override
  void paint(final Canvas canvas, final Size size) {

  /*  if (T is! AudioClip) {
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
        indexTp.paint(
            canvas, paintRect.center.translate(-indexTp.width * 0.5, -indexTp.height / 2));
      }
    }*/

    if (T == AudioClip) {

      for (final T clip in clips) {
        clip as AudioClip;

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.redAccent;

        final path = Path();

        for (var i = 0; i < clip.samples.length; i++) {
          final x = (size.width / clip.samples.length) * i;
          final y = clip.samples[i];

          if (i == clip.samples.length - 1) {
            path.lineTo(x, 0);
          } else {
            path.lineTo(x, y);
          }
        }

        //Gets the [alignPosition] depending on [waveformAlignment]
        final alignPosition = size.height / 2;

        //Shifts the path along y-axis by amount of [alignPosition]
        final shiftedPath = path.shift(Offset(0, alignPosition));

        canvas.drawPath(shiftedPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
