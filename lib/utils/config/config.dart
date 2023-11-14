import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:video_editor/utils/audio/audio_data_util.dart';
import 'package:video_editor/utils/audio/background_audio.dart';
import 'package:video_editor/utils/backend/backend_util.dart';
import 'package:video_editor/utils/backend/preview_util.dart';
import 'package:video_editor/utils/config/config_util.dart';
import 'package:video_editor/utils/config/project.dart';
import 'package:video_editor/utils/config/project_config.dart';
import 'package:video_editor/utils/model/video_clip.dart';

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

Future<void> setAudioPath(final String path) async {
  config.audioPath = path;
  return loadBackgroundAudio();
}

void removeClip(final VideoClip videoClip) {
  // Delete old preview
  if (config.generatedPreviews.containsKey(videoClip.id)) {
    final File file = File(config.generatedPreviews[videoClip.id]!);

    file.exists().then((value) {
      if (value) {
        file.delete();
      }
    });
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
    final File previewFile = File(config.previewPath);
    previewFile.exists().then((value) => previewFile.delete());
  }

  config.previewPath = previewPath;
}

String previewSegmentJson(final VideoClip videoClip) {
  final json = previewJson(videoClip);
  return kEncoder.convert(json);
}

String previewEditJson(final List<String> previews) {
  final json = previewEdit(previews);
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

Future<void> updateVideoClip(final VideoClip videoClip) async {
  final int indexOfClip = config.videoClips.indexOf(videoClip);

  // TODO: handle this
  if (indexOfClip == -1) {
    return;
  }

  // update the previous clip; TODO: Instead of replacing, edit the state?
  videoProject.config.videoClips[indexOfClip] = videoClip;

  // Trigger regenerate
  await generateSinglePreview(videoClip).then((value) => _setClipPath(videoClip, value));
}

Future<void> updateVideoClips(final List<VideoClip> clips) async {
  for (final VideoClip element in clips) {
    await updateVideoClip(element);
  }
}

void updateClipTimes() {
  final List<double> beatTimes = config.timeBetweenBeats();

  for (int i = 0; i < beatTimes.length; i++) {
    if (i < config.videoClips.length) {
      config.videoClips[i].clipLength = Duration(milliseconds: beatTimes[i].round());
    }
  }
}

Future<void> saveApplicationState() async {
  final File file = File(path.join(videoProject.projectPath, 'application_state.json'));
  final String appState = await applicationState();
  file.writeAsString(appState);
}

Stream<(String, int)> _importProject(final File file) async* {
  yield ('Importing project file', 50);

  videoProject = fromJson(file);

  yield ('Loading audio source.', 70);
  await loadBackgroundAudio();

  yield ('Extracting audio from source.', 80);
  config.audioData = await readVideoFile(config.videoPath);

  yield ('Done extracting', 100);
}

Future<Stream<(String, int)>> importProject({String? path}) async {
  // Error handling, display error message: Could not import project
  if (path == null || path.isEmpty) {
    return Future.error('Could not import project. The project file does not exist.');
  }

  final File file = File(path);
  if (!file.existsSync()) {
    return Future.error('Could not import project. The project file does not exist.');
  }

  return _importProject(file);
}
