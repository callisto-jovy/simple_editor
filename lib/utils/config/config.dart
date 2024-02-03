import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:video_editor/utils/audio/background_audio.dart';
import 'package:video_editor/utils/config/config_util.dart';
import 'package:video_editor/utils/config/project.dart';
import 'package:video_editor/utils/config/project_config.dart';

/// The applications [Uuid]
const Uuid kUuid = Uuid();

/// The applications [JsonEncoder] with a specified indent of two.
const JsonEncoder kEncoder = JsonEncoder.withIndent('  ');

/// the current [VideoProject], has not be not null.
late VideoProject videoProject;

/// Getter to the underlying project config, in order to reduce call length
ProjectConfig get config => videoProject.config;

/// Makes sure that the working [Directory] exists
Future<void> ensureOutExists() async {
  final bool exists = await videoProject.workingDirectory.exists();
  if (!exists) {
    await videoProject.workingDirectory.create();
  }
}

/// Helper setter method in order to make sure
Future<void> setAudioPath(final String path) async {
  config.audioPath = path;
  return loadBackgroundAudio();
}

void fromJson(final Map<String, dynamic> json) {
  // Handle old app versions
  if (json['version'] == null) {
    videoProject = handleLegacyJson(json);
    return;
  } else if (json['version'] == '1.0.0') {
    json['config']['beat_times'] = []; // add empty beat time list. saving the beat times has only been introduced in 1.1.0
  } else if (json['version'] == '1.1.0') {
    json['config']['video_clips'] = [];
  } else if (json['version'] == '1.1.1') {
    json['config']['preview_path'] = '';
    json['config']['clip_previews'] = {};
  }
  // NOTE:: Whenever the config is changed in major ways or needs to be handled differently due to breaking changes,
  // we can have a different method to read previous configs. At least after version 1.0.0 when saving the config again, the old config is overwritten.

  videoProject = VideoProject.fromJson(json);
}

Future<String> applicationState() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final json = videoProject.toJson(packageInfo.version);

  return kEncoder.convert(json);
}

Future<void> handlePreview(final String previewPath) async {
  /// Deletes the previous preview & sets the new path.
  if (config.previewPath.isNotEmpty) {
    final File previewFile = File(config.previewPath);
    previewFile.exists().then((value) => previewFile.delete());
  }

  config.previewPath = previewPath;
}

/// Creates a JSON [String] with all the app's state to pass to the backend.
Future<String> toEditorConfig() async {
  final json = await config.editorConfig();
  return kEncoder.convert(json);
}

Future<void> saveApplicationState() async {
  final File file = File(path.join(videoProject.projectPath, 'application_state.json'));
  final String appState = await applicationState();
  file.writeAsString(appState);
}

Future<void> importFile({String? path}) async {
  if (path == null || path.isEmpty) return;

  final File file = File(path);
  dynamic json = jsonDecode(file.readAsStringSync());

  fromJson(json);
  await loadBackgroundAudio();
}
