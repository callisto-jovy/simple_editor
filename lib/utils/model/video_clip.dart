import 'dart:ui';

import 'package:video_editor/utils/config.dart';
import 'package:video_editor/utils/model/timestamp.dart';

class VideoClip {
  /// UUID
  final String id;

  /// Reference to the clips [TimeStamp]
  final TimeStamp timeStamp;

  /// The [Duration] of the clip. This is the time between the beats.
  Duration clipLength;

  /// Whether the audio should be muted or not.
  bool audioMuted = true;

  //TODO: JSON
  Offset? positionOffset;

  VideoClip(this.timeStamp, this.clipLength, {this.positionOffset}) : id = kUuid.v4();

  // TODO: from size
  Rect paintingBounds(final Size size) =>
      paintingBoundsOffset(positionOffset ?? const Offset(0, 0), size);

  // TODO: from size
  Rect paintingBoundsOffset(final Offset offset, final Size size) =>
      Rect.fromCenter(center: offset, width: 120, height: 40);

  VideoClip.fromJson(final Map<String, dynamic> json)
      : timeStamp = TimeStamp.fromJson(json['time_stamp']),
        id = json['id'],
        clipLength = Duration(milliseconds: json['length']),
        audioMuted = json['mute_audio'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'length': clipLength.inMilliseconds,
        'mute_audio': audioMuted,
        'time_stamp': timeStamp.toJson()
      };
}
