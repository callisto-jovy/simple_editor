import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/utils/model/abstract_clip.dart';

class AudioClip extends AbstractClip {
  Duration timeStamp;

  AudioClip({required this.timeStamp, required super.clipLength, required super.positionOffset});

  @override
  double height(Size size) => size.height / 4;

  @override
  Offset constrainPosition(RenderBox renderBox, Offset offset) {
    final double limitX = clampDouble(offset.dx, width / 2, renderBox.size.width - width / 2);

    final double limitY = clampDouble(offset.dy, height(renderBox.size) / 2, renderBox.size.height - height(renderBox.size) / 2);

    // Offset within the bounds.
    return Offset(limitX, limitY);
  }

  @override
  Rect paintingBoundsOffset(Offset offset, Size size) {
    return Rect.fromCenter(center: offset, width: width, height: height(size));
  }

  @override
  Rect paintingBounds(Size size) {
    return paintingBoundsOffset(positionOffset, size);
  }
}
