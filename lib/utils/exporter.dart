import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_cli/ffmpeg_cli.dart' hide Stream;
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/notifier.dart';

/// Exports the beat-times as a "markerbox" (for premiere pro) compatible CSV format.
Future<void> exportAsCSV(final String? path) async {
  if (path == null) return;

  final File output = File(path);

  for (final double beat in config.beatStamps) {
    final Duration duration = Duration(milliseconds: beat.round());

    //hh:mm:ss:ms

    await output.writeAsString(
        '${duration.inHours}:${duration.inMinutes}:${duration.inSeconds}:${duration.inMilliseconds},,blue,"segment${config.beatStamps.indexOf(beat)}"\n',
        mode: FileMode.append);
  }
}