import 'package:flutter/cupertino.dart';
import 'package:video_editor/utils/config.dart';
import 'package:video_editor/utils/model/abstract_clip.dart';
import 'package:video_editor/utils/model/timestamp.dart';

class VideoClip extends AbstractClip {
  /// UUID
  final String id;

  /// Reference to the clips [TimeStamp]
  final TimeStamp timeStamp;

  /// Whether the audio should be muted or not.
  bool audioMuted = true;

  //TODO: JSON

  VideoClip(this.timeStamp, {required super.clipLength, required super.positionOffset})
      : id = kUuid.v4();

  VideoClip.fromJson(final Map<String, dynamic> json)
      : timeStamp = TimeStamp.fromJson(json['time_stamp']),
        id = json['id'],
        audioMuted = json['mute_audio'],
        super(
            clipLength: Duration(milliseconds: json['length']),
            positionOffset: const Offset(0, 0)); // TODO: JSON

  Map<String, dynamic> toJson() => {
        'id': id,
        'length': clipLength.inMilliseconds,
        'mute_audio': audioMuted,
        'time_stamp': timeStamp.toJson()
      };
}
