import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:video_editor/utils/config_util.dart';
import 'package:video_editor/utils/model/project.dart';
import 'package:video_editor/utils/model/project_config.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/preview_util.dart';

/// The applications [Uuid]
const Uuid kUuid = Uuid();

/// The applications [JsonEncoder] with a specified indent of two.
const JsonEncoder kEncoder = JsonEncoder.withIndent('  ');

/// the current [VideoProject], has not be not null.
late VideoProject videoProject;

/// Getter to the underlying project config, in order to reduce call length
ProjectConfig get config => videoProject.config;

/// Makes sure that the [Directory] exists
Future<void> ensureOutExists() async {
  final bool exists = await videoProject.workingDirectory.exists();
  if (!exists) {
    await videoProject.workingDirectory.create();
  }
}

void fromJson(final Map<String, dynamic> json) {
  // Handle old app versions
  if (json['version'] == null) {
    videoProject = handleLegacyJson(json);
    return;
  } else if (json['version'] == '1.0.0') {
    json['config']['beat_times'] =
        []; // add empty beat time list. saving the beat times has only been introduced in 1.1.0
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

void removeClip(final VideoClip videoClip) {
  // Delete old preview
  if (config.generatedPreviews.containsKey(videoClip.id)) {
    File(config.generatedPreviews[videoClip.id]!).delete();
  }

  config.generatedPreviews.remove(videoClip.id);
  config.videoClips.remove(videoClip);
}

Future<String> applicationState() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final json = videoProject.toJson(packageInfo.version);

  return kEncoder.convert(json);
}

Future<void> handlePreview(final String previewPath) async {
  /// Deletes the previous preview & sets the new path.
  if (config.previewPath.isNotEmpty) {
    await File(config.previewPath).delete();
  }

  config.previewPath = previewPath;
}

/// Creates a JSON [String] with all the app's state to pass to the backend.
String toEditorConfig() {
  final json = config.editorConfig();
  return kEncoder.convert(json);
}

String previewSegmentJson(final VideoClip videoClip) {
  final json = config.previewJson(videoClip);
  return kEncoder.convert(json);
}

String previewJson(final List<String> previews) {
  final json = config.previewEdit(previews);
  return kEncoder.convert(json);
}

void _setClipPath(final VideoClip videoClip, final String path) {
  config.generatedPreviews[videoClip.id] = path;
}

void createVideoClip(final VideoClip videoClip) {
  // add to the global list
  config.videoClips.add(videoClip);

  // Generate a preview of the clip. after that's finished, generate the edit preview.

  generateSinglePreview(videoClip).then((value) => _setClipPath(videoClip, value));
}

void updateVideoClip(final VideoClip videoClip) {
  final int indexOfClip = config.videoClips.indexOf(videoClip);

  // TODO: handle this
  if (indexOfClip == -1) {
    return;
  }

  final VideoClip oldVideoClip = config.videoClips[indexOfClip];
  // update the previous clip; TODO: Instead of replacing, edit the state?
  videoProject.config.videoClips[indexOfClip] = videoClip;

  if (videoClip.clipLength.inMilliseconds != oldVideoClip.clipLength.inMilliseconds) {
    // Trigger regenerate
    generateSinglePreview(videoClip).then((value) => _setClipPath(videoClip, value));
  }
}

void updateVideoClips(final List<VideoClip> clips) {
  for (final VideoClip element in clips) {
    updateVideoClip(element);
  }
}

Future<void> saveApplicationState() async {
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
