import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:video_editor/utils/config/project.dart';
import 'package:video_editor/utils/config/project_config.dart';
import 'package:video_editor/utils/model/timestamp.dart';

VideoProject fromJson(final File file) {
  dynamic json = jsonDecode(file.readAsStringSync());

  // Handle old app versions
  if (json['version'] == null) {
    return handleLegacyJson(json, file.path);
  } else if (json['version'] == '1.0.0') {
    json['config']['beat_times'] =
        []; // add empty beat time list. saving the beat times has only been introduced in 1.1.0
  } else if (json['version'] == '1.1.0') {
    json['config']['video_clips'] = [];
  } else if (json['version'] == '1.1.1') {
    json['config']['preview_path'] = '';
    json['config']['clip_previews'] = {};
  } else if (json['version'] == '1.1.2') {
    json['config']['audio_data'] = {'path': ''};
  }
  // NOTE:: Whenever the config is changed in major ways or needs to be handled differently due to breaking changes,
  // we can have a different method to read previous configs. At least after version 1.0.0 when saving the config again, the old config is overwritten.

  return VideoProject.fromJson(json);
}

VideoProject handleLegacyJson(final Map<String, dynamic> json, final String importPath) {
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

  final String importDir = dirname(importPath);

  return VideoProject(importDir, projectName: 'Unnamed project', config: config);
}
