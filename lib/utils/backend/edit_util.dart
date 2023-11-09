import 'dart:isolate';

import 'package:jni/jni.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/backend/easy_edits_backend.dart';
import 'package:video_editor/utils/log_util.dart';
import 'package:video_editor/utils/notifier.dart';

Future<String> _prepareConfig() async {
  await ensureOutExists();

  final String json = await toEditorConfig();
  // Dump into a log.

  return json;
}

Future<void> edit() async {
  //TODO: Make sure that the state is fulfilled.
  final String json = await _prepareConfig();

  await logIntoFile('Starting editing process with config $json');

  await Isolate.run(() => FlutterWrapper.edit(JString.fromString(json)))
      .then((value) => notify('Done editing.'))
      .onError(dumpErrorAndNotify);
}

Future<void> exportSegments() async {
  //TODO: Make sure that the state is fulfilled.
  final String json = await _prepareConfig();
  await logIntoFile('Starting editing process with config $json');

  // Run the export process in a new isolate
  await Isolate.run(() => FlutterWrapper.exportSegments(JString.fromString(json)))
      .then((value) => notify('Done exporting the segments.'))
      .onError(dumpErrorAndNotify);
}
