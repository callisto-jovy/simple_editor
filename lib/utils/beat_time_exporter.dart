import 'dart:io';

import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/utils/config/config.dart';

/// Exports the beat-times as a "markerbox" (for premiere pro) compatible CSV format.
Future<void> exportAsCSV(final String? path) async {
  if (path == null) return;

  final File output = File(path);

  for (final double beat in config.beatStamps) {

    final Duration duration = Duration(milliseconds: beat.round());

    //hh:mm:ss:ms

    await output.writeAsString('${duration.inHours}:${duration.inMinutes}:${duration.inSeconds}:${duration.inMilliseconds},,blue,"segment${config.beatStamps.indexOf(beat)}"\n',
        mode: FileMode.append);
  }
}
