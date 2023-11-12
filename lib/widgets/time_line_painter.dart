import 'dart:math';

import 'package:flutter/material.dart';
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
        final Paint paint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blueAccent;

        final Path path = Path();

        // The clip's x position
        final double xPos = clip.positionOffset.dx - clip.width / 2;
        // The clip's y position
        final double yPos = clip.positionOffset.dy - clip.height(size) / 2;

        final double height = clip.height(size);

        // Process the samples
        final List<double> processedSamples = clip.samples.map((e) => e * height).toList();

        final maxNum = processedSamples.reduce((a, b) => max(a.abs(), b.abs()));

        if (maxNum > 0) {
          final double multiplier = pow(maxNum, -1).toDouble() * height / 2;

          final List<double> samples = processedSamples.map((e) => e * multiplier).toList();

          // move to
          path.moveTo(xPos, yPos);

          for (var i = 0; i < samples.length; ++i) {
            final double x = xPos + ((clip.width / samples.length) * i);
            final double y = yPos + samples[i];

            if (i == samples.length - 1) {
              path.lineTo(x, yPos);
            } else {
              path.lineTo(x, y);
            }
          }
        }

        //Gets the [alignPosition] depending on [waveformAlignment]
        final double alignPosition = height / 2;

        //Shifts the path along y-axis by amount of [alignPosition]
        final Path shiftedPath = path.shift(Offset(0, alignPosition));

        canvas.drawPath(shiftedPath, paint);
        canvas.drawRect(clip.paintingBounds(size), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
