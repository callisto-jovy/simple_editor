import 'dart:io';

import 'package:video_editor/utils/config/config.dart';

/// Exports the beat-times as a "markerbox" (for premiere pro) compatible CSV format.
Future<void> exportAsCSV(final String? path) async {
  if (path == null) return;

  final File output = File(path);

  for (final double beat in config.beatStamps) {

    await output.writeAsString('${beat / 1000},,blue,"segment${config.beatStamps.indexOf(beat)}\n',
        mode: FileMode.append);
  }
}
