import 'dart:typed_data';

import 'package:fast_image_resizer/fast_image_resizer.dart';

class TimeStamp {
  final Duration start;
  final ByteData? startFrame;

  TimeStamp(this.start, this.startFrame);
}

Future<TimeStamp> createTimeStamp(final Duration time, final Uint8List? frame) async {
  if (frame == null) {
    return TimeStamp(time, null);
  }
  final ByteData? bytes = await resizeImage(frame, height: 100);
  return TimeStamp(time, bytes);
}
