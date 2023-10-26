import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_image_resizer/fast_image_resizer.dart';

class TimeStamp {

  Duration start;
  final ByteData? startFrame;

  TimeStamp(this.start, this.startFrame);

  TimeStamp.fromJson(Map<String, dynamic> json)
      : start = Duration(microseconds: json['time']),
        startFrame = base64Decode(json['thumbnail']).buffer.asByteData();

  Map<String, dynamic> toJson() => {
        'time': start.inMicroseconds,
        'thumbnail': startFrame == null ? null : base64Encode(Uint8List.view(startFrame!.buffer)),
      };
}

Future<TimeStamp> createTimeStamp(final Duration time, final Uint8List? frame) async {
  if (frame == null) {
    return TimeStamp(time, null);
  }
  final ByteData? bytes = await resizeImage(frame, height: 100);
  return TimeStamp(time, bytes);
}
