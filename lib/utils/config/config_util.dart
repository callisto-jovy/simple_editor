import 'dart:convert';

import 'package:video_editor/utils/config/project.dart';
import 'package:video_editor/utils/config/project_config.dart';
import 'package:video_editor/utils/model/timestamp.dart';

VideoProject handleLegacyJson(final Map<String, dynamic> json) {
  final ProjectConfig config = ProjectConfig();

  config.peakThreshold = json['peak_threshold'];
  config.msThreshold = json['ms_threshold'];
  config.videoPath = json['source_video'];
  config.audioPath = json['source_audio'];

  dynamic editorState = json['editor_state'];

  config.introStart = Duration(microseconds: editorState['intro_start']);
  config.introEnd = Duration(microseconds: editorState['intro_end']);

  final List<dynamic> micros = editorState['time_stamps'];
  final List<dynamic>? thumbnails = json['thumbnails'];

  for (int i = 0; i < micros.length; i++) {
    final Duration duration = Duration(microseconds: micros[i]);

    if (thumbnails != null && thumbnails.length > i && thumbnails[i] != null) {
      final String thumbnail = thumbnails[i];
      config.timeStamps.add(TimeStamp(duration, base64Decode(thumbnail).buffer.asByteData()));
    } else {
      config.timeStamps.add(TimeStamp(duration, null));
    }
  }

  return VideoProject('', projectName: 'Unnamed project', config: config);
}
