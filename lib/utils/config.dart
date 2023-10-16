import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:video_editor/utils/model/project.dart';
import 'package:video_editor/utils/model/project_config.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:path/path.dart' as path;

/// Makes sure that the [Directory] exists
Future<void> ensureOutExists() async {
  final bool exists = await videoProject.workingDirectory.exists();
  if (!exists) {
    await videoProject.workingDirectory.create();
  }
}

/// The applications [JsonEncoder] with a specified indent of two.
const JsonEncoder encoder = JsonEncoder.withIndent('  ');

late VideoProject videoProject;

void fromJson(final Map<String, dynamic> json) {
  // Handle old app versions
  if (json['version'] == null) {
    _handleLegacyJson(json);
    return;
  }

  // NOTE:: Whenever the config is changed in major ways or needs to be handled differently due to breaking changes,
  // we can have a different method to read previous configs. At least after version 1.0.0 when saving the config again, the old config is overwritten.

  videoProject = VideoProject.fromJson(json);
}

Future<String> applicationState() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final json = videoProject.toJson(packageInfo.version);

  return encoder.convert(json);
}

/// Creates a JSON [String] with all the app's state to pass to the backend.
String toEditorConfig() {
  final json = videoProject.config.editorConfig();
  return encoder.convert(json);
}

void saveApplicationState() async {
  final File file = File(path.join(videoProject.projectPath, 'application_state.json'));
  final String appState = await applicationState();
  file.writeAsString(appState);
}

void importFile({String? path}) {
  if (path == null || path.isEmpty) return;

  final File file = File(path);
  dynamic json = jsonDecode(file.readAsStringSync());

  fromJson(json);
}

void _handleLegacyJson(final Map<String, dynamic> json) {
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
  videoProject = VideoProject('', projectName: 'NullProject', config: config);
}
