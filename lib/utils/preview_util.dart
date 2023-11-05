import 'dart:io';
import 'dart:isolate';

import 'package:jni/jni.dart';
import 'package:video_editor/utils/config.dart';
import 'package:video_editor/utils/easy_edits_backend.dart';
import 'package:video_editor/utils/model/video_clip.dart';

Future<String> generateSinglePreview(final VideoClip videoClip) async {
  await ensureOutExists();

  // Check whether the clip already has a preview.
  if (config.generatedPreviews.containsKey(videoClip.id)) {
    // delete the old file.
    final File previewFile = File(config.generatedPreviews[videoClip.id]!);

    previewFile.exists().then((value) => previewFile.delete());
    // after that, generate a new preview.
  }

  final String json = previewSegmentJson(videoClip);

  // Run the preview process in a new isolate.
  final String path = await Isolate.run(
      () => FlutterWrapper.previewSegment(json.toJString()).toDartString(releaseOriginal: true));

  // add the path to the map
  return path;
}

Future<String> generateEditPreview() async {
  await ensureOutExists();

  // List of the generated video paths in the order of the clips.
  final List<String> paths = [];

  // Get the clips in order.
  for (final VideoClip clip in config.videoClips) {
    if (config.generatedPreviews.containsKey(clip.id)) {
      paths.add(config.generatedPreviews[clip.id]!);
    }
  }

  final String json = previewEditJson(paths);

  // Run the preview process in a new isolate.
  final String path =
      await Isolate.run(() => FlutterWrapper.editPreviews(json.toJString()).toDartString());

  return path;
}
