import 'dart:io';
import 'dart:isolate';

import 'package:jni/jni.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart';
import 'package:video_editor/utils/model/video_clip.dart';

/// generates a preview video for a given [VideoClip]
Future<void> generateClipPreview(final VideoClip clip) async {
  await config.ensureOutExists();

  // Check whether the clip already has a preview.
  if (config.videoProject.config.generatedPreviews.containsKey(clip.id)) {
    // delete the old file.
    final File previewFile = File(config.videoProject.config.generatedPreviews[clip.id]!);
    previewFile.deleteSync();

    // after that, generate a new preview.
  }

  final String json = config.previewSegmentJson(clip);

  // Run the preview process in a new isolate.
  final String path = await Isolate.run(
      () => FlutterWrapper.previewSegment(json.toJString()).toDartString(releaseOriginal: true));

  // add the path to the map
  config.videoProject.config.generatedPreviews[clip.id] = path;
}

Future<String> generateEditPreview() async {
  await config.ensureOutExists();

  // List of the generated video paths in the order of the clips.
  final List<String> paths = [];

  // Get the clips in order.
  for (final VideoClip clip in config.videoProject.config.videoClips) {
    if (config.videoProject.config.generatedPreviews.containsKey(clip.id)) {
      paths.add(config.videoProject.config.generatedPreviews[clip.id]!);
    }
  }

  final String json = config.previewJson(paths);

  // Run the preview process in a new isolate.
  final String path =
      await Isolate.run(() => FlutterWrapper.editPreviews(json.toJString()).toDartString());

  return path;
}
