
import 'package:flutter/material.dart';

abstract class AbstractClip {

  /// The [Duration] of the clip. This is the time between the beats.
  Duration clipLength;

  ///
  Offset positionOffset;

  AbstractClip({required this.clipLength, required this.positionOffset});


  Offset constrainPosition(final RenderBox renderBox, final Offset offset) {
    // Elements are translated at their center.
    // therefore: Offset the center.
    final Rect ownBounds = paintingBoundsOffset(offset, renderBox.size);

    final double limitX =
    offset.dx.clamp(ownBounds.width / 2, renderBox.size.width - ownBounds.width / 2);
    final double limitY =
    offset.dy.clamp(ownBounds.height / 2, renderBox.size.height - ownBounds.height / 2);

    // Offset within the bounds.
    return Offset(limitX, limitY);
  }

  // TODO: from size
  Rect paintingBounds(final Size size) =>
      paintingBoundsOffset(positionOffset, size);

  // TODO: from size
  Rect paintingBoundsOffset(final Offset offset, final Size size) =>
      Rect.fromCenter(center: offset, width: 120, height: 40);
}
