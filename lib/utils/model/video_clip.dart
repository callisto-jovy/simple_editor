import 'package:video_editor/utils/config.dart';
import 'package:video_editor/utils/model/timestamp.dart';

class VideoClip {
  /// UUID
  final String id;

  /// Reference to the clips [TimeStamp]
  final TimeStamp timeStamp;

  /// Whether the audio should be muted or not.
  bool audioMuted = true;

  Duration clipLength;

  VideoClip(
    this.timeStamp, {
    required this.clipLength,
  }) : id = kUuid.v4();

  VideoClip.fromJson(final Map<String, dynamic> json)
      : timeStamp = TimeStamp.fromJson(json['time_stamp']),
        id = json['id'],
        audioMuted = json['mute_audio'],
        clipLength = Duration(milliseconds: json['length']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'length': clipLength.inMilliseconds,
        'mute_audio': audioMuted,
        'time_stamp': timeStamp.toJson(),
      };
}
