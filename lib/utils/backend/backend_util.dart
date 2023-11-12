import 'dart:isolate';

import 'package:jni/jni.dart';
import 'package:path/path.dart';
import 'package:video_editor/utils/backend/easy_edits_backend.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/log_util.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/notifier.dart';



Future<void> edit() async {
  await ensureOutExists();

  //TODO: Make sure that the state is fulfilled.
  final config = editorConfig();
  final String json = kEncoder.convert(config);

  await logIntoFile('Starting editing process with config $json');

  await Isolate.run(() => FlutterWrapper.edit(JString.fromString(json)))
      .then((value) => notify('Done editing.'))
      .onError(dumpErrorAndNotify);
}

Future<void> exportSegments(final double duration) async {
  await ensureOutExists();

  final config = exportConfig(duration);
  final String json = kEncoder.convert(config);

  await logIntoFile('Starting editing process with config $json');

  // Run the export process in a new isolate
  await Isolate.run(() => FlutterWrapper.exportSegments(JString.fromString(json)))
      .then((value) => notify('Done exporting the segments.'))
      .onError(dumpErrorAndNotify);
}


List<Map<String, dynamic>> _videoClips() {
  final List<double> beatTimes = config.timeBetweenBeats();

  return config.videoClips.isEmpty
      ? config.timeStamps
          .asMap()
          .map((key, value) => MapEntry(key, {
                'time_stamp': value.start.inMicroseconds,
                'mute_audio': true,
                'clip_length': beatTimes[key] // TODO: Figure out, whether this works.
              }))
          .values
          .toList()
      : config.videoClips
          .map((e) => {
                'time_stamp': e.timeStamp.start.inMicroseconds,
                'mute_audio': e.audioMuted,
                'clip_length': e.clipLength.inMilliseconds
              })
          .toList();

  // NOTE:: breaking change for older backend versions.
}

Map<String, dynamic> exportConfig(final double segmentDuration) {
  final List<double> beatTimes = config.timeBetweenBeats();

  return {
    'source_video': config.videoPath,
    'output_path': videoProject.workingDirectory.path,
    'video_clips': config.timeStamps
        .asMap()
        .map((key, value) => MapEntry(key, {
              'time_stamp': value.start.inMicroseconds,
              'mute_audio': true,
              // Ternary hell
              'clip_length': segmentDuration == 0
                  ? (key > beatTimes.length
                      ? (10 * 1000) // Failsafe: All clips that have no length associated with them are just 10 seconds long
                      : beatTimes[key])
                  : (segmentDuration * 1000),
            }))
        .values
        .toList(),
    'editing_flags': config.editingOptions,
    'filters': config.filters
        .where((element) => element.enabled)
        .map((e) => {'name': e.name, 'values': e.values})
        .toList(),
  };
}

/// Converts the project's state into a json format which the Java-backend can understand.
/// This [Map] stores the most important information in order to configure the editor.
Map<String, dynamic> editorConfig() {
  return {
    'source_video': config.videoPath,
    'source_audio': config.audioPath,
    'peak_threshold': config.peakThreshold,
    'ms_threshold': config.msThreshold,
    'working_path': videoProject.workingDirectory.path,
    'output_path':
        join(videoProject.projectPath, '${basenameWithoutExtension(config.videoPath)}.mkv'),

    //TODO: Request file picker for filename and path.
    'editor_state': {
      'intro_start': config.introStart == null ? -1 : config.introStart!.inMicroseconds,
      'intro_end': config.introEnd == null ? -1 : config.introEnd!.inMicroseconds,
      'video_clips': _videoClips(),
      'editing_flags': config.editingOptions,
      'filters': config.filters
          .where((element) => element.enabled)
          .map((e) => {'name': e.name, 'values': e.values})
          .toList(),
    },
  };
}

Map<String, dynamic> previewJson(final VideoClip clip) {
  return {
    'source_video': config.videoPath,
    'working_path': videoProject.workingDirectory.path,
    'clip': {
      'time_stamp': clip.timeStamp.start.inMicroseconds,
      'mute_audio': clip.audioMuted,
      'clip_length': clip.clipLength.inMilliseconds
    },
    'filters': config.filters
        .where((element) => element.enabled)
        .map((e) => {'name': e.name, 'values': e.values})
        .toList(),
    'editing_flags': config.editingOptions,
  };
}

Map<String, dynamic> previewEdit(final List<String> previewPaths) {
  return {
    'source_video': config.videoPath,
    'source_audio': config.audioPath,
    'working_path': videoProject.workingDirectory.path,
    'filters': config.filters
        .where((element) => element.enabled)
        .map((e) => {'name': e.name, 'values': e.values})
        .toList(),
    'editing_flags': config.editingOptions,
    'previews': previewPaths,
  };
}
