import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/widgets/timeline_editor.dart';

abstract class AbstractClip {
  /// The [Duration] of the clip. This is the time between the beats.
  Duration clipLength;

  ///
  Offset positionOffset;

  AbstractClip({required this.clipLength, required this.positionOffset});

  double get width => (clipLength.inMilliseconds * milliPixelMultiplier);

  double height(final Size size) => size.height;

  Offset constrainPosition(final RenderBox renderBox, final Offset offset) {
    // Elements are translated at their center.
    // therefore: Offset the center.

    final double limitX = clampDouble(offset.dx, width / 2, renderBox.size.width);

    final double limitY = height(renderBox.size) / 2;

    // Offset within the bounds.
    return Offset(limitX, limitY);
  }

  Rect paintingBounds(final Size size) => paintingBoundsOffset(positionOffset, size);

  Rect paintingBoundsOffset(final Offset offset, final Size size) =>
      Rect.fromCenter(center: offset, width: width, height: height(size));
}
