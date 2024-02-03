import 'dart:isolate';

import 'package:jni/jni.dart';
import 'package:video_editor/utils/backend/easy_edits_backend.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/log_util.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/notifier.dart';

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

Future<void> exportSegment(final TimeStamp timeStamp, final double segmentDuration) async {
  await ensureOutExists();

  final json = {
    'source_video': config.videoPath,
    'output_path': videoProject.workingDirectory.path,
    'video_clips': [
      {
        'time_stamp': timeStamp.start.inMicroseconds,
        'mute_audio': false,
        'clip_length': segmentDuration == 0 ? 1000 * 10 : segmentDuration * 1000,
      }
    ],
    'editing_flags': config.editingOptions,
    'filters': config.filters
        .where((element) => element.enabled)
        .map((e) => {'name': e.name, 'values': e.values})
        .toList()
  };

  final String jsonString = kEncoder.convert(json);

  await logIntoFile('Starting editing process with config $json');

// Run the export process in a new isolate
  await Isolate.run(() => FlutterWrapper.exportSegments(JString.fromString(jsonString)))
      .then((value) => notify('Done exporting the segments.'))
      .onError(dumpErrorAndNotify);
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
              'mute_audio': false,
// Ternary hell
              'clip_length': segmentDuration == 0
                  ? (key > beatTimes.length
                      ? (10 *
                          1000) // Failsafe: All clips that have no length associated with them are just 10 seconds long
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
